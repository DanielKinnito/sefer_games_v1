import 'package:flutter_test/flutter_test.dart';
import 'package:sefer_games_v1/features/lobby/data/services/lan_network_service.dart';
import 'dart:io';

void main() {
  group('LanNetworkService', () {
    late LanNetworkService service;

    setUp(() {
      service = LanNetworkService();
    });

    tearDown(() {
      service.dispose();
    });

    group('IP Address Detection', () {
      test('should detect valid local IP address', () async {
        final ip = await service.getLocalIpAddress();
        
        expect(ip, isNotNull);
        expect(ip, isNotEmpty);
        
        // Should be a valid IP format (basic check)
        final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
        expect(ipRegex.hasMatch(ip), true, reason: 'IP should match format: $ip');
      });

      test('should return consistent IP on multiple calls', () async {
        final ip1 = await service.getLocalIpAddress();
        final ip2 = await service.getLocalIpAddress();
        
        expect(ip1, equals(ip2));
      });
    });

    group('Hosting and Discovery', () {
      test('should handle hosting start and stop', () async {
        try {
          final result = await service.startHosting('test-lobby', 'Test Lobby');
          expect(result, isNotNull);
          expect(result.isNotEmpty, true);
          
          // Stop hosting
          await service.stopHosting();
        } on SocketException catch (e) {
          // Expected in test environment where port might be in use
          expect(e.message, contains('Failed to create server socket'));
        } catch (e) {
          fail('Unexpected error: $e');
        }
      });

      test('should handle discovery without timeout', () async {
        final discoveredLobbies = await service.discoverLocalLobbies();
        
        // Should return empty list or found lobbies without throwing
        expect(discoveredLobbies, isA<List>());
      });

      test('should handle connection errors gracefully', () async {
        try {
          await service.connectToLobbyHost('invalid-host', 8080);
          fail('Should have thrown an exception');
        } catch (e) {
          // Expected - invalid host should cause connection error
          expect(e, isA<Exception>());
        }
      });
    });

    group('Connection Management', () {
      test('should handle basic operations', () {
        // Basic smoke test - service should be creatable and disposable
        expect(service, isNotNull);
      });

      test('should handle stop hosting when not hosting', () async {
        // Should not throw even if not hosting
        await service.stopHosting();
        // No exception means success
      });
    });

    group('Resource Cleanup', () {
      test('should dispose resources properly', () {
        // Should not throw
        service.dispose();
        
        // Should be safe to call multiple times
        service.dispose();
      });
    });
  });
}
