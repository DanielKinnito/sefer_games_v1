import '../repositories/lobby_repository.dart';
import '../entities/lobby.dart';

class DiscoverLocalLobbies {
  final LobbyRepository repository;
  DiscoverLocalLobbies(this.repository);

  Future<List<Lobby>> call() {
    return repository.discoverLocalLobbies();
  }
}
