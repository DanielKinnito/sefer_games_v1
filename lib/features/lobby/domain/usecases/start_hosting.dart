import '../repositories/lobby_repository.dart';

class StartHosting {
  final LobbyRepository repository;
  StartHosting(this.repository);

  Future<String> call(String lobbyId, {int port = 8080}) {
    return repository.startHosting(lobbyId, port: port);
  }
}
