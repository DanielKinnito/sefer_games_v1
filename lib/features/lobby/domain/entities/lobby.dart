import 'player.dart';

enum LobbyStatus { waiting, inGame, gameFinished }

abstract class Lobby {
  String get id;
  String get name;
  String get hostId;
  List<Player> get players;
  String get gameType;
  LobbyStatus get status;
  int get maxPlayers;
  DateTime get createdAt;
  String? get hostAddress;
  int? get hostPort;
}

class LobbyEntity implements Lobby {
  @override
  final String id;
  @override
  final String name;
  @override
  final String hostId;
  @override
  final List<Player> players;
  @override
  final String gameType;
  @override
  final LobbyStatus status;
  @override
  final int maxPlayers;
  @override
  final DateTime createdAt;
  @override
  final String? hostAddress;
  @override
  final int? hostPort;

  LobbyEntity({
    required this.id,
    required this.name,
    required this.hostId,
    required this.players,
    required this.gameType,
    this.status = LobbyStatus.waiting,
    this.maxPlayers = 8,
    DateTime? createdAt,
    this.hostAddress,
    this.hostPort,
  }) : createdAt = createdAt ?? DateTime.now();

  LobbyEntity copyWith({
    String? id,
    String? name,
    String? hostId,
    List<Player>? players,
    String? gameType,
    LobbyStatus? status,
    int? maxPlayers,
    DateTime? createdAt,
    String? hostAddress,
    int? hostPort,
  }) {
    return LobbyEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      hostId: hostId ?? this.hostId,
      players: players ?? this.players,
      gameType: gameType ?? this.gameType,
      status: status ?? this.status,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      createdAt: createdAt ?? this.createdAt,
      hostAddress: hostAddress ?? this.hostAddress,
      hostPort: hostPort ?? this.hostPort,
    );
  }
}
