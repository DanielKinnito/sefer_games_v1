import '../repositories/lobby_repository.dart';
import '../entities/lobby.dart';

class CreateLobby {
  final LobbyRepository repository;
  CreateLobby(this.repository);

  Future<Lobby> call(String hostId, String gameType) {
    return repository.createLobby(hostId, gameType);
  }
}
