import '../../domain/entities/lobby.dart';

class LobbyModel extends LobbyEntity {
  LobbyModel({
    required super.id,
    required super.hostId,
    required super.playerIds,
    required super.gameType,
  });

  factory LobbyModel.fromJson(Map<String, dynamic> json) {
    return LobbyModel(
      id: json['id'] as String,
      hostId: json['hostId'] as String,
      playerIds: List<String>.from(json['playerIds'] as List),
      gameType: json['gameType'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hostId': hostId,
      'playerIds': playerIds,
      'gameType': gameType,
    };
  }
}
