import 'package:flutter_test/flutter_test.dart';
import 'package:sefer_games_v1/core/game/game_manager.dart';
import 'package:sefer_games_v1/core/game/game_base.dart';
import 'package:sefer_games_v1/features/lobby/domain/entities/lobby.dart';
import 'package:sefer_games_v1/features/lobby/domain/entities/player.dart';
import 'dart:async';

void main() {
  group('GameManager', () {
    late GameManager gameManager;
    late _MockGame mockGame;

    setUp(() {
      gameManager = GameManager();
      mockGame = _MockGame();
      
      // Register the mock game
      GameRegistry.registerGame('MockGame', () => mockGame);
    });

    tearDown(() {
      gameManager.dispose();
      GameRegistry.clearRegistry();
    });

    group('Game Lifecycle', () {
      test('should start game successfully', () async {
        final lobby = _createTestLobby();
        
        final result = await gameManager.startGame(lobby);
        
        expect(result, true);
        expect(gameManager.hasActiveGame(lobby.id), true);
        expect(mockGame.initializeCalled, true);
        expect(mockGame.startCalled, true);
      });

      test('should fail to start game with unsupported type', () async {
        final lobby = _createTestLobby(gameType: 'UnsupportedGame');
        
        final result = await gameManager.startGame(lobby);
        
        expect(result, false);
        expect(gameManager.hasActiveGame(lobby.id), false);
      });

      test('should end game successfully', () async {
        final lobby = _createTestLobby();
        await gameManager.startGame(lobby);
        
        await gameManager.endGame(lobby.id);
        
        expect(gameManager.hasActiveGame(lobby.id), false);
        expect(mockGame.endCalled, true);
        expect(mockGame.disposeCalled, true);
      });

      test('should handle ending non-existent game gracefully', () async {
        await gameManager.endGame('non-existent-lobby');
        // Should not throw
      });
    });

    group('Game Actions', () {
      test('should process game action successfully', () async {
        final lobby = _createTestLobby();
        await gameManager.startGame(lobby);
        
        mockGame.nextActionResult = GameActionResult.success({'points': 10});
        
        final result = await gameManager.processGameAction(
          lobby.id,
          'player_1',
          {'type': 'test_action', 'data': 'test'},
        );
        
        expect(result.success, true);
        expect(result.resultData, {'points': 10});
        expect(mockGame.processActionCalled, true);
      });

      test('should handle action for non-existent game', () async {
        final result = await gameManager.processGameAction(
          'non-existent-lobby',
          'player_1',
          {'type': 'test_action'},
        );
        
        expect(result.success, false);
        expect(result.errorMessage, contains('No active game'));
      });

      test('should handle action processing errors', () async {
        final lobby = _createTestLobby();
        await gameManager.startGame(lobby);
        
        mockGame.shouldThrowOnAction = true;
        
        final result = await gameManager.processGameAction(
          lobby.id,
          'player_1',
          {'type': 'test_action'},
        );
        
        expect(result.success, false);
        expect(result.errorMessage, contains('Failed to process action'));
      });
    });

    group('Game State', () {
      test('should get game state for active game', () async {
        final lobby = _createTestLobby();
        await gameManager.startGame(lobby);
        
        final state = gameManager.getGameState(lobby.id);
        
        expect(state, mockGame.gameState);
      });

      test('should return null for non-existent game', () {
        final state = gameManager.getGameState('non-existent-lobby');
        expect(state, isNull);
      });

      test('should get game results for finished game', () async {
        final lobby = _createTestLobby();
        await gameManager.startGame(lobby);
        
        final results = gameManager.getGameResults(lobby.id);
        
        expect(results, mockGame.gameResults);
      });
    });
  });
}

// Mock implementations for testing

class _MockGame extends GameBase {
  bool initializeCalled = false;
  bool startCalled = false;
  bool endCalled = false;
  bool disposeCalled = false;
  bool processActionCalled = false;
  bool shouldThrowOnAction = false;
  GameActionResult? nextActionResult;

  final StreamController<GameEvent> _eventController = StreamController.broadcast();

  @override
  String get gameId => 'mock_game_123';

  @override
  String get gameName => 'Mock Game';

  @override
  String get gameType => 'MockGame';

  @override
  int get minPlayers => 2;

  @override
  int get maxPlayers => 4;

  @override
  Map<String, dynamic> get gameState => {'state': 'mock', 'initialized': initializeCalled};

  @override
  Stream<GameEvent> get gameEvents => _eventController.stream;

  @override
  bool get isGameFinished => false;

  @override
  Map<String, dynamic> get gameResults => {'winner': 'player_1', 'score': 100};

  @override
  Future<void> initializeGame(List<String> playerIds) async {
    initializeCalled = true;
  }

  @override
  Future<GameActionResult> processAction(String playerId, GameAction action) async {
    processActionCalled = true;
    
    if (shouldThrowOnAction) {
      throw Exception('Mock action error');
    }
    
    return nextActionResult ?? GameActionResult.success();
  }

  @override
  Future<void> startGame() async {
    startCalled = true;
  }

  @override
  Future<void> endGame() async {
    endCalled = true;
  }

  @override
  void dispose() {
    disposeCalled = true;
    _eventController.close();
  }
}

LobbyEntity _createTestLobby({String gameType = 'MockGame'}) {
  return LobbyEntity(
    id: 'test_lobby_123',
    name: 'Test Lobby',
    hostId: 'host_1',
    players: [
      PlayerEntity(
        id: 'player_1',
        name: 'Player 1',
        avatarId: 'avatar_1',
        isHost: true,
        isConnected: true,
      ),
      PlayerEntity(
        id: 'player_2',
        name: 'Player 2',
        avatarId: 'avatar_2',
        isHost: false,
        isConnected: true,
      ),
    ],
    gameType: gameType,
  );
}
