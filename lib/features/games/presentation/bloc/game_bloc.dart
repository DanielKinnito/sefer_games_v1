import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/game/game_base.dart';
import '../../../../core/error/error_handler.dart';
import '../../../lobby/domain/entities/lobby.dart';
import '../../../lobby/data/services/lan_service.dart';
import '../../../lobby/data/models/network_models.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/usecases/start_game_session.dart';
import '../../domain/usecases/process_game_action.dart';
import '../../domain/usecases/end_game_session.dart';

// Game Events
abstract class GameEvent {}

class StartGameSessionEvent extends GameEvent {
  final Lobby lobby;
  StartGameSessionEvent(this.lobby);
}

class ProcessGameActionEvent extends GameEvent {
  final String playerId;
  final GameAction action;
  ProcessGameActionEvent(this.playerId, this.action);
}

class EndGameSessionEvent extends GameEvent {
  final String sessionId;
  EndGameSessionEvent(this.sessionId);
}

class ReturnToLobbyEvent extends GameEvent {
  final String sessionId;
  ReturnToLobbyEvent(this.sessionId);
}

// Real-time game events
class GameEventReceivedEvent extends GameEvent {
  final GameEvent gameEvent;
  GameEventReceivedEvent(this.gameEvent);
}

class GameStateUpdateEvent extends GameEvent {
  final Map<String, dynamic> gameState;
  GameStateUpdateEvent(this.gameState);
}

class PlayerActionEvent extends GameEvent {
  final String playerId;
  final String actionType;
  final Map<String, dynamic> actionData;
  PlayerActionEvent(this.playerId, this.actionType, this.actionData);
}

// Network events for games
class GameNetworkMessageEvent extends GameEvent {
  final NetworkMessage message;
  GameNetworkMessageEvent(this.message);
}

class GameConnectionStatusEvent extends GameEvent {
  final ConnectionStatus status;
  GameConnectionStatusEvent(this.status);
}

// Error recovery events
class RetryLastGameOperationEvent extends GameEvent {}

class ClearGameErrorEvent extends GameEvent {}

class RecoverFromSyncErrorEvent extends GameEvent {
  final String sessionId;
  RecoverFromSyncErrorEvent(this.sessionId);
}

// Game States
abstract class GameState {}

class GameInitial extends GameState {}

class GameLoading extends GameState {}

class GameSessionActive extends GameState {
  final GameSession session;
  final Map<String, dynamic> currentGameState;
  final String? currentPlayer;
  
  GameSessionActive(this.session, this.currentGameState, {this.currentPlayer});
}

class GameActionProcessed extends GameState {
  final GameSession session;
  final GameActionResult result;
  final Map<String, dynamic> updatedGameState;
  
  GameActionProcessed(this.session, this.result, this.updatedGameState);
}

class GameSessionEnded extends GameState {
  final GameSession session;
  final Map<String, dynamic> gameResults;
  
  GameSessionEnded(this.session, this.gameResults);
}

class GameError extends GameState {
  final String message;
  final GameErrorType errorType;
  final bool canRetry;
  
  GameError(this.message, {this.errorType = GameErrorType.general, this.canRetry = false});
}

// Real-time game states
class GameStateUpdated extends GameState {
  final GameSession session;
  final Map<String, dynamic> gameState;
  final String updateType;
  
  GameStateUpdated(this.session, this.gameState, this.updateType);
}

class PlayerActionReceived extends GameState {
  final GameSession session;
  final String playerId;
  final String actionType;
  final Map<String, dynamic> result;
  
  PlayerActionReceived(this.session, this.playerId, this.actionType, this.result);
}

class GameRoundChanged extends GameState {
  final GameSession session;
  final int currentRound;
  final int totalRounds;
  
  GameRoundChanged(this.session, this.currentRound, this.totalRounds);
}

class GamePlayerTurnChanged extends GameState {
  final GameSession session;
  final String currentPlayerId;
  final String? nextPlayerId;
  
  GamePlayerTurnChanged(this.session, this.currentPlayerId, this.nextPlayerId);
}

// Network status states for games
class GameNetworkConnected extends GameState {
  final GameSession session;
  final String? hostAddress;
  
  GameNetworkConnected(this.session, {this.hostAddress});
}

class GameNetworkDisconnected extends GameState {
  final GameSession session;
  final String? reason;
  
  GameNetworkDisconnected(this.session, {this.reason});
}

class GameSynchronizing extends GameState {
  final GameSession session;
  final String syncType;
  
  GameSynchronizing(this.session, this.syncType);
}

enum GameErrorType {
  general,
  network,
  validation,
  gameLogic,
  synchronization,
}

class GameBloc extends Bloc<GameEvent, GameState> {
  final StartGameSession startGameSession;
  final ProcessGameAction processGameAction;
  final EndGameSession endGameSession;
  final LanService lanService;

  // Current game session tracking
  GameSession? _currentSession;
  GameBase? _currentGame;
  
  // Real-time subscriptions
  StreamSubscription? _gameEventSubscription;
  StreamSubscription? _networkMessageSubscription;
  StreamSubscription? _connectionStatusSubscription;
  
  // Retry mechanism
  Timer? _retryTimer;
  int _retryAttempts = 0;
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  GameEvent? _lastFailedOperation;
  final RetryMechanism _retryMechanism = RetryMechanism();

  GameBloc({
    required this.startGameSession,
    required this.processGameAction,
    required this.endGameSession,
    required this.lanService,
  }) : super(GameInitial()) {
    
    // Setup network listeners
    _setupNetworkListeners();
    
    // Register event handlers
    on<StartGameSessionEvent>((event, emit) async {
      emit(GameLoading());
      try {
        final session = await _retryMechanism.execute(
          () => startGameSession(event.lobby),
          shouldRetry: (error) => ErrorHandler.isRetryableError(error),
          onRetry: (attempt, error) {
            ErrorHandler.logError(error, null, context: 'StartGameSession attempt $attempt');
          },
        );
        
        _currentSession = session;
        _currentGame = session.gameInstance;
        
        // Subscribe to game events
        _subscribeToGameEvents();
        
        emit(GameSessionActive(
          session, 
          session.gameInstance.gameState,
          currentPlayer: _getCurrentPlayer(),
        ));
        
        _resetRetryState();
      } catch (e) {
        _lastFailedOperation = event;
        final errorMessage = ErrorHandler.getUserFriendlyMessage(e, ErrorContext.game);
        final canRetry = ErrorHandler.isRetryableError(e);
        
        ErrorHandler.logError(e, null, context: 'StartGameSession');
        emit(GameError(errorMessage, errorType: GameErrorType.gameLogic, canRetry: canRetry));
      }
    });
    
    on<ProcessGameActionEvent>((event, emit) async {
      if (_currentSession == null) {
        emit(GameError('No active game session', errorType: GameErrorType.validation));
        return;
      }
      
      try {
        final result = await _retryMechanism.execute(
          () => processGameAction(event.playerId, event.action),
          shouldRetry: (error) => ErrorHandler.isRetryableError(error),
          onRetry: (attempt, error) {
            ErrorHandler.logError(error, null, context: 'ProcessGameAction attempt $attempt');
          },
        );
        
        if (result.success) {
          final updatedGameState = _currentGame?.gameState ?? {};
          emit(GameActionProcessed(_currentSession!, result, updatedGameState));
          
          // Check if game is finished
          if (_currentGame?.isGameFinished == true) {
            emit(GameSessionEnded(_currentSession!, _currentGame!.gameResults));
          } else {
            // Emit updated game state
            emit(GameSessionActive(
              _currentSession!, 
              updatedGameState,
              currentPlayer: _getCurrentPlayer(),
            ));
          }
        } else {
          final errorMessage = ErrorHandler.getUserFriendlyMessage(
            result.errorMessage ?? 'Game action failed', 
            ErrorContext.game
          );
          emit(GameError(errorMessage, errorType: GameErrorType.gameLogic));
        }
      } catch (e) {
        final errorMessage = ErrorHandler.getUserFriendlyMessage(e, ErrorContext.game);
        final errorType = ErrorHandler.isRetryableError(e) 
            ? GameErrorType.network 
            : GameErrorType.gameLogic;
        
        ErrorHandler.logError(e, null, context: 'ProcessGameAction');
        emit(GameError(errorMessage, errorType: errorType, canRetry: ErrorHandler.isRetryableError(e)));
      }
    });
    
    on<EndGameSessionEvent>((event, emit) async {
      if (_currentSession?.sessionId != event.sessionId) {
        emit(GameError('Invalid session ID'));
        return;
      }
      
      try {
        await endGameSession(event.sessionId);
        
        final gameResults = _currentGame?.gameResults ?? {};
        emit(GameSessionEnded(_currentSession!, gameResults));
        
        _cleanupGameSession();
      } catch (e) {
        emit(GameError('Failed to end game session: $e'));
      }
    });
    
    on<ReturnToLobbyEvent>((event, emit) async {
      try {
        if (_currentSession != null) {
          await endGameSession(event.sessionId);
        }
        
        _cleanupGameSession();
        emit(GameInitial());
      } catch (e) {
        emit(GameError('Failed to return to lobby: $e'));
      }
    });
    
    // Real-time game event handlers
    on<GameEventReceivedEvent>((event, emit) async {
      if (_currentSession == null) return;
      
      try {
        await _handleGameEvent(event.gameEvent, emit);
      } catch (e) {
        emit(GameError('Failed to process game event: $e'));
      }
    });
    
    on<GameStateUpdateEvent>((event, emit) {
      if (_currentSession == null) return;
      
      emit(GameStateUpdated(_currentSession!, event.gameState, 'state_update'));
    });
    
    on<PlayerActionEvent>((event, emit) {
      if (_currentSession == null) return;
      
      emit(PlayerActionReceived(
        _currentSession!, 
        event.playerId, 
        event.actionType, 
        event.actionData,
      ));
    });
    
    // Network event handlers
    on<GameNetworkMessageEvent>((event, emit) async {
      try {
        await _handleNetworkMessage(event.message, emit);
      } catch (e) {
        emit(GameError('Failed to process network message: $e', 
                      errorType: GameErrorType.network));
      }
    });
    
    on<GameConnectionStatusEvent>((event, emit) {
      if (_currentSession == null) return;
      
      if (event.status.isConnected) {
        emit(GameNetworkConnected(_currentSession!, 
                                 hostAddress: event.status.hostAddress));
        
        // Attempt to recover from sync errors when reconnected
        if (event.status.reconnectAttempts > 0) {
          add(RecoverFromSyncErrorEvent(_currentSession!.sessionId));
        }
      } else {
        emit(GameNetworkDisconnected(_currentSession!, 
                                   reason: event.status.errorMessage));
        
        // Attempt to synchronize game state when reconnected
        if (event.status.reconnectAttempts > 0) {
          emit(GameSynchronizing(_currentSession!, 'reconnection'));
        }
      }
    });
    
    // Error recovery event handlers
    on<RetryLastGameOperationEvent>((event, emit) async {
      if (_lastFailedOperation != null && _retryAttempts < maxRetryAttempts) {
        _retryAttempts++;
        emit(GameLoading());
        
        // Wait before retrying
        await Future.delayed(ErrorHandler.getRetryDelay(_retryAttempts));
        
        // Retry the last failed operation
        add(_lastFailedOperation!);
      } else {
        emit(GameError('Maximum retry attempts reached', 
                      errorType: GameErrorType.general, canRetry: false));
      }
    });
    
    on<ClearGameErrorEvent>((event, emit) {
      _resetRetryState();
      if (_currentSession != null) {
        emit(GameSessionActive(
          _currentSession!, 
          _currentGame?.gameState ?? {},
          currentPlayer: _getCurrentPlayer(),
        ));
      } else {
        emit(GameInitial());
      }
    });
    
    on<RecoverFromSyncErrorEvent>((event, emit) async {
      if (_currentSession?.sessionId != event.sessionId) return;
      
      emit(GameSynchronizing(_currentSession!, 'recovery'));
      
      try {
        // Attempt to recover from synchronization errors
        final recovered = await ErrorRecoveryStrategy.recoverFromSyncError();
        
        if (recovered && _currentGame != null) {
          // Re-sync game state
          emit(GameStateUpdated(_currentSession!, _currentGame!.gameState, 'recovered'));
          
          // Return to active state
          emit(GameSessionActive(
            _currentSession!, 
            _currentGame!.gameState,
            currentPlayer: _getCurrentPlayer(),
          ));
        } else {
          emit(GameError('Failed to recover from synchronization error', 
                        errorType: GameErrorType.synchronization, canRetry: true));
        }
      } catch (e) {
        ErrorHandler.logError(e, null, context: 'RecoverFromSyncError');
        emit(GameError('Recovery failed: ${ErrorHandler.getUserFriendlyMessage(e, ErrorContext.network)}', 
                      errorType: GameErrorType.synchronization, canRetry: true));
      }
    });
  }
  
  /// Setup network message listeners for game events
  void _setupNetworkListeners() {
    // Listen to network messages for game-specific updates
    _networkMessageSubscription = lanService.messageStream.listen((message) {
      if (_isGameMessage(message)) {
        add(GameNetworkMessageEvent(message));
      }
    });
    
    // Listen to connection status changes
    _connectionStatusSubscription = lanService.connectionStatusStream.listen((status) {
      add(GameConnectionStatusEvent(status));
    });
  }
  
  /// Subscribe to game events from the current game instance
  void _subscribeToGameEvents() {
    if (_currentGame == null) return;
    
    _gameEventSubscription = _currentGame!.gameEvents.listen((gameEvent) {
      add(GameEventReceivedEvent(gameEvent));
    });
  }
  
  /// Handle incoming game events
  Future<void> _handleGameEvent(GameEvent gameEvent, Emitter<GameState> emit) async {
    if (_currentSession == null || _currentGame == null) return;
    
    switch (gameEvent.type) {
      case 'game_started':
        emit(GameSessionActive(
          _currentSession!, 
          _currentGame!.gameState,
          currentPlayer: _getCurrentPlayer(),
        ));
        break;
        
      case 'player_turn_changed':
        final currentPlayerId = gameEvent.data['currentPlayer'] as String?;
        final nextPlayerId = gameEvent.data['nextPlayer'] as String?;
        if (currentPlayerId != null) {
          emit(GamePlayerTurnChanged(_currentSession!, currentPlayerId, nextPlayerId));
        }
        break;
        
      case 'round_changed':
        final currentRound = gameEvent.data['currentRound'] as int? ?? 1;
        final totalRounds = gameEvent.data['totalRounds'] as int? ?? 1;
        emit(GameRoundChanged(_currentSession!, currentRound, totalRounds));
        break;
        
      case 'game_state_changed':
        emit(GameStateUpdated(_currentSession!, _currentGame!.gameState, 'game_event'));
        break;
        
      case 'game_finished':
        emit(GameSessionEnded(_currentSession!, _currentGame!.gameResults));
        break;
        
      default:
        // Generic game state update
        emit(GameStateUpdated(_currentSession!, _currentGame!.gameState, gameEvent.type));
    }
  }
  
  /// Handle network messages related to games
  Future<void> _handleNetworkMessage(NetworkMessage message, Emitter<GameState> emit) async {
    if (_currentSession == null) return;
    
    switch (message.type) {
      case NetworkMessageTypes.gameAction:
        final playerId = message.data['playerId'] as String;
        final actionType = message.data['actionType'] as String;
        final actionData = message.data['actionData'] as Map<String, dynamic>;
        
        add(PlayerActionEvent(playerId, actionType, actionData));
        break;
        
      case NetworkMessageTypes.gameStateSync:
        final gameState = message.data['gameState'] as Map<String, dynamic>;
        add(GameStateUpdateEvent(gameState));
        break;
        
      case NetworkMessageTypes.gameEnded:
        final sessionId = message.data['sessionId'] as String;
        add(EndGameSessionEvent(sessionId));
        break;
        
      default:
        // Handle other game-related messages
        break;
    }
  }
  
  /// Check if a network message is game-related
  bool _isGameMessage(NetworkMessage message) {
    const gameMessageTypes = [
      NetworkMessageTypes.gameAction,
      NetworkMessageTypes.gameStateSync,
      NetworkMessageTypes.gameStarted,
      NetworkMessageTypes.gameEnded,
    ];
    
    return gameMessageTypes.contains(message.type);
  }
  
  /// Get current player from game state
  String? _getCurrentPlayer() {
    if (_currentGame == null) return null;
    
    final gameState = _currentGame!.gameState;
    return gameState['currentPlayer'] as String? ?? 
           gameState['currentGuesser'] as String?;
  }
  
  /// Clean up game session resources
  void _cleanupGameSession() {
    _gameEventSubscription?.cancel();
    _gameEventSubscription = null;
    
    _currentGame?.dispose();
    _currentGame = null;
    _currentSession = null;
  }
  
  /// Reset retry state
  void _resetRetryState() {
    _retryAttempts = 0;
    _lastFailedOperation = null;
    _retryTimer?.cancel();
    _retryTimer = null;
  }
  
  @override
  Future<void> close() {
    _gameEventSubscription?.cancel();
    _networkMessageSubscription?.cancel();
    _connectionStatusSubscription?.cancel();
    _retryTimer?.cancel();
    _cleanupGameSession();
    return super.close();
  }
}