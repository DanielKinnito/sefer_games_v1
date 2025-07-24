import 'package:flutter_test/flutter_test.dart';
import 'package:sefer_games_v1/features/lobby/domain/usecases/start_hosting.dart';
import 'package:sefer_games_v1/features/lobby/data/repositories/lobby_repository_impl.dart';

void main() {
  group('StartHosting UseCase', () {
    late LobbyRepositoryImpl repository;
    late StartHosting usecase;

    setUp(() {
      repository = LobbyRepositoryImpl();
      usecase = StartHosting(repository);
    });

    tearDown(() {
      // Clean up any network resources
    });

    test('should start hosting existing lobby', () async {
      final lobby = await repository.createLobby('Host Test', 'Host1', 'avatar1', 'NumberGuessing');
      
      final hostAddress = await usecase(lobby.id);
      
      expect(hostAddress, isNotEmpty);
      expect(hostAddress, contains(':'));
      
      // Should contain IP and port
      final parts = hostAddress.split(':');
      expect(parts.length, 2);
      
      // Port should be numeric
      final port = int.tryParse(parts[1]);
      expect(port, isNotNull);
      expect(port!, greaterThan(0));
    });

    test('should start hosting on custom port', () async {
      final lobby = await repository.createLobby('Custom Port Test', 'Host1', 'avatar1', 'NumberGuessing');
      
      const customPort = 9999;
      final hostAddress = await usecase(lobby.id, port: customPort);
      
      expect(hostAddress, contains(':$customPort'));
    });

    test('should fail to host non-existent lobby', () async {
      expect(
        () => usecase('non-existent-lobby-id'),
        throwsException,
      );
    });

    test('should return valid IP address format', () async {
      final lobby = await repository.createLobby('IP Test', 'Host1', 'avatar1', 'NumberGuessing');
      
      final hostAddress = await usecase(lobby.id);
      final ip = hostAddress.split(':')[0];
      
      // Should be valid IPv4 format
      final parts = ip.split('.');
      expect(parts.length, 4);
      
      for (final part in parts) {
        final num = int.tryParse(part);
        expect(num, isNotNull);
        expect(num!, inInclusiveRange(0, 255));
      }
    });

    test('should handle multiple lobbies hosting', () async {
      final lobby1 = await repository.createLobby('Host Test 1', 'Host1', 'avatar1', 'NumberGuessing');
      final lobby2 = await repository.createLobby('Host Test 2', 'Host2', 'avatar2', 'NumberGuessing');
      
      final address1 = await usecase(lobby1.id, port: 8080);
      final address2 = await usecase(lobby2.id, port: 8081);
      
      expect(address1, isNotEmpty);
      expect(address2, isNotEmpty);
      expect(address1, isNot(address2)); // Should have different ports
    });
  });
}
