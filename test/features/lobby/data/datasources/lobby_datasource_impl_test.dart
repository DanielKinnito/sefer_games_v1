import 'package:flutter_test/flutter_test.dart';
import 'package:sefer_games_v1/features/lobby/data/datasources/lobby_datasource_impl.dart';

void main() {
  group('LobbyDataSourceImpl', () {
    final dataSource = LobbyDataSourceImpl();

    test('should create a lobby', () async {
      final lobby = await dataSource.createLobby('host1', 'WordBlitz');
      expect(lobby.hostId, 'host1');
      expect(lobby.gameType, 'WordBlitz');
      expect(lobby.playerIds, contains('host1'));
    });

    test('should join a lobby', () async {
      final lobby = await dataSource.createLobby('host2', 'Mafia');
      final joined = await dataSource.joinLobby(lobby.id, 'player2');
      expect(joined?.playerIds, contains('player2'));
    });

    test('should get available lobbies', () async {
      await dataSource.createLobby('host3', 'Impostor');
      final lobbies = await dataSource.getAvailableLobbies();
      expect(lobbies.isNotEmpty, true);
    });

    test('should leave a lobby', () async {
      final lobby = await dataSource.createLobby('host4', '20Questions');
      await dataSource.leaveLobby(lobby.id, 'host4');
      final lobbies = await dataSource.getAvailableLobbies();
      expect(lobbies.where((l) => l.id == lobby.id).isEmpty, true);
    });
  });
}
