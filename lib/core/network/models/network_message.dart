class NetworkMessage {
  final String type;
  final Map<String, dynamic> data;
  final String? senderId;
  final DateTime timestamp;

  NetworkMessage({
    required this.type,
    required this.data,
    this.senderId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'type': type,
    'data': data,
    'senderId': senderId,
    'timestamp': timestamp.toIso8601String(),
  };

  factory NetworkMessage.fromJson(Map<String, dynamic> json) => NetworkMessage(
    type: json['type'] as String,
    data: Map<String, dynamic>.from(json['data'] as Map),
    senderId: json['senderId'] as String?,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

// Network message types
class MessageTypes {
  static const String lobbyCreated = 'lobby_created';
  static const String lobbyJoined = 'lobby_joined';
  static const String lobbyLeft = 'lobby_left';
  static const String playerUpdate = 'player_update';
  static const String gameStart = 'game_start';
  static const String gameUpdate = 'game_update';
  static const String gameEnd = 'game_end';
  static const String keepAlive = 'keep_alive';
  static const String discovery = 'discovery';
  static const String discoveryResponse = 'discovery_response';
}
