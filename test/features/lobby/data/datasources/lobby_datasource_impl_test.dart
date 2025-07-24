import 'package:flutter_test/flutter_test.dart';
import 'package:sefer_games_v1/features/lobby/data/datasources/lobby_datasource_impl.dart';

void main() {
  group('LobbyDataSourceImpl', () {
    final dataSource = LobbyDataSourceImpl();

    test('should create a lobby', () async {
      final lobby = await dataSource.createLobby('Test Lobby', 'Host1', 'avatar1', 'WordBlitz');
      expect(lobby.hostId, isNotEmpty);
      expect(lobby.gameType, 'WordBlitz');
      expect(lobby.name, 'Test Lobby');
      expect(lobby.players.length, 1);
      expect(lobby.players.first.name, 'Host1');
      expect(lobby.players.first.isHost, true);
    });

    test('should join a lobby', () async {
      final lobby = await dataSource.createLobby('Test Lobby 2', 'Host2', 'avatar1', 'Mafia');
      final joined = await dataSource.joinLobby(lobby.id, 'Player2', 'avatar2');
      expect(joined?.players.length, 2);
      expect(joined?.players.any((p) => p.name == 'Player2'), true);
    });

    test('should get available lobbies', () async {
      await dataSource.createLobby('Test Lobby 3', 'Host3', 'avatar1', 'Impostor');
      final lobbies = await dataSource.getAvailableLobbies();
      expect(lobbies.isNotEmpty, true);
    });

    test('should leave a lobby', () async {
      final lobby = await dataSource.createLobby('Test Lobby 4', 'Host4', 'avatar1', '20Questions');
      await dataSource.leaveLobby(lobby.id, lobby.hostId);
      final lobbies = await dataSource.getAvailableLobbies();
      expect(lobbies.where((l) => l.id == lobby.id).isEmpty, true);
    });
  });
}
