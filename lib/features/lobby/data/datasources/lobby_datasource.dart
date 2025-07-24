import '../models/lobby_model.dart';

abstract class LobbyDataSource {
  Future<LobbyModel> createLobby(String lobbyName, String hostName, String hostAvatarId, String gameType, {int maxPlayers = 8});
  Future<LobbyModel?> joinLobby(String lobbyId, String playerName, String playerAvatarId);
  Future<List<LobbyModel>> getAvailableLobbies();
  Future<void> leaveLobby(String lobbyId, String playerId);
  Future<void> updatePlayerStatus(String lobbyId, String playerId, bool isConnected);
  Future<LobbyModel?> getLobby(String lobbyId);
  Stream<LobbyModel> watchLobby(String lobbyId);
  
  // LAN-specific methods
  Future<String> startHosting(String lobbyId, {int port = 8080});
  Future<List<LobbyModel>> discoverLocalLobbies();
  Future<bool> connectToLobbyHost(String hostAddress, int port);
}
