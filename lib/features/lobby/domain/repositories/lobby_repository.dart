import '../entities/lobby.dart';

abstract class LobbyRepository {
  Future<Lobby> createLobby(String lobbyName, String hostName, String hostAvatarId, String gameType, {int maxPlayers = 8});
  Future<Lobby?> joinLobby(String lobbyId, String playerName, String playerAvatarId);
  Future<List<Lobby>> getAvailableLobbies();
  Future<void> leaveLobby(String lobbyId, String playerId);
  Future<void> updatePlayerStatus(String lobbyId, String playerId, bool isConnected);
  Future<Lobby?> getLobby(String lobbyId);
  Stream<Lobby> watchLobby(String lobbyId);
  
  // LAN-specific methods
  Future<String> startHosting(String lobbyId, {int port = 8080});
  Future<List<Lobby>> discoverLocalLobbies();
  Future<bool> connectToLobbyHost(String hostAddress, int port);
}
