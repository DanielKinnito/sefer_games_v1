import '../../domain/entities/lobby.dart';
import '../../domain/repositories/lobby_repository.dart';
import '../datasources/lobby_datasource_impl.dart';

class LobbyRepositoryImpl implements LobbyRepository {
  final LobbyDataSourceImpl _dataSource = LobbyDataSourceImpl();

  @override
  Future<Lobby> createLobby(String lobbyName, String hostName, String hostAvatarId, String gameType, {int maxPlayers = 8}) {
    return _dataSource.createLobby(lobbyName, hostName, hostAvatarId, gameType, maxPlayers: maxPlayers);
  }

  @override
  Future<Lobby?> joinLobby(String lobbyId, String playerName, String playerAvatarId) {
    return _dataSource.joinLobby(lobbyId, playerName, playerAvatarId);
  }

  @override
  Future<List<Lobby>> getAvailableLobbies() {
    return _dataSource.getAvailableLobbies();
  }

  @override
  Future<void> leaveLobby(String lobbyId, String playerId) {
    return _dataSource.leaveLobby(lobbyId, playerId);
  }

  @override
  Future<void> updatePlayerStatus(String lobbyId, String playerId, bool isConnected) {
    return _dataSource.updatePlayerStatus(lobbyId, playerId, isConnected);
  }

  @override
  Future<Lobby?> getLobby(String lobbyId) {
    return _dataSource.getLobby(lobbyId);
  }

  @override
  Stream<Lobby> watchLobby(String lobbyId) {
    return _dataSource.watchLobby(lobbyId);
  }

  // LAN-specific implementations
  @override
  Future<String> startHosting(String lobbyId, {int port = 8080}) {
    return _dataSource.startHosting(lobbyId, port: port);
  }

  @override
  Future<List<Lobby>> discoverLocalLobbies() {
    return _dataSource.discoverLocalLobbies();
  }

  @override
  Future<bool> connectToLobbyHost(String hostAddress, int port) {
    return _dataSource.connectToLobbyHost(hostAddress, port);
  }
}
