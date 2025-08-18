import 'package:flutter_test/flutter_test.dart';
import 'package:sefer_games_v1/features/lobby/data/models/network_models.dart';

void main() {
  group('NetworkMessage', () {
    test('should create NetworkMessage with all required fields', () {
      final timestamp = DateTime.now();
      final message = NetworkMessage(
        type: NetworkMessageTypes.playerJoined,
        senderId: 'player1',
        data: {'name': 'John', 'avatar': 'avatar1'},
        timestamp: timestamp,
        targetId: 'lobby1',
      );

      expect(message.type, NetworkMessageTypes.playerJoined);
      expect(message.senderId, 'player1');
      expect(message.data, {'name': 'John', 'avatar': 'avatar1'});
      expect(message.timestamp, timestamp);
      expect(message.targetId, 'lobby1');
    });

    test('should create NetworkMessage with default timestamp when not provided', () {
      final beforeCreation = DateTime.now();
      final message = NetworkMessage(
        type: NetworkMessageTypes.ping,
        senderId: 'player1',
        data: {},
      );
      final afterCreation = DateTime.now();

      expect(message.timestamp.isAfter(beforeCreation) || 
             message.timestamp.isAtSameMomentAs(beforeCreation), true);
      expect(message.timestamp.isBefore(afterCreation) || 
             message.timestamp.isAtSameMomentAs(afterCreation), true);
    });

    test('should serialize to and from JSON correctly', () {
      final originalMessage = NetworkMessage(
        type: NetworkMessageTypes.gameAction,
        senderId: 'player2',
        data: {'action': 'move', 'position': {'x': 10, 'y': 20}},
        targetId: 'game1',
      );

      final json = originalMessage.toJson();
      final deserializedMessage = NetworkMessage.fromJson(json);

      expect(deserializedMessage.type, originalMessage.type);
      expect(deserializedMessage.senderId, originalMessage.senderId);
      expect(deserializedMessage.data, originalMessage.data);
      expect(deserializedMessage.targetId, originalMessage.targetId);
      expect(deserializedMessage.timestamp.toIso8601String(), 
             originalMessage.timestamp.toIso8601String());
    });

    test('should serialize to and from JSON string correctly', () {
      final originalMessage = NetworkMessage(
        type: NetworkMessageTypes.lobbyUpdate,
        senderId: 'host1',
        data: {'players': 3, 'status': 'waiting'},
      );

      final jsonString = originalMessage.toJsonString();
      final deserializedMessage = NetworkMessage.fromJsonString(jsonString);

      expect(deserializedMessage.type, originalMessage.type);
      expect(deserializedMessage.senderId, originalMessage.senderId);
      expect(deserializedMessage.data, originalMessage.data);
    });

    test('should create copy with modified fields', () {
      final originalMessage = NetworkMessage(
        type: NetworkMessageTypes.ping,
        senderId: 'player1',
        data: {},
      );

      final copiedMessage = originalMessage.copyWith(
        type: NetworkMessageTypes.pong,
        targetId: 'player1',
      );

      expect(copiedMessage.type, NetworkMessageTypes.pong);
      expect(copiedMessage.senderId, originalMessage.senderId);
      expect(copiedMessage.targetId, 'player1');
      expect(copiedMessage.timestamp, originalMessage.timestamp);
    });

    test('should implement equality correctly', () {
      final timestamp = DateTime.now();
      final message1 = NetworkMessage(
        type: NetworkMessageTypes.ping,
        senderId: 'player1',
        data: {},
        timestamp: timestamp,
      );

      final message2 = NetworkMessage(
        type: NetworkMessageTypes.ping,
        senderId: 'player1',
        data: {},
        timestamp: timestamp,
      );

      final message3 = NetworkMessage(
        type: NetworkMessageTypes.pong,
        senderId: 'player1',
        data: {},
        timestamp: timestamp,
      );

      expect(message1, equals(message2));
      expect(message1, isNot(equals(message3)));
    });
  });

  group('NetworkMessageTypes', () {
    test('should validate known message types', () {
      expect(NetworkMessageTypes.isValidType(NetworkMessageTypes.playerJoined), true);
      expect(NetworkMessageTypes.isValidType(NetworkMessageTypes.gameAction), true);
      expect(NetworkMessageTypes.isValidType(NetworkMessageTypes.ping), true);
      expect(NetworkMessageTypes.isValidType('unknown_type'), false);
      expect(NetworkMessageTypes.isValidType(''), false);
    });
  });

  group('DiscoveredLobby', () {
    test('should create DiscoveredLobby with all required fields', () {
      final discoveredAt = DateTime.now();
      final lobby = DiscoveredLobby(
        id: 'lobby1',
        name: 'Test Lobby',
        hostAddress: '192.168.1.100',
        hostPort: 8080,
        gameType: 'NumberGuessing',
        currentPlayers: 2,
        maxPlayers: 8,
        discoveredAt: discoveredAt,
      );

      expect(lobby.id, 'lobby1');
      expect(lobby.name, 'Test Lobby');
      expect(lobby.hostAddress, '192.168.1.100');
      expect(lobby.hostPort, 8080);
      expect(lobby.gameType, 'NumberGuessing');
      expect(lobby.currentPlayers, 2);
      expect(lobby.maxPlayers, 8);
      expect(lobby.discoveredAt, discoveredAt);
    });

    test('should create DiscoveredLobby with default discoveredAt when not provided', () {
      final beforeCreation = DateTime.now();
      final lobby = DiscoveredLobby(
        id: 'lobby1',
        name: 'Test Lobby',
        hostAddress: '192.168.1.100',
        hostPort: 8080,
        gameType: 'NumberGuessing',
        currentPlayers: 2,
        maxPlayers: 8,
      );
      final afterCreation = DateTime.now();

      expect(lobby.discoveredAt.isAfter(beforeCreation) || 
             lobby.discoveredAt.isAtSameMomentAs(beforeCreation), true);
      expect(lobby.discoveredAt.isBefore(afterCreation) || 
             lobby.discoveredAt.isAtSameMomentAs(afterCreation), true);
    });

    test('should serialize to and from JSON correctly', () {
      final originalLobby = DiscoveredLobby(
        id: 'lobby2',
        name: 'Another Lobby',
        hostAddress: '192.168.1.101',
        hostPort: 8081,
        gameType: 'WordGame',
        currentPlayers: 1,
        maxPlayers: 6,
      );

      final json = originalLobby.toJson();
      final deserializedLobby = DiscoveredLobby.fromJson(json);

      expect(deserializedLobby.id, originalLobby.id);
      expect(deserializedLobby.name, originalLobby.name);
      expect(deserializedLobby.hostAddress, originalLobby.hostAddress);
      expect(deserializedLobby.hostPort, originalLobby.hostPort);
      expect(deserializedLobby.gameType, originalLobby.gameType);
      expect(deserializedLobby.currentPlayers, originalLobby.currentPlayers);
      expect(deserializedLobby.maxPlayers, originalLobby.maxPlayers);
    });

    test('should create from broadcast message correctly', () {
      const broadcastMessage = '''
      {
        "lobbyId": "lobby3",
        "lobbyName": "Broadcast Lobby",
        "hostPort": 8082,
        "gameType": "Trivia",
        "currentPlayers": 3,
        "maxPlayers": 8,
        "timestamp": "2024-01-01T12:00:00.000Z"
      }
      ''';

      final lobby = DiscoveredLobby.fromBroadcastMessage(
        broadcastMessage, 
        '192.168.1.102'
      );

      expect(lobby.id, 'lobby3');
      expect(lobby.name, 'Broadcast Lobby');
      expect(lobby.hostAddress, '192.168.1.102');
      expect(lobby.hostPort, 8082);
      expect(lobby.gameType, 'Trivia');
      expect(lobby.currentPlayers, 3);
      expect(lobby.maxPlayers, 8);
    });

    test('should throw FormatException for invalid broadcast message', () {
      const invalidMessage = '{"invalid": "format"}';

      expect(
        () => DiscoveredLobby.fromBroadcastMessage(invalidMessage, '192.168.1.100'),
        throwsA(isA<FormatException>()),
      );
    });

    test('should create broadcast message correctly', () {
      final lobby = DiscoveredLobby(
        id: 'lobby4',
        name: 'Broadcast Test',
        hostAddress: '192.168.1.103',
        hostPort: 8083,
        gameType: 'Quiz',
        currentPlayers: 2,
        maxPlayers: 4,
      );

      final broadcastMessage = lobby.toBroadcastMessage();
      expect(broadcastMessage, contains('"lobbyId":"lobby4"'));
      expect(broadcastMessage, contains('"lobbyName":"Broadcast Test"'));
      expect(broadcastMessage, contains('"hostPort":8083'));
      expect(broadcastMessage, contains('"gameType":"Quiz"'));
    });

    test('should implement equality correctly', () {
      final lobby1 = DiscoveredLobby(
        id: 'lobby1',
        name: 'Test',
        hostAddress: '192.168.1.100',
        hostPort: 8080,
        gameType: 'Game',
        currentPlayers: 1,
        maxPlayers: 4,
      );

      final lobby2 = DiscoveredLobby(
        id: 'lobby1',
        name: 'Different Name',
        hostAddress: '192.168.1.100',
        hostPort: 8080,
        gameType: 'Different Game',
        currentPlayers: 2,
        maxPlayers: 6,
      );

      final lobby3 = DiscoveredLobby(
        id: 'lobby2',
        name: 'Test',
        hostAddress: '192.168.1.100',
        hostPort: 8080,
        gameType: 'Game',
        currentPlayers: 1,
        maxPlayers: 4,
      );

      expect(lobby1, equals(lobby2)); // Same ID, host, and port
      expect(lobby1, isNot(equals(lobby3))); // Different ID
    });
  });

  group('ConnectionStatus', () {
    test('should create ConnectionStatus with all fields', () {
      final lastPing = DateTime.now();
      final status = ConnectionStatus(
        isConnected: true,
        hostAddress: '192.168.1.100',
        lastPing: lastPing,
        reconnectAttempts: 2,
        errorMessage: 'Connection timeout',
      );

      expect(status.isConnected, true);
      expect(status.hostAddress, '192.168.1.100');
      expect(status.lastPing, lastPing);
      expect(status.reconnectAttempts, 2);
      expect(status.errorMessage, 'Connection timeout');
    });

    test('should serialize to and from JSON correctly', () {
      final originalStatus = ConnectionStatus(
        isConnected: false,
        hostAddress: '192.168.1.101',
        reconnectAttempts: 3,
        errorMessage: 'Host unreachable',
      );

      final json = originalStatus.toJson();
      final deserializedStatus = ConnectionStatus.fromJson(json);

      expect(deserializedStatus.isConnected, originalStatus.isConnected);
      expect(deserializedStatus.hostAddress, originalStatus.hostAddress);
      expect(deserializedStatus.reconnectAttempts, originalStatus.reconnectAttempts);
      expect(deserializedStatus.errorMessage, originalStatus.errorMessage);
    });
  });

  group('LobbyUpdate', () {
    test('should create LobbyUpdate with all fields', () {
      final timestamp = DateTime.now();
      final update = LobbyUpdate(
        type: 'player_joined',
        data: {'playerId': 'player1', 'playerName': 'John'},
        timestamp: timestamp,
      );

      expect(update.type, 'player_joined');
      expect(update.data, {'playerId': 'player1', 'playerName': 'John'});
      expect(update.timestamp, timestamp);
    });

    test('should serialize to and from JSON correctly', () {
      final originalUpdate = LobbyUpdate(
        type: 'game_starting',
        data: {'gameType': 'NumberGuessing', 'countdown': 5},
      );

      final json = originalUpdate.toJson();
      final deserializedUpdate = LobbyUpdate.fromJson(json);

      expect(deserializedUpdate.type, originalUpdate.type);
      expect(deserializedUpdate.data, originalUpdate.data);
    });
  });

  group('LobbyBroadcastInfo', () {
    test('should create LobbyBroadcastInfo with all fields', () {
      final info = LobbyBroadcastInfo(
        lobbyId: 'lobby1',
        lobbyName: 'Test Lobby',
        hostPort: 8080,
        gameType: 'NumberGuessing',
        currentPlayers: 2,
        maxPlayers: 8,
      );

      expect(info.lobbyId, 'lobby1');
      expect(info.lobbyName, 'Test Lobby');
      expect(info.hostPort, 8080);
      expect(info.gameType, 'NumberGuessing');
      expect(info.currentPlayers, 2);
      expect(info.maxPlayers, 8);
    });

    test('should serialize to and from JSON string correctly', () {
      final originalInfo = LobbyBroadcastInfo(
        lobbyId: 'lobby2',
        lobbyName: 'Another Lobby',
        hostPort: 8081,
        gameType: 'WordGame',
        currentPlayers: 1,
        maxPlayers: 6,
      );

      final jsonString = originalInfo.toJsonString();
      final deserializedInfo = LobbyBroadcastInfo.fromJsonString(jsonString);

      expect(deserializedInfo.lobbyId, originalInfo.lobbyId);
      expect(deserializedInfo.lobbyName, originalInfo.lobbyName);
      expect(deserializedInfo.hostPort, originalInfo.hostPort);
      expect(deserializedInfo.gameType, originalInfo.gameType);
      expect(deserializedInfo.currentPlayers, originalInfo.currentPlayers);
      expect(deserializedInfo.maxPlayers, originalInfo.maxPlayers);
    });
  });

  group('NetworkMessageValidator', () {
    test('should validate correct NetworkMessage', () {
      final validMessage = NetworkMessage(
        type: NetworkMessageTypes.playerJoined,
        senderId: 'player1',
        data: {'name': 'John'},
      );

      expect(NetworkMessageValidator.validateMessage(validMessage), true);
    });

    test('should reject NetworkMessage with empty type', () {
      final invalidMessage = NetworkMessage(
        type: '',
        senderId: 'player1',
        data: {},
      );

      expect(NetworkMessageValidator.validateMessage(invalidMessage), false);
    });

    test('should reject NetworkMessage with empty senderId', () {
      final invalidMessage = NetworkMessage(
        type: NetworkMessageTypes.ping,
        senderId: '',
        data: {},
      );

      expect(NetworkMessageValidator.validateMessage(invalidMessage), false);
    });

    test('should reject NetworkMessage with invalid type', () {
      final invalidMessage = NetworkMessage(
        type: 'invalid_type',
        senderId: 'player1',
        data: {},
      );

      expect(NetworkMessageValidator.validateMessage(invalidMessage), false);
    });

    test('should reject NetworkMessage with timestamp too old', () {
      final oldTimestamp = DateTime.now().subtract(const Duration(minutes: 10));
      final invalidMessage = NetworkMessage(
        type: NetworkMessageTypes.ping,
        senderId: 'player1',
        data: {},
        timestamp: oldTimestamp,
      );

      expect(NetworkMessageValidator.validateMessage(invalidMessage), false);
    });

    test('should validate correct DiscoveredLobby', () {
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

    test('should reject DiscoveredLobby with empty id', () {
      final invalidLobby = DiscoveredLobby(
        id: '',
        name: 'Test Lobby',
        hostAddress: '192.168.1.100',
        hostPort: 8080,
        gameType: 'NumberGuessing',
        currentPlayers: 2,
        maxPlayers: 8,
      );

      expect(NetworkMessageValidator.validateDiscoveredLobby(invalidLobby), false);
    });

    test('should reject DiscoveredLobby with invalid port', () {
      final invalidLobby = DiscoveredLobby(
        id: 'lobby1',
        name: 'Test Lobby',
        hostAddress: '192.168.1.100',
        hostPort: 0,
        gameType: 'NumberGuessing',
        currentPlayers: 2,
        maxPlayers: 8,
      );

      expect(NetworkMessageValidator.validateDiscoveredLobby(invalidLobby), false);
    });

    test('should reject DiscoveredLobby with invalid player counts', () {
      final invalidLobby = DiscoveredLobby(
        id: 'lobby1',
        name: 'Test Lobby',
        hostAddress: '192.168.1.100',
        hostPort: 8080,
        gameType: 'NumberGuessing',
        currentPlayers: 10,
        maxPlayers: 8,
      );

      expect(NetworkMessageValidator.validateDiscoveredLobby(invalidLobby), false);
    });
  });
}