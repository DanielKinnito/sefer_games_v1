import 'package:flutter_test/flutter_test.dart';
import 'package:sefer_games_v1/features/lobby/domain/usecases/create_lobby.dart';
import 'package:sefer_games_v1/features/lobby/data/repositories/lobby_repository_impl.dart';

void main() {
  group('CreateLobby UseCase', () {
    final repository = LobbyRepositoryImpl();
    final usecase = CreateLobby(repository);

    test('should create a lobby', () async {
      final lobby = await usecase('host1', 'WordBlitz');
      expect(lobby.hostId, 'host1');
      expect(lobby.gameType, 'WordBlitz');
      expect(lobby.playerIds, contains('host1'));
    });
  });
}
