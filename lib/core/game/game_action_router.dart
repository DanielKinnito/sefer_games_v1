import 'dart:async';
import 'game_base.dart';
import 'game_session_manager.dart';
import '../../features/lobby/data/services/lan_service.dart';
import '../../features/lobby/data/models/network_models.dart';

/// Routes game actions between clients and host, ensuring proper synchronization
class GameActionRouter {
  static final GameActionRouter _instance = GameActionRouter._internal();
  factory GameActionRouter() => _instance;
  GameActionRouter._internal();

  LanService? _lanService;
  GameSessionManager? _sessionManager;
  StreamSubscription? _networkMessageSubscription;
  
  final Map<String, GameActionMessage> _pendingActions = {};
  final StreamController<GameActionResult> _actionResultController = StreamController.broadcast();
  
  /// Stream of game action results
  Stream<GameActionResult> get actionResultStream => _actionResultController.stream;
  
  /// Initialize the router with required services
  void initialize(LanService lanService, GameSessionManager sessionManager) {
    _lanService = lanService;
    _sessionManager = sessionManager;
    _setupNetworkListener();
  }
  
  /// Send a game action from client to host
  Future<GameActionResult> sendGameAction(GameAction action) async {
    try {
      if (_lanService == null) {
        return GameActionResult.error('LAN service not initialized');
      }
      
      // Create game action message
      final actionMessage = GameActionMessage(
        actionId: _generateActionId(),
        action: action,
        timestamp: DateTime.now(),
      );
      
      // Store pending action for result tracking
      _pendingActions[actionMessage.actionId] = actionMessage;
      
      // Send to host via network
      final networkMessage = NetworkMessage(
        type: NetworkMessageTypes.gameAction,
        senderId: action.playerId,
        data: {
          'actionId': actionMessage.actionId,
          'action': {
            'type': action.type,
            'playerId': action.playerId,
            'data': action.data,
            'timestamp': action.timestamp.toIso8601String(),
          },
        },
      );
      
      if (_lanService!.isConnectedToHost) {
        await _lanService!.sendNetworkMessageToHost(networkMessage);
      } else {
        // If we are the host, process locally
        return await _processActionAsHost(action);
      }
      
      // Wait for result with timeout
      return await _waitForActionResult(actionMessage.actionId);
      
    } catch (e) {
      return GameActionResult.error('Failed to send game action: $e');
    }
  }
  
  /// Process game action as host and broadcast result
  Future<GameActionResult> processActionAsHost(GameAction action) async {
    return await _processActionAsHost(action);
  }
  
  /// Broadcast game state synchronization to all clients
  Future<void> broadcastGameStateSync(Map<String, dynamic> gameState) async {
    if (_lanService == null) return;
    
    final message = NetworkMessage(
      type: NetworkMessageTypes.gameStateSync,
      senderId: 'host',
      data: {
        'gameState': gameState,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    
    await _lanService!.broadcastNetworkMessage(message);
  }
  
  /// Broadcast game event to all clients
  Future<void> broadcastGameEvent(GameEvent gameEvent) async {
    if (_lanService == null) return;
    
    final message = NetworkMessage(
      type: NetworkMessageTypes.gameEvent,
      senderId: 'host',
      data: {
        'gameEvent': {
          'type': gameEvent.type,
          'gameId': gameEvent.gameId,
          'data': gameEvent.data,
          'timestamp': gameEvent.timestamp.toIso8601String(),
          'targetPlayerIds': gameEvent.targetPlayerIds,
        },
      },
    );
    
    if (gameEvent.targetPlayerIds != null) {
      // Send to specific players
      for (final playerId in gameEvent.targetPlayerIds!) {
        await _lanService!.sendNetworkMessageToClient(playerId, message);
      }
    } else {
      // Broadcast to all clients
      await _lanService!.broadcastNetworkMessage(message);
    }
  }
  
  /// Request game state synchronization from host
  Future<void> requestGameStateSync() async {
    if (_lanService == null || !_lanService!.isConnectedToHost) return;
    
    final message = NetworkMessage(
      type: NetworkMessageTypes.gameStateRequest,
      senderId: 'client',
      data: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    
    await _lanService!.sendNetworkMessageToHost(message);
  }
  
  /// Setup network message listener
  void _setupNetworkListener() {
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
      case NetworkMessageTypes.gameEvent:
        _handleGameEventMessage(message);
        break;
      case NetworkMessageTypes.gameStateSync:
        _handleGameStateSyncMessage(message);
        break;
      case NetworkMessageTypes.gameStateRequest:
        _handleGameStateRequestMessage(message);
        break;
    }
  }
  
  /// Handle game action messages
  void _handleGameActionMessage(NetworkMessage message) async {
    try {
      final actionData = message.data['action'] as Map<String, dynamic>?;
      final actionId = message.data['actionId'] as String?;
      
      if (actionData == null || actionId == null) {
        print('Invalid game action message format');
        return;
      }
      
      // Reconstruct game action
      final action = BasicGameAction(
        type: actionData['type'] as String,
        playerId: actionData['playerId'] as String,
        data: actionData['data'] as Map<String, dynamic>,
        timestamp: DateTime.parse(actionData['timestamp'] as String),
      );
      
      // Check if this is a result message or a new action
      if (message.data.containsKey('result')) {
        _handleActionResult(actionId, message.data['result'] as Map<String, dynamic>);
      } else {
        // Process as new action (we are the host)
        final result = await _processActionAsHost(action);
        
        // Send result back to sender
        await _sendActionResult(actionId, message.senderId, result);
      }
      
    } catch (e) {
      print('Error handling game action message: $e');
    }
  }
  
  /// Handle game event messages
  void _handleGameEventMessage(NetworkMessage message) {
    try {
      final gameEventData = message.data['gameEvent'] as Map<String, dynamic>?;
      if (gameEventData == null) return;
      
      // Reconstruct game event
      final gameEvent = BasicGameEvent(
        type: gameEventData['type'] as String,
        gameId: gameEventData['gameId'] as String,
        data: gameEventData['data'] as Map<String, dynamic>,
        timestamp: DateTime.parse(gameEventData['timestamp'] as String),
        targetPlayerIds: (gameEventData['targetPlayerIds'] as List<dynamic>?)?.cast<String>(),
      );
      
      // Forward to local game event stream if needed
      // This would be handled by GameSessionManager
      
    } catch (e) {
      print('Error handling game event message: $e');
    }
  }
  
  /// Handle game state sync messages
  void _handleGameStateSyncMessage(NetworkMessage message) {
    try {
      final gameState = message.data['gameState'] as Map<String, dynamic>?;
      if (gameState == null) return;
      
      // Forward to session manager for local game state update
      // This would be handled by the game instance directly
      
    } catch (e) {
      print('Error handling game state sync message: $e');
    }
  }
  
  /// Handle game state request messages
  void _handleGameStateRequestMessage(NetworkMessage message) async {
    // Only host should handle this
    if (_sessionManager?.currentSession != null) {
      final gameState = _sessionManager!.currentSession!.gameInstance.gameState;
      await broadcastGameStateSync(gameState);
    }
  }
  
  /// Process game action as host
  Future<GameActionResult> _processActionAsHost(GameAction action) async {
    if (_sessionManager == null) {
      return GameActionResult.error('Session manager not initialized');
    }
    
    try {
      // Process action through session manager
      final result = await _sessionManager!.processGameAction(action.playerId, action);
      
      // Broadcast action result to all clients for synchronization
      await _broadcastActionResult(action, result);
      
      return result;
    } catch (e) {
      return GameActionResult.error('Failed to process action: $e');
    }
  }
  
  /// Send action result back to specific client
  Future<void> _sendActionResult(String actionId, String clientId, GameActionResult result) async {
    if (_lanService == null) return;
    
    final message = NetworkMessage(
      type: NetworkMessageTypes.gameAction,
      senderId: 'host',
      targetId: clientId,
      data: {
        'actionId': actionId,
        'result': {
          'success': result.success,
          'errorMessage': result.errorMessage,
          'resultData': result.resultData,
        },
      },
    );
    
    await _lanService!.sendNetworkMessageToClient(clientId, message);
  }
  
  /// Broadcast action result to all clients for synchronization
  Future<void> _broadcastActionResult(GameAction action, GameActionResult result) async {
    if (_lanService == null) return;
    
    final message = NetworkMessage(
      type: NetworkMessageTypes.gameEvent,
      senderId: 'host',
      data: {
        'eventType': 'action_processed',
        'action': {
          'type': action.type,
          'playerId': action.playerId,
          'data': action.data,
        },
        'result': {
          'success': result.success,
          'errorMessage': result.errorMessage,
          'resultData': result.resultData,
        },
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    
    await _lanService!.broadcastNetworkMessage(message);
  }
  
  /// Handle action result from host
  void _handleActionResult(String actionId, Map<String, dynamic> resultData) {
    final pendingAction = _pendingActions.remove(actionId);
    if (pendingAction == null) return;
    
    final result = GameActionResult(
      success: resultData['success'] as bool,
      errorMessage: resultData['errorMessage'] as String?,
      resultData: resultData['resultData'] as Map<String, dynamic>?,
    );
    
    _actionResultController.add(result);
  }
  
  /// Wait for action result with timeout
  Future<GameActionResult> _waitForActionResult(String actionId, {Duration timeout = const Duration(seconds: 10)}) async {
    final completer = Completer<GameActionResult>();
    Timer? timeoutTimer;
    StreamSubscription? subscription;
    
    // Set up timeout
    timeoutTimer = Timer(timeout, () {
      if (!completer.isCompleted) {
        _pendingActions.remove(actionId);
        completer.complete(GameActionResult.error('Action timeout'));
      }
    });
    
    // Listen for result
    subscription = actionResultStream.listen((result) {
      if (!completer.isCompleted) {
        timeoutTimer?.cancel();
        subscription?.cancel();
        completer.complete(result);
      }
    });
    
    return completer.future;
  }
  
  /// Generate unique action ID
  String _generateActionId() {
    return 'action_${DateTime.now().millisecondsSinceEpoch}_${_pendingActions.length}';
  }
  
  /// Dispose resources
  void dispose() {
    _networkMessageSubscription?.cancel();
    _actionResultController.close();
    _pendingActions.clear();
  }
}

/// Game action message wrapper for network transmission
class GameActionMessage {
  final String actionId;
  final GameAction action;
  final DateTime timestamp;
  
  GameActionMessage({
    required this.actionId,
    required this.action,
    required this.timestamp,
  });
  
  /// Create from JSON
  factory GameActionMessage.fromJson(Map<String, dynamic> json) {
    return GameActionMessage(
      actionId: json['actionId'] as String,
      action: BasicGameAction(
        type: json['action']['type'] as String,
        playerId: json['action']['playerId'] as String,
        data: json['action']['data'] as Map<String, dynamic>,
        timestamp: DateTime.parse(json['action']['timestamp'] as String),
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'actionId': actionId,
      'action': {
        'type': action.type,
        'playerId': action.playerId,
        'data': action.data,
        'timestamp': action.timestamp.toIso8601String(),
      },
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Game action validation utilities
class GameActionValidator {
  /// Validate game action structure and content
  static bool validateAction(GameAction action) {
    // Check required fields
    if (action.type.isEmpty || action.playerId.isEmpty) {
      return false;
    }
    
    // Validate timestamp (not too old or in future)
    final now = DateTime.now();
    final timeDiff = now.difference(action.timestamp).abs();
    if (timeDiff.inMinutes > 1) {
      return false;
    }
    
    return true;
  }
  
  /// Validate action data based on action type
  static bool validateActionData(String actionType, Map<String, dynamic> data) {
    switch (actionType) {
      case 'make_guess':
        return data.containsKey('guess') && data['guess'] is int;
      case 'next_round':
        return true; // No specific data required
      case 'ready':
        return data.containsKey('ready') && data['ready'] is bool;
      default:
        return true; // Allow unknown action types for extensibility
    }
  }
}