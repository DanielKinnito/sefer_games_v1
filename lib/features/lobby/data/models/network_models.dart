import 'dart:convert';

/// Standardized message format for all network communication
class NetworkMessage {
  final String type;
  final String senderId;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String? targetId;

  NetworkMessage({
    required this.type,
    required this.senderId,
    required this.data,
    DateTime? timestamp,
    this.targetId,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create NetworkMessage from JSON
  factory NetworkMessage.fromJson(Map<String, dynamic> json) {
    return NetworkMessage(
      type: json['type'] as String,
      senderId: json['senderId'] as String,
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      targetId: json['targetId'] as String?,
    );
  }

  /// Convert NetworkMessage to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'senderId': senderId,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'targetId': targetId,
    };
  }

  /// Convert NetworkMessage to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create NetworkMessage from JSON string
  factory NetworkMessage.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return NetworkMessage.fromJson(json);
  }

  NetworkMessage copyWith({
    String? type,
    String? senderId,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    String? targetId,
  }) {
    return NetworkMessage(
      type: type ?? this.type,
      senderId: senderId ?? this.senderId,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      targetId: targetId ?? this.targetId,
    );
  }

  @override
  String toString() {
    return 'NetworkMessage(type: $type, senderId: $senderId, targetId: $targetId, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NetworkMessage &&
        other.type == type &&
        other.senderId == senderId &&
        other.targetId == targetId &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return type.hashCode ^
        senderId.hashCode ^
        (targetId?.hashCode ?? 0) ^
        timestamp.hashCode;
  }
}

/// Message type constants for network communication
class NetworkMessageTypes {
  // Lobby management messages
  static const String lobbyUpdate = 'lobby_update';
  static const String playerJoined = 'player_joined';
  static const String playerLeft = 'player_left';
  static const String lobbyCreated = 'lobby_created';
  static const String lobbyDestroyed = 'lobby_destroyed';
  
  // Connection management messages
  static const String ping = 'ping';
  static const String pong = 'pong';
  static const String connect = 'connect';
  static const String disconnect = 'disconnect';
  static const String reconnect = 'reconnect';
  
  // Game session messages
  static const String gameStarting = 'game_starting';
  static const String gameStarted = 'game_started';
  static const String gameAction = 'game_action';
  static const String gameEvent = 'game_event';
  static const String gameEnded = 'game_ended';
  static const String gameStateSync = 'game_state_sync';
  static const String gameStateRequest = 'game_state_request';
  static const String playerReconnected = 'player_reconnected';
  
  // Error messages
  static const String error = 'error';
  static const String warning = 'warning';
  
  // Discovery messages
  static const String lobbyBroadcast = 'lobby_broadcast';
  static const String discoveryRequest = 'discovery_request';
  static const String discoveryResponse = 'discovery_response';

  /// Validate if a message type is supported
  static bool isValidType(String type) {
    return [
      lobbyUpdate, playerJoined, playerLeft, lobbyCreated, lobbyDestroyed,
      ping, pong, connect, disconnect, reconnect,
      gameStarting, gameStarted, gameAction, gameEvent, gameEnded, gameStateSync, gameStateRequest, playerReconnected,
      error, warning,
      lobbyBroadcast, discoveryRequest, discoveryResponse,
    ].contains(type);
  }
}

/// Discovered lobby information from UDP broadcasts
class DiscoveredLobby {
  final String id;
  final String name;
  final String hostAddress;
  final int hostPort;
  final String gameType;
  final int currentPlayers;
  final int maxPlayers;
  final DateTime discoveredAt;

  DiscoveredLobby({
    required this.id,
    required this.name,
    required this.hostAddress,
    required this.hostPort,
    required this.gameType,
    required this.currentPlayers,
    required this.maxPlayers,
    DateTime? discoveredAt,
  }) : discoveredAt = discoveredAt ?? DateTime.now();

  /// Create DiscoveredLobby from JSON
  factory DiscoveredLobby.fromJson(Map<String, dynamic> json) {
    return DiscoveredLobby(
      id: json['id'] as String,
      name: json['name'] as String,
      hostAddress: json['hostAddress'] as String,
      hostPort: json['hostPort'] as int,
      gameType: json['gameType'] as String,
      currentPlayers: json['currentPlayers'] as int,
      maxPlayers: json['maxPlayers'] as int,
      discoveredAt: json['discoveredAt'] != null 
          ? DateTime.parse(json['discoveredAt'] as String)
          : DateTime.now(),
    );
  }

  /// Convert DiscoveredLobby to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'hostAddress': hostAddress,
      'hostPort': hostPort,
      'gameType': gameType,
      'currentPlayers': currentPlayers,
      'maxPlayers': maxPlayers,
      'discoveredAt': discoveredAt.toIso8601String(),
    };
  }

  /// Create DiscoveredLobby from broadcast message
  factory DiscoveredLobby.fromBroadcastMessage(String message, String senderAddress) {
    try {
      final json = jsonDecode(message) as Map<String, dynamic>;
      return DiscoveredLobby(
        id: json['lobbyId'] as String,
        name: json['lobbyName'] as String,
        hostAddress: senderAddress,
        hostPort: json['hostPort'] as int,
        gameType: json['gameType'] as String,
        currentPlayers: json['currentPlayers'] as int,
        maxPlayers: json['maxPlayers'] as int,
      );
    } catch (e) {
      throw FormatException('Invalid broadcast message format: $e');
    }
  }

  /// Convert to broadcast message format
  String toBroadcastMessage() {
    return jsonEncode({
      'lobbyId': id,
      'lobbyName': name,
      'hostPort': hostPort,
      'gameType': gameType,
      'currentPlayers': currentPlayers,
      'maxPlayers': maxPlayers,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  DiscoveredLobby copyWith({
    String? id,
    String? name,
    String? hostAddress,
    int? hostPort,
    String? gameType,
    int? currentPlayers,
    int? maxPlayers,
    DateTime? discoveredAt,
  }) {
    return DiscoveredLobby(
      id: id ?? this.id,
      name: name ?? this.name,
      hostAddress: hostAddress ?? this.hostAddress,
      hostPort: hostPort ?? this.hostPort,
      gameType: gameType ?? this.gameType,
      currentPlayers: currentPlayers ?? this.currentPlayers,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      discoveredAt: discoveredAt ?? this.discoveredAt,
    );
  }

  @override
  String toString() {
    return 'DiscoveredLobby(id: $id, name: $name, host: $hostAddress:$hostPort, players: $currentPlayers/$maxPlayers)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiscoveredLobby &&
        other.id == id &&
        other.hostAddress == hostAddress &&
        other.hostPort == hostPort;
  }

  @override
  int get hashCode {
    return id.hashCode ^ hostAddress.hashCode ^ hostPort.hashCode;
  }
}

/// Connection status information
class ConnectionStatus {
  final bool isConnected;
  final String? hostAddress;
  final DateTime lastPing;
  final int reconnectAttempts;
  final String? errorMessage;

  ConnectionStatus({
    required this.isConnected,
    this.hostAddress,
    DateTime? lastPing,
    this.reconnectAttempts = 0,
    this.errorMessage,
  }) : lastPing = lastPing ?? DateTime.now();

  /// Create ConnectionStatus from JSON
  factory ConnectionStatus.fromJson(Map<String, dynamic> json) {
    return ConnectionStatus(
      isConnected: json['isConnected'] as bool,
      hostAddress: json['hostAddress'] as String?,
      lastPing: DateTime.parse(json['lastPing'] as String),
      reconnectAttempts: json['reconnectAttempts'] as int? ?? 0,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  /// Convert ConnectionStatus to JSON
  Map<String, dynamic> toJson() {
    return {
      'isConnected': isConnected,
      'hostAddress': hostAddress,
      'lastPing': lastPing.toIso8601String(),
      'reconnectAttempts': reconnectAttempts,
      'errorMessage': errorMessage,
    };
  }

  ConnectionStatus copyWith({
    bool? isConnected,
    String? hostAddress,
    DateTime? lastPing,
    int? reconnectAttempts,
    String? errorMessage,
  }) {
    return ConnectionStatus(
      isConnected: isConnected ?? this.isConnected,
      hostAddress: hostAddress ?? this.hostAddress,
      lastPing: lastPing ?? this.lastPing,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() {
    return 'ConnectionStatus(connected: $isConnected, host: $hostAddress, attempts: $reconnectAttempts)';
  }
}

/// Lobby update information for real-time synchronization
class LobbyUpdate {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  LobbyUpdate({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create LobbyUpdate from JSON
  factory LobbyUpdate.fromJson(Map<String, dynamic> json) {
    return LobbyUpdate(
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Convert LobbyUpdate to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  LobbyUpdate copyWith({
    String? type,
    Map<String, dynamic>? data,
    DateTime? timestamp,
  }) {
    return LobbyUpdate(
      type: type ?? this.type,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'LobbyUpdate(type: $type, timestamp: $timestamp)';
  }
}

/// Lobby broadcast information for UDP discovery
class LobbyBroadcastInfo {
  final String lobbyId;
  final String lobbyName;
  final int hostPort;
  final String gameType;
  final int currentPlayers;
  final int maxPlayers;

  LobbyBroadcastInfo({
    required this.lobbyId,
    required this.lobbyName,
    required this.hostPort,
    required this.gameType,
    required this.currentPlayers,
    required this.maxPlayers,
  });

  /// Create LobbyBroadcastInfo from JSON
  factory LobbyBroadcastInfo.fromJson(Map<String, dynamic> json) {
    return LobbyBroadcastInfo(
      lobbyId: json['lobbyId'] as String,
      lobbyName: json['lobbyName'] as String,
      hostPort: json['hostPort'] as int,
      gameType: json['gameType'] as String,
      currentPlayers: json['currentPlayers'] as int,
      maxPlayers: json['maxPlayers'] as int,
    );
  }

  /// Convert LobbyBroadcastInfo to JSON
  Map<String, dynamic> toJson() {
    return {
      'lobbyId': lobbyId,
      'lobbyName': lobbyName,
      'hostPort': hostPort,
      'gameType': gameType,
      'currentPlayers': currentPlayers,
      'maxPlayers': maxPlayers,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Convert to JSON string for UDP broadcasting
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create from JSON string
  factory LobbyBroadcastInfo.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return LobbyBroadcastInfo.fromJson(json);
  }

  @override
  String toString() {
    return 'LobbyBroadcastInfo(id: $lobbyId, name: $lobbyName, players: $currentPlayers/$maxPlayers)';
  }
}

/// Network message validation utilities
class NetworkMessageValidator {
  /// Validate NetworkMessage structure and content
  static bool validateMessage(NetworkMessage message) {
    // Check required fields
    if (message.type.isEmpty || message.senderId.isEmpty) {
      return false;
    }

    // Validate message type
    if (!NetworkMessageTypes.isValidType(message.type)) {
      return false;
    }

    // Validate timestamp (not too old or in future)
    final now = DateTime.now();
    final timeDiff = now.difference(message.timestamp).abs();
    if (timeDiff.inMinutes > 5) {
      return false;
    }

    return true;
  }

  /// Validate DiscoveredLobby data
  static bool validateDiscoveredLobby(DiscoveredLobby lobby) {
    if (lobby.id.isEmpty || lobby.name.isEmpty || lobby.hostAddress.isEmpty) {
      return false;
    }

    if (lobby.hostPort <= 0 || lobby.hostPort > 65535) {
      return false;
    }

    if (lobby.currentPlayers < 0 || lobby.maxPlayers <= 0 || 
        lobby.currentPlayers > lobby.maxPlayers) {
      return false;
    }

    return true;
  }
}