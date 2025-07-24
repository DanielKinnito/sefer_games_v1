import 'package:flutter_test/flutter_test.dart';
import 'package:sefer_games_v1/features/lobby/domain/usecases/create_lobby.dart';
import 'package:sefer_games_v1/features/lobby/data/repositories/lobby_repository_impl.dart';

void main() {
  group('CreateLobby UseCase', () {
    final repository = LobbyRepositoryImpl();
    final usecase = CreateLobby(repository);

    test('should create a lobby', () async {
      final lobby = await usecase('Test Lobby', 'Host1', 'avatar1', 'WordBlitz');
      expect(lobby.hostId, isNotEmpty);
      expect(lobby.gameType, 'WordBlitz');
      expect(lobby.name, 'Test Lobby');
      expect(lobby.players.length, 1);
      expect(lobby.players.first.name, 'Host1');
      expect(lobby.players.first.isHost, true);
    });
  });
}
