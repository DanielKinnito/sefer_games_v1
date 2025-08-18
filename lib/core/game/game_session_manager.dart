import 'dart:async';
import 'game_base.dart';
import 'game_action_router.dart';
import '../../features/lobby/domain/entities/lobby.dart';
import '../../features/lobby/data/services/lan_service.dart';
import '../../features/lobby/data/models/network_models.dart';

/// Manages game sessions, bridging lobby system and game instances
class GameSessionManager {
  static final GameSessionManager _instance = GameSessionManager._internal();
  factory GameSessionManager() => _instance;
  GameSessionManager._internal();

  GameSession? _currentSession;
  final StreamController<GameEvent> _gameEventController = StreamController.broadcast();
  final StreamController<GameSessionStatus> _sessionStatusController = StreamController.broadcast();
  
  LanService? _lanService;
  GameActionRouter? _actionRouter;
  StreamSubscription? _networkMessageSubscription;
  
  /// Stream of game events for UI updates
  Stream<GameEvent> get gameEventStream => _gameEventController.stream;
  
  /// Stream of session status changes
  Stream<GameSessionStatus> get sessionStatusStream => _sessionStatusController.stream;
  
  /// Current game session
  GameSession? get currentSession => _currentSession;
  
  /// Initialize the manager with LAN service
  void initialize(LanService lanService) {
    _lanService = lanService;
    _actionRouter = GameActionRouter();
    _actionRouter!.initialize(lanService, this);
    _setupNetworkMessageListener();
  }
  
  /// Start a new game session from a lobby
  Future<void> startGameSession(Lobby lobby) async {
    try {
      if (_currentSession != null) {
        throw GameSessionException('A game session is already active');
      }
      
      // Validate game start conditions
      await _validateGameStart(lobby);
      
      // Create game instance
      final gameInstance = GameRegistry.createGame(lobby.gameType);
      if (gameInstance == null) {
        throw GameSessionException('Failed to create game instance for type "${lobby.gameType}"');
      }
      
      // Create game session
      final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
      final playerIds = lobby.players.map((p) => p.id).toList();
      
      _currentSession = GameSession(
        sessionId: sessionId,
        lobbyId: lobby.id,
        gameType: lobby.gameType,
        playerIds: playerIds,
        gameInstance: gameInstance,
        startedAt: DateTime.now(),
        status: GameSessionStatus.initializing,
      );
      
      _sessionStatusController.add(GameSessionStatus.initializing);
      
      // Initialize the game
      await gameInstance.initializeGame(playerIds);
      
      // Subscribe to game events
      _subscribeToGameEvents();
      
      // Broadcast game start to all players
      await _broadcastGameEvent(GameEventType.gameStarting, {
        'sessionId': sessionId,
        'gameType': lobby.gameType,
        'playerIds': playerIds,
        'gameState': gameInstance.gameState,
      });
      
      // Start the game
      await gameInstance.startGame();
      
      _currentSession = _currentSession!.copyWith(status: GameSessionStatus.active);
      _sessionStatusController.add(GameSessionStatus.active);
      
      await _broadcastGameEvent(GameEventType.gameStarted, {
        'sessionId': sessionId,
        'gameState': gameInstance.gameState,
      });
      
    } catch (e) {
      await _handleSessionError('Failed to start game session: $e');
      rethrow;
    }
  }
  
  /// Process a game action from a player
  Future<GameActionResult> processGameAction(String playerId, GameAction action) async {
    try {
      if (_currentSession == null) {
        return GameActionResult.error('No active game session');
      }
      
      if (_currentSession!.status != GameSessionStatus.active) {
        return GameActionResult.error('Game session is not active');
      }
      
      if (!_currentSession!.playerIds.contains(playerId)) {
        return GameActionResult.error('Player not in current game session');
      }
      
      // Process the action through the game instance
      final result = await _currentSession!.gameInstance.processAction(playerId, action);
      
      // Use action router to broadcast the result
      if (_actionRouter != null) {
        await _actionRouter!.broadcastGameStateSync(_currentSession!.gameInstance.gameState);
      }
      
      // Check if game is finished
      if (_currentSession!.gameInstance.isGameFinished) {
        await _handleGameFinished();
      }
      
      return result;
    } catch (e) {
      final errorResult = GameActionResult.error('Failed to process game action: $e');
      await _broadcastGameEvent(GameEventType.gameError, {
        'playerId': playerId,
        'error': e.toString(),
      });
      return errorResult;
    }
  }
  
  /// End the current game session
  Future<void> endGameSession() async {
    try {
      if (_currentSession == null) {
        return;
      }
      
      final sessionId = _currentSession!.sessionId;
      
      // End the game instance
      await _currentSession!.gameInstance.endGame();
      
      // Broadcast game ended event
      await _broadcastGameEvent(GameEventType.gameEnded, {
        'sessionId': sessionId,
        'results': _currentSession!.gameInstance.gameResults,
      });
      
      // Cleanup
      await _cleanupSession();
      
    } catch (e) {
      await _handleSessionError('Failed to end game session: $e');
    }
  }
  
  /// Sync game state to all players (for reconnection scenarios)
  Future<void> syncGameState() async {
    if (_currentSession == null || _actionRouter == null) return;
    
    await _actionRouter!.broadcastGameStateSync(_currentSession!.gameInstance.gameState);
  }
  
  /// Handle player reconnection
  Future<void> handlePlayerReconnection(String playerId) async {
    if (_currentSession == null) return;
    
    if (!_currentSession!.playerIds.contains(playerId)) {
      return;
    }
    
    // Send current game state to reconnected player
    await _sendGameEventToPlayer(playerId, GameEventType.playerReconnected, {
      'sessionId': _currentSession!.sessionId,
      'gameState': _currentSession!.gameInstance.gameState,
      'status': _currentSession!.status.toString(),
    });
    
    // Notify other players
    await _broadcastGameEvent(GameEventType.playerReconnected, {
      'playerId': playerId,
    }, excludePlayerId: playerId);
  }
  
  /// Setup network message listener for game-related messages
  void _setupNetworkMessageListener() {
    _networkMessageSubscription?.cancel();
    _networkMessageSubscription = _lanService?.messageStream.listen((message) {
      _handleNetworkMessage(message);
    });
  }
  
  /// Handle incoming network messages
  void _handleNetworkMessage(NetworkMessage message) {
    switch (message.type) {
      case NetworkMessageTypes.gameAction:
        _handleGameActionMessage(message);
        break;
      case NetworkMessageTypes.gameStateRequest:
        _handleGameStateRequest(message);
        break;
      case NetworkMessageTypes.playerReconnected:
        _handlePlayerReconnectedMessage(message);
        break;
    }
  }
  
  /// Handle game action messages from network
  void _handleGameActionMessage(NetworkMessage message) async {
    try {
      final actionData = message.data['action'] as Map<String, dynamic>?;
      if (actionData == null) return;
      
      final action = BasicGameAction(
        type: actionData['type'] as String,
        playerId: message.senderId,
        data: actionData['data'] as Map<String, dynamic>,
        timestamp: DateTime.parse(actionData['timestamp'] as String),
      );
      
      await processGameAction(message.senderId, action);
    } catch (e) {
      print('Error handling game action message: $e');
    }
  }
  
  /// Handle game state request messages
  void _handleGameStateRequest(NetworkMessage message) async {
    await syncGameState();
  }
  
  /// Handle player reconnected messages
  void _handlePlayerReconnectedMessage(NetworkMessage message) async {
    final playerId = message.data['playerId'] as String?;
    if (playerId != null) {
      await handlePlayerReconnection(playerId);
    }
  }
  
  /// Subscribe to game events from the current game instance
  void _subscribeToGameEvents() {
    if (_currentSession == null || _actionRouter == null) return;
    
    _currentSession!.gameInstance.gameEvents.listen((gameEvent) {
      // Forward game events to the network via action router
      _actionRouter!.broadcastGameEvent(gameEvent);
      
      // Forward to local stream
      _gameEventController.add(gameEvent);
    });
  }
  
  /// Handle game finished scenario
  Future<void> _handleGameFinished() async {
    if (_currentSession == null) return;
    
    _currentSession = _currentSession!.copyWith(status: GameSessionStatus.finished);
    _sessionStatusController.add(GameSessionStatus.finished);
    
    await _broadcastGameEvent(GameEventType.gameFinished, {
      'sessionId': _currentSession!.sessionId,
      'results': _currentSession!.gameInstance.gameResults,
    });
  }
  
  /// Handle session errors
  Future<void> _handleSessionError(String error) async {
    print('Game session error: $error');
    
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(status: GameSessionStatus.error);
      _sessionStatusController.add(GameSessionStatus.error);
      
      await _broadcastGameEvent(GameEventType.sessionError, {
        'sessionId': _currentSession!.sessionId,
        'error': error,
      });
    }
  }
  
  /// Broadcast game event to all players
  Future<void> _broadcastGameEvent(String eventType, Map<String, dynamic> data, {String? excludePlayerId}) async {
    if (_lanService == null) return;
    
    final message = NetworkMessage(
      type: NetworkMessageTypes.gameEvent,
      senderId: 'game_session_manager',
      data: {
        'eventType': eventType,
        'sessionId': _currentSession?.sessionId,
        ...data,
      },
    );
    
    if (excludePlayerId != null) {
      // Send to all players except excluded one
      for (final playerId in _currentSession?.playerIds ?? <String>[]) {
        if (playerId != excludePlayerId) {
          await _lanService!.sendNetworkMessageToClient(playerId, message);
        }
      }
    } else {
      await _lanService!.broadcastNetworkMessage(message);
    }
  }
  
  /// Send game event to specific player
  Future<void> _sendGameEventToPlayer(String playerId, String eventType, Map<String, dynamic> data) async {
    if (_lanService == null) return;
    
    final message = NetworkMessage(
      type: NetworkMessageTypes.gameEvent,
      senderId: 'game_session_manager',
      data: {
        'eventType': eventType,
        'sessionId': _currentSession?.sessionId,
        ...data,
      },
    );
    
    await _lanService!.sendNetworkMessageToClient(playerId, message);
  }
  
  /// Validate game start conditions
  Future<void> _validateGameStart(Lobby lobby) async {
    // Validate game type is supported
    if (!GameRegistry.isGameTypeSupported(lobby.gameType)) {
      throw GameSessionException('Game type "${lobby.gameType}" is not supported');
    }
    
    // Create temporary game instance to check player requirements
    final gameInstance = GameRegistry.createGame(lobby.gameType);
    if (gameInstance == null) {
      throw GameSessionException('Failed to create game instance for validation');
    }
    
    // Validate player count
    if (lobby.players.length < gameInstance.minPlayers) {
      throw GameSessionException(
        'Not enough players. Need at least ${gameInstance.minPlayers}, have ${lobby.players.length}'
      );
    }
    
    if (lobby.players.length > gameInstance.maxPlayers) {
      throw GameSessionException(
        'Too many players. Maximum ${gameInstance.maxPlayers}, have ${lobby.players.length}'
      );
    }
    
    // Validate all players are connected
    final disconnectedPlayers = lobby.players.where((p) => !p.isConnected).toList();
    if (disconnectedPlayers.isNotEmpty) {
      throw GameSessionException(
        'Some players are disconnected: ${disconnectedPlayers.map((p) => p.name).join(', ')}'
      );
    }
    
    // Dispose temporary instance
    gameInstance.dispose();
  }
  
  /// Pause the current game session
  Future<void> pauseGameSession({String? reason}) async {
    if (_currentSession == null || _currentSession!.status != GameSessionStatus.active) {
      return;
    }
    
    _currentSession = _currentSession!.copyWith(status: GameSessionStatus.paused);
    _sessionStatusController.add(GameSessionStatus.paused);
    
    await _broadcastGameEvent(GameEventType.gamePaused, {
      'sessionId': _currentSession!.sessionId,
      'reason': reason ?? 'Game paused',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Resume the current game session
  Future<void> resumeGameSession() async {
    if (_currentSession == null || _currentSession!.status != GameSessionStatus.paused) {
      return;
    }
    
    _currentSession = _currentSession!.copyWith(status: GameSessionStatus.active);
    _sessionStatusController.add(GameSessionStatus.active);
    
    await _broadcastGameEvent(GameEventType.gameResumed, {
      'sessionId': _currentSession!.sessionId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Return to lobby after game completion
  Future<void> returnToLobby() async {
    if (_currentSession == null) return;
    
    final lobbyId = _currentSession!.lobbyId;
    
    // Broadcast return to lobby event
    await _broadcastGameEvent(GameEventType.returnToLobby, {
      'sessionId': _currentSession!.sessionId,
      'lobbyId': lobbyId,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // Cleanup session
    await _cleanupSession();
  }
  
  /// Handle player disconnection during game
  Future<void> handlePlayerDisconnection(String playerId) async {
    if (_currentSession == null || !_currentSession!.playerIds.contains(playerId)) {
      return;
    }
    
    // Pause game if active
    if (_currentSession!.status == GameSessionStatus.active) {
      await pauseGameSession(reason: 'Player disconnected: $playerId');
    }
    
    // Broadcast player disconnection
    await _broadcastGameEvent(GameEventType.playerDisconnected, {
      'sessionId': _currentSession!.sessionId,
      'playerId': playerId,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // Start reconnection timer
    _startReconnectionTimer(playerId);
  }
  
  /// Start reconnection timer for disconnected player
  void _startReconnectionTimer(String playerId, {Duration timeout = const Duration(seconds: 30)}) {
    Timer(timeout, () async {
      if (_currentSession != null && 
          _currentSession!.status == GameSessionStatus.paused &&
          _currentSession!.playerIds.contains(playerId)) {
        
        // Player didn't reconnect in time
        await _handlePlayerTimeout(playerId);
      }
    });
  }
  
  /// Handle player timeout (didn't reconnect in time)
  Future<void> _handlePlayerTimeout(String playerId) async {
    if (_currentSession == null) return;
    
    // Remove player from session
    final updatedPlayerIds = _currentSession!.playerIds.where((id) => id != playerId).toList();
    _currentSession = _currentSession!.copyWith(playerIds: updatedPlayerIds);
    
    // Check if we still have enough players to continue
    final gameInstance = _currentSession!.gameInstance;
    if (updatedPlayerIds.length < gameInstance.minPlayers) {
      // Not enough players, end the game
      await endGameSession();
      return;
    }
    
    // Broadcast player removal and resume game
    await _broadcastGameEvent(GameEventType.playerRemoved, {
      'sessionId': _currentSession!.sessionId,
      'playerId': playerId,
      'reason': 'Connection timeout',
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    await resumeGameSession();
  }
  
  /// Get session statistics
  Map<String, dynamic> getSessionStatistics() {
    if (_currentSession == null) {
      return {'status': 'no_active_session'};
    }
    
    final duration = DateTime.now().difference(_currentSession!.startedAt);
    
    return {
      'sessionId': _currentSession!.sessionId,
      'gameType': _currentSession!.gameType,
      'status': _currentSession!.status.toString(),
      'playerCount': _currentSession!.playerIds.length,
      'duration': duration.inSeconds,
      'startedAt': _currentSession!.startedAt.toIso8601String(),
      'gameState': _currentSession!.gameInstance.gameState,
    };
  }
  
  /// Check if session can be started
  bool canStartSession(Lobby lobby) {
    try {
      // Quick validation without throwing exceptions
      if (_currentSession != null) return false;
      if (!GameRegistry.isGameTypeSupported(lobby.gameType)) return false;
      
      final gameInstance = GameRegistry.createGame(lobby.gameType);
      if (gameInstance == null) return false;
      
      final playerCount = lobby.players.length;
      final canStart = playerCount >= gameInstance.minPlayers && 
                      playerCount <= gameInstance.maxPlayers &&
                      lobby.players.every((p) => p.isConnected);
      
      gameInstance.dispose();
      return canStart;
    } catch (e) {
      return false;
    }
  }
  
  /// Cleanup current session
  Future<void> _cleanupSession() async {
    if (_currentSession != null) {
      _currentSession!.gameInstance.dispose();
      _currentSession = null;
    }
    _sessionStatusController.add(GameSessionStatus.idle);
  }
  
  /// Dispose resources
  void dispose() {
    _networkMessageSubscription?.cancel();
    _actionRouter?.dispose();
    _gameEventController.close();
    _sessionStatusController.close();
    _cleanupSession();
  }
}

/// Game session data class
class GameSession {
  final String sessionId;
  final String lobbyId;
  final String gameType;
  final List<String> playerIds;
  final GameBase gameInstance;
  final DateTime startedAt;
  final GameSessionStatus status;
  
  GameSession({
    required this.sessionId,
    required this.lobbyId,
    required this.gameType,
    required this.playerIds,
    required this.gameInstance,
    required this.startedAt,
    required this.status,
  });
  
  GameSession copyWith({
    String? sessionId,
    String? lobbyId,
    String? gameType,
    List<String>? playerIds,
    GameBase? gameInstance,
    DateTime? startedAt,
    GameSessionStatus? status,
  }) {
    return GameSession(
      sessionId: sessionId ?? this.sessionId,
      lobbyId: lobbyId ?? this.lobbyId,
      gameType: gameType ?? this.gameType,
      playerIds: playerIds ?? this.playerIds,
      gameInstance: gameInstance ?? this.gameInstance,
      startedAt: startedAt ?? this.startedAt,
      status: status ?? this.status,
    );
  }
}

/// Game session status enumeration
enum GameSessionStatus {
  idle,
  initializing,
  active,
  paused,
  finished,
  error,
}

/// Game event types for network communication
class GameEventType {
  static const String gameStarting = 'game_starting';
  static const String gameStarted = 'game_started';
  static const String gameAction = 'game_action';
  static const String gameEvent = 'game_event';
  static const String gameFinished = 'game_finished';
  static const String gameEnded = 'game_ended';
  static const String gameStateSync = 'game_state_sync';
  static const String playerReconnected = 'player_reconnected';
  static const String playerDisconnected = 'player_disconnected';
  static const String playerRemoved = 'player_removed';
  static const String gamePaused = 'game_paused';
  static const String gameResumed = 'game_resumed';
  static const String returnToLobby = 'return_to_lobby';
  static const String sessionError = 'session_error';
}

/// Game session exception
class GameSessionException implements Exception {
  final String message;
  GameSessionException(this.message);
  
  @override
  String toString() => 'GameSessionException: $message';
}