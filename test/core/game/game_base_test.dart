import 'package:flutter_test/flutter_test.dart';
import 'package:sefer_games_v1/core/game/game_base.dart';

void main() {
  group('GameRegistry', () {
  setUp(() {
    // Clear registry before each test
    GameRegistry.clearRegistry();
  });    test('should register and create games', () {
      // Register a test game
      GameRegistry.registerGame('TestGame', () => _TestGame());
      
      expect(GameRegistry.isGameTypeSupported('TestGame'), true);
      expect(GameRegistry.isGameTypeSupported('NonExistentGame'), false);
      
      final game = GameRegistry.createGame('TestGame');
      expect(game, isA<_TestGame>());
      expect(game?.gameType, 'TestGame');
    });

    test('should return null for unregistered game', () {
      final game = GameRegistry.createGame('UnregisteredGame');
      expect(game, isNull);
    });

    test('should list available game types', () {
      GameRegistry.registerGame('Game1', () => _TestGame());
      GameRegistry.registerGame('Game2', () => _TestGame());
      
      final types = GameRegistry.getAvailableGameTypes();
      expect(types, contains('Game1'));
      expect(types, contains('Game2'));
      expect(types.length, 2);
    });
  });

  group('GameActionResult', () {
    test('should create success result', () {
      final result = GameActionResult.success({'score': 100});
      
      expect(result.success, true);
      expect(result.errorMessage, isNull);
      expect(result.resultData, {'score': 100});
    });

    test('should create error result', () {
      final result = GameActionResult.error('Invalid move');
      
      expect(result.success, false);
      expect(result.errorMessage, 'Invalid move');
      expect(result.resultData, isNull);
    });
  });

  group('BasicGameEvent', () {
    test('should create event with timestamp', () {
      final event = BasicGameEvent(
        type: 'test_event',
        gameId: 'game_123',
        data: {'key': 'value'},
      );
      
      expect(event.type, 'test_event');
      expect(event.gameId, 'game_123');
      expect(event.data, {'key': 'value'});
      expect(event.timestamp, isA<DateTime>());
      expect(event.targetPlayerIds, isNull);
    });

    test('should create event with specific timestamp and targets', () {
      final timestamp = DateTime.now();
      final event = BasicGameEvent(
        type: 'player_event',
        gameId: 'game_123',
        data: {'message': 'hello'},
        timestamp: timestamp,
        targetPlayerIds: ['player1', 'player2'],
      );
      
      expect(event.timestamp, timestamp);
      expect(event.targetPlayerIds, ['player1', 'player2']);
    });

    test('should copy event with modifications', () {
      final original = BasicGameEvent(
        type: 'original_event',
        gameId: 'game_123',
        data: {'original': 'data'},
      );
      
      final modified = original.copyWith(
        type: 'modified_event',
        data: {'modified': 'data'},
      );
      
      expect(modified.type, 'modified_event');
      expect(modified.gameId, 'game_123'); // Unchanged
      expect(modified.data, {'modified': 'data'});
      expect(modified.timestamp, original.timestamp); // Unchanged
    });
  });

  group('BasicGameAction', () {
    test('should create action with timestamp', () {
      final action = BasicGameAction(
        type: 'move',
        playerId: 'player_123',
        data: {'x': 5, 'y': 10},
      );
      
      expect(action.type, 'move');
      expect(action.playerId, 'player_123');
      expect(action.data, {'x': 5, 'y': 10});
      expect(action.timestamp, isA<DateTime>());
    });

    test('should create action with specific timestamp', () {
      final timestamp = DateTime.now();
      final action = BasicGameAction(
        type: 'action',
        playerId: 'player_123',
        data: {'test': 'data'},
        timestamp: timestamp,
      );
      
      expect(action.timestamp, timestamp);
    });
  });
}

// Test implementation of GameBase for testing purposes
class _TestGame extends GameBase {
  @override
  String get gameId => 'test_game_123';

  @override
  String get gameName => 'Test Game';

  @override
  String get gameType => 'TestGame';

  @override
  int get minPlayers => 2;

  @override
  int get maxPlayers => 4;

  @override
  Map<String, dynamic> get gameState => {'state': 'test'};

  @override
  Stream<GameEvent> get gameEvents => Stream.empty();

  @override
  bool get isGameFinished => false;

  @override
  Map<String, dynamic> get gameResults => {};

  @override
  Future<void> initializeGame(List<String> playerIds) async {
    // Test implementation
  }

  @override
  Future<GameActionResult> processAction(String playerId, GameAction action) async {
    return GameActionResult.success();
  }

  @override
  Future<void> startGame() async {
    // Test implementation
  }

  @override
  Future<void> endGame() async {
    // Test implementation
  }

  @override
  void dispose() {
    // Test implementation
  }
}
