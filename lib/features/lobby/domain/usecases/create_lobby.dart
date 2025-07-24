import '../repositories/lobby_repository.dart';
import '../entities/lobby.dart';

class CreateLobby {
  final LobbyRepository repository;
  CreateLobby(this.repository);

  Future<Lobby> call(String lobbyName, String hostName, String hostAvatarId, String gameType, {int maxPlayers = 8}) {
    return repository.createLobby(lobbyName, hostName, hostAvatarId, gameType, maxPlayers: maxPlayers);
  }
}
