import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/error_handler.dart';
import '../../domain/entities/lobby.dart';
import '../../domain/usecases/create_lobby.dart';
import '../../domain/usecases/join_lobby.dart';
import '../../domain/usecases/get_available_lobbies.dart';
import '../../domain/usecases/leave_lobby.dart';
import '../../domain/usecases/start_hosting.dart';
import '../../domain/usecases/discover_local_lobbies.dart';
import '../../data/services/lan_service.dart';
import '../../data/models/network_models.dart';

abstract class LobbyEvent {}

class CreateLobbyEvent extends LobbyEvent {
  final String lobbyName;
  final String hostName;
  final String hostAvatarId;
  final String gameType;
  final int maxPlayers;
  final Map<String, dynamic>? gameConfig;
  
  CreateLobbyEvent(
    this.lobbyName, 
    this.hostName, 
    this.hostAvatarId, 
    this.gameType, {
    this.maxPlayers = 8,
    this.gameConfig,
  });
}

class JoinLobbyEvent extends LobbyEvent {
  final String lobbyId;
  final String playerName;
  final String playerAvatarId;
  
  JoinLobbyEvent(this.lobbyId, this.playerName, this.playerAvatarId);
}

class LoadLobbiesEvent extends LobbyEvent {}

class LeaveLobbyEvent extends LobbyEvent {
  final String lobbyId;
  final String playerId;
  
  LeaveLobbyEvent(this.lobbyId, this.playerId);
}

class StartHostingEvent extends LobbyEvent {
  final String lobbyId;
  final int port;
  
  StartHostingEvent(this.lobbyId, {this.port = 8080});
}

class DiscoverLocalLobbiesEvent extends LobbyEvent {}

// Real-time update events
class LobbyUpdateReceivedEvent extends LobbyEvent {
  final LobbyUpdate update;
  LobbyUpdateReceivedEvent(this.update);
}

class PlayerJoinedEvent extends LobbyEvent {
  final String lobbyId;
  final String playerId;
  final String playerName;
  final String avatarId;
  
  PlayerJoinedEvent(this.lobbyId, this.playerId, this.playerName, this.avatarId);
}

class PlayerLeftEvent extends LobbyEvent {
  final String lobbyId;
  final String playerId;
  
  PlayerLeftEvent(this.lobbyId, this.playerId);
}

// Network status events
class NetworkStatusChangedEvent extends LobbyEvent {
  final ConnectionStatus status;
  NetworkStatusChangedEvent(this.status);
}

class ConnectionLostEvent extends LobbyEvent {
  final String? reason;
  ConnectionLostEvent({this.reason});
}

class ReconnectionAttemptEvent extends LobbyEvent {
  final int attemptNumber;
  ReconnectionAttemptEvent(this.attemptNumber);
}

class ReconnectedEvent extends LobbyEvent {}

// Lobby synchronization events
class SyncLobbyStateEvent extends LobbyEvent {
  final String lobbyId;
  SyncLobbyStateEvent(this.lobbyId);
}

class RefreshLobbiesEvent extends LobbyEvent {}

// Error recovery events
class RetryLastOperationEvent extends LobbyEvent {}

class ClearErrorEvent extends LobbyEvent {}

abstract class LobbyState {}

class LobbyInitial extends LobbyState {}

class LobbyLoading extends LobbyState {}

class LobbyLoaded extends LobbyState {
  final List<Lobby> lobbies;
  LobbyLoaded(this.lobbies);
}

class LobbyJoined extends LobbyState {
  final Lobby lobby;
  LobbyJoined(this.lobby);
}

class LobbyCreated extends LobbyState {
  final Lobby lobby;
  LobbyCreated(this.lobby);
}

class LobbyHosting extends LobbyState {
  final Lobby lobby;
  final String hostAddress;
  LobbyHosting(this.lobby, this.hostAddress);
}

class LobbyError extends LobbyState {
  final String message;
  final LobbyErrorType errorType;
  final bool canRetry;
  
  LobbyError(this.message, {this.errorType = LobbyErrorType.general, this.canRetry = false});
}

// Real-time update states
class LobbyUpdated extends LobbyState {
  final Lobby lobby;
  final String updateType;
  
  LobbyUpdated(this.lobby, this.updateType);
}

class PlayerJoined extends LobbyState {
  final Lobby lobby;
  final String playerName;
  
  PlayerJoined(this.lobby, this.playerName);
}

class PlayerLeft extends LobbyState {
  final Lobby lobby;
  final String playerName;
  
  PlayerLeft(this.lobby, this.playerName);
}

// Network status states
class NetworkConnected extends LobbyState {
  final String? hostAddress;
  NetworkConnected({this.hostAddress});
}

class NetworkDisconnected extends LobbyState {
  final String? reason;
  NetworkDisconnected({this.reason});
}

class NetworkReconnecting extends LobbyState {
  final int attemptNumber;
  final int maxAttempts;
  
  NetworkReconnecting(this.attemptNumber, this.maxAttempts);
}

// Combined states for complex scenarios
class LobbyWithNetworkStatus extends LobbyState {
  final Lobby lobby;
  final ConnectionStatus networkStatus;
  final String? lastUpdate;
  
  LobbyWithNetworkStatus(this.lobby, this.networkStatus, {this.lastUpdate});
}

enum LobbyErrorType {
  general,
  network,
  validation,
  timeout,
  serverError,
}

class LobbyBloc extends Bloc<LobbyEvent, LobbyState> {
  final CreateLobby createLobby;
  final JoinLobby joinLobby;
  final GetAvailableLobbies getAvailableLobbies;
  final LeaveLobby leaveLobby;
  final StartHosting startHosting;
  final DiscoverLocalLobbies discoverLocalLobbies;
  final LanService lanService;

  // Real-time update subscriptions
  StreamSubscription? _networkMessageSubscription;
  StreamSubscription? _connectionStatusSubscription;
  
  // Current state tracking
  Lobby? _currentLobby;
  ConnectionStatus? _currentConnectionStatus;
  LobbyEvent? _lastFailedOperation;
  
  // Retry mechanism
  Timer? _retryTimer;
  int _retryAttempts = 0;
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  final RetryMechanism _retryMechanism = RetryMechanism();

  LobbyBloc({
    required this.createLobby,
    required this.joinLobby,
    required this.getAvailableLobbies,
    required this.leaveLobby,
    required this.startHosting,
    required this.discoverLocalLobbies,
    required this.lanService,
  }) : super(LobbyInitial()) {
    
    // Setup real-time listeners
    _setupNetworkListeners();
    
    // Register event handlers
    
    on<CreateLobbyEvent>((event, emit) async {
      emit(LobbyLoading());
      try {
        final lobby = await createLobby(
          event.lobbyName, 
          event.hostName, 
          event.hostAvatarId, 
          event.gameType, 
          maxPlayers: event.maxPlayers
        );
        _updateCurrentLobby(lobby);
        emit(LobbyCreated(lobby));
        _resetRetryState();
      } catch (e) {
        _lastFailedOperation = event;
        final errorMessage = ErrorHandler.getUserFriendlyMessage(e, ErrorContext.lobby);
        final canRetry = ErrorHandler.isRetryableError(e);
        
        ErrorHandler.logError(e, null, context: 'CreateLobby');
        emit(LobbyError(errorMessage, errorType: LobbyErrorType.validation, canRetry: canRetry));
      }
    });
    
    on<JoinLobbyEvent>((event, emit) async {
      emit(LobbyLoading());
      try {
        final lobby = await joinLobby(event.lobbyId, event.playerName, event.playerAvatarId);
        if (lobby != null) {
          emit(LobbyJoined(lobby));
        } else {
          emit(LobbyError('Lobby not found or already full.'));
        }
      } catch (e) {
        emit(LobbyError(e.toString()));
      }
    });
    
    on<LoadLobbiesEvent>((event, emit) async {
      emit(LobbyLoading());
      try {
        final lobbies = await getAvailableLobbies();
        emit(LobbyLoaded(lobbies));
      } catch (e) {
        emit(LobbyError(e.toString()));
      }
    });
    
    on<LeaveLobbyEvent>((event, emit) async {
      emit(LobbyLoading());
      try {
        await leaveLobby(event.lobbyId, event.playerId);
        final lobbies = await getAvailableLobbies();
        emit(LobbyLoaded(lobbies));
      } catch (e) {
        emit(LobbyError(e.toString()));
      }
    });

    on<StartHostingEvent>((event, emit) async {
      emit(LobbyLoading());
      try {
        final hostAddress = await startHosting(event.lobbyId, port: event.port);
        // Get the updated lobby to show hosting status
        final lobbies = await getAvailableLobbies();
        final lobby = lobbies.firstWhere((l) => l.id == event.lobbyId);
        emit(LobbyHosting(lobby, hostAddress));
      } catch (e) {
        emit(LobbyError(e.toString()));
      }
    });

    on<DiscoverLocalLobbiesEvent>((event, emit) async {
      emit(LobbyLoading());
      try {
        final lobbies = await discoverLocalLobbies();
        emit(LobbyLoaded(lobbies));
        _resetRetryState();
      } catch (e) {
        _lastFailedOperation = event;
        final errorMessage = ErrorHandler.getUserFriendlyMessage(e, ErrorContext.network);
        
        ErrorHandler.logError(e, null, context: 'DiscoverLocalLobbies');
        emit(LobbyError(errorMessage, errorType: LobbyErrorType.network, canRetry: true));
      }
    });
    
    // Real-time update handlers
    on<LobbyUpdateReceivedEvent>((event, emit) async {
      try {
        await _handleLobbyUpdate(event.update, emit);
      } catch (e) {
        emit(LobbyError('Failed to process lobby update: $e'));
      }
    });
    
    on<PlayerJoinedEvent>((event, emit) async {
      if (_currentLobby?.id == event.lobbyId) {
        // Refresh lobby state to get updated player list
        await _refreshCurrentLobby(emit);
      }
    });
    
    on<PlayerLeftEvent>((event, emit) async {
      if (_currentLobby?.id == event.lobbyId) {
        // Refresh lobby state to get updated player list
        await _refreshCurrentLobby(emit);
      }
    });
    
    // Network status handlers
    on<NetworkStatusChangedEvent>((event, emit) {
      _currentConnectionStatus = event.status;
      
      if (event.status.isConnected) {
        emit(NetworkConnected(hostAddress: event.status.hostAddress));
        _resetRetryState();
      } else {
        emit(NetworkDisconnected(reason: event.status.errorMessage));
      }
      
      // Update combined state if we have a current lobby
      if (_currentLobby != null) {
        emit(LobbyWithNetworkStatus(_currentLobby!, event.status));
      }
    });
    
    on<ConnectionLostEvent>((event, emit) {
      emit(NetworkDisconnected(reason: event.reason));
      _startReconnectionAttempts();
    });
    
    on<ReconnectionAttemptEvent>((event, emit) {
      emit(NetworkReconnecting(event.attemptNumber, maxRetryAttempts));
    });
    
    on<ReconnectedEvent>((event, emit) {
      emit(NetworkConnected(hostAddress: _currentConnectionStatus?.hostAddress));
      _resetRetryState();
      
      // Sync lobby state after reconnection
      if (_currentLobby != null) {
        add(SyncLobbyStateEvent(_currentLobby!.id));
      }
    });
    
    // Synchronization handlers
    on<SyncLobbyStateEvent>((event, emit) async {
      try {
        await _syncLobbyState(event.lobbyId, emit);
      } catch (e) {
        emit(LobbyError('Failed to sync lobby state: $e', errorType: LobbyErrorType.network));
      }
    });
    
    on<RefreshLobbiesEvent>((event, emit) async {
      try {
        final lobbies = await getAvailableLobbies();
        emit(LobbyLoaded(lobbies));
      } catch (e) {
        emit(LobbyError('Failed to refresh lobbies: $e', errorType: LobbyErrorType.network));
      }
    });
    
    // Error recovery handlers
    on<RetryLastOperationEvent>((event, emit) async {
      if (_lastFailedOperation != null && _retryAttempts < maxRetryAttempts) {
        _retryAttempts++;
        emit(LobbyLoading());
        
        // Wait a bit before retrying
        await Future.delayed(retryDelay);
        
        // Retry the last failed operation
        add(_lastFailedOperation!);
      } else {
        emit(LobbyError('Maximum retry attempts reached', canRetry: false));
      }
    });
    
    on<ClearErrorEvent>((event, emit) {
      _resetRetryState();
      emit(LobbyInitial());
    });
  }
  
  /// Setup network message and connection status listeners
  void _setupNetworkListeners() {
    // Listen to network messages for real-time updates
    _networkMessageSubscription = lanService.messageStream.listen((message) {
      _handleNetworkMessage(message);
    });
    
    // Listen to connection status changes
    _connectionStatusSubscription = lanService.connectionStatusStream.listen((status) {
      add(NetworkStatusChangedEvent(status));
    });
  }
  
  /// Handle incoming network messages
  void _handleNetworkMessage(NetworkMessage message) {
    switch (message.type) {
      case NetworkMessageTypes.playerJoined:
        final data = message.data;
        add(PlayerJoinedEvent(
          data['lobbyId'] as String,
          data['playerId'] as String,
          data['playerName'] as String,
          data['avatarId'] as String,
        ));
        break;
        
      case NetworkMessageTypes.playerLeft:
        final data = message.data;
        add(PlayerLeftEvent(
          data['lobbyId'] as String,
          data['playerId'] as String,
        ));
        break;
        
      case NetworkMessageTypes.lobbyUpdate:
        final updateData = message.data;
        final update = LobbyUpdate(
          type: updateData['type'] as String,
          data: updateData['data'] as Map<String, dynamic>,
        );
        add(LobbyUpdateReceivedEvent(update));
        break;
        
      case NetworkMessageTypes.disconnect:
        add(ConnectionLostEvent(reason: message.data['reason'] as String?));
        break;
        
      case NetworkMessageTypes.reconnect:
        add(ReconnectedEvent());
        break;
    }
  }
  
  /// Handle lobby update messages
  Future<void> _handleLobbyUpdate(LobbyUpdate update, Emitter<LobbyState> emit) async {
    switch (update.type) {
      case 'player_joined':
        if (_currentLobby != null) {
          await _refreshCurrentLobby(emit);
          final playerName = update.data['playerName'] as String? ?? 'Unknown';
          emit(PlayerJoined(_currentLobby!, playerName));
        }
        break;
        
      case 'player_left':
        if (_currentLobby != null) {
          await _refreshCurrentLobby(emit);
          final playerName = update.data['playerName'] as String? ?? 'Unknown';
          emit(PlayerLeft(_currentLobby!, playerName));
        }
        break;
        
      case 'lobby_state_changed':
        if (_currentLobby != null) {
          await _refreshCurrentLobby(emit);
          emit(LobbyUpdated(_currentLobby!, 'state_changed'));
        }
        break;
        
      case 'game_starting':
        if (_currentLobby != null) {
          emit(LobbyUpdated(_currentLobby!, 'game_starting'));
        }
        break;
    }
  }
  
  /// Refresh current lobby state
  Future<void> _refreshCurrentLobby(Emitter<LobbyState> emit) async {
    if (_currentLobby == null) return;
    
    try {
      // Get updated lobby information
      final lobbies = await getAvailableLobbies();
      final updatedLobby = lobbies.firstWhere(
        (l) => l.id == _currentLobby!.id,
        orElse: () => _currentLobby!,
      );
      
      _currentLobby = updatedLobby;
      
      // Emit combined state with network status if available
      if (_currentConnectionStatus != null) {
        emit(LobbyWithNetworkStatus(updatedLobby, _currentConnectionStatus!));
      }
    } catch (e) {
      // Handle refresh error silently or emit warning
      print('Failed to refresh lobby state: $e');
    }
  }
  
  /// Sync lobby state after reconnection
  Future<void> _syncLobbyState(String lobbyId, Emitter<LobbyState> emit) async {
    try {
      // Request fresh lobby data
      final lobbies = await getAvailableLobbies();
      final lobby = lobbies.firstWhere((l) => l.id == lobbyId);
      
      _currentLobby = lobby;
      emit(LobbyUpdated(lobby, 'synced'));
      
    } catch (e) {
      throw Exception('Failed to sync lobby state: $e');
    }
  }
  
  /// Start automatic reconnection attempts
  void _startReconnectionAttempts() {
    _retryAttempts = 0;
    _attemptReconnection();
  }
  
  /// Attempt reconnection with exponential backoff
  void _attemptReconnection() {
    if (_retryAttempts >= maxRetryAttempts) {
      add(NetworkStatusChangedEvent(ConnectionStatus(
        isConnected: false,
        errorMessage: 'Maximum reconnection attempts reached',
        reconnectAttempts: _retryAttempts,
      )));
      return;
    }
    
    _retryAttempts++;
    add(ReconnectionAttemptEvent(_retryAttempts));
    
    final delay = Duration(seconds: retryDelay.inSeconds * _retryAttempts);
    _retryTimer = Timer(delay, () {
      // Attempt to reconnect through LAN service
      // This would trigger connection status updates
      _attemptReconnection();
    });
  }
  
  /// Reset retry state
  void _resetRetryState() {
    _retryAttempts = 0;
    _lastFailedOperation = null;
    _retryTimer?.cancel();
    _retryTimer = null;
  }
  
  /// Update current lobby reference
  void _updateCurrentLobby(Lobby lobby) {
    _currentLobby = lobby;
  }
  
  @override
  Future<void> close() {
    _networkMessageSubscription?.cancel();
    _connectionStatusSubscription?.cancel();
    _retryTimer?.cancel();
    return super.close();
  }
}
