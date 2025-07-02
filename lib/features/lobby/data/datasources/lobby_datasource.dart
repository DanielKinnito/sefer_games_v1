import '../models/lobby_model.dart';

abstract class LobbyDataSource {
  Future<LobbyModel> createLobby(String hostId, String gameType);
  Future<LobbyModel?> joinLobby(String lobbyId, String playerId);
  Future<List<LobbyModel>> getAvailableLobbies();
  Future<void> leaveLobby(String lobbyId, String playerId);
}
