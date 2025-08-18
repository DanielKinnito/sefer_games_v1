import '../../../../core/game/game_base.dart';
import '../entities/game_session.dart';

abstract class GameSessionRepository {
  /// Create a new game session
  Future<GameSession> createGameSession({
    required String lobbyId,
    required String gameType,
    required List<String> playerIds,
    required GameBase gameInstance,
  });

  /// Get a specific game session by ID
  Future<GameSession?> getSession(String sessionId);

  /// Get the current active session (if any)
  Future<GameSession?> getCurrentSession();

  /// Update session state
  Future<void> updateSessionState(String sessionId, Map<String, dynamic> gameState);

  /// End a game session
  Future<void> endSession(String sessionId, Map<String, dynamic> gameResults);

  /// Broadcast game action to all players in session
  Future<void> broadcastGameAction({
    required String sessionId,
    required String playerId,
    required GameAction action,
    required GameActionResult result,
  });

  /// Broadcast game end to all players
  Future<void> broadcastGameEnd(String sessionId, Map<String, dynamic> gameResults);

  /// Broadcast game state update to all players
  Future<void> broadcastGameStateUpdate(String sessionId, Map<String, dynamic> gameState);

  /// Get all active sessions
  Future<List<GameSession>> getActiveSessions();

  /// Clean up finished sessions
  Future<void> cleanupFinishedSessions();
}