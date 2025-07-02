import '../repositories/lobby_repository.dart';

class LeaveLobby {
  final LobbyRepository repository;
  LeaveLobby(this.repository);

  Future<void> call(String lobbyId, String playerId) {
    return repository.leaveLobby(lobbyId, playerId);
  }
}
