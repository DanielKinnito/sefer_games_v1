import '../entities/game_session.dart';
import '../repositories/game_session_repository.dart';

class EndGameSession {
  final GameSessionRepository repository;

  EndGameSession(this.repository);

  Future<void> call(String sessionId) async {
    final session = await repository.getSession(sessionId);
    if (session == null) {
      throw Exception('Game session not found: $sessionId');
    }

    // End the game instance
    await session.gameInstance.endGame();

    // Get final results
    final gameResults = session.gameInstance.gameResults;

    // Update session status and results
    await repository.endSession(sessionId, gameResults);

    // Broadcast game end to all players
    await repository.broadcastGameEnd(sessionId, gameResults);

    // Clean up resources
    session.gameInstance.dispose();
  }
}