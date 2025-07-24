import 'package:flutter_test/flutter_test.dart';
import 'package:sefer_games_v1/features/lobby/data/datasources/lobby_datasource_impl.dart';
import 'package:sefer_games_v1/features/lobby/domain/entities/lobby.dart';

void main() {
  group('LobbyDataSourceImpl', () {
    late LobbyDataSourceImpl dataSource;

    setUp(() {
      dataSource = LobbyDataSourceImpl();
    });

    tearDown(() {
      dataSource.dispose();
    });

    group('Basic Operations', () {
      test('should create a lobby with correct properties', () async {
        final lobby = await dataSource.createLobby('Test Lobby', 'Host1', 'avatar1', 'NumberGuessing');
        
        expect(lobby.hostId, isNotEmpty);
        expect(lobby.gameType, 'NumberGuessing');
        expect(lobby.name, 'Test Lobby');
        expect(lobby.players.length, 1);
        expect(lobby.players.first.name, 'Host1');
        expect(lobby.players.first.isHost, true);
        expect(lobby.status, LobbyStatus.waiting);
        expect(lobby.maxPlayers, 8);
      });

      test('should create lobby with custom max players', () async {
        final lobby = await dataSource.createLobby('Small Lobby', 'Host1', 'avatar1', 'NumberGuessing', maxPlayers: 4);
        expect(lobby.maxPlayers, 4);
      });

      test('should join a lobby successfully', () async {
        final lobby = await dataSource.createLobby('Test Lobby 2', 'Host2', 'avatar1', 'NumberGuessing');
        final joined = await dataSource.joinLobby(lobby.id, 'Player2', 'avatar2');
        
        expect(joined, isNotNull);
        expect(joined!.players.length, 2);
        expect(joined.players.any((p) => p.name == 'Player2'), true);
        
        final player2 = joined.players.firstWhere((p) => p.name == 'Player2');
        expect(player2.isHost, false);
        expect(player2.isConnected, true);
      });

      test('should not join lobby with duplicate name', () async {
        final lobby = await dataSource.createLobby('Test Lobby', 'Host1', 'avatar1', 'NumberGuessing');
        await dataSource.joinLobby(lobby.id, 'Player1', 'avatar2');
        
        final duplicateJoin = await dataSource.joinLobby(lobby.id, 'Player1', 'avatar3');
        expect(duplicateJoin, isNull);
      });

      test('should not join full lobby', () async {
        final lobby = await dataSource.createLobby('Full Lobby', 'Host1', 'avatar1', 'NumberGuessing', maxPlayers: 2);
        await dataSource.joinLobby(lobby.id, 'Player1', 'avatar2');
        
        final overflowJoin = await dataSource.joinLobby(lobby.id, 'Player2', 'avatar3');
        expect(overflowJoin, isNull);
      });

      test('should get available lobbies', () async {
        await dataSource.createLobby('Lobby 1', 'Host1', 'avatar1', 'NumberGuessing');
        await dataSource.createLobby('Lobby 2', 'Host2', 'avatar1', 'NumberGuessing');
        
        final lobbies = await dataSource.getAvailableLobbies();
        expect(lobbies.length, greaterThanOrEqualTo(2));
        expect(lobbies.every((l) => l.status == LobbyStatus.waiting), true);
      });

      test('should leave a lobby', () async {
        final lobby = await dataSource.createLobby('Test Lobby', 'Host1', 'avatar1', 'NumberGuessing');
        await dataSource.joinLobby(lobby.id, 'Player1', 'avatar2');
        
        final player1 = lobby.players.firstWhere((p) => p.name == 'Player1');
        await dataSource.leaveLobby(lobby.id, player1.id);
        
        final updated = await dataSource.getLobby(lobby.id);
        expect(updated!.players.length, 1);
        expect(updated.players.any((p) => p.name == 'Player1'), false);
      });

      test('should remove lobby when host leaves', () async {
        final lobby = await dataSource.createLobby('Test Lobby', 'Host1', 'avatar1', 'NumberGuessing');
        await dataSource.leaveLobby(lobby.id, lobby.hostId);
        
        final retrieved = await dataSource.getLobby(lobby.id);
        expect(retrieved, isNull);
      });

      test('should get lobby by id', () async {
        final lobby = await dataSource.createLobby('Specific Lobby', 'Host1', 'avatar1', 'NumberGuessing');
        
        final retrieved = await dataSource.getLobby(lobby.id);
        expect(retrieved, isNotNull);
        expect(retrieved!.id, lobby.id);
        expect(retrieved.name, 'Specific Lobby');
      });

      test('should update player status', () async {
        final lobby = await dataSource.createLobby('Test Lobby', 'Host1', 'avatar1', 'NumberGuessing');
        await dataSource.joinLobby(lobby.id, 'Player1', 'avatar2');
        
        final player = lobby.players.firstWhere((p) => p.name == 'Player1');
        await dataSource.updatePlayerStatus(lobby.id, player.id, false);
        
        final updated = await dataSource.getLobby(lobby.id);
        final updatedPlayer = updated!.players.firstWhere((p) => p.id == player.id);
        expect(updatedPlayer.isConnected, false);
      });
    });

    group('Lobby Streams', () {
      test('should create and update lobby streams', () async {
        final lobby = await dataSource.createLobby('Stream Test', 'Host1', 'avatar1', 'NumberGuessing');
        
        final stream = dataSource.watchLobby(lobby.id);
        expect(stream, isA<Stream>());
        
        // Test that the stream emits updates
        final streamTest = expectLater(
          stream,
          emitsInOrder([
            isA().having((l) => l.players.length, 'players count', 2),
          ]),
        );
        
        // Trigger an update
        await dataSource.joinLobby(lobby.id, 'Player1', 'avatar2');
        
        await streamTest;
      });

      test('should handle non-existent lobby stream', () async {
        final stream = dataSource.watchLobby('non-existent-id');
        expect(stream, isA<Stream>());
      });
    });

    group('LAN Network Features', () {
      test('should start hosting', () async {
        final lobby = await dataSource.createLobby('Host Test', 'Host1', 'avatar1', 'NumberGuessing');
        
        final hostAddress = await dataSource.startHosting(lobby.id);
        
        expect(hostAddress, isNotEmpty);
        expect(hostAddress, contains(':'));
      });

      test('should fail to host non-existent lobby', () async {
        expect(
          () => dataSource.startHosting('non-existent-id'),
          throwsException,
        );
      });

      test('should discover local lobbies', () async {
        final lobby1 = await dataSource.createLobby('Discoverable 1', 'Host1', 'avatar1', 'NumberGuessing');
        final lobby2 = await dataSource.createLobby('Discoverable 2', 'Host2', 'avatar1', 'NumberGuessing');
        
        await dataSource.startHosting(lobby1.id);
        await dataSource.startHosting(lobby2.id);
        
        final discovered = await dataSource.discoverLocalLobbies();
        expect(discovered, isA<List>());
      });

      test('should attempt to connect to lobby host', () async {
        const testAddress = '127.0.0.1';
        const testPort = 8080;
        
        final result = await dataSource.connectToLobbyHost(testAddress, testPort);
        expect(result, isA<bool>());
      });
    });
  });
}
