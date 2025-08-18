import '../../../../core/game/game_base.dart';
import '../repositories/game_session_repository.dart';

class ProcessGameAction {
  final GameSessionRepository repository;

  ProcessGameAction(this.repository);

  Future<GameActionResult> call(String playerId, GameAction action) async {
    // Get current active session
    final session = await repository.getCurrentSession();
    if (session == null) {
      return GameActionResult.error('No active game session');
    }

    // Validate player is in the session
    if (!session.playerIds.contains(playerId)) {
      return GameActionResult.error('Player not in current game session');
    }

    // Process the action through the game instance
    final result = await session.gameInstance.processAction(playerId, action);

    // If successful, broadcast the action and result to other players
    if (result.success) {
      await repository.broadcastGameAction(
        sessionId: session.sessionId,
        playerId: playerId,
        action: action,
        result: result,
      );

      // Update session state if needed
      await repository.updateSessionState(
        session.sessionId,
        session.gameInstance.gameState,
      );
    }

    return result;
  }
}