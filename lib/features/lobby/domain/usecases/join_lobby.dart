import '../repositories/lobby_repository.dart';
import '../entities/lobby.dart';

class JoinLobby {
  final LobbyRepository repository;
  JoinLobby(this.repository);

  Future<Lobby?> call(String lobbyId, String playerName, String playerAvatarId) {
    return repository.joinLobby(lobbyId, playerName, playerAvatarId);
  }
}
