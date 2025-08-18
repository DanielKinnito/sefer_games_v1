import 'dart:async';
import 'lobby_datasource.dart';
import '../models/lobby_model.dart';
import '../models/player_model.dart';
import '../models/network_models.dart';
import '../models/network_errors.dart';
import '../services/lan_service.dart';
import '../../domain/entities/lobby.dart';

// Extension to add firstOrNull method
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class LobbyDataSourceImpl implements LobbyDataSource {
  final List<LobbyModel> _lobbies = [];
  final Map<String, StreamController<LobbyModel>> _lobbyStreams = {};
  final LanService _lanService = LanService();
  
  // Track which lobbies are being hosted
  final Map<String, String> _hostAddresses = {};
  
  // Stream subscriptions for network events
  StreamSubscription<List<DiscoveredLobby>>? _discoverySubscription;
  StreamSubscription<NetworkMessage>? _messageSubscription;
  StreamSubscription<ConnectionStatus>? _connectionSubscription;

  @override
  Future<LobbyModel> createLobby(String lobbyName, String hostName, String hostAvatarId, String gameType, {int maxPlayers = 8}) async {
    final hostId = DateTime.now().millisecondsSinceEpoch.toString();
    final host = PlayerModel(
      id: hostId,
      name: hostName,
      avatarId: hostAvatarId,
      isHost: true,
      isConnected: true,
    );
    
    final lobby = LobbyModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: lobbyName,
      hostId: hostId,
      players: [host],
      gameType: gameType,
      maxPlayers: maxPlayers,
      status: LobbyStatus.waiting,
    );
    
    _lobbies.add(lobby);
    _createLobbyStream(lobby.id);
    
    // Update LAN service with lobby state for HTTP endpoints
    _lanService.updateLobbyState({
      'id': lobby.id,
      'name': lobby.name,
      'hostId': lobby.hostId,
      'players': lobby.players.map((p) => {
        'id': p.id,
        'name': p.name,
        'avatarId': p.avatarId,
        'isHost': p.isHost,
        'isConnected': p.isConnected,
      }).toList(),
      'gameType': lobby.gameType,
      'maxPlayers': lobby.maxPlayers,
      'status': lobby.status.toString(),
    });
    
    return lobby;
  }

  @override
  Future<LobbyModel?> joinLobby(String lobbyId, String playerName, String playerAvatarId) async {
    // First try to find local lobby
    LobbyModel? lobby;
    try {
      lobby = _lobbies.firstWhere((l) => l.id == lobbyId);
      
      // Local lobby - add player directly
      if (lobby.players.length < lobby.maxPlayers) {
        final playerId = DateTime.now().millisecondsSinceEpoch.toString();
        final player = PlayerModel(
          id: playerId,
          name: playerName,
          avatarId: playerAvatarId,
          isHost: false,
          isConnected: true,
        );
        
        // Check if player with same name already exists
        if (!lobby.players.any((p) => p.name == playerName)) {
          lobby.players.add(player);
          _updateLobbyStream(lobby);
          
          // Update LAN service with new lobby state
          _lanService.updateLobbyState({
            'id': lobby.id,
            'name': lobby.name,
            'hostId': lobby.hostId,
            'players': lobby.players.map((p) => {
              'id': p.id,
              'name': p.name,
              'avatarId': p.avatarId,
              'isHost': p.isHost,
              'isConnected': p.isConnected,
            }).toList(),
            'gameType': lobby.gameType,
            'maxPlayers': lobby.maxPlayers,
            'status': lobby.status.toString(),
          });
          
          // Broadcast player joined event with error handling
          try {
            await _lanService.broadcastNetworkMessage(NetworkMessage(
              type: NetworkMessageTypes.playerJoined,
              senderId: 'server',
              data: {
                'lobbyId': lobbyId,
                'player': {
                  'id': player.id,
                  'name': player.name,
                  'avatarId': player.avatarId,
                  'isHost': player.isHost,
                },
              },
            ));
          } catch (e) {
            print('Failed to broadcast player joined event: $e');
            // Continue anyway - local state is updated
          }
          
          return lobby;
        }
      }
      return null;
    } catch (_) {
      // Not a local lobby - this might be a remote lobby join request
      // For remote lobbies, we would need the host address to connect
      // This should be handled by the connectToLobbyHost method first
      return null;
    }
  }

  @override
  Future<List<LobbyModel>> getAvailableLobbies() async {
    // Return local lobbies that are waiting
    return _lobbies.where((lobby) => lobby.status == LobbyStatus.waiting).toList();
  }

  @override
  Future<void> leaveLobby(String lobbyId, String playerId) async {
    LobbyModel? lobby;
    try {
      lobby = _lobbies.firstWhere((l) => l.id == lobbyId);
    } catch (_) {
      return;
    }
    
    lobby.players.removeWhere((player) => player.id == playerId);
    
    // Broadcast player left event with error handling
    try {
      await _lanService.broadcastNetworkMessage(NetworkMessage(
        type: NetworkMessageTypes.playerLeft,
        senderId: 'server',
        data: {
          'lobbyId': lobbyId,
          'playerId': playerId,
        },
      ));
    } catch (e) {
      print('Failed to broadcast player left event: $e');
      // Continue anyway - local state is updated
    }
    
    // If host leaves or lobby is empty, remove the lobby
    if (lobby.players.isEmpty || lobby.hostId == playerId) {
      _lobbies.remove(lobby);
      _closeLobbyStream(lobbyId);
      
      // Stop hosting if this was a hosted lobby
      if (_hostAddresses.containsKey(lobbyId)) {
        await _lanService.stopHosting();
        await _lanService.stopBroadcasting();
        _hostAddresses.remove(lobbyId);
      }
      
      // Broadcast lobby destroyed event with error handling
      try {
        await _lanService.broadcastNetworkMessage(NetworkMessage(
          type: NetworkMessageTypes.lobbyDestroyed,
          senderId: 'server',
          data: {
            'lobbyId': lobbyId,
          },
        ));
      } catch (e) {
        print('Failed to broadcast lobby destroyed event: $e');
        // Continue anyway - cleanup is more important
      }
    } else {
      _updateLobbyStream(lobby);
      
      // Update LAN service with new lobby state
      _lanService.updateLobbyState({
        'id': lobby.id,
        'name': lobby.name,
        'hostId': lobby.hostId,
        'players': lobby.players.map((p) => {
          'id': p.id,
          'name': p.name,
          'avatarId': p.avatarId,
          'isHost': p.isHost,
          'isConnected': p.isConnected,
        }).toList(),
        'gameType': lobby.gameType,
        'maxPlayers': lobby.maxPlayers,
        'status': lobby.status.toString(),
      });
    }
  }

  @override
  Future<void> updatePlayerStatus(String lobbyId, String playerId, bool isConnected) async {
    LobbyModel? lobby;
    try {
      lobby = _lobbies.firstWhere((l) => l.id == lobbyId);
    } catch (_) {
      return;
    }
    
    final playerIndex = lobby.players.indexWhere((p) => p.id == playerId);
    if (playerIndex != -1) {
      final updatedPlayer = PlayerModel(
        id: lobby.players[playerIndex].id,
        name: lobby.players[playerIndex].name,
        avatarId: lobby.players[playerIndex].avatarId,
        isHost: lobby.players[playerIndex].isHost,
        isConnected: isConnected,
        joinedAt: lobby.players[playerIndex].joinedAt,
      );
      lobby.players[playerIndex] = updatedPlayer;
      _updateLobbyStream(lobby);
    }
  }

  @override
  Future<LobbyModel?> getLobby(String lobbyId) async {
    try {
      return _lobbies.firstWhere((l) => l.id == lobbyId);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<LobbyModel> watchLobby(String lobbyId) {
    if (!_lobbyStreams.containsKey(lobbyId)) {
      _createLobbyStream(lobbyId);
    }
    return _lobbyStreams[lobbyId]!.stream;
  }

  // LAN-specific implementations
  @override
  Future<String> startHosting(String lobbyId, {int port = 8080}) async {
    return await NetworkErrorHandler.withTimeout(
      () async {
        return await NetworkErrorHandler.withRetry(
          () async {
            try {
              final lobby = await getLobby(lobbyId);
              if (lobby == null) {
                throw LobbyUnavailableError('not found', lobbyId: lobbyId);
              }
              
              // Start hosting with lobby state
              final lobbyState = {
                'id': lobby.id,
                'name': lobby.name,
                'hostId': lobby.hostId,
                'players': lobby.players.map((p) => {
                  'id': p.id,
                  'name': p.name,
                  'avatarId': p.avatarId,
                  'isHost': p.isHost,
                  'isConnected': p.isConnected,
                }).toList(),
                'gameType': lobby.gameType,
                'maxPlayers': lobby.maxPlayers,
                'status': lobby.status.toString(),
              };
              
              final hostAddress = await _lanService.startHosting(port: port, lobbyState: lobbyState);
              _hostAddresses[lobbyId] = hostAddress;
              
              // Start broadcasting lobby information
              final broadcastInfo = LobbyBroadcastInfo(
                lobbyId: lobby.id,
                lobbyName: lobby.name,
                hostPort: port,
                gameType: lobby.gameType,
                currentPlayers: lobby.players.length,
                maxPlayers: lobby.maxPlayers,
              );
              
              await _lanService.startBroadcasting(broadcastInfo);
              
              // Set up network message handling
              _setupNetworkMessageHandling();
              
              return hostAddress;
            } catch (e) {
              throw NetworkErrorHandler.convertToNetworkError(e, context: 'hosting');
            }
          },
          shouldRetry: NetworkErrorHandler.isRetryableError,
        );
      },
      const Duration(seconds: 30),
      operationName: 'start hosting',
    );
  }

  @override
  Future<List<LobbyModel>> discoverLocalLobbies() async {
    return await NetworkErrorHandler.withTimeout(
      () async {
        try {
          final discoveredLobbies = await NetworkErrorHandler.withRetry(
            () async {
              try {
                return await _lanService.discoverLobbies();
              } catch (e) {
                throw NetworkErrorHandler.convertToNetworkError(e, context: 'discovery');
              }
            },
            maxAttempts: 2, // Fewer retries for discovery
            shouldRetry: (error) => NetworkErrorHandler.isRetryableError(error) && error is! DiscoveryError,
          );
          
          final List<LobbyModel> lobbies = [];
          
          for (final discoveredLobby in discoveredLobbies) {
            // Validate discovered lobby data
            if (!NetworkMessageValidator.validateDiscoveredLobby(discoveredLobby)) {
              print('Invalid lobby data received, skipping: $discoveredLobby');
              continue;
            }
            
            // Convert discovered lobby info to LobbyModel
            final lobby = LobbyModel(
              id: discoveredLobby.id,
              name: discoveredLobby.name,
              hostId: 'remote_host', // We don't have the actual host ID
              players: [], // Will be populated when joining
              gameType: discoveredLobby.gameType,
              status: LobbyStatus.waiting,
              hostAddress: discoveredLobby.hostAddress,
              hostPort: discoveredLobby.hostPort,
            );
            lobbies.add(lobby);
          }
          
          return lobbies;
        } catch (e) {
          // Graceful degradation: return local lobbies if network discovery fails
          print('Network discovery failed, returning local lobbies: $e');
          return _lobbies.where((lobby) => 
            lobby.status == LobbyStatus.waiting && 
            _hostAddresses.containsKey(lobby.id)
          ).toList();
        }
      },
      const Duration(seconds: 15),
      operationName: 'discover lobbies',
    );
  }

  @override
  Future<bool> connectToLobbyHost(String hostAddress, int port) async {
    try {
      return await NetworkErrorHandler.withTimeout(
        () async {
          return await NetworkErrorHandler.withRetry(
            () async {
              try {
                final success = await _lanService.connectToHost(hostAddress, port);
                if (success) {
                  // Set up network message handling for client
                  _setupNetworkMessageHandling();
                  return true;
                } else {
                  throw ConnectionError(
                    'Failed to connect to lobby host',
                    hostAddress: hostAddress,
                    port: port,
                  );
                }
              } catch (e) {
                throw NetworkErrorHandler.convertToNetworkError(e, context: 'connection');
              }
            },
            shouldRetry: NetworkErrorHandler.isRetryableError,
          );
        },
        const Duration(seconds: 20),
        operationName: 'connect to host',
      );
    } catch (e) {
      print('Failed to connect to lobby host $hostAddress:$port - $e');
      return false;
    }
  }

  // Helper methods for stream management
  void _createLobbyStream(String lobbyId) {
    if (!_lobbyStreams.containsKey(lobbyId)) {
      _lobbyStreams[lobbyId] = StreamController<LobbyModel>.broadcast();
    }
  }

  void _updateLobbyStream(LobbyModel lobby) {
    if (_lobbyStreams.containsKey(lobby.id)) {
      _lobbyStreams[lobby.id]!.add(lobby);
    }
  }

  void _closeLobbyStream(String lobbyId) {
    if (_lobbyStreams.containsKey(lobbyId)) {
      _lobbyStreams[lobbyId]!.close();
      _lobbyStreams.remove(lobbyId);
    }
  }

  // Network message handling setup
  void _setupNetworkMessageHandling() {
    // Cancel existing subscriptions
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();
    
    // Listen to network messages with error handling
    _messageSubscription = _lanService.messageStream.listen(
      (message) {
        try {
          _handleNetworkMessage(message);
        } catch (e) {
          print('Error handling network message: $e');
        }
      },
      onError: (error) {
        print('Network message stream error: $error');
        // Attempt to reconnect after a delay
        Timer(const Duration(seconds: 5), () {
          if (!_messageSubscription!.isPaused) {
            _setupNetworkMessageHandling();
          }
        });
      },
    );
    
    // Listen to connection status changes with error handling
    _connectionSubscription = _lanService.connectionStatusStream.listen(
      (status) {
        try {
          _handleConnectionStatusChange(status);
        } catch (e) {
          print('Error handling connection status change: $e');
        }
      },
      onError: (error) {
        print('Connection status stream error: $error');
      },
    );
  }
  
  // Handle incoming network messages
  void _handleNetworkMessage(NetworkMessage message) {
    // Validate message first
    if (!NetworkMessageValidator.validateMessage(message)) {
      print('Invalid network message received: $message');
      return;
    }

    try {
      switch (message.type) {
        case NetworkMessageTypes.playerJoined:
          _handlePlayerJoinedMessage(message);
          break;
        case NetworkMessageTypes.playerLeft:
          _handlePlayerLeftMessage(message);
          break;
        case NetworkMessageTypes.lobbyUpdate:
          _handleLobbyUpdateMessage(message);
          break;
        case NetworkMessageTypes.error:
          _handleErrorMessage(message);
          break;
        default:
          // Forward other messages to interested parties
          print('Unhandled message type: ${message.type}');
          break;
      }
    } catch (e) {
      print('Error processing network message ${message.type}: $e');
    }
  }
  
  // Handle player joined messages
  void _handlePlayerJoinedMessage(NetworkMessage message) {
    final lobbyId = message.data['lobbyId'] as String?;
    final playerData = message.data['player'] as Map<String, dynamic>?;
    
    if (lobbyId != null && playerData != null) {
      final lobby = _lobbies.where((l) => l.id == lobbyId).firstOrNull;
      if (lobby != null) {
        final player = PlayerModel(
          id: playerData['id'] as String,
          name: playerData['name'] as String,
          avatarId: playerData['avatarId'] as String,
          isHost: playerData['isHost'] as bool? ?? false,
          isConnected: true,
        );
        
        // Add player if not already present
        if (!lobby.players.any((p) => p.id == player.id)) {
          lobby.players.add(player);
          _updateLobbyStream(lobby);
        }
      }
    }
  }
  
  // Handle player left messages
  void _handlePlayerLeftMessage(NetworkMessage message) {
    final lobbyId = message.data['lobbyId'] as String?;
    final playerId = message.data['playerId'] as String?;
    
    if (lobbyId != null && playerId != null) {
      final lobby = _lobbies.where((l) => l.id == lobbyId).firstOrNull;
      if (lobby != null) {
        lobby.players.removeWhere((p) => p.id == playerId);
        _updateLobbyStream(lobby);
      }
    }
  }
  
  // Handle lobby update messages
  void _handleLobbyUpdateMessage(NetworkMessage message) {
    final lobbyData = message.data['lobby'] as Map<String, dynamic>?;
    if (lobbyData != null) {
      // Update local lobby state with remote changes
      final lobbyId = lobbyData['id'] as String?;
      if (lobbyId != null) {
        final lobby = _lobbies.where((l) => l.id == lobbyId).firstOrNull;
        if (lobby != null) {
          // Update lobby properties as needed
          _updateLobbyStream(lobby);
        }
      }
    }
  }
  
  // Handle error messages from network
  void _handleErrorMessage(NetworkMessage message) {
    final errorType = message.data['errorType'] as String?;
    final errorMessage = message.data['message'] as String?;
    
    print('Network error received: $errorType - $errorMessage');
    
    // Handle specific error types
    switch (errorType) {
      case 'lobby_full':
        // Handle lobby full error
        break;
      case 'connection_lost':
        // Handle connection lost error
        _attemptReconnection();
        break;
      case 'invalid_action':
        // Handle invalid action error
        break;
      default:
        print('Unknown error type: $errorType');
    }
  }

  // Handle connection status changes
  void _handleConnectionStatusChange(ConnectionStatus status) {
    print('Connection status changed: ${status.isConnected ? 'connected' : 'disconnected'}');
    
    if (!status.isConnected && status.reconnectAttempts > 0) {
      print('Connection lost, attempting reconnection (attempt ${status.reconnectAttempts})');
    }
    
    // Update player connection status in lobbies
    for (final lobby in _lobbies) {
      // Mark players as connected/disconnected based on status
      // This is a simplified implementation - in practice you'd track individual player connections
      _updateLobbyStream(lobby);
    }
  }

  // Attempt to reconnect when connection is lost
  void _attemptReconnection() {
    // This would be called when we detect connection issues
    // The LanService handles the actual reconnection logic
    print('Attempting to reconnect to network...');
  }

  // Cleanup method
  void dispose() {
    // Cancel network subscriptions
    _discoverySubscription?.cancel();
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();
    
    // Close lobby streams
    for (final controller in _lobbyStreams.values) {
      controller.close();
    }
    _lobbyStreams.clear();
    
    // Dispose LAN service
    _lanService.dispose();
  }
}
