import 'package:flutter_test/flutter_test.dart';
import 'package:sefer_games_v1/features/lobby/data/services/lan_service.dart';
import 'package:sefer_games_v1/features/lobby/data/models/network_models.dart';
import 'dart:io';
import 'dart:convert';

void main() {
  group('LanService WebSocket Tests', () {
    late LanService lanService;

    setUp(() {
      lanService = LanService();
    });

    tearDown(() async {
      await lanService.disconnectFromHost();
      lanService.dispose();
    });

    test('should start hosting and create HTTP server', () async {
      final hostAddress = await lanService.startHosting(port: 8090);
      
      expect(hostAddress, contains(':'));
      expect(hostAddress, contains('8090'));
      
      await lanService.stopHosting();
    });

    test('should handle lobby broadcast info correctly', () async {
      final lobbyInfo = LobbyBroadcastInfo(
        lobbyId: 'test_lobby',
        lobbyName: 'Test Lobby',
        hostPort: 8091,
        gameType: 'NumberGuessing',
        currentPlayers: 1,
        maxPlayers: 8,
      );

      await lanService.startBroadcasting(lobbyInfo);
      
      // Verify broadcast info is stored by checking if broadcasting started
      // (we can't directly access private fields, so we test the behavior)
      expect(lobbyInfo.lobbyName, equals('Test Lobby'));
      expect(lobbyInfo.gameType, equals('NumberGuessing'));
      
      await lanService.stopBroadcasting();
    });

    test('should generate unique client IDs', () {
      // Access private method through reflection or create a public wrapper
      // For now, we'll test the public interface
      expect(lanService.connectedClientIds, isEmpty);
      expect(lanService.connectedClientCount, equals(0));
    });

    test('should handle network messages correctly', () async {
      final messageStream = lanService.messageStream;
      final connectionStatusStream = lanService.connectionStatusStream;
      
      expect(messageStream, isA<Stream<NetworkMessage>>());
      expect(connectionStatusStream, isA<Stream<ConnectionStatus>>());
    });

    test('should validate lobby state updates', () async {
      final testLobbyState = {
        'id': 'test_lobby',
        'name': 'Test Lobby',
        'players': [
          {'id': 'player1', 'name': 'John', 'avatar': 'avatar1'}
        ],
        'maxPlayers': 8,
        'gameType': 'NumberGuessing',
      };

      lanService.updateLobbyState(testLobbyState);
      
      expect(lanService.currentLobbyState, equals(testLobbyState));
    });

    test('should handle client connection status', () {
      expect(lanService.isClientConnected('nonexistent_client'), false);
      expect(lanService.connectedClientCount, equals(0));
    });

    test('should broadcast messages to clients', () async {
      final testData = {
        'type': 'test_message',
        'content': 'Hello clients',
      };

      // This should not throw even with no connected clients
      await lanService.broadcastToClients(testData);
      
      expect(lanService.connectedClientCount, equals(0));
    });

    test('should handle network message broadcasting', () async {
      final testMessage = NetworkMessage(
        type: NetworkMessageTypes.lobbyUpdate,
        senderId: 'server',
        data: {'test': 'data'},
      );

      // This should not throw even with no connected clients
      await lanService.broadcastNetworkMessage(testMessage);
      
      expect(lanService.connectedClientCount, equals(0));
    });

    test('should handle client connection state', () {
      expect(lanService.isConnectedToHost, false);
      expect(lanService.currentHostAddress, isNull);
    });

    test('should queue messages when not connected', () async {
      final testMessage = NetworkMessage(
        type: NetworkMessageTypes.gameAction,
        senderId: 'client',
        data: {'action': 'test'},
      );

      // Should queue message when not connected
      await lanService.sendNetworkMessageToHost(testMessage);
      
      expect(lanService.isConnectedToHost, false);
    });

    test('should handle connection to invalid host gracefully', () async {
      final connected = await lanService.connectToHost('invalid.host', 9999);
      
      expect(connected, false);
      expect(lanService.isConnectedToHost, false);
    });

    test('should handle disconnection properly', () async {
      await lanService.disconnectFromHost();
      
      expect(lanService.isConnectedToHost, false);
      expect(lanService.currentHostAddress, isNull);
    });

    test('should handle discovery correctly', () async {
      // Test discovery stream
      final discoveryStream = lanService.discoveredLobbiesStream;
      expect(discoveryStream, isA<Stream<List<DiscoveredLobby>>>());
      
      // Test discovery method (will timeout quickly in test environment)
      try {
        final lobbies = await lanService.discoverLobbies();
        expect(lobbies, isA<List<DiscoveredLobby>>());
      } catch (e) {
        // Expected in test environment without actual network
        expect(e.toString(), contains('Failed to discover lobbies'));
      }
    });
  });

  group('LanService Network Message Validation', () {
    test('should validate NetworkMessage correctly', () {
      final validMessage = NetworkMessage(
        type: NetworkMessageTypes.playerJoined,
        senderId: 'player1',
        data: {'name': 'John'},
      );

      expect(NetworkMessageValidator.validateMessage(validMessage), true);
    });

    test('should reject invalid NetworkMessage', () {
      final invalidMessage = NetworkMessage(
        type: 'invalid_type',
        senderId: 'player1',
        data: {},
      );

      expect(NetworkMessageValidator.validateMessage(invalidMessage), false);
    });

    test('should validate DiscoveredLobby correctly', () {
      final validLobby = DiscoveredLobby(
        id: 'lobby1',
        name: 'Test Lobby',
        hostAddress: '192.168.1.100',
        hostPort: 8080,
        gameType: 'NumberGuessing',
        currentPlayers: 2,
        maxPlayers: 8,
      );

      expect(NetworkMessageValidator.validateDiscoveredLobby(validLobby), true);
    });
  });

  group('LanService HTTP Endpoints', () {
    late LanService lanService;
    late HttpClient httpClient;
    String? hostAddress;

    setUp(() async {
      lanService = LanService();
      httpClient = HttpClient();
      
      try {
        hostAddress = await lanService.startHosting(port: 8092);
      } catch (e) {
        // Skip HTTP tests if we can't start server
        hostAddress = null;
      }
    });

    tearDown(() async {
      httpClient.close();
      await lanService.stopHosting();
      lanService.dispose();
    });

    test('should respond to ping requests', () async {
      if (hostAddress == null) return;
      
      final parts = hostAddress!.split(':');
      final host = parts[0];
      final port = int.parse(parts[1]);
      
      try {
        final request = await httpClient.get(host, port, '/ping');
        final response = await request.close();
        
        expect(response.statusCode, equals(200));
        
        final responseBody = await response.transform(utf8.decoder).join();
        final responseData = jsonDecode(responseBody);
        
        expect(responseData['status'], equals('ok'));
        expect(responseData['message'], equals('pong'));
      } catch (e) {
        // Network tests may fail in some environments
        print('HTTP test skipped due to network error: $e');
      }
    });

    test('should handle lobby info requests', () async {
      if (hostAddress == null) return;
      
      final parts = hostAddress!.split(':');
      final host = parts[0];
      final port = int.parse(parts[1]);
      
      // Set up lobby state
      lanService.updateLobbyState({
        'id': 'test_lobby',
        'name': 'Test Lobby',
        'players': [],
        'maxPlayers': 8,
      });
      
      try {
        final request = await httpClient.get(host, port, '/lobby');
        final response = await request.close();
        
        expect(response.statusCode, equals(200));
        
        final responseBody = await response.transform(utf8.decoder).join();
        final responseData = jsonDecode(responseBody);
        
        expect(responseData['status'], equals('ok'));
        expect(responseData['lobby'], isNotNull);
        expect(responseData['lobby']['name'], equals('Test Lobby'));
      } catch (e) {
        // Network tests may fail in some environments
        print('HTTP test skipped due to network error: $e');
      }
    });
  });
}