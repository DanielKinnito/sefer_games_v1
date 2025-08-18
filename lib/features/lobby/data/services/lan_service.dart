import 'dart:async';
import 'dart:io';
import 'dart:convert';
import '../models/network_models.dart';

/// Service responsible for LAN networking functionality
class LanService {
  static final LanService _instance = LanService._internal();
  factory LanService() => _instance;
  LanService._internal();

  HttpServer? _server;
  RawDatagramSocket? _udpSocket;
  Timer? _broadcastTimer;
  LobbyBroadcastInfo? _currentLobbyInfo;
  final Map<String, DiscoveredLobby> _discoveredLobbies = {};
  final StreamController<List<DiscoveredLobby>> _discoveryController = StreamController.broadcast();
  
  // WebSocket connections management
  final Map<String, WebSocket> _connectedClients = {};
  final StreamController<NetworkMessage> _messageController = StreamController.broadcast();
  final StreamController<ConnectionStatus> _connectionStatusController = StreamController.broadcast();
  
  // Client-side WebSocket connection
  WebSocket? _clientWebSocket;
  String? _hostAddress;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  final Duration _reconnectDelay = const Duration(seconds: 2);
  final Duration _heartbeatInterval = const Duration(seconds: 30);
  final List<NetworkMessage> _messageQueue = [];
  
  // Current lobby state for HTTP endpoints
  Map<String, dynamic>? _currentLobbyState;
  
  // Default ports for LAN communication
  static const int defaultPort = 8080;
  static const int discoveryPort = 8081;
  static const Duration broadcastInterval = Duration(seconds: 3);
  static const Duration discoveryTimeout = Duration(seconds: 10);

  /// Start hosting a lobby on the local network
  /// Returns the host address (IP:port) that others can connect to
  Future<String> startHosting({int port = defaultPort, Map<String, dynamic>? lobbyState}) async {
    try {
      final localIP = await _getLocalIP();
      
      // Try to bind to the specified port, or find an available port
      HttpServer? server;
      int currentPort = port;
      int maxAttempts = 10;
      
      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        try {
          server = await HttpServer.bind(localIP, currentPort);
          break;
        } catch (e) {
          print('Port $currentPort is busy, trying ${currentPort + 1}');
          currentPort++;
        }
      }
      
      if (server == null) {
        throw Exception('Could not find an available port after $maxAttempts attempts');
      }
      
      _server = server;
      _currentLobbyState = lobbyState;
      
      // Set up request handling with CORS support
      _server!.listen((HttpRequest request) {
        _handleRequest(request);
      });
      
      print('HTTP server started on $localIP:$currentPort');
      return '$localIP:$currentPort';
    } catch (e) {
      throw Exception('Failed to start hosting: $e');
    }
  }

  /// Stop hosting the lobby
  Future<void> stopHosting() async {
    await _server?.close();
    _server = null;
  }

  /// Start broadcasting lobby information via UDP
  Future<void> startBroadcasting(LobbyBroadcastInfo lobbyInfo) async {
    try {
      _currentLobbyInfo = lobbyInfo;
      
      // Create UDP socket for broadcasting
      _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _udpSocket!.broadcastEnabled = true;
      
      // Start periodic broadcasting
      _broadcastTimer = Timer.periodic(broadcastInterval, (timer) {
        _broadcastLobbyInfo();
      });
      
      print('Started broadcasting lobby: ${lobbyInfo.lobbyName}');
    } catch (e) {
      throw Exception('Failed to start broadcasting: $e');
    }
  }

  /// Stop broadcasting lobby information
  Future<void> stopBroadcasting() async {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    _udpSocket?.close();
    _udpSocket = null;
    _currentLobbyInfo = null;
    print('Stopped broadcasting lobby');
  }

  /// Discover lobbies on the local network
  Future<List<DiscoveredLobby>> discoverLobbies() async {
    try {
      // Clear previous discoveries
      _discoveredLobbies.clear();
      
      // Create UDP socket for listening
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, discoveryPort);
      
      // Set up listener for incoming broadcasts
      final completer = Completer<List<DiscoveredLobby>>();
      late StreamSubscription subscription;
      
      subscription = socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            _handleDiscoveryMessage(datagram);
          }
        }
      });
      
      // Set timeout for discovery
      Timer(discoveryTimeout, () {
        subscription.cancel();
        socket.close();
        if (!completer.isCompleted) {
          completer.complete(_discoveredLobbies.values.toList());
        }
      });
      
      return await completer.future;
    } catch (e) {
      throw Exception('Failed to discover lobbies: $e');
    }
  }

  /// Get stream of discovered lobbies for real-time updates
  Stream<List<DiscoveredLobby>> get discoveredLobbiesStream => _discoveryController.stream;

  /// Start continuous lobby discovery
  Future<void> startDiscovery() async {
    try {
      // Create UDP socket for listening
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, discoveryPort);
      
      socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            _handleDiscoveryMessage(datagram);
            // Emit updated list
            _discoveryController.add(_discoveredLobbies.values.toList());
          }
        }
      });
      
      print('Started continuous lobby discovery');
    } catch (e) {
      throw Exception('Failed to start discovery: $e');
    }
  }

  /// Connect to a lobby host via WebSocket
  Future<bool> connectToHost(String hostAddress, int port) async {
    try {
      _hostAddress = '$hostAddress:$port';
      final wsUrl = 'ws://$hostAddress:$port/ws';
      
      print('Attempting to connect to WebSocket: $wsUrl');
      
      _clientWebSocket = await WebSocket.connect(wsUrl);
      _reconnectAttempts = 0;
      
      // Update connection status
      _updateConnectionStatus(ConnectionStatus(
        isConnected: true,
        hostAddress: _hostAddress,
        reconnectAttempts: _reconnectAttempts,
      ));
      
      // Set up message handling
      _clientWebSocket!.listen(
        (data) => _handleServerMessage(data),
        onDone: () => _handleServerDisconnection(),
        onError: (error) => _handleServerError(error),
      );
      
      // Start heartbeat
      _startHeartbeat();
      
      // Send queued messages
      _sendQueuedMessages();
      
      print('Successfully connected to host: $_hostAddress');
      return true;
    } catch (e) {
      print('Failed to connect to host: $e');
      _handleConnectionFailure(e);
      return false;
    }
  }

  /// Disconnect from the host
  Future<void> disconnectFromHost() async {
    _stopHeartbeat();
    _stopReconnectTimer();
    
    if (_clientWebSocket != null) {
      await _clientWebSocket!.close();
      _clientWebSocket = null;
    }
    
    _hostAddress = null;
    _reconnectAttempts = 0;
    _messageQueue.clear();
    
    _updateConnectionStatus(ConnectionStatus(
      isConnected: false,
      hostAddress: null,
      reconnectAttempts: 0,
    ));
    
    print('Disconnected from host');
  }



  /// Send data to the host
  Future<void> sendToHost(Map<String, dynamic> data) async {
    final message = NetworkMessage(
      type: data['type'] ?? NetworkMessageTypes.lobbyUpdate,
      senderId: data['senderId'] ?? 'client',
      data: data,
    );
    
    await sendNetworkMessageToHost(message);
  }

  /// Send network message to host
  Future<void> sendNetworkMessageToHost(NetworkMessage message) async {
    if (_clientWebSocket != null) {
      try {
        _clientWebSocket!.add(message.toJsonString());
        print('Sent message to host: ${message.type}');
      } catch (e) {
        print('Error sending message to host: $e');
        _queueMessage(message);
        _handleConnectionFailure(e);
      }
    } else {
      print('Not connected to host, queueing message: ${message.type}');
      _queueMessage(message);
    }
  }

  // Private helper methods
  Future<String> _getLocalIP() async {
    if (_cachedLocalIP != null) return _cachedLocalIP!;
    
    try {
      // Get local IP address
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            _cachedLocalIP = addr.address;
            return _cachedLocalIP!;
          }
        }
      }
      _cachedLocalIP = 'localhost'; // Fallback
      return _cachedLocalIP!;
    } catch (e) {
      _cachedLocalIP = 'localhost';
      return _cachedLocalIP!;
    }
  }

  void _handleRequest(HttpRequest request) {
    // Add CORS headers for cross-origin requests
    _addCorsHeaders(request.response);
    
    // Handle preflight requests
    if (request.method == 'OPTIONS') {
      request.response
        ..statusCode = 200
        ..close();
      return;
    }
    
    try {
      switch (request.uri.path) {
        case '/ping':
          _handlePingRequest(request);
          break;
        case '/lobby':
          _handleLobbyInfoRequest(request);
          break;
        case '/lobby/join':
          _handleJoinLobbyRequest(request);
          break;
        case '/lobby/leave':
          _handleLeaveLobbyRequest(request);
          break;
        case '/lobby/players':
          _handlePlayersRequest(request);
          break;
        case '/ws':
          _handleWebSocketUpgrade(request);
          break;
        default:
          _handleNotFound(request);
      }
    } catch (e) {
      _handleError(request, e);
    }
  }

  /// Add CORS headers to response
  void _addCorsHeaders(HttpResponse response) {
    response.headers.add('Access-Control-Allow-Origin', '*');
    response.headers.add('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    response.headers.contentType = ContentType.json;
  }

  /// Handle ping requests for connectivity testing
  void _handlePingRequest(HttpRequest request) {
    request.response
      ..statusCode = 200
      ..write(jsonEncode({
        'status': 'ok',
        'message': 'pong',
        'timestamp': DateTime.now().toIso8601String(),
      }))
      ..close();
  }

  /// Handle lobby info requests
  void _handleLobbyInfoRequest(HttpRequest request) {
    if (request.method != 'GET') {
      request.response
        ..statusCode = 405
        ..write(jsonEncode({'error': 'Method not allowed'}))
        ..close();
      return;
    }

    if (_currentLobbyState == null) {
      request.response
        ..statusCode = 404
        ..write(jsonEncode({'error': 'No active lobby'}))
        ..close();
      return;
    }

    request.response
      ..statusCode = 200
      ..write(jsonEncode({
        'status': 'ok',
        'lobby': _currentLobbyState,
        'timestamp': DateTime.now().toIso8601String(),
      }))
      ..close();
  }

  /// Handle join lobby requests
  void _handleJoinLobbyRequest(HttpRequest request) {
    if (request.method != 'POST') {
      request.response
        ..statusCode = 405
        ..write(jsonEncode({'error': 'Method not allowed'}))
        ..close();
      return;
    }

    request.cast<List<int>>().transform(utf8.decoder).join().then((body) {
      try {
        final data = jsonDecode(body) as Map<String, dynamic>;
        final playerName = data['playerName'] as String?;
        final playerAvatarId = data['playerAvatarId'] as String?;

        if (playerName == null || playerAvatarId == null) {
          request.response
            ..statusCode = 400
            ..write(jsonEncode({'error': 'Missing required fields: playerName, playerAvatarId'}))
            ..close();
          return;
        }

        // Validate lobby capacity
        if (_currentLobbyState != null) {
          final players = _currentLobbyState!['players'] as List?;
          final maxPlayers = _currentLobbyState!['maxPlayers'] as int? ?? 8;
          
          if (players != null && players.length >= maxPlayers) {
            request.response
              ..statusCode = 409
              ..write(jsonEncode({'error': 'Lobby is full'}))
              ..close();
            return;
          }
        }

        request.response
          ..statusCode = 200
          ..write(jsonEncode({
            'status': 'ok',
            'message': 'Join request accepted',
            'playerName': playerName,
            'playerAvatarId': playerAvatarId,
            'timestamp': DateTime.now().toIso8601String(),
          }))
          ..close();
      } catch (e) {
        request.response
          ..statusCode = 400
          ..write(jsonEncode({'error': 'Invalid JSON format'}))
          ..close();
      }
    }).catchError((error) {
      request.response
        ..statusCode = 500
        ..write(jsonEncode({'error': 'Internal server error'}))
        ..close();
    });
  }

  /// Handle leave lobby requests
  void _handleLeaveLobbyRequest(HttpRequest request) {
    if (request.method != 'POST') {
      request.response
        ..statusCode = 405
        ..write(jsonEncode({'error': 'Method not allowed'}))
        ..close();
      return;
    }

    request.cast<List<int>>().transform(utf8.decoder).join().then((body) {
      try {
        final data = jsonDecode(body) as Map<String, dynamic>;
        final playerId = data['playerId'] as String?;

        if (playerId == null) {
          request.response
            ..statusCode = 400
            ..write(jsonEncode({'error': 'Missing required field: playerId'}))
            ..close();
          return;
        }

        request.response
          ..statusCode = 200
          ..write(jsonEncode({
            'status': 'ok',
            'message': 'Leave request accepted',
            'playerId': playerId,
            'timestamp': DateTime.now().toIso8601String(),
          }))
          ..close();
      } catch (e) {
        request.response
          ..statusCode = 400
          ..write(jsonEncode({'error': 'Invalid JSON format'}))
          ..close();
      }
    }).catchError((error) {
      request.response
        ..statusCode = 500
        ..write(jsonEncode({'error': 'Internal server error'}))
        ..close();
    });
  }

  /// Handle players list requests
  void _handlePlayersRequest(HttpRequest request) {
    if (request.method != 'GET') {
      request.response
        ..statusCode = 405
        ..write(jsonEncode({'error': 'Method not allowed'}))
        ..close();
      return;
    }

    final players = _currentLobbyState?['players'] as List? ?? [];
    
    request.response
      ..statusCode = 200
      ..write(jsonEncode({
        'status': 'ok',
        'players': players,
        'count': players.length,
        'timestamp': DateTime.now().toIso8601String(),
      }))
      ..close();
  }

  /// Handle 404 not found
  void _handleNotFound(HttpRequest request) {
    request.response
      ..statusCode = 404
      ..write(jsonEncode({
        'error': 'Endpoint not found',
        'path': request.uri.path,
        'method': request.method,
      }))
      ..close();
  }

  /// Handle server errors
  void _handleError(HttpRequest request, dynamic error) {
    print('HTTP request error: $error');
    request.response
      ..statusCode = 500
      ..write(jsonEncode({
        'error': 'Internal server error',
        'message': error.toString(),
      }))
      ..close();
  }

  /// Broadcast current lobby information
  void _broadcastLobbyInfo() {
    if (_currentLobbyInfo == null || _udpSocket == null) return;
    
    try {
      final message = _currentLobbyInfo!.toJsonString();
      final data = utf8.encode(message);
      
      // Broadcast to all devices on the network
      _udpSocket!.send(data, InternetAddress('255.255.255.255'), discoveryPort);
    } catch (e) {
      print('Error broadcasting lobby info: $e');
    }
  }

  /// Handle incoming discovery messages
  void _handleDiscoveryMessage(Datagram datagram) {
    try {
      final message = utf8.decode(datagram.data);
      final senderAddress = datagram.address.address;
      
      // Don't process our own broadcasts
      if (senderAddress == _getLocalIPSync()) return;
      
      final discoveredLobby = DiscoveredLobby.fromBroadcastMessage(message, senderAddress);
      
      // Update discovered lobbies map
      final key = '${discoveredLobby.hostAddress}:${discoveredLobby.hostPort}';
      _discoveredLobbies[key] = discoveredLobby;
      
      print('Discovered lobby: ${discoveredLobby.name} at ${discoveredLobby.hostAddress}');
    } catch (e) {
      print('Error processing discovery message: $e');
    }
  }

  /// Get local IP synchronously (cached version)
  String? _cachedLocalIP;
  String _getLocalIPSync() {
    if (_cachedLocalIP != null) return _cachedLocalIP!;
    
    // For synchronous access, we'll use a fallback approach
    // In practice, this should be called after _getLocalIP() has cached the IP
    return _cachedLocalIP ?? 'localhost';
  }

  /// Update lobby broadcast information
  void updateLobbyInfo(LobbyBroadcastInfo lobbyInfo) {
    _currentLobbyInfo = lobbyInfo;
  }

  /// Update current lobby state for HTTP endpoints
  void updateLobbyState(Map<String, dynamic> lobbyState) {
    _currentLobbyState = lobbyState;
  }

  /// Get current lobby state
  Map<String, dynamic>? get currentLobbyState => _currentLobbyState;

  /// Get stream of network messages
  Stream<NetworkMessage> get messageStream => _messageController.stream;

  /// Get stream of connection status updates
  Stream<ConnectionStatus> get connectionStatusStream => _connectionStatusController.stream;

  /// Get list of connected client IDs
  List<String> get connectedClientIds => _connectedClients.keys.toList();

  /// Handle WebSocket upgrade requests
  void _handleWebSocketUpgrade(HttpRequest request) {
    WebSocketTransformer.upgrade(request).then((WebSocket webSocket) {
      final clientId = _generateClientId();
      _connectedClients[clientId] = webSocket;
      
      print('Client $clientId connected via WebSocket');
      
      // Send welcome message to client
      _sendToClient(clientId, NetworkMessage(
        type: NetworkMessageTypes.connect,
        senderId: 'server',
        data: {
          'clientId': clientId,
          'message': 'Connected successfully',
          'lobbyState': _currentLobbyState,
        },
      ));

      // Broadcast player joined to other clients
      _broadcastToOtherClients(clientId, NetworkMessage(
        type: NetworkMessageTypes.playerJoined,
        senderId: 'server',
        data: {
          'clientId': clientId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ));

      // Update connection status
      _updateConnectionStatus(ConnectionStatus(
        isConnected: true,
        hostAddress: _getLocalIPSync(),
        reconnectAttempts: 0,
      ));

      // Listen for messages from this client
      webSocket.listen(
        (data) => _handleWebSocketMessage(clientId, data),
        onDone: () => _handleClientDisconnection(clientId),
        onError: (error) => _handleWebSocketError(clientId, error),
      );
    }).catchError((error) {
      print('WebSocket upgrade failed: $error');
      request.response
        ..statusCode = 500
        ..write(jsonEncode({'error': 'WebSocket upgrade failed'}))
        ..close();
    });
  }

  /// Handle incoming WebSocket messages from clients
  void _handleWebSocketMessage(String clientId, dynamic data) {
    try {
      final messageData = data is String ? data : utf8.decode(data);
      final networkMessage = NetworkMessage.fromJsonString(messageData);
      
      // Validate message
      if (!NetworkMessageValidator.validateMessage(networkMessage)) {
        print('Invalid message from client $clientId: $messageData');
        return;
      }

      // Add client ID to message if not present
      final messageWithClientId = networkMessage.copyWith(senderId: clientId);
      
      // Add to message stream for processing by other components
      _messageController.add(messageWithClientId);
      
      // Handle specific message types
      switch (networkMessage.type) {
        case NetworkMessageTypes.ping:
          _handlePingMessage(clientId);
          break;
        case NetworkMessageTypes.gameAction:
          _handleGameActionMessage(clientId, networkMessage);
          break;
        case NetworkMessageTypes.lobbyUpdate:
          _handleLobbyUpdateMessage(clientId, networkMessage);
          break;
        default:
          // Forward message to other clients if needed
          if (networkMessage.targetId == null) {
            _broadcastToOtherClients(clientId, messageWithClientId);
          } else {
            _sendToClient(networkMessage.targetId!, messageWithClientId);
          }
      }
    } catch (e) {
      print('Error handling WebSocket message from $clientId: $e');
    }
  }

  /// Handle client disconnection
  void _handleClientDisconnection(String clientId) {
    print('Client $clientId disconnected');
    
    _connectedClients.remove(clientId);
    
    // Broadcast player left to remaining clients
    _broadcastToAllClients(NetworkMessage(
      type: NetworkMessageTypes.playerLeft,
      senderId: 'server',
      data: {
        'clientId': clientId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    ));

    // Update connection status if no clients left
    if (_connectedClients.isEmpty) {
      _updateConnectionStatus(ConnectionStatus(
        isConnected: false,
        hostAddress: _getLocalIPSync(),
        reconnectAttempts: 0,
      ));
    }
  }

  /// Handle WebSocket errors
  void _handleWebSocketError(String clientId, dynamic error) {
    print('WebSocket error for client $clientId: $error');
    
    _connectedClients.remove(clientId);
    
    _updateConnectionStatus(ConnectionStatus(
      isConnected: false,
      hostAddress: _getLocalIPSync(),
      reconnectAttempts: 0,
      errorMessage: error.toString(),
    ));
  }

  /// Handle ping messages from clients
  void _handlePingMessage(String clientId) {
    _sendToClient(clientId, NetworkMessage(
      type: NetworkMessageTypes.pong,
      senderId: 'server',
      data: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    ));
  }

  /// Handle game action messages
  void _handleGameActionMessage(String clientId, NetworkMessage message) {
    // Forward game actions to all clients for synchronization
    _broadcastToAllClients(message.copyWith(senderId: clientId));
  }

  /// Handle lobby update messages
  void _handleLobbyUpdateMessage(String clientId, NetworkMessage message) {
    // Update lobby state and broadcast to all clients
    if (message.data.containsKey('lobbyState')) {
      _currentLobbyState = message.data['lobbyState'] as Map<String, dynamic>?;
    }
    
    _broadcastToAllClients(message.copyWith(senderId: clientId));
  }

  /// Send message to specific client
  void _sendToClient(String clientId, NetworkMessage message) {
    final client = _connectedClients[clientId];
    if (client != null) {
      try {
        client.add(message.toJsonString());
      } catch (e) {
        print('Error sending message to client $clientId: $e');
        _connectedClients.remove(clientId);
      }
    }
  }

  /// Broadcast message to all connected clients
  void _broadcastToAllClients(NetworkMessage message) {
    final clientIds = _connectedClients.keys.toList();
    for (final clientId in clientIds) {
      _sendToClient(clientId, message);
    }
  }

  /// Broadcast message to all clients except the sender
  void _broadcastToOtherClients(String senderClientId, NetworkMessage message) {
    final clientIds = _connectedClients.keys.where((id) => id != senderClientId).toList();
    for (final clientId in clientIds) {
      _sendToClient(clientId, message);
    }
  }

  /// Generate unique client ID
  String _generateClientId() {
    return 'client_${DateTime.now().millisecondsSinceEpoch}_${_connectedClients.length}';
  }

  /// Send data to connected clients (updated implementation)
  Future<void> broadcastToClients(Map<String, dynamic> data) async {
    final message = NetworkMessage(
      type: NetworkMessageTypes.lobbyUpdate,
      senderId: 'server',
      data: data,
    );
    _broadcastToAllClients(message);
  }

  /// Send network message to all clients
  Future<void> broadcastNetworkMessage(NetworkMessage message) async {
    _broadcastToAllClients(message);
  }

  /// Send network message to specific client
  Future<void> sendNetworkMessageToClient(String clientId, NetworkMessage message) async {
    _sendToClient(clientId, message);
  }

  /// Check if client is connected
  bool isClientConnected(String clientId) {
    return _connectedClients.containsKey(clientId);
  }

  /// Get number of connected clients
  int get connectedClientCount => _connectedClients.length;

  /// Check if connected to host as client
  bool get isConnectedToHost => _clientWebSocket != null;

  /// Get current host address
  String? get currentHostAddress => _hostAddress;

  /// Handle messages from server (when acting as client)
  void _handleServerMessage(dynamic data) {
    try {
      final messageData = data is String ? data : utf8.decode(data);
      final networkMessage = NetworkMessage.fromJsonString(messageData);
      
      // Validate message
      if (!NetworkMessageValidator.validateMessage(networkMessage)) {
        print('Invalid message from server: $messageData');
        return;
      }

      // Add to message stream for processing by other components
      _messageController.add(networkMessage);
      
      // Handle specific message types
      switch (networkMessage.type) {
        case NetworkMessageTypes.pong:
          _handlePongMessage(networkMessage);
          break;
        case NetworkMessageTypes.connect:
          _handleConnectMessage(networkMessage);
          break;
        case NetworkMessageTypes.disconnect:
          _handleDisconnectMessage(networkMessage);
          break;
        case NetworkMessageTypes.error:
          _handleErrorMessage(networkMessage);
          break;
        default:
          print('Received message from server: ${networkMessage.type}');
      }
    } catch (e) {
      print('Error handling server message: $e');
    }
  }

  /// Handle server disconnection
  void _handleServerDisconnection() {
    print('Server disconnected');
    _clientWebSocket = null;
    _stopHeartbeat();
    
    _updateConnectionStatus(ConnectionStatus(
      isConnected: false,
      hostAddress: _hostAddress,
      reconnectAttempts: _reconnectAttempts,
    ));
    
    // Attempt reconnection
    _attemptReconnection();
  }

  /// Handle server connection errors
  void _handleServerError(dynamic error) {
    print('Server connection error: $error');
    _clientWebSocket = null;
    _stopHeartbeat();
    
    _updateConnectionStatus(ConnectionStatus(
      isConnected: false,
      hostAddress: _hostAddress,
      reconnectAttempts: _reconnectAttempts,
      errorMessage: error.toString(),
    ));
    
    _handleConnectionFailure(error);
  }

  /// Handle connection failures and attempt reconnection
  void _handleConnectionFailure(dynamic error) {
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _attemptReconnection();
    } else {
      print('Max reconnection attempts reached. Giving up.');
      _updateConnectionStatus(ConnectionStatus(
        isConnected: false,
        hostAddress: _hostAddress,
        reconnectAttempts: _reconnectAttempts,
        errorMessage: 'Max reconnection attempts reached',
      ));
    }
  }

  /// Attempt to reconnect to host
  void _attemptReconnection() {
    if (_hostAddress == null) return;
    
    _reconnectAttempts++;
    print('Attempting reconnection $_reconnectAttempts/$_maxReconnectAttempts');
    
    _updateConnectionStatus(ConnectionStatus(
      isConnected: false,
      hostAddress: _hostAddress,
      reconnectAttempts: _reconnectAttempts,
    ));
    
    _stopReconnectTimer();
    _reconnectTimer = Timer(_reconnectDelay * _reconnectAttempts, () async {
      if (_hostAddress != null) {
        final parts = _hostAddress!.split(':');
        if (parts.length == 2) {
          final host = parts[0];
          final port = int.tryParse(parts[1]) ?? 8080;
          await connectToHost(host, port);
        }
      }
    });
  }

  /// Start heartbeat to keep connection alive
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_clientWebSocket != null) {
        sendNetworkMessageToHost(NetworkMessage(
          type: NetworkMessageTypes.ping,
          senderId: 'client',
          data: {'timestamp': DateTime.now().toIso8601String()},
        ));
      }
    });
  }

  /// Stop heartbeat timer
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Stop reconnect timer
  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// Queue message for later sending
  void _queueMessage(NetworkMessage message) {
    _messageQueue.add(message);
    
    // Limit queue size to prevent memory issues
    if (_messageQueue.length > 100) {
      _messageQueue.removeAt(0);
    }
  }

  /// Send all queued messages
  void _sendQueuedMessages() {
    if (_clientWebSocket != null && _messageQueue.isNotEmpty) {
      print('Sending ${_messageQueue.length} queued messages');
      
      for (final message in _messageQueue) {
        try {
          _clientWebSocket!.add(message.toJsonString());
        } catch (e) {
          print('Error sending queued message: $e');
          break;
        }
      }
      
      _messageQueue.clear();
    }
  }

  /// Handle pong messages from server
  void _handlePongMessage(NetworkMessage message) {
    // Update connection status with successful ping
    _connectionStatusController.add(ConnectionStatus(
      isConnected: true,
      hostAddress: _hostAddress,
      reconnectAttempts: _reconnectAttempts,
    ));
  }

  /// Handle connect messages from server
  void _handleConnectMessage(NetworkMessage message) {
    print('Connected to server successfully');
    
    // Update lobby state if provided
    if (message.data.containsKey('lobbyState')) {
      _currentLobbyState = message.data['lobbyState'] as Map<String, dynamic>?;
    }
  }

  /// Handle disconnect messages from server
  void _handleDisconnectMessage(NetworkMessage message) {
    print('Server requested disconnection: ${message.data}');
    disconnectFromHost();
  }

  /// Handle error messages from server
  void _handleErrorMessage(NetworkMessage message) {
    print('Server error: ${message.data}');
    
    _updateConnectionStatus(ConnectionStatus(
      isConnected: _clientWebSocket != null,
      hostAddress: _hostAddress,
      reconnectAttempts: _reconnectAttempts,
      errorMessage: message.data['message']?.toString(),
    ));
  }

  /// Helper method to safely update connection status
  void _updateConnectionStatus(ConnectionStatus status) {
    if (!_connectionStatusController.isClosed) {
      _connectionStatusController.add(status);
    }
  }

  /// Cleanup resources
  void dispose() {
    // Stop timers
    _broadcastTimer?.cancel();
    _stopHeartbeat();
    _stopReconnectTimer();
    
    // Close network connections
    _udpSocket?.close();
    _server?.close();
    
    // Close client WebSocket connection
    if (_clientWebSocket != null) {
      _clientWebSocket!.close();
      _clientWebSocket = null;
    }
    
    // Close all server WebSocket connections
    for (final client in _connectedClients.values) {
      client.close();
    }
    _connectedClients.clear();
    
    // Close stream controllers
    _discoveryController.close();
    _messageController.close();
    _connectionStatusController.close();
    
    // Clear data
    _discoveredLobbies.clear();
    _messageQueue.clear();
    _currentLobbyState = null;
    _currentLobbyInfo = null;
    _hostAddress = null;
    _cachedLocalIP = null;
    _reconnectAttempts = 0;
  }
}
