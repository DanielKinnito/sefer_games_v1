import '../repositories/lobby_repository.dart';
import '../entities/lobby.dart';

class GetAvailableLobbies {
  final LobbyRepository repository;
  GetAvailableLobbies(this.repository);

  Future<List<Lobby>> call() {
    return repository.getAvailableLobbies();
  }
}
