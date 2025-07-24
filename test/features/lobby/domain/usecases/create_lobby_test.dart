import 'package:flutter_test/flutter_test.dart';
import 'package:sefer_games_v1/features/lobby/domain/usecases/create_lobby.dart';
import 'package:sefer_games_v1/features/lobby/data/repositories/lobby_repository_impl.dart';
import 'package:sefer_games_v1/features/lobby/domain/entities/lobby.dart';

void main() {
  group('CreateLobby UseCase', () {
    late LobbyRepositoryImpl repository;
    late CreateLobby usecase;

    setUp(() {
      repository = LobbyRepositoryImpl();
      usecase = CreateLobby(repository);
    });

    test('should create a lobby with default parameters', () async {
      final lobby = await usecase('Test Lobby', 'Host1', 'avatar1', 'NumberGuessing');
      
      expect(lobby.hostId, isNotEmpty);
      expect(lobby.gameType, 'NumberGuessing');
      expect(lobby.name, 'Test Lobby');
      expect(lobby.players.length, 1);
      expect(lobby.players.first.name, 'Host1');
      expect(lobby.players.first.isHost, true);
      expect(lobby.players.first.avatarId, 'avatar1');
      expect(lobby.status, LobbyStatus.waiting);
      expect(lobby.maxPlayers, 8); // Default value
    });

    test('should create a lobby with custom max players', () async {
      final lobby = await usecase('Small Lobby', 'Host1', 'avatar1', 'NumberGuessing', maxPlayers: 4);
      
      expect(lobby.maxPlayers, 4);
      expect(lobby.players.length, 1);
      expect(lobby.players.first.name, 'Host1');
    });

    test('should create lobby with valid timestamps', () async {
      final beforeCreation = DateTime.now();
      final lobby = await usecase('Time Test Lobby', 'Host1', 'avatar1', 'NumberGuessing');
      final afterCreation = DateTime.now();
      
      expect(lobby.createdAt.isAfter(beforeCreation.subtract(const Duration(seconds: 1))), true);
      expect(lobby.createdAt.isBefore(afterCreation.add(const Duration(seconds: 1))), true);
    });

    test('should create multiple lobbies with unique IDs', () async {
      final lobby1 = await usecase('Lobby 1', 'Host1', 'avatar1', 'NumberGuessing');
      final lobby2 = await usecase('Lobby 2', 'Host2', 'avatar2', 'NumberGuessing');
      
      expect(lobby1.id, isNot(lobby2.id));
      expect(lobby1.hostId, isNot(lobby2.hostId));
    });

    test('should create lobby with different game types', () async {
      final lobby1 = await usecase('Game 1', 'Host1', 'avatar1', 'NumberGuessing');
      final lobby2 = await usecase('Game 2', 'Host2', 'avatar2', 'WordBlitz');
      
      expect(lobby1.gameType, 'NumberGuessing');
      expect(lobby2.gameType, 'WordBlitz');
    });

    test('should handle various input formats', () async {
      // Test with special characters in names
      final lobby = await usecase('Lobby with Spéciâl Chars!', 'Höst Namé', 'avatar_special', 'NumberGuessing');
      
      expect(lobby.name, 'Lobby with Spéciâl Chars!');
      expect(lobby.players.first.name, 'Höst Namé');
    });

    test('should create lobby with minimal valid inputs', () async {
      final lobby = await usecase('L', 'H', 'a', 'T');
      
      expect(lobby.name, 'L');
      expect(lobby.players.first.name, 'H');
      expect(lobby.players.first.avatarId, 'a');
      expect(lobby.gameType, 'T');
    });
  });
}
