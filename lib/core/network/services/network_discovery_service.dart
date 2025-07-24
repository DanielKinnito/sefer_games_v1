import 'dart:async';
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';

abstract class NetworkDiscoveryService {
  Stream<String> get discoveredHosts;
  Future<void> startDiscovery();
  Future<void> stopDiscovery();
  Future<void> announceHost(int port);
  Future<void> stopAnnouncing();
  Future<String?> getLocalIPAddress();
}

class NetworkDiscoveryServiceImpl implements NetworkDiscoveryService {
  static const int discoveryPort = 8888;
  static const String discoveryMessage = 'SEFER_GAMES_HOST';
  
  final StreamController<String> _discoveredHostsController = StreamController<String>.broadcast();
  RawDatagramSocket? _listenSocket;
  RawDatagramSocket? _announceSocket;
  Timer? _announceTimer;
  
  @override
  Stream<String> get discoveredHosts => _discoveredHostsController.stream;

  @override
  Future<void> startDiscovery() async {
    try {
      _listenSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, discoveryPort);
      _listenSocket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final packet = _listenSocket!.receive();
          if (packet != null) {
            final message = String.fromCharCodes(packet.data);
            if (message.startsWith(discoveryMessage)) {
              final hostInfo = message.substring(discoveryMessage.length + 1);
              _discoveredHostsController.add(hostInfo);
            }
          }
        }
      });
    } catch (e) {
      print('Error starting discovery: $e');
    }
  }

  @override
  Future<void> stopDiscovery() async {
    _listenSocket?.close();
    _listenSocket = null;
  }

  @override
  Future<void> announceHost(int port) async {
    try {
      final localIP = await getLocalIPAddress();
      if (localIP == null) return;
      
      _announceSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _announceSocket!.broadcastEnabled = true;
      
      final message = '$discoveryMessage:$localIP:$port';
      final data = message.codeUnits;
      
      _announceTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        _announceSocket!.send(data, InternetAddress('255.255.255.255'), discoveryPort);
      });
    } catch (e) {
      print('Error announcing host: $e');
    }
  }

  @override
  Future<void> stopAnnouncing() async {
    _announceTimer?.cancel();
    _announceTimer = null;
    _announceSocket?.close();
    _announceSocket = null;
  }

  @override
  Future<String?> getLocalIPAddress() async {
    try {
      final info = NetworkInfo();
      return await info.getWifiIP();
    } catch (e) {
      print('Error getting local IP: $e');
      return null;
    }
  }

  void dispose() {
    _discoveredHostsController.close();
    stopDiscovery();
    stopAnnouncing();
  }
}
