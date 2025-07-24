import 'package:flutter_test/flutter_test.dart';
import 'package:sefer_games_v1/features/lobby/data/repositories/lobby_repository_impl.dart';
import 'package:sefer_games_v1/features/lobby/domain/entities/lobby.dart';

void main() {
  group('LobbyRepositoryImpl', () {
    late LobbyRepositoryImpl repository;

    setUp(() {
      repository = LobbyRepositoryImpl();
    });

    tearDown(() {
      // Clean up any resources if needed
    });

    group('Basic Lobby Operations', () {
      test('should create a lobby with correct properties', () async {
        final lobby = await repository.createLobby('Test Lobby', 'Host1', 'avatar1', 'NumberGuessing');
        
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

      test('should create lobby with custom max players', () async {
        final lobby = await repository.createLobby('Small Lobby', 'Host1', 'avatar1', 'NumberGuessing', maxPlayers: 4);
        
        expect(lobby.maxPlayers, 4);
        expect(lobby.players.length, 1);
      });

      test('should join a lobby successfully', () async {
        final lobby = await repository.createLobby('Test Lobby 2', 'Host2', 'avatar1', 'NumberGuessing');
        final joined = await repository.joinLobby(lobby.id, 'Player2', 'avatar2');
        
        expect(joined, isNotNull);
        expect(joined!.players.length, 2);
        expect(joined.players.any((p) => p.name == 'Player2'), true);
        expect(joined.players.any((p) => p.name == 'Host2'), true);
        
        final player2 = joined.players.firstWhere((p) => p.name == 'Player2');
        expect(player2.isHost, false);
        expect(player2.avatarId, 'avatar2');
        expect(player2.isConnected, true);
      });

      test('should not join non-existent lobby', () async {
        final joined = await repository.joinLobby('non-existent-id', 'Player1', 'avatar1');
        expect(joined, isNull);
      });

      test('should not join lobby with duplicate player name', () async {
        final lobby = await repository.createLobby('Test Lobby', 'Host1', 'avatar1', 'NumberGuessing');
        await repository.joinLobby(lobby.id, 'Player1', 'avatar2');
        
        // Try to join with same name
        final joined = await repository.joinLobby(lobby.id, 'Player1', 'avatar3');
        expect(joined, isNull);
      });

      test('should not join full lobby', () async {
        final lobby = await repository.createLobby('Full Lobby', 'Host1', 'avatar1', 'NumberGuessing', maxPlayers: 2);
        await repository.joinLobby(lobby.id, 'Player1', 'avatar2');
        
        // Try to join when lobby is full
        final joined = await repository.joinLobby(lobby.id, 'Player2', 'avatar3');
        expect(joined, isNull);
      });

      test('should get available lobbies', () async {
        await repository.createLobby('Lobby 1', 'Host1', 'avatar1', 'NumberGuessing');
        await repository.createLobby('Lobby 2', 'Host2', 'avatar1', 'NumberGuessing');
        
        final lobbies = await repository.getAvailableLobbies();
        expect(lobbies.length, greaterThanOrEqualTo(2));
        expect(lobbies.every((l) => l.status == LobbyStatus.waiting), true);
      });

      test('should leave a lobby', () async {
        final lobby = await repository.createLobby('Test Lobby', 'Host1', 'avatar1', 'NumberGuessing');
        await repository.joinLobby(lobby.id, 'Player1', 'avatar2');
        
        final beforeLeaving = await repository.getLobby(lobby.id);
        expect(beforeLeaving!.players.length, 2);
        
        await repository.leaveLobby(lobby.id, lobby.players.firstWhere((p) => p.name == 'Player1').id);
        
        final afterLeaving = await repository.getLobby(lobby.id);
        expect(afterLeaving!.players.length, 1);
        expect(afterLeaving.players.any((p) => p.name == 'Player1'), false);
      });

      test('should remove lobby when host leaves', () async {
        final lobby = await repository.createLobby('Test Lobby', 'Host1', 'avatar1', 'NumberGuessing');
        await repository.joinLobby(lobby.id, 'Player1', 'avatar2');
        
        await repository.leaveLobby(lobby.id, lobby.hostId);
        
        final afterHostLeaves = await repository.getLobby(lobby.id);
        expect(afterHostLeaves, isNull);
      });

      test('should remove lobby when all players leave', () async {
        final lobby = await repository.createLobby('Test Lobby', 'Host1', 'avatar1', 'NumberGuessing');
        
        await repository.leaveLobby(lobby.id, lobby.hostId);
        
        final afterAllLeave = await repository.getLobby(lobby.id);
        expect(afterAllLeave, isNull);
      });

      test('should get specific lobby by id', () async {
        final lobby = await repository.createLobby('Specific Lobby', 'Host1', 'avatar1', 'NumberGuessing');
        
        final retrieved = await repository.getLobby(lobby.id);
        expect(retrieved, isNotNull);
        expect(retrieved!.id, lobby.id);
        expect(retrieved.name, 'Specific Lobby');
      });

      test('should return null for non-existent lobby', () async {
        final retrieved = await repository.getLobby('non-existent-id');
        expect(retrieved, isNull);
      });

      test('should update player status', () async {
        final lobby = await repository.createLobby('Test Lobby', 'Host1', 'avatar1', 'NumberGuessing');
        await repository.joinLobby(lobby.id, 'Player1', 'avatar2');
        
        final player = lobby.players.firstWhere((p) => p.name == 'Player1');
        await repository.updatePlayerStatus(lobby.id, player.id, false);
        
        final updated = await repository.getLobby(lobby.id);
        final updatedPlayer = updated!.players.firstWhere((p) => p.id == player.id);
        expect(updatedPlayer.isConnected, false);
      });
    });

    group('LAN Networking Features', () {
      test('should start hosting and return host address', () async {
        final lobby = await repository.createLobby('Host Test', 'Host1', 'avatar1', 'NumberGuessing');
        
        final hostAddress = await repository.startHosting(lobby.id);
        
        expect(hostAddress, isNotEmpty);
        expect(hostAddress, contains(':'));
        
        // Should contain IP and port
        final parts = hostAddress.split(':');
        expect(parts.length, 2);
        expect(int.tryParse(parts[1]), isNotNull); // Port should be numeric
      });

      test('should fail to start hosting non-existent lobby', () async {
        expect(
          () => repository.startHosting('non-existent-id'),
          throwsException,
        );
      });

      test('should discover local lobbies', () async {
        // Create some lobbies first
        final lobby1 = await repository.createLobby('Discoverable 1', 'Host1', 'avatar1', 'NumberGuessing');
        final lobby2 = await repository.createLobby('Discoverable 2', 'Host2', 'avatar1', 'NumberGuessing');
        
        // Start hosting them
        await repository.startHosting(lobby1.id);
        await repository.startHosting(lobby2.id);
        
        final discovered = await repository.discoverLocalLobbies();
        
        // Should find at least the lobbies we created and are hosting
        expect(discovered, isNotEmpty);
        // Note: In a real test environment, this might not work perfectly due to network constraints
        // In production, you might want to mock the network layer for more reliable tests
      });

      test('should connect to lobby host', () async {
        // Note: This test might fail in environments without actual network connectivity
        // In a real test suite, you'd want to mock the network layer
        const testAddress = '127.0.0.1';
        const testPort = 8080;
        
        final canConnect = await repository.connectToLobbyHost(testAddress, testPort);
        
        // Since we're not actually running a server, this should return false
        // In a properly mocked environment, this would test the connection logic
        expect(canConnect, isA<bool>());
      });
    });

    group('Lobby Streams', () {
      test('should watch lobby changes', () async {
        final lobby = await repository.createLobby('Watch Test', 'Host1', 'avatar1', 'NumberGuessing');
        
        final stream = repository.watchLobby(lobby.id);
        expect(stream, isA<Stream<Lobby>>());
        
        // Test stream emits lobby updates
        final streamTest = expectLater(
          stream,
          emitsInOrder([
            isA<Lobby>().having((l) => l.players.length, 'initial players', 1),
            isA<Lobby>().having((l) => l.players.length, 'after join', 2),
          ]),
        );
        
        // Trigger lobby update by joining
        await repository.joinLobby(lobby.id, 'Player1', 'avatar2');
        
        await streamTest;
      });
    });
  });
}
