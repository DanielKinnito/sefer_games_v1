import 'dart:convert';
import 'dart:io';
import 'dart:async';
import '../../../../core/game/game_manager.dart';

/// Network service for LAN-based lobby discovery and communication
class LanNetworkService {
  static const int _discoveryPort = 8888;
  static const int _defaultGamePort = 8080;

  
  RawDatagramSocket? _discoverySocket;
  HttpServer? _gameServer;
  final Map<String, String> _hostAddresses = {};
  final StreamController<String> _lobbyDiscoveryController = StreamController.broadcast();
  final GameManager _gameManager = GameManager();
  
  /// Get the local IP address for LAN communication
  Future<String> getLocalIpAddress() async {
    try {
      // Get all network interfaces
      final interfaces = await NetworkInterface.list();
      
      // Look for WiFi or Ethernet interfaces first
      for (final interface in interfaces) {
        if (interface.name.toLowerCase().contains('wifi') || 
            interface.name.toLowerCase().contains('ethernet') ||
            interface.name.toLowerCase().contains('en0') ||
            interface.name.toLowerCase().contains('wlan')) {
          for (final addr in interface.addresses) {
            if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
              return addr.address;
            }
          }
        }
      }
      
      // Fallback to any non-loopback IPv4 address
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
      
      return '127.0.0.1'; // Last resort
    } catch (e) {
      return '127.0.0.1';
    }
  }
  
  /// Start hosting a lobby on the specified port
  Future<String> startHosting(String lobbyId, String lobbyName, {int port = _defaultGamePort}) async {
    try {
      final localIp = await getLocalIpAddress();
      
      // Start the game server
      _gameServer = await HttpServer.bind(localIp, port);
      
      // Start broadcasting lobby information for discovery
      await _startLobbyBroadcast(lobbyId, lobbyName, localIp, port);
      
      // Handle incoming connections
      _gameServer!.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          final webSocket = await WebSocketTransformer.upgrade(request);
          _handleClientConnection(lobbyId, webSocket);
        }
      });
      
      final hostAddress = '$localIp:$port';
      _hostAddresses[lobbyId] = hostAddress;
      
      return hostAddress;
    } catch (e) {
      throw Exception('Failed to start hosting: $e');
    }
  }
  
  /// Start broadcasting lobby information for LAN discovery
  Future<void> _startLobbyBroadcast(String lobbyId, String lobbyName, String hostIp, int port) async {
    try {
      _discoverySocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _discoverySocket!.broadcastEnabled = true;
      
      // Broadcast lobby information every 3 seconds
      Timer.periodic(const Duration(seconds: 3), (timer) {
        if (_gameServer == null) {
          timer.cancel();
          return;
        }
        
        final lobbyInfo = {
          'type': 'lobby_announcement',
          'lobbyId': lobbyId,
          'lobbyName': lobbyName,
          'hostAddress': hostIp,
          'hostPort': port,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        
        final message = json.encode(lobbyInfo);
        final bytes = utf8.encode(message);
        
        _discoverySocket!.send(bytes, InternetAddress('255.255.255.255'), _discoveryPort);
      });
    } catch (e) {
      print('Failed to start lobby broadcast: $e');
    }
  }
  
  /// Handle incoming WebSocket connections from clients
  void _handleClientConnection(String lobbyId, WebSocket webSocket) {
    print('New client connected to lobby $lobbyId');
    
    // Add connection to game manager for real-time game updates
    _gameManager.addLobbyConnection(lobbyId, webSocket);
    
    webSocket.listen(
      (data) {
        try {
          final message = json.decode(data as String);
          _handleClientMessage(lobbyId, webSocket, message);
        } catch (e) {
          print('Error processing client message: $e');
        }
      },
      onDone: () {
        print('Client disconnected from lobby $lobbyId');
        _gameManager.removeLobbyConnection(lobbyId, webSocket);
      },
      onError: (error) {
        print('WebSocket error: $error');
        _gameManager.removeLobbyConnection(lobbyId, webSocket);
      },
    );
  }
  
  /// Handle messages from connected clients
  void _handleClientMessage(String lobbyId, WebSocket webSocket, Map<String, dynamic> message) {
    switch (message['type']) {
      case 'join_lobby':
        _handleJoinLobby(lobbyId, webSocket, message);
        break;
      case 'leave_lobby':
        _handleLeaveLobby(lobbyId, webSocket, message);
        break;
      case 'game_action':
        _handleGameAction(lobbyId, webSocket, message);
        break;
      case 'start_game':
        _handleStartGame(lobbyId, webSocket, message);
        break;
      case 'end_game':
        _handleEndGame(lobbyId, webSocket, message);
        break;
      default:
        print('Unknown message type: ${message['type']}');
    }
  }
  
  void _handleJoinLobby(String lobbyId, WebSocket webSocket, Map<String, dynamic> message) {
    // TODO: Implement join lobby logic
    final response = {
      'type': 'lobby_joined',
      'lobbyId': lobbyId,
      'playerId': message['playerId'],
      'success': true,
    };
    webSocket.add(json.encode(response));
  }
  
  void _handleLeaveLobby(String lobbyId, WebSocket webSocket, Map<String, dynamic> message) {
    // TODO: Implement leave lobby logic
    final response = {
      'type': 'lobby_left',
      'lobbyId': lobbyId,
      'playerId': message['playerId'],
      'success': true,
    };
    webSocket.add(json.encode(response));
  }
  
  void _handleGameAction(String lobbyId, WebSocket webSocket, Map<String, dynamic> message) {
    // Process game action through game manager
    final playerId = message['playerId'] as String?;
    final actionData = message['action'] as Map<String, dynamic>?;
    
    if (playerId != null && actionData != null) {
      _gameManager.processGameAction(lobbyId, playerId, actionData).then((result) {
        final response = {
          'type': 'game_action_result',
          'success': result.success,
          'errorMessage': result.errorMessage,
          'resultData': result.resultData,
        };
        webSocket.add(json.encode(response));
      }).catchError((error) {
        final response = {
          'type': 'game_action_result',
          'success': false,
          'errorMessage': 'Failed to process action: $error',
        };
        webSocket.add(json.encode(response));
      });
    }
  }
  
  void _handleStartGame(String lobbyId, WebSocket webSocket, Map<String, dynamic> message) {
    // TODO: Start game through lobby repository
    // For now, just acknowledge the request
    final response = {
      'type': 'start_game_result',
      'success': true,
      'message': 'Game start requested',
    };
    webSocket.add(json.encode(response));
  }
  
  void _handleEndGame(String lobbyId, WebSocket webSocket, Map<String, dynamic> message) {
    _gameManager.endGame(lobbyId).then((_) {
      final response = {
        'type': 'end_game_result',
        'success': true,
        'message': 'Game ended successfully',
      };
      webSocket.add(json.encode(response));
    }).catchError((error) {
      final response = {
        'type': 'end_game_result',
        'success': false,
        'errorMessage': 'Failed to end game: $error',
      };
      webSocket.add(json.encode(response));
    });
  }
  
  /// Discover lobbies on the local network
  Future<List<Map<String, dynamic>>> discoverLocalLobbies() async {
    final List<Map<String, dynamic>> discoveredLobbies = [];
    final completer = Completer<List<Map<String, dynamic>>>();
    
    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _discoveryPort);
      
      // Listen for lobby announcements
      final subscription = socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            try {
              final message = utf8.decode(datagram.data);
              final lobbyInfo = json.decode(message) as Map<String, dynamic>;
              
              if (lobbyInfo['type'] == 'lobby_announcement') {
                // Check if we already have this lobby
                final existingIndex = discoveredLobbies.indexWhere(
                  (lobby) => lobby['lobbyId'] == lobbyInfo['lobbyId'],
                );
                
                if (existingIndex >= 0) {
                  discoveredLobbies[existingIndex] = lobbyInfo;
                } else {
                  discoveredLobbies.add(lobbyInfo);
                }
              }
            } catch (e) {
              // Ignore invalid messages
            }
          }
        }
      });
      
      // Stop discovery after 5 seconds
      Timer(const Duration(seconds: 5), () {
        subscription.cancel();
        socket.close();
        completer.complete(discoveredLobbies);
      });
      
    } catch (e) {
      completer.completeError('Failed to discover lobbies: $e');
    }
    
    return completer.future;
  }
  
  /// Connect to a lobby host
  Future<WebSocket> connectToLobbyHost(String hostAddress, int port) async {
    try {
      final uri = Uri.parse('ws://$hostAddress');
      final webSocket = await WebSocket.connect(uri.toString());
      return webSocket;
    } catch (e) {
      throw Exception('Failed to connect to lobby host: $e');
    }
  }
  
  /// Stop hosting and cleanup resources
  Future<void> stopHosting() async {
    _gameServer?.close();
    _gameServer = null;
    
    _discoverySocket?.close();
    _discoverySocket = null;
    
    _hostAddresses.clear();
  }
  
  /// Cleanup all resources
  void dispose() {
    stopHosting();
    _lobbyDiscoveryController.close();
    _gameManager.dispose();
  }
}
