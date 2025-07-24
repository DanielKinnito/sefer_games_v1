import '../repositories/lobby_repository.dart';

class ConnectToLobbyHost {
  final LobbyRepository repository;
  ConnectToLobbyHost(this.repository);

  Future<bool> call(String hostAddress, int port) {
    return repository.connectToLobbyHost(hostAddress, port);
  }
}
