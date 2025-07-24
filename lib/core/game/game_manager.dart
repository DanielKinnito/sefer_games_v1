import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../game/game_base.dart';
import '../../features/lobby/domain/entities/lobby.dart';

/// Manages game instances and their lifecycle within lobbies
class GameManager {
  final Map<String, GameBase> _activeGames = {};
  final Map<String, List<WebSocket>> _lobbyConnections = {};
  final StreamController<GameEvent> _gameEventController = StreamController.broadcast();
  
  /// Stream of all game events
  Stream<GameEvent> get gameEvents => _gameEventController.stream;
  
  /// Start a game for a specific lobby
  Future<bool> startGame(Lobby lobby) async {
    try {
      // Check if game type is supported
      if (!GameRegistry.isGameTypeSupported(lobby.gameType)) {
        throw Exception('Game type ${lobby.gameType} is not supported');
      }
      
      // Create game instance
      final game = GameRegistry.createGame(lobby.gameType);
      if (game == null) {
        throw Exception('Failed to create game instance for ${lobby.gameType}');
      }
      
      // Initialize game with player IDs
      final playerIds = lobby.players.map((p) => p.id).toList();
      await game.initializeGame(playerIds);
      
      // Store the game instance
      _activeGames[lobby.id] = game;
      
      // Listen to game events and broadcast them
      game.gameEvents.listen((event) {
        _broadcastGameEvent(lobby.id, event);
        _gameEventController.add(event);
      });
      
      // Start the actual game
      await game.startGame();
      
      // Notify all players that the game has started
      _broadcastToLobby(lobby.id, {
        'type': 'game_started',
        'gameType': lobby.gameType,
        'gameState': game.gameState,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      print('Failed to start game for lobby ${lobby.id}: $e');
      return false;
    }
  }
  
  /// Process a game action from a player
  Future<GameActionResult> processGameAction(String lobbyId, String playerId, Map<String, dynamic> actionData) async {
    final game = _activeGames[lobbyId];
    if (game == null) {
      return GameActionResult.error('No active game found for lobby');
    }
    
    try {
      final action = BasicGameAction(
        type: actionData['type'] as String,
        playerId: playerId,
        data: actionData,
      );
      
      final result = await game.processAction(playerId, action);
      
      // If action was successful, broadcast the updated game state
      if (result.success) {
        _broadcastToLobby(lobbyId, {
          'type': 'game_state_updated',
          'gameState': game.gameState,
          'actionResult': result.resultData,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        // Check if game is finished
        if (game.isGameFinished) {
          await _handleGameFinished(lobbyId, game);
        }
      }
      
      return result;
    } catch (e) {
      return GameActionResult.error('Failed to process action: $e');
    }
  }
  
  /// End a game for a specific lobby
  Future<void> endGame(String lobbyId) async {
    final game = _activeGames[lobbyId];
    if (game == null) return;
    
    try {
      await game.endGame();
      
      _broadcastToLobby(lobbyId, {
        'type': 'game_ended',
        'gameResults': game.gameResults,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      game.dispose();
      _activeGames.remove(lobbyId);
    } catch (e) {
      print('Error ending game for lobby $lobbyId: $e');
    }
  }
  
  /// Handle game finished event
  Future<void> _handleGameFinished(String lobbyId, GameBase game) async {
    _broadcastToLobby(lobbyId, {
      'type': 'game_finished',
      'gameResults': game.gameResults,
      'finalState': game.gameState,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // Clean up after a delay to allow clients to receive final state
    Timer(const Duration(seconds: 5), () {
      endGame(lobbyId);
    });
  }
  
  /// Add a WebSocket connection for a lobby
  void addLobbyConnection(String lobbyId, WebSocket webSocket) {
    _lobbyConnections.putIfAbsent(lobbyId, () => []).add(webSocket);
    
    // Send current game state if game is active
    final game = _activeGames[lobbyId];
    if (game != null) {
      final message = json.encode({
        'type': 'game_state_sync',
        'gameState': game.gameState,
        'isFinished': game.isGameFinished,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      try {
        webSocket.add(message);
      } catch (e) {
        print('Failed to send game state to new connection: $e');
      }
    }
  }
  
  /// Remove a WebSocket connection for a lobby
  void removeLobbyConnection(String lobbyId, WebSocket webSocket) {
    final connections = _lobbyConnections[lobbyId];
    if (connections != null) {
      connections.remove(webSocket);
      if (connections.isEmpty) {
        _lobbyConnections.remove(lobbyId);
      }
    }
  }
  
  /// Broadcast a message to all connections in a lobby
  void _broadcastToLobby(String lobbyId, Map<String, dynamic> message) {
    final connections = _lobbyConnections[lobbyId];
    if (connections == null) return;
    
    final messageString = json.encode(message);
    final deadConnections = <WebSocket>[];
    
    for (final connection in connections) {
      try {
        connection.add(messageString);
      } catch (e) {
        // Connection is dead, mark for removal
        deadConnections.add(connection);
      }
    }
    
    // Remove dead connections
    for (final deadConnection in deadConnections) {
      connections.remove(deadConnection);
    }
  }
  
  /// Broadcast a game event to the appropriate players
  void _broadcastGameEvent(String lobbyId, GameEvent event) {
    final connections = _lobbyConnections[lobbyId];
    if (connections == null) return;
    
    final message = {
      'type': 'game_event',
      'event': {
        'type': event.type,
        'data': event.data,
        'timestamp': event.timestamp.toIso8601String(),
      },
    };
    
    // If event has specific target players, filter connections
    // For now, broadcast to all (player-specific targeting would require connection tracking)
    _broadcastToLobby(lobbyId, message);
  }
  
  /// Get current game state for a lobby
  Map<String, dynamic>? getGameState(String lobbyId) {
    final game = _activeGames[lobbyId];
    return game?.gameState;
  }
  
  /// Check if a lobby has an active game
  bool hasActiveGame(String lobbyId) {
    return _activeGames.containsKey(lobbyId);
  }
  
  /// Get game results for a finished game
  Map<String, dynamic>? getGameResults(String lobbyId) {
    final game = _activeGames[lobbyId];
    return game?.gameResults;
  }
  
  /// Cleanup all resources
  void dispose() {
    // End all active games
    for (final entry in _activeGames.entries) {
      endGame(entry.key);
    }
    
    // Close all connections
    for (final connections in _lobbyConnections.values) {
      for (final connection in connections) {
        try {
          connection.close();
        } catch (e) {
          // Ignore errors when closing
        }
      }
    }
    
    _activeGames.clear();
    _lobbyConnections.clear();
    _gameEventController.close();
  }
}
