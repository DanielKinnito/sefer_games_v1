import '../../domain/entities/lobby.dart';
import '../../domain/repositories/lobby_repository.dart';
import '../datasources/lobby_datasource_impl.dart';

class LobbyRepositoryImpl implements LobbyRepository {
  final LobbyDataSourceImpl _dataSource = LobbyDataSourceImpl();

  @override
  Future<Lobby> createLobby(String hostId, String gameType) {
    return _dataSource.createLobby(hostId, gameType);
  }

  @override
  Future<Lobby?> joinLobby(String lobbyId, String playerId) {
    return _dataSource.joinLobby(lobbyId, playerId);
  }

  @override
  Future<List<Lobby>> getAvailableLobbies() {
    return _dataSource.getAvailableLobbies();
  }

  @override
  Future<void> leaveLobby(String lobbyId, String playerId) {
    return _dataSource.leaveLobby(lobbyId, playerId);
  }
}
