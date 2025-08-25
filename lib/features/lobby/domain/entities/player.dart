abstract class Player {
  String get id;
  String get name;
  String get avatarId;
  bool get isHost;
  bool get isConnected;
  bool get isReady;
  DateTime get joinedAt;
}

class PlayerEntity implements Player {
  @override
  final String id;
  @override
  final String name;
  @override
  final String avatarId;
  @override
  final bool isHost;
  @override
  final bool isConnected;
  @override
  final bool isReady;
  @override
  final DateTime joinedAt;

  PlayerEntity({
    required this.id,
    required this.name,
    required this.avatarId,
    required this.isHost,
    required this.isConnected,
    this.isReady = false,
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.now();

  PlayerEntity copyWith({
    String? id,
    String? name,
    String? avatarId,
    bool? isHost,
    bool? isConnected,
    bool? isReady,
    DateTime? joinedAt,
  }) {
    return PlayerEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarId: avatarId ?? this.avatarId,
      isHost: isHost ?? this.isHost,
      isConnected: isConnected ?? this.isConnected,
      isReady: isReady ?? this.isReady,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}
