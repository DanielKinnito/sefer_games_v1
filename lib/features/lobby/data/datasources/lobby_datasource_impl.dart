import 'lobby_datasource.dart';
import '../models/lobby_model.dart';

class LobbyDataSourceImpl implements LobbyDataSource {
  final List<LobbyModel> _lobbies = [];

  @override
  Future<LobbyModel> createLobby(String hostId, String gameType) async {
    final lobby = LobbyModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      hostId: hostId,
      playerIds: [hostId],
      gameType: gameType,
    );
    _lobbies.add(lobby);
    return lobby;
  }

  @override
  Future<LobbyModel?> joinLobby(String lobbyId, String playerId) async {
    LobbyModel? lobby;
    try {
      lobby = _lobbies.firstWhere((l) => l.id == lobbyId);
    } catch (_) {
      lobby = null;
    }
    if (lobby != null && !lobby.playerIds.contains(playerId)) {
      lobby.playerIds.add(playerId);
      return lobby;
    }
    return null;
  }

  @override
  Future<List<LobbyModel>> getAvailableLobbies() async {
    return _lobbies;
  }

  @override
  Future<void> leaveLobby(String lobbyId, String playerId) async {
    LobbyModel? lobby;
    try {
      lobby = _lobbies.firstWhere((l) => l.id == lobbyId);
    } catch (_) {
      lobby = null;
    }
    if (lobby != null) {
      lobby.playerIds.remove(playerId);
      if (lobby.playerIds.isEmpty) {
        _lobbies.remove(lobby);
      }
    }
  }
}
