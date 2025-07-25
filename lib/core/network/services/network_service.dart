import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/network_message.dart';

abstract class NetworkService {
  Stream<NetworkMessage> get messageStream;
  Future<bool> startHost(int port);
  Future<bool> connectToHost(String hostAddress, int port);
  Future<void> sendMessage(NetworkMessage message);
  Future<void> disconnect();
  bool get isConnected;
  bool get isHost;
  String? get hostAddress;
}

class NetworkServiceImpl implements NetworkService {
  static const int defaultPort = 3000;
  
  IO.Socket? _socket;
  final StreamController<NetworkMessage> _messageController = StreamController<NetworkMessage>.broadcast();
  bool _isHost = false;
  String? _hostAddress;
  
  @override
  Stream<NetworkMessage> get messageStream => _messageController.stream;
  
  @override
  bool get isConnected => _socket?.connected ?? false;
  
  @override
  bool get isHost => _isHost;
  
  @override
  String? get hostAddress => _hostAddress;

  @override
  Future<bool> startHost(int port) async {
    try {
      // For now, we'll simulate host functionality
      // In a real implementation, you'd need a Node.js server or similar
      _isHost = true;
      _hostAddress = 'localhost:$port';
      
      // Create a socket connection for testing
      _socket = IO.io('http://localhost:$port', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });
      
      _setupSocketListeners();
      _socket!.connect();
      
      return true;
    } catch (e) {
      print('Error starting host: $e');
      return false;
    }
  }

  @override
  Future<bool> connectToHost(String hostAddress, int port) async {
    try {
      _isHost = false;
      _hostAddress = hostAddress;
      
      _socket = IO.io('http://$hostAddress:$port', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });
      
      _setupSocketListeners();
      _socket!.connect();
      
      return true;
    } catch (e) {
      print('Error connecting to host: $e');
      return false;
    }
  }

  void _setupSocketListeners() {
    _socket!.on('connect', (_) {
      print('Connected to server');
    });
    
    _socket!.on('disconnect', (_) {
      print('Disconnected from server');
    });
    
    _socket!.on('message', (data) {
      try {
        final message = NetworkMessage.fromJson(Map<String, dynamic>.from(data));
        _messageController.add(message);
      } catch (e) {
        print('Error parsing message: $e');
      }
    });
    
    _socket!.on('error', (error) {
      print('Socket error: $error');
    });
  }

  @override
  Future<void> sendMessage(NetworkMessage message) async {
    if (_socket?.connected == true) {
      _socket!.emit('message', message.toJson());
    } else {
      throw Exception('Not connected to server');
    }
  }

  @override
  Future<void> disconnect() async {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isHost = false;
    _hostAddress = null;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
