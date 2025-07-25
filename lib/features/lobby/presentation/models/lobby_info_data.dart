import '../../domain/entities/lobby.dart';
import '../../domain/entities/player.dart';

/// Data class for lobby information display
class LobbyInfoData {
  final String lobbyId;
  final String lobbyName;
  final String hostName;
  final String hostIp;
  final int port;
  final String gameType;
  final List<Player> players;
  final int maxPlayers;
  final bool isGameStarted;
  final DateTime createdAt;
  final Map<String, int> leaderboard;

  const LobbyInfoData({
    required this.lobbyId,
    required this.lobbyName,
    required this.hostName,
    required this.hostIp,
    required this.port,
    required this.gameType,
    required this.players,
    required this.maxPlayers,
    required this.isGameStarted,
    required this.createdAt,
    required this.leaderboard,
  });

  factory LobbyInfoData.fromLobby(
    Lobby lobby, {
    required String hostIp,
    required int port,
    required DateTime createdAt,
    Map<String, int>? leaderboard,
  }) {
    return LobbyInfoData(
      lobbyId: lobby.id,
      lobbyName: lobby.name,
      hostName: lobby.players.firstWhere((p) => p.isHost).name,
      hostIp: hostIp,
      port: port,
      gameType: lobby.gameType,
      players: lobby.players,
      maxPlayers: 8, // Default max players
      isGameStarted: false, // TODO: Get from lobby state
      createdAt: createdAt,
      leaderboard: leaderboard ?? {},
    );
  }

  int get currentPlayerCount => players.length;
  
  List<Player> get connectedPlayers => 
      players.where((p) => p.isConnected).toList();
      
  List<Player> get sortedPlayersByScore {
    final playersList = List<Player>.from(players);
    playersList.sort((a, b) {
      final scoreA = leaderboard[a.id] ?? 0;
      final scoreB = leaderboard[b.id] ?? 0;
      return scoreB.compareTo(scoreA); // Descending order
    });
    return playersList;
  }
}
