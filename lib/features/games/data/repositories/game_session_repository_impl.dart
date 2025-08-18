import '../../../../core/game/game_base.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/repositories/game_session_repository.dart';
import '../../../lobby/data/services/lan_service.dart';
import '../../../lobby/data/models/network_models.dart';

class GameSessionRepositoryImpl implements GameSessionRepository {
  final LanService lanService;
  final Map<String, GameSession> _activeSessions = {};
  GameSession? _currentSession;

  GameSessionRepositoryImpl({required this.lanService});

  @override
  Future<GameSession> createGameSession({
    required String lobbyId,
    required String gameType,
    required List<String> playerIds,
    required GameBase gameInstance,
  }) async {
    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    
    final session = GameSessionEntity(
      sessionId: sessionId,
      lobbyId: lobbyId,
      gameType: gameType,
      playerIds: playerIds,
      gameInstance: gameInstance,
      status: GameSessionStatus.initializing,
    );

    _activeSessions[sessionId] = session;
    _currentSession = session;

    // Broadcast session creation to all players
    await lanService.broadcastNetworkMessage(NetworkMessage(
      type: NetworkMessageTypes.gameStarted,
      senderId: 'server',
      data: {
        'sessionId': sessionId,
        'lobbyId': lobbyId,
        'gameType': gameType,
        'playerIds': playerIds,
        'timestamp': DateTime.now().toIso8601String(),
      },
    ));

    return session;
  }

  @override
  Future<GameSession?> getSession(String sessionId) async {
    return _activeSessions[sessionId];
  }

  @override
  Future<GameSession?> getCurrentSession() async {
    return _currentSession;
  }

  @override
  Future<void> updateSessionState(String sessionId, Map<String, dynamic> gameState) async {
    final session = _activeSessions[sessionId];
    if (session == null) return;

    // Update local session
    _activeSessions[sessionId] = (session as GameSessionEntity).copyWith(
      status: GameSessionStatus.active,
    );

    // Broadcast state update to all players
    await broadcastGameStateUpdate(sessionId, gameState);
  }

  @override
  Future<void> endSession(String sessionId, Map<String, dynamic> gameResults) async {
    final session = _activeSessions[sessionId];
    if (session == null) return;

    // Update session status
    _activeSessions[sessionId] = (session as GameSessionEntity).copyWith(
      status: GameSessionStatus.finished,
      endedAt: DateTime.now(),
      gameResults: gameResults,
    );

    // Clear current session if this was it
    if (_currentSession?.sessionId == sessionId) {
      _currentSession = null;
    }
  }

  @override
  Future<void> broadcastGameAction({
    required String sessionId,
    required String playerId,
    required GameAction action,
    required GameActionResult result,
  }) async {
    await lanService.broadcastNetworkMessage(NetworkMessage(
      type: NetworkMessageTypes.gameAction,
      senderId: playerId,
      data: {
        'sessionId': sessionId,
        'playerId': playerId,
        'actionType': action.type,
        'actionData': action.data,
        'result': {
          'success': result.success,
          'errorMessage': result.errorMessage,
          'resultData': result.resultData,
        },
        'timestamp': DateTime.now().toIso8601String(),
      },
    ));
  }

  @override
  Future<void> broadcastGameEnd(String sessionId, Map<String, dynamic> gameResults) async {
    await lanService.broadcastNetworkMessage(NetworkMessage(
      type: NetworkMessageTypes.gameEnded,
      senderId: 'server',
      data: {
        'sessionId': sessionId,
        'gameResults': gameResults,
        'timestamp': DateTime.now().toIso8601String(),
      },
    ));
  }

  @override
  Future<void> broadcastGameStateUpdate(String sessionId, Map<String, dynamic> gameState) async {
    await lanService.broadcastNetworkMessage(NetworkMessage(
      type: NetworkMessageTypes.gameStateSync,
      senderId: 'server',
      data: {
        'sessionId': sessionId,
        'gameState': gameState,
        'timestamp': DateTime.now().toIso8601String(),
      },
    ));
  }

  @override
  Future<List<GameSession>> getActiveSessions() async {
    return _activeSessions.values
        .where((session) => session.status == GameSessionStatus.active || 
                           session.status == GameSessionStatus.initializing)
        .toList();
  }

  @override
  Future<void> cleanupFinishedSessions() async {
    final finishedSessions = _activeSessions.entries
        .where((entry) => entry.value.status == GameSessionStatus.finished)
        .toList();

    for (final entry in finishedSessions) {
      // Dispose game instance
      entry.value.gameInstance.dispose();
      
      // Remove from active sessions
      _activeSessions.remove(entry.key);
    }
  }
}