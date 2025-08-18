import '../../../../core/game/game_base.dart';
import '../../../lobby/domain/entities/lobby.dart';
import '../entities/game_session.dart';
import '../repositories/game_session_repository.dart';

class StartGameSession {
  final GameSessionRepository repository;

  StartGameSession(this.repository);

  Future<GameSession> call(Lobby lobby) async {
    // Validate minimum players
    if (lobby.players.length < 2) {
      throw Exception('Not enough players to start game. Minimum 2 players required.');
    }

    // Get game instance from registry
    final gameInstance = GameRegistry.createGame(lobby.gameType);
    if (gameInstance == null) {
      throw Exception('Unsupported game type: ${lobby.gameType}');
    }

    // Validate player count for this game type
    if (lobby.players.length < gameInstance.minPlayers) {
      throw Exception('Not enough players for ${lobby.gameType}. Minimum ${gameInstance.minPlayers} required.');
    }

    if (lobby.players.length > gameInstance.maxPlayers) {
      throw Exception('Too many players for ${lobby.gameType}. Maximum ${gameInstance.maxPlayers} allowed.');
    }

    // Create game session
    final session = await repository.createGameSession(
      lobbyId: lobby.id,
      gameType: lobby.gameType,
      playerIds: lobby.players.map((p) => p.id).toList(),
      gameInstance: gameInstance,
    );

    // Initialize the game with player IDs
    await gameInstance.initializeGame(session.playerIds);

    // Start the game
    await gameInstance.startGame();

    return session;
  }
}