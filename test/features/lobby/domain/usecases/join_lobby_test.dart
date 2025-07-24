import 'package:flutter_test/flutter_test.dart';
import 'package:sefer_games_v1/features/lobby/domain/usecases/join_lobby.dart';
import 'package:sefer_games_v1/features/lobby/data/repositories/lobby_repository_impl.dart';

void main() {
  group('JoinLobby UseCase', () {
    late LobbyRepositoryImpl repository;
    late JoinLobby usecase;

    setUp(() {
      repository = LobbyRepositoryImpl();
      usecase = JoinLobby(repository);
    });

    test('should join existing lobby successfully', () async {
      // First create a lobby
      final lobby = await repository.createLobby('Test Lobby', 'Host1', 'avatar1', 'NumberGuessing');
      
      // Then join it
      final joinedLobby = await usecase(lobby.id, 'Player1', 'avatar2');
      
      expect(joinedLobby, isNotNull);
      expect(joinedLobby!.players.length, 2);
      expect(joinedLobby.players.any((p) => p.name == 'Player1'), true);
      expect(joinedLobby.players.any((p) => p.name == 'Host1'), true);
      
      final joinedPlayer = joinedLobby.players.firstWhere((p) => p.name == 'Player1');
      expect(joinedPlayer.isHost, false);
      expect(joinedPlayer.avatarId, 'avatar2');
      expect(joinedPlayer.isConnected, true);
    });

    test('should return null for non-existent lobby', () async {
      final result = await usecase('non-existent-id', 'Player1', 'avatar1');
      expect(result, isNull);
    });

    test('should not join lobby with duplicate player name', () async {
      final lobby = await repository.createLobby('Test Lobby', 'Host1', 'avatar1', 'NumberGuessing');
      await repository.joinLobby(lobby.id, 'Player1', 'avatar2');
      
      // Try to join with same name
      final result = await usecase(lobby.id, 'Player1', 'avatar3');
      expect(result, isNull);
    });

    test('should not join full lobby', () async {
      final lobby = await repository.createLobby('Full Lobby', 'Host1', 'avatar1', 'NumberGuessing', maxPlayers: 2);
      await repository.joinLobby(lobby.id, 'Player1', 'avatar2');
      
      // Try to join when lobby is full
      final result = await usecase(lobby.id, 'Player2', 'avatar3');
      expect(result, isNull);
    });

    test('should join lobby with multiple players', () async {
      final lobby = await repository.createLobby('Multi Player Lobby', 'Host1', 'avatar1', 'NumberGuessing');
      
      await usecase(lobby.id, 'Player1', 'avatar2');
      await usecase(lobby.id, 'Player2', 'avatar3');
      final finalLobby = await usecase(lobby.id, 'Player3', 'avatar4');
      
      expect(finalLobby!.players.length, 4);
      expect(finalLobby.players.map((p) => p.name).toList(), 
             containsAll(['Host1', 'Player1', 'Player2', 'Player3']));
    });
  });
}
