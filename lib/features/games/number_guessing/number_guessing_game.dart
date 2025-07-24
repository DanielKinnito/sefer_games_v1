import 'dart:async';
import 'dart:math';
import '../../../../core/game/game_base.dart';

/// A simple number guessing game for demonstration
class NumberGuessingGame extends GameBase {
  static const String gameTypeId = 'NumberGuessing';
  
  @override
  String get gameId => _gameId;
  
  @override
  String get gameName => 'Number Guessing Game';
  
  @override
  String get gameType => gameTypeId;
  
  @override
  int get minPlayers => 2;
  
  @override
  int get maxPlayers => 8;
  
  String _gameId = '';
  List<String> _players = [];
  int _targetNumber = 0;
  int _currentRound = 1;
  int _maxRounds = 3;
  bool _gameFinished = false;
  Map<String, int> _scores = {};
  Map<String, int> _lastGuesses = {};
  String? _currentGuesser;
  int _guesserIndex = 0;
  
  final StreamController<GameEvent> _eventController = StreamController.broadcast();
  
  @override
  Stream<GameEvent> get gameEvents => _eventController.stream;
  
  @override
  Map<String, dynamic> get gameState => {
    'gameId': _gameId,
    'currentRound': _currentRound,
    'maxRounds': _maxRounds,
    'targetNumber': _targetNumber, // In a real game, this would be hidden
    'scores': _scores,
    'lastGuesses': _lastGuesses,
    'currentGuesser': _currentGuesser,
    'isFinished': _gameFinished,
    'players': _players,
  };
  
  @override
  bool get isGameFinished => _gameFinished;
  
  @override
  Map<String, dynamic> get gameResults {
    if (!_gameFinished) return {};
    
    final sortedScores = _scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return {
      'finalScores': _scores,
      'winner': sortedScores.isNotEmpty ? sortedScores.first.key : null,
      'rankings': sortedScores.map((e) => {'playerId': e.key, 'score': e.value}).toList(),
    };
  }
  
  @override
  Future<void> initializeGame(List<String> playerIds) async {
    _gameId = 'number_game_${DateTime.now().millisecondsSinceEpoch}';
    _players = List.from(playerIds);
    _scores = {for (String playerId in _players) playerId: 0};
    _lastGuesses = {};
    _currentGuesser = _players.isNotEmpty ? _players.first : null;
    _guesserIndex = 0;
    
    _generateNewNumber();
    
    _broadcastEvent('game_initialized', {
      'players': _players,
      'currentRound': _currentRound,
      'maxRounds': _maxRounds,
    });
  }
  
  @override
  Future<void> startGame() async {
    _broadcastEvent('game_started', {
      'currentGuesser': _currentGuesser,
      'round': _currentRound,
    });
  }
  
  @override
  Future<GameActionResult> processAction(String playerId, GameAction action) async {
    try {
      switch (action.type) {
        case 'make_guess':
          return await _handleGuess(playerId, action.data);
        case 'next_round':
          return await _handleNextRound(playerId);
        default:
          return GameActionResult.error('Unknown action type: ${action.type}');
      }
    } catch (e) {
      return GameActionResult.error('Error processing action: $e');
    }
  }
  
  Future<GameActionResult> _handleGuess(String playerId, Map<String, dynamic> data) async {
    // Check if it's the player's turn
    if (_currentGuesser != playerId) {
      return GameActionResult.error('Not your turn to guess');
    }
    
    final guess = data['guess'] as int?;
    if (guess == null) {
      return GameActionResult.error('Invalid guess provided');
    }
    
    _lastGuesses[playerId] = guess;
    
    String result;
    int points = 0;
    
    if (guess == _targetNumber) {
      result = 'correct';
      points = 10; // Base points for correct guess
      _scores[playerId] = (_scores[playerId] ?? 0) + points;
      
      _broadcastEvent('correct_guess', {
        'playerId': playerId,
        'guess': guess,
        'targetNumber': _targetNumber,
        'points': points,
        'newScore': _scores[playerId],
      });
      
      // Move to next round or end game
      if (_currentRound >= _maxRounds) {
        _gameFinished = true;
        _broadcastEvent('game_finished', gameResults);
      } else {
        _currentRound++;
        _generateNewNumber();
        _broadcastEvent('round_finished', {
          'round': _currentRound - 1,
          'newRound': _currentRound,
          'scores': _scores,
        });
      }
    } else if (guess < _targetNumber) {
      result = 'too_low';
    } else {
      result = 'too_high';
    }
    
    // Move to next player
    _moveToNextGuesser();
    
    _broadcastEvent('guess_made', {
      'playerId': playerId,
      'guess': guess,
      'result': result,
      'nextGuesser': _currentGuesser,
    });
    
    return GameActionResult.success({
      'result': result,
      'points': points,
      'nextGuesser': _currentGuesser,
    });
  }
  
  Future<GameActionResult> _handleNextRound(String playerId) async {
    // Only allow host or current round winner to advance
    if (_currentRound >= _maxRounds) {
      return GameActionResult.error('Game is already finished');
    }
    
    _currentRound++;
    _generateNewNumber();
    _resetForNewRound();
    
    _broadcastEvent('new_round_started', {
      'round': _currentRound,
      'currentGuesser': _currentGuesser,
    });
    
    return GameActionResult.success({'newRound': _currentRound});
  }
  
  void _generateNewNumber() {
    final random = Random();
    _targetNumber = random.nextInt(100) + 1; // Number between 1 and 100
  }
  
  void _moveToNextGuesser() {
    if (_players.isEmpty) return;
    _guesserIndex = (_guesserIndex + 1) % _players.length;
    _currentGuesser = _players[_guesserIndex];
  }
  
  void _resetForNewRound() {
    _lastGuesses.clear();
    _guesserIndex = 0;
    _currentGuesser = _players.isNotEmpty ? _players.first : null;
  }
  
  void _broadcastEvent(String eventType, Map<String, dynamic> data) {
    final event = BasicGameEvent(
      type: eventType,
      gameId: _gameId,
      data: data,
    );
    _eventController.add(event);
  }
  
  @override
  Future<void> endGame() async {
    _gameFinished = true;
    _broadcastEvent('game_ended', gameResults);
  }
  
  @override
  void dispose() {
    _eventController.close();
  }
}
