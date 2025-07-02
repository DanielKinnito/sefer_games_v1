import 'package:flutter_test/flutter_test.dart';
import 'package:sefer_games_v1/features/lobby/data/repositories/lobby_repository_impl.dart';

void main() {
  group('LobbyRepositoryImpl', () {
    final repository = LobbyRepositoryImpl();

    test('should create a lobby', () async {
      final lobby = await repository.createLobby('host1', 'WordBlitz');
      expect(lobby.hostId, 'host1');
      expect(lobby.gameType, 'WordBlitz');
      expect(lobby.playerIds, contains('host1'));
    });

    test('should join a lobby', () async {
      final lobby = await repository.createLobby('host2', 'Mafia');
      final joined = await repository.joinLobby(lobby.id, 'player2');
      expect(joined?.playerIds, contains('player2'));
    });

    test('should get available lobbies', () async {
      await repository.createLobby('host3', 'Impostor');
      final lobbies = await repository.getAvailableLobbies();
      expect(lobbies.isNotEmpty, true);
    });

    test('should leave a lobby', () async {
      final lobby = await repository.createLobby('host4', '20Questions');
      await repository.leaveLobby(lobby.id, 'host4');
      final lobbies = await repository.getAvailableLobbies();
      expect(lobbies.where((l) => l.id == lobby.id).isEmpty, true);
    });
  });
}
