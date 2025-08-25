import 'dart:async';
import 'dart:math';
import '../../../core/game/game_base.dart';

/// Word Blitz game implementation
class WordBlitzGame extends GameBase {
  static const String gameTypeId = 'word_blitz';
  
  // Game configuration
  final List<String> _availableThemes;
  final int _roundsToWin;
  final Duration _roundTimeout;
  final bool _allowCustomThemes;
  
  // Game state
  String _gameId;
  List<String> _playerIds = [];
  String _currentTheme = '';
  String? _currentLetter;
  List<String> _activePlayers = [];
  List<String> _eliminatedPlayers = [];
  Map<String, int> _playerWins = {};
  int _currentRound = 0;
  bool _isRoundActive = false;
  bool _isGameFinished = false;
  String? _gameWinner;
  DateTime? _roundStartTime;
  Timer? _roundTimer;
  
  // Event stream
  final StreamController<GameEvent> _eventController = StreamController<GameEvent>.broadcast();
  
  // Random number generator for letter selection
  final Random _random = Random();
  
  // Available letters (excluding difficult ones)
  static const List<String> _availableLetters = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y'
  ];

  WordBlitzGame({
    String? gameId,
    List<String>? availableThemes,
    int roundsToWin = 3,
    Duration roundTimeout = const Duration(minutes: 2),
    bool allowCustomThemes = false,
  }) : _gameId = gameId ?? 'word_blitz_${DateTime.now().millisecondsSinceEpoch}',
       _availableThemes = availableThemes ?? [
         'Countries',
         'Famous People',
         'Capital Cities',
         'Movies',
         'TV Series',
         'Animals',
         'Food',
         'Sports',
       ],
       _roundsToWin = roundsToWin,
       _roundTimeout = roundTimeout,
       _allowCustomThemes = allowCustomThemes;

  @override
  String get gameId => _gameId;

  @override
  String get gameName => 'Word Blitz';

  @override
  String get gameType => gameTypeId;

  @override
  int get minPlayers => 3;

  @override
  int get maxPlayers => 10;

  @override
  bool get isGameFinished => _isGameFinished;

  @override
  Map<String, dynamic> get gameState => {
    'gameId': _gameId,
    'currentTheme': _currentTheme,
    'currentLetter': _currentLetter,
    'activePlayers': _activePlayers,
    'eliminatedPlayers': _eliminatedPlayers,
    'playerWins': _playerWins,
    'currentRound': _currentRound,
    'isRoundActive': _isRoundActive,
    'isGameFinished': _isGameFinished,
    'gameWinner': _gameWinner,
    'roundStartTime': _roundStartTime?.toIso8601String(),
    'availableThemes': _availableThemes,
    'roundsToWin': _roundsToWin,
    'roundTimeoutMinutes': _roundTimeout.inMinutes,
    'allowCustomThemes': _allowCustomThemes,
  };

  @override
  Map<String, dynamic> get gameResults => {
    'winner': _gameWinner,
    'playerWins': _playerWins,
    'totalRounds': _currentRound,
    'gameFinished': _isGameFinished,
    'finalTheme': _currentTheme,
  };

  @override
  Stream<GameEvent> get gameEvents => _eventController.stream;

  @override
  Future<void> initializeGame(List<String> playerIds) async {
    if (playerIds.length < minPlayers || playerIds.length > maxPlayers) {
      throw ArgumentError('Invalid player count: ${playerIds.length}. Must be between $minPlayers and $maxPlayers.');
    }

    _playerIds = List.from(playerIds);
    _activePlayers = List.from(playerIds);
    _eliminatedPlayers.clear();
    _playerWins.clear();
    
    // Initialize player wins
    for (final playerId in playerIds) {
      _playerWins[playerId] = 0;
    }
    
    _currentRound = 0;
    _isRoundActive = false;
    _isGameFinished = false;
    _gameWinner = null;
    _currentTheme = '';
    _currentLetter = null;
    _roundStartTime = null;

    _emitEvent('game_initialized', {
      'playerIds': _playerIds,
      'availableThemes': _availableThemes,
    });
  }

  @override
  Future<void> startGame() async {
    if (_playerIds.isEmpty) {
      throw StateError('Game not initialized. Call initializeGame first.');
    }

    _emitEvent('game_started', {
      'playerCount': _playerIds.length,
      'roundsToWin': _roundsToWin,
    });
  }

  @override
  Future<GameActionResult> processAction(String playerId, GameAction action) async {
    try {
      switch (action.type) {
        case 'set_theme':
          return await _handleSetTheme(playerId, action);
        case 'generate_letter':
          return await _handleGenerateLetter(playerId, action);
        case 'eliminate_player':
          return await _handleEliminatePlayer(playerId, action);
        case 'start_round':
          return await _handleStartRound(playerId, action);
        case 'end_round':
          return await _handleEndRound(playerId, action);
        case 'add_custom_theme':
          return await _handleAddCustomTheme(playerId, action);
        default:
          return GameActionResult.error('Unknown action type: ${action.type}');
      }
    } catch (e) {
      return GameActionResult.error('Action failed: $e');
    }
  }

  @override
  Future<void> endGame() async {
    _isGameFinished = true;
    _isRoundActive = false;
    _roundTimer?.cancel();
    
    _emitEvent('game_ended', {
      'winner': _gameWinner,
      'playerWins': _playerWins,
      'totalRounds': _currentRound,
    });
  }

  @override
  void dispose() {
    _roundTimer?.cancel();
    _eventController.close();
  }

  // Theme management
  Future<GameActionResult> _handleSetTheme(String playerId, GameAction action) async {
    final theme = action.data['theme'] as String?;
    if (theme == null || theme.isEmpty) {
      return GameActionResult.error('Theme cannot be empty');
    }

    // Validate theme if custom themes are not allowed
    if (!_allowCustomThemes && !_availableThemes.contains(theme)) {
      return GameActionResult.error('Theme not available: $theme');
    }

    _currentTheme = theme;
    
    _emitEvent('theme_selected', {
      'theme': theme,
      'selectedBy': playerId,
    });

    return GameActionResult.success({'theme': theme});
  }

  // Letter generation
  Future<GameActionResult> _handleGenerateLetter(String playerId, GameAction action) async {
    if (_currentTheme.isEmpty) {
      return GameActionResult.error('Theme must be set before generating letter');
    }

    _currentLetter = _availableLetters[_random.nextInt(_availableLetters.length)];
    
    _emitEvent('letter_generated', {
      'letter': _currentLetter,
      'theme': _currentTheme,
      'generatedBy': playerId,
    });

    return GameActionResult.success({'letter': _currentLetter});
  }

  // Player elimination
  Future<GameActionResult> _handleEliminatePlayer(String playerId, GameAction action) async {
    final targetPlayerId = action.data['targetPlayerId'] as String?;
    if (targetPlayerId == null) {
      return GameActionResult.error('Target player ID is required');
    }

    if (!_activePlayers.contains(targetPlayerId)) {
      return GameActionResult.error('Player is not active: $targetPlayerId');
    }

    _activePlayers.remove(targetPlayerId);
    _eliminatedPlayers.add(targetPlayerId);

    _emitEvent('player_eliminated', {
      'eliminatedPlayer': targetPlayerId,
      'eliminatedBy': playerId,
      'activePlayers': _activePlayers,
      'eliminatedPlayers': _eliminatedPlayers,
    });

    // Check if round is won
    if (_activePlayers.length == 1) {
      await _handleRoundWon(_activePlayers.first);
    }

    return GameActionResult.success({
      'eliminatedPlayer': targetPlayerId,
      'activePlayers': _activePlayers,
    });
  }

  // Round management
  Future<GameActionResult> _handleStartRound(String playerId, GameAction action) async {
    if (_currentTheme.isEmpty) {
      return GameActionResult.error('Theme must be set before starting round');
    }

    _currentRound++;
    _isRoundActive = true;
    _roundStartTime = DateTime.now();
    
    // Reset active players for new round
    _activePlayers = List.from(_playerIds);
    _eliminatedPlayers.clear();

    // Start round timer
    _startRoundTimer();

    _emitEvent('round_started', {
      'round': _currentRound,
      'theme': _currentTheme,
      'startTime': _roundStartTime!.toIso8601String(),
      'timeoutMinutes': _roundTimeout.inMinutes,
    });

    return GameActionResult.success({
      'round': _currentRound,
      'theme': _currentTheme,
    });
  }

  Future<GameActionResult> _handleEndRound(String playerId, GameAction action) async {
    if (!_isRoundActive) {
      return GameActionResult.error('No active round to end');
    }

    _isRoundActive = false;
    _roundTimer?.cancel();
    _currentLetter = null;

    _emitEvent('round_ended', {
      'round': _currentRound,
      'endedBy': playerId,
      'activePlayers': _activePlayers,
    });

    return GameActionResult.success({
      'round': _currentRound,
      'activePlayers': _activePlayers,
    });
  }

  // Custom theme handling
  Future<GameActionResult> _handleAddCustomTheme(String playerId, GameAction action) async {
    if (!_allowCustomThemes) {
      return GameActionResult.error('Custom themes are not allowed');
    }

    final theme = action.data['theme'] as String?;
    if (theme == null || theme.isEmpty) {
      return GameActionResult.error('Theme cannot be empty');
    }

    if (_availableThemes.contains(theme)) {
      return GameActionResult.error('Theme already exists');
    }

    _availableThemes.add(theme);

    _emitEvent('custom_theme_added', {
      'theme': theme,
      'addedBy': playerId,
      'availableThemes': _availableThemes,
    });

    return GameActionResult.success({
      'theme': theme,
      'availableThemes': _availableThemes,
    });
  }

  // Round timer management
  void _startRoundTimer() {
    _roundTimer?.cancel();
    _roundTimer = Timer(_roundTimeout, () {
      if (_isRoundActive) {
        _handleRoundTimeout();
      }
    });
  }

  void _handleRoundTimeout() {
    _isRoundActive = false;
    _currentLetter = null;

    _emitEvent('round_timeout', {
      'round': _currentRound,
      'activePlayers': _activePlayers,
    });
  }

  // Round completion
  Future<void> _handleRoundWon(String winnerId) async {
    _isRoundActive = false;
    _roundTimer?.cancel();
    _currentLetter = null;
    
    // Increment winner's score
    _playerWins[winnerId] = (_playerWins[winnerId] ?? 0) + 1;

    _emitEvent('round_won', {
      'winner': winnerId,
      'round': _currentRound,
      'playerWins': _playerWins,
    });

    // Check if game is won
    if (_playerWins[winnerId]! >= _roundsToWin) {
      _gameWinner = winnerId;
      _isGameFinished = true;

      _emitEvent('game_won', {
        'winner': winnerId,
        'playerWins': _playerWins,
        'totalRounds': _currentRound,
      });
    }
  }

  // Event emission
  void _emitEvent(String type, Map<String, dynamic> data) {
    final event = BasicGameEvent(
      type: type,
      gameId: _gameId,
      data: data,
    );
    _eventController.add(event);
  }

  // Utility methods
  List<String> get availableThemes => List.unmodifiable(_availableThemes);
  String get currentTheme => _currentTheme;
  String? get currentLetter => _currentLetter;
  List<String> get activePlayers => List.unmodifiable(_activePlayers);
  List<String> get eliminatedPlayers => List.unmodifiable(_eliminatedPlayers);
  Map<String, int> get playerWins => Map.unmodifiable(_playerWins);
  int get currentRound => _currentRound;
  bool get isRoundActive => _isRoundActive;
  String? get gameWinner => _gameWinner;
  int get roundsToWin => _roundsToWin;
  Duration get roundTimeout => _roundTimeout;
  bool get allowCustomThemes => _allowCustomThemes;
}