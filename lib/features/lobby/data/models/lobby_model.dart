import '../../domain/entities/lobby.dart';
import 'player_model.dart';

class LobbyModel extends LobbyEntity {
  LobbyModel({
    required super.id,
    required super.name,
    required super.hostId,
    required super.players,
    required super.gameType,
    super.status = LobbyStatus.waiting,
    super.maxPlayers = 8,
    super.createdAt,
    super.hostAddress,
    super.hostPort,
  });

  factory LobbyModel.fromJson(Map<String, dynamic> json) {
    return LobbyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      hostId: json['hostId'] as String,
      players: (json['players'] as List)
          .map((playerJson) => PlayerModel.fromJson(playerJson as Map<String, dynamic>))
          .toList(),
      gameType: json['gameType'] as String,
      status: LobbyStatus.values[json['status'] as int],
      maxPlayers: json['maxPlayers'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      hostAddress: json['hostAddress'] as String?,
      hostPort: json['hostPort'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'hostId': hostId,
      'players': players.map((player) => PlayerModel.fromEntity(player).toJson()).toList(),
      'gameType': gameType,
      'status': status.index,
      'maxPlayers': maxPlayers,
      'createdAt': createdAt.toIso8601String(),
      'hostAddress': hostAddress,
      'hostPort': hostPort,
    };
  }

  factory LobbyModel.fromEntity(Lobby lobby) {
    return LobbyModel(
      id: lobby.id,
      name: lobby.name,
      hostId: lobby.hostId,
      players: lobby.players,
      gameType: lobby.gameType,
      status: lobby.status,
      maxPlayers: lobby.maxPlayers,
      createdAt: lobby.createdAt,
      hostAddress: lobby.hostAddress,
      hostPort: lobby.hostPort,
    );
  }
}
