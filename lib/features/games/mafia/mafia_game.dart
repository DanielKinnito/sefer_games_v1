import 'dart:async';
import 'dart:math';
import '../../../core/game/game_base.dart';

/// Mafia game implementation
class MafiaGame extends GameBase {
  static const String gameTypeId = 'mafia';
  
  // Game configuration
  final int _mafiaCount;
  final int _policeCount;
  final int _doctorCount;
  final int _jokerCount;
  final bool _doctorCanSaveSamePerson;
  final bool _doctorCanSaveSelf;
  
  // Game state
  String _gameId;
  List<String> _playerIds = [];
  Map<String, PlayerRole> _playerRoles = {};
  List<String> _alivePlayers = [];
  List<String> _deadPlayers = [];
  GamePhase _currentPhase = GamePhase.setup;
  int _currentDay = 0;
  bool _isGameFinished = false;
  String? _gameWinner;
  
  // Night actions
  Map<String, String> _policeInvestigations = {}; // police -> target
  Map<String, String> _doctorHeals = {}; // doctor -> target
  Map<String, String> _mafiaKills = {}; // mafia -> target
  Set<String> _doctorPreviousHeals = {}; // players healed before (if restriction enabled)
  
  // Voting
  Map<String, String> _votes = {}; // voter -> target
  Map<String, int> _voteCounts = {};
  
  // Event stream
  final StreamController<GameEvent> _eventController = StreamController<GameEvent>.broadcast();
  
  // Random number generator
  final Random _random = Random();

  MafiaGame({
    String? gameId,
    int mafiaCount = 2,
    int policeCount = 1,
    int doctorCount = 1,
    int jokerCount = 0,
    bool doctorCanSaveSamePerson = false,
    bool doctorCanSaveSelf = true,
  }) : _gameId = gameId ?? 'mafia_${DateTime.now().millisecondsSinceEpoch}',
       _mafiaCount = mafiaCount,
       _policeCount = policeCount,
       _doctorCount = doctorCount,
       _jokerCount = jokerCount,
       _doctorCanSaveSamePerson = doctorCanSaveSamePerson,
       _doctorCanSaveSelf = doctorCanSaveSelf;

  @override
  String get gameId => _gameId;

  @override
  String get gameName => 'Mafia';

  @override
  String get gameType => gameTypeId;

  @override
  int get minPlayers => _mafiaCount + _policeCount + _doctorCount + _jokerCount + 2; // At least 2 civilians

  @override
  int get maxPlayers => 20;

  @override
  bool get isGameFinished => _isGameFinished;

  @override
  Map<String, dynamic> get gameState => {
    'gameId': _gameId,
    'playerRoles': _playerRoles.map((k, v) => MapEntry(k, v.toString())),
    'alivePlayers': _alivePlayers,
    'deadPlayers': _deadPlayers,
    'currentPhase': _currentPhase.toString(),
    'currentDay': _currentDay,
    'isGameFinished': _isGameFinished,
    'gameWinner': _gameWinner,
    'votes': _votes,
    'voteCounts': _voteCounts,
    'mafiaCount': _mafiaCount,
    'policeCount': _policeCount,
    'doctorCount': _doctorCount,
    'jokerCount': _jokerCount,
    'doctorCanSaveSamePerson': _doctorCanSaveSamePerson,
    'doctorCanSaveSelf': _doctorCanSaveSelf,
  };

  @override
  Map<String, dynamic> get gameResults => {
    'winner': _gameWinner,
    'playerRoles': _playerRoles.map((k, v) => MapEntry(k, v.toString())),
    'totalDays': _currentDay,
    'gameFinished': _isGameFinished,
    'survivingPlayers': _alivePlayers,
  };

  @override
  Stream<GameEvent> get gameEvents => _eventController.stream;

  @override
  Future<void> initializeGame(List<String> playerIds) async {
    if (playerIds.length < minPlayers || playerIds.length > maxPlayers) {
      throw ArgumentError('Invalid player count: ${playerIds.length}. Must be between $minPlayers and $maxPlayers.');
    }

    _playerIds = List.from(playerIds);
    _alivePlayers = List.from(playerIds);
    _deadPlayers.clear();
    _assignRoles();
    
    _currentPhase = GamePhase.setup;
    _currentDay = 0;
    _isGameFinished = false;
    _gameWinner = null;
    _votes.clear();
    _voteCounts.clear();
    _policeInvestigations.clear();
    _doctorHeals.clear();
    _mafiaKills.clear();
    _doctorPreviousHeals.clear();

    _emitEvent('game_initialized', {
      'playerIds': _playerIds,
      'playerCount': _playerIds.length,
      'roles': _getRoleDistribution(),
    });
  }

  @override
  Future<void> startGame() async {
    if (_playerIds.isEmpty) {
      throw StateError('Game not initialized. Call initializeGame first.');
    }

    _currentPhase = GamePhase.day;
    _currentDay = 1;

    _emitEvent('game_started', {
      'currentPhase': _currentPhase.toString(),
      'currentDay': _currentDay,
    });

    _emitEvent('day_started', {
      'day': _currentDay,
      'alivePlayers': _alivePlayers,
    });
  }

  @override
  Future<GameActionResult> processAction(String playerId, GameAction action) async {
    try {
      switch (action.type) {
        case 'vote':
          return await _handleVote(playerId, action);
        case 'police_investigate':
          return await _handlePoliceInvestigation(playerId, action);
        case 'doctor_heal':
          return await _handleDoctorHeal(playerId, action);
        case 'mafia_kill':
          return await _handleMafiaKill(playerId, action);
        case 'advance_phase':
          return await _handleAdvancePhase(playerId, action);
        case 'start_voting':
          return await _handleStartVoting(playerId, action);
        case 'end_voting':
          return await _handleEndVoting(playerId, action);
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
    
    _emitEvent('game_ended', {
      'winner': _gameWinner,
      'playerRoles': _playerRoles.map((k, v) => MapEntry(k, v.toString())),
      'totalDays': _currentDay,
    });
  }

  @override
  void dispose() {
    _eventController.close();
  }

  // Role assignment
  void _assignRoles() {
    final shuffledPlayers = List<String>.from(_playerIds);
    shuffledPlayers.shuffle(_random);
    
    int index = 0;
    
    // Assign Mafia
    for (int i = 0; i < _mafiaCount && index < shuffledPlayers.length; i++) {
      _playerRoles[shuffledPlayers[index++]] = PlayerRole.mafia;
    }
    
    // Assign Police
    for (int i = 0; i < _policeCount && index < shuffledPlayers.length; i++) {
      _playerRoles[shuffledPlayers[index++]] = PlayerRole.police;
    }
    
    // Assign Doctors
    for (int i = 0; i < _doctorCount && index < shuffledPlayers.length; i++) {
      _playerRoles[shuffledPlayers[index++]] = PlayerRole.doctor;
    }
    
    // Assign Jokers
    for (int i = 0; i < _jokerCount && index < shuffledPlayers.length; i++) {
      _playerRoles[shuffledPlayers[index++]] = PlayerRole.joker;
    }
    
    // Assign remaining as Civilians
    while (index < shuffledPlayers.length) {
      _playerRoles[shuffledPlayers[index++]] = PlayerRole.civilian;
    }
  }

  // Voting actions
  Future<GameActionResult> _handleVote(String playerId, GameAction action) async {
    if (_currentPhase != GamePhase.voting) {
      return GameActionResult.error('Voting is not currently active');
    }

    if (!_alivePlayers.contains(playerId)) {
      return GameActionResult.error('Dead players cannot vote');
    }

    final targetId = action.data['targetId'] as String?;
    if (targetId == null || !_alivePlayers.contains(targetId)) {
      return GameActionResult.error('Invalid vote target');
    }

    // Update vote
    final previousVote = _votes[playerId];
    if (previousVote != null) {
      _voteCounts[previousVote] = (_voteCounts[previousVote] ?? 1) - 1;
      if (_voteCounts[previousVote]! <= 0) {
        _voteCounts.remove(previousVote);
      }
    }

    _votes[playerId] = targetId;
    _voteCounts[targetId] = (_voteCounts[targetId] ?? 0) + 1;

    _emitEvent('vote_cast', {
      'voter': playerId,
      'target': targetId,
      'voteCounts': _voteCounts,
    });

    return GameActionResult.success({'target': targetId});
  }

  // Night actions
  Future<GameActionResult> _handlePoliceInvestigation(String playerId, GameAction action) async {
    if (_currentPhase != GamePhase.night) {
      return GameActionResult.error('Police can only investigate during night phase');
    }

    if (_playerRoles[playerId] != PlayerRole.police) {
      return GameActionResult.error('Only police can investigate');
    }

    if (!_alivePlayers.contains(playerId)) {
      return GameActionResult.error('Dead players cannot perform actions');
    }

    final targetId = action.data['targetId'] as String?;
    if (targetId == null || !_alivePlayers.contains(targetId)) {
      return GameActionResult.error('Invalid investigation target');
    }

    if (targetId == playerId) {
      return GameActionResult.error('Police cannot investigate themselves');
    }

    _policeInvestigations[playerId] = targetId;
    final isMafia = _playerRoles[targetId] == PlayerRole.mafia;

    _emitEvent('police_investigation', {
      'investigator': playerId,
      'target': targetId,
      'result': isMafia,
    });

    return GameActionResult.success({
      'target': targetId,
      'isMafia': isMafia,
    });
  }

  Future<GameActionResult> _handleDoctorHeal(String playerId, GameAction action) async {
    if (_currentPhase != GamePhase.night) {
      return GameActionResult.error('Doctor can only heal during night phase');
    }

    if (_playerRoles[playerId] != PlayerRole.doctor) {
      return GameActionResult.error('Only doctors can heal');
    }

    if (!_alivePlayers.contains(playerId)) {
      return GameActionResult.error('Dead players cannot perform actions');
    }

    final targetId = action.data['targetId'] as String?;
    if (targetId == null || !_alivePlayers.contains(targetId)) {
      return GameActionResult.error('Invalid heal target');
    }

    if (!_doctorCanSaveSelf && targetId == playerId) {
      return GameActionResult.error('Doctor cannot heal themselves');
    }

    if (!_doctorCanSaveSamePerson && _doctorPreviousHeals.contains(targetId)) {
      return GameActionResult.error('Doctor cannot heal the same person twice');
    }

    _doctorHeals[playerId] = targetId;
    if (!_doctorCanSaveSamePerson) {
      _doctorPreviousHeals.add(targetId);
    }

    _emitEvent('doctor_heal', {
      'healer': playerId,
      'target': targetId,
    });

    return GameActionResult.success({'target': targetId});
  }

  Future<GameActionResult> _handleMafiaKill(String playerId, GameAction action) async {
    if (_currentPhase != GamePhase.night) {
      return GameActionResult.error('Mafia can only kill during night phase');
    }

    if (_playerRoles[playerId] != PlayerRole.mafia) {
      return GameActionResult.error('Only mafia can kill');
    }

    if (!_alivePlayers.contains(playerId)) {
      return GameActionResult.error('Dead players cannot perform actions');
    }

    final targetId = action.data['targetId'] as String?;
    if (targetId == null || !_alivePlayers.contains(targetId)) {
      return GameActionResult.error('Invalid kill target');
    }

    if (_playerRoles[targetId] == PlayerRole.mafia) {
      return GameActionResult.error('Mafia cannot kill other mafia members');
    }

    _mafiaKills[playerId] = targetId;

    _emitEvent('mafia_kill_attempt', {
      'killer': playerId,
      'target': targetId,
    });

    return GameActionResult.success({'target': targetId});
  }

  // Phase management
  Future<GameActionResult> _handleAdvancePhase(String playerId, GameAction action) async {
    // Only host can advance phases
    // This would need to be validated based on host permissions
    
    switch (_currentPhase) {
      case GamePhase.setup:
        return await _startDay();
      case GamePhase.day:
        return await _startNight();
      case GamePhase.night:
        return await _processNightActions();
      case GamePhase.voting:
        return await _processVotingResults();
    }
  }

  Future<GameActionResult> _handleStartVoting(String playerId, GameAction action) async {
    if (_currentPhase != GamePhase.day) {
      return GameActionResult.error('Voting can only start during day phase');
    }

    _currentPhase = GamePhase.voting;
    _votes.clear();
    _voteCounts.clear();

    _emitEvent('voting_started', {
      'day': _currentDay,
      'alivePlayers': _alivePlayers,
    });

    return GameActionResult.success({});
  }

  Future<GameActionResult> _handleEndVoting(String playerId, GameAction action) async {
    if (_currentPhase != GamePhase.voting) {
      return GameActionResult.error('No voting in progress');
    }

    return await _processVotingResults();
  }

  Future<GameActionResult> _startDay() async {
    _currentPhase = GamePhase.day;
    _currentDay++;

    _emitEvent('day_started', {
      'day': _currentDay,
      'alivePlayers': _alivePlayers,
    });

    return GameActionResult.success({'phase': 'day', 'day': _currentDay});
  }

  Future<GameActionResult> _startNight() async {
    _currentPhase = GamePhase.night;
    _policeInvestigations.clear();
    _doctorHeals.clear();
    _mafiaKills.clear();

    _emitEvent('night_started', {
      'day': _currentDay,
      'alivePlayers': _alivePlayers,
    });

    return GameActionResult.success({'phase': 'night'});
  }

  Future<GameActionResult> _processNightActions() async {
    final healedPlayers = Set<String>.from(_doctorHeals.values);
    final killedPlayers = <String>[];

    // Process kills, but exclude healed players
    for (final target in _mafiaKills.values) {
      if (!healedPlayers.contains(target)) {
        killedPlayers.add(target);
      }
    }

    // Remove killed players
    for (final playerId in killedPlayers) {
      _alivePlayers.remove(playerId);
      _deadPlayers.add(playerId);
    }

    _emitEvent('night_results', {
      'killedPlayers': killedPlayers,
      'healedPlayers': healedPlayers.toList(),
      'investigations': _policeInvestigations,
    });

    // Check win conditions
    final winner = _checkWinConditions();
    if (winner != null) {
      _gameWinner = winner;
      _isGameFinished = true;
      
      _emitEvent('game_won', {
        'winner': winner,
        'playerRoles': _playerRoles.map((k, v) => MapEntry(k, v.toString())),
      });
      
      return GameActionResult.success({'gameEnded': true, 'winner': winner});
    }

    return await _startDay();
  }

  Future<GameActionResult> _processVotingResults() async {
    if (_voteCounts.isEmpty) {
      _emitEvent('voting_ended', {
        'result': 'no_votes',
        'eliminatedPlayer': null,
      });
      
      _currentPhase = GamePhase.day;
      return GameActionResult.success({'result': 'no_elimination'});
    }

    // Find player with most votes
    final maxVotes = _voteCounts.values.reduce((a, b) => a > b ? a : b);
    final playersWithMaxVotes = _voteCounts.entries
        .where((entry) => entry.value == maxVotes)
        .map((entry) => entry.key)
        .toList();

    String? eliminatedPlayer;
    if (playersWithMaxVotes.length == 1) {
      eliminatedPlayer = playersWithMaxVotes.first;
      _alivePlayers.remove(eliminatedPlayer);
      _deadPlayers.add(eliminatedPlayer);
    }

    _emitEvent('voting_ended', {
      'result': eliminatedPlayer != null ? 'elimination' : 'tie',
      'eliminatedPlayer': eliminatedPlayer,
      'voteCounts': _voteCounts,
    });

    // Check win conditions
    final winner = _checkWinConditions();
    if (winner != null) {
      _gameWinner = winner;
      _isGameFinished = true;
      
      _emitEvent('game_won', {
        'winner': winner,
        'playerRoles': _playerRoles.map((k, v) => MapEntry(k, v.toString())),
      });
      
      return GameActionResult.success({'gameEnded': true, 'winner': winner});
    }

    return await _startNight();
  }

  String? _checkWinConditions() {
    final aliveMafia = _alivePlayers.where((p) => _playerRoles[p] == PlayerRole.mafia).length;
    final aliveNonMafia = _alivePlayers.where((p) => _playerRoles[p] != PlayerRole.mafia).length;
    final aliveJokers = _alivePlayers.where((p) => _playerRoles[p] == PlayerRole.joker);

    // Joker wins if they get voted out
    final deadJokers = _deadPlayers.where((p) => _playerRoles[p] == PlayerRole.joker);
    if (deadJokers.isNotEmpty) {
      return 'joker';
    }

    // Mafia wins if they equal or outnumber non-mafia
    if (aliveMafia >= aliveNonMafia) {
      return 'mafia';
    }

    // Town wins if all mafia are eliminated
    if (aliveMafia == 0) {
      return 'town';
    }

    return null; // Game continues
  }

  void _emitEvent(String type, Map<String, dynamic> data) {
    final event = BasicGameEvent(
      type: type,
      gameId: _gameId,
      data: data,
    );
    _eventController.add(event);
  }

  Map<String, int> _getRoleDistribution() {
    return {
      'mafia': _mafiaCount,
      'police': _policeCount,
      'doctor': _doctorCount,
      'joker': _jokerCount,
      'civilian': _playerIds.length - _mafiaCount - _policeCount - _doctorCount - _jokerCount,
    };
  }

  // Getters for game state
  PlayerRole? getPlayerRole(String playerId) => _playerRoles[playerId];
  List<String> get alivePlayers => List.unmodifiable(_alivePlayers);
  List<String> get deadPlayers => List.unmodifiable(_deadPlayers);
  GamePhase get currentPhase => _currentPhase;
  int get currentDay => _currentDay;
  Map<String, String> get currentVotes => Map.unmodifiable(_votes);
  Map<String, int> get voteCounts => Map.unmodifiable(_voteCounts);
}

/// Player roles in Mafia game
enum PlayerRole {
  mafia,
  police,
  doctor,
  joker,
  civilian,
}

/// Game phases in Mafia
enum GamePhase {
  setup,
  day,
  night,
  voting,
}