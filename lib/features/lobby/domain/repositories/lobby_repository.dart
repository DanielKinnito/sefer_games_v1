import '../entities/lobby.dart';

abstract class LobbyRepository {
  Future<Lobby> createLobby(String hostId, String gameType);
  Future<Lobby?> joinLobby(String lobbyId, String playerId);
  Future<List<Lobby>> getAvailableLobbies();
  Future<void> leaveLobby(String lobbyId, String playerId);
}
