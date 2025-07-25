import '../../domain/entities/player.dart';

class PlayerModel extends PlayerEntity {
  PlayerModel({
    required super.id,
    required super.name,
    required super.avatarId,
    required super.isHost,
    required super.isConnected,
    super.joinedAt,
  });

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarId: json['avatarId'] as String,
      isHost: json['isHost'] as bool,
      isConnected: json['isConnected'] as bool,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarId': avatarId,
      'isHost': isHost,
      'isConnected': isConnected,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }

  factory PlayerModel.fromEntity(Player player) {
    return PlayerModel(
      id: player.id,
      name: player.name,
      avatarId: player.avatarId,
      isHost: player.isHost,
      isConnected: player.isConnected,
      joinedAt: player.joinedAt,
    );
  }
}
