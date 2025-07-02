abstract class Lobby {
  String get id;
  String get hostId;
  List<String> get playerIds;
  String get gameType;
}

class LobbyEntity implements Lobby {
  @override
  final String id;
  @override
  final String hostId;
  @override
  final List<String> playerIds;
  @override
  final String gameType;

  LobbyEntity({
    required this.id,
    required this.hostId,
    required this.playerIds,
    required this.gameType,
  });
}
