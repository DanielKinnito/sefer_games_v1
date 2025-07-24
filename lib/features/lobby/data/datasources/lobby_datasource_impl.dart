import 'dart:async';
import 'lobby_datasource.dart';
import '../models/lobby_model.dart';
import '../models/player_model.dart';
import '../services/lan_network_service.dart';
import '../../domain/entities/lobby.dart';

class LobbyDataSourceImpl implements LobbyDataSource {
  final List<LobbyModel> _lobbies = [];
  final Map<String, StreamController<LobbyModel>> _lobbyStreams = {};
  final LanNetworkService _networkService = LanNetworkService();
  
  // Track which lobbies are being hosted
  final Map<String, String> _hostAddresses = {};

  @override
  Future<LobbyModel> createLobby(String lobbyName, String hostName, String hostAvatarId, String gameType, {int maxPlayers = 8}) async {
    final hostId = DateTime.now().millisecondsSinceEpoch.toString();
    final host = PlayerModel(
      id: hostId,
      name: hostName,
      avatarId: hostAvatarId,
      isHost: true,
      isConnected: true,
    );
    
    final lobby = LobbyModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: lobbyName,
      hostId: hostId,
      players: [host],
      gameType: gameType,
      maxPlayers: maxPlayers,
      status: LobbyStatus.waiting,
    );
    
    _lobbies.add(lobby);
    _createLobbyStream(lobby.id);
    return lobby;
  }

  @override
  Future<LobbyModel?> joinLobby(String lobbyId, String playerName, String playerAvatarId) async {
    LobbyModel? lobby;
    try {
      lobby = _lobbies.firstWhere((l) => l.id == lobbyId);
    } catch (_) {
      return null;
    }
    
    if (lobby.players.length < lobby.maxPlayers) {
      final playerId = DateTime.now().millisecondsSinceEpoch.toString();
      final player = PlayerModel(
        id: playerId,
        name: playerName,
        avatarId: playerAvatarId,
        isHost: false,
        isConnected: true,
      );
      
      // Check if player with same name already exists
      if (!lobby.players.any((p) => p.name == playerName)) {
        lobby.players.add(player);
        _updateLobbyStream(lobby);
        return lobby;
      }
    }
    return null;
  }

  @override
  Future<List<LobbyModel>> getAvailableLobbies() async {
    return _lobbies.where((lobby) => lobby.status == LobbyStatus.waiting).toList();
  }

  @override
  Future<void> leaveLobby(String lobbyId, String playerId) async {
    LobbyModel? lobby;
    try {
      lobby = _lobbies.firstWhere((l) => l.id == lobbyId);
    } catch (_) {
      return;
    }
    
    lobby.players.removeWhere((player) => player.id == playerId);
    
    // If host leaves or lobby is empty, remove the lobby
    if (lobby.players.isEmpty || lobby.hostId == playerId) {
      _lobbies.remove(lobby);
      _closeLobbyStream(lobbyId);
    } else {
      _updateLobbyStream(lobby);
    }
  }

  @override
  Future<void> updatePlayerStatus(String lobbyId, String playerId, bool isConnected) async {
    LobbyModel? lobby;
    try {
      lobby = _lobbies.firstWhere((l) => l.id == lobbyId);
    } catch (_) {
      return;
    }
    
    final playerIndex = lobby.players.indexWhere((p) => p.id == playerId);
    if (playerIndex != -1) {
      final updatedPlayer = PlayerModel(
        id: lobby.players[playerIndex].id,
        name: lobby.players[playerIndex].name,
        avatarId: lobby.players[playerIndex].avatarId,
        isHost: lobby.players[playerIndex].isHost,
        isConnected: isConnected,
        joinedAt: lobby.players[playerIndex].joinedAt,
      );
      lobby.players[playerIndex] = updatedPlayer;
      _updateLobbyStream(lobby);
    }
  }

  @override
  Future<LobbyModel?> getLobby(String lobbyId) async {
    try {
      return _lobbies.firstWhere((l) => l.id == lobbyId);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<LobbyModel> watchLobby(String lobbyId) {
    if (!_lobbyStreams.containsKey(lobbyId)) {
      _createLobbyStream(lobbyId);
    }
    return _lobbyStreams[lobbyId]!.stream;
  }

  // LAN-specific implementations
  @override
  Future<String> startHosting(String lobbyId, {int port = 8080}) async {
    try {
      final lobby = await getLobby(lobbyId);
      if (lobby == null) {
        throw Exception('Lobby not found');
      }
      
      final hostAddress = await _networkService.startHosting(lobbyId, lobby.name, port: port);
      _hostAddresses[lobbyId] = hostAddress;
      return hostAddress;
    } catch (e) {
      throw Exception('Failed to start hosting: $e');
    }
  }

  @override
  Future<List<LobbyModel>> discoverLocalLobbies() async {
    try {
      final discoveredLobbies = await _networkService.discoverLocalLobbies();
      final List<LobbyModel> lobbies = [];
      
      for (final lobbyInfo in discoveredLobbies) {
        // Convert discovered lobby info to LobbyModel
        final lobby = LobbyModel(
          id: lobbyInfo['lobbyId'] as String,
          name: lobbyInfo['lobbyName'] as String,
          hostId: 'remote_host', // We don't have the actual host ID
          players: [], // Will be populated when joining
          gameType: 'Unknown', // Will be updated when joining
          status: LobbyStatus.waiting,
          hostAddress: lobbyInfo['hostAddress'] as String,
          hostPort: lobbyInfo['hostPort'] as int,
        );
        lobbies.add(lobby);
      }
      
      return lobbies;
    } catch (e) {
      // Return local lobbies if network discovery fails
      return _lobbies.where((lobby) => 
        lobby.status == LobbyStatus.waiting && 
        _hostAddresses.containsKey(lobby.id)
      ).toList();
    }
  }

  @override
  Future<bool> connectToLobbyHost(String hostAddress, int port) async {
    try {
      final webSocket = await _networkService.connectToLobbyHost(hostAddress, port);
      // TODO: Handle the WebSocket connection for real-time communication
      webSocket.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Helper methods for stream management
  void _createLobbyStream(String lobbyId) {
    if (!_lobbyStreams.containsKey(lobbyId)) {
      _lobbyStreams[lobbyId] = StreamController<LobbyModel>.broadcast();
    }
  }

  void _updateLobbyStream(LobbyModel lobby) {
    if (_lobbyStreams.containsKey(lobby.id)) {
      _lobbyStreams[lobby.id]!.add(lobby);
    }
  }

  void _closeLobbyStream(String lobbyId) {
    if (_lobbyStreams.containsKey(lobbyId)) {
      _lobbyStreams[lobbyId]!.close();
      _lobbyStreams.remove(lobbyId);
    }
  }

  // Cleanup method
  void dispose() {
    for (final controller in _lobbyStreams.values) {
      controller.close();
    }
    _lobbyStreams.clear();
    _networkService.dispose();
  }
}
