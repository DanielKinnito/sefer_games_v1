import 'dart:async';
import '../../../../core/game/game_base.dart';
import 'lan_service.dart';

/// Represents an active game session
class GameSession {
  final String sessionId;
  final String lobbyId;
  final GameBase game;
  final DateTime createdAt;

  GameSession({
    required this.sessionId,
    required this.lobbyId,
    required this.game,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

/// Manages game sessions and bridges lobby system with game instances
class GameSessionManager {
  static final GameSessionManager _instance = GameSessionManager._internal();
  factory GameSessionManager() => _instance;
  GameSessionManager._internal();

  final Map<String, GameSession> _activeSessions = {};
  final StreamController<GameEvent> _gameEventController = StreamController.broadcast();
  final LanService _lanService = LanService();

  /// Stream of game events from all active sessions
  Stream<GameEvent> get gameEvents => _gameEventController.stream;

  /// Create a new game session
  Future<GameSession?> createSession({
    required String lobbyId,
    required String gameType,
    required List<String> playerIds,
  }) async {
    try {
      final game = GameRegistry.createGame(gameType);
      if (game == null) {
        return null;
      }

      await game.initializeGame(playerIds);
      
      final session = GameSession(
        sessionId: 'session_${DateTime.now().millisecondsSinceEpoch}',
        lobbyId: lobbyId,
        game: game,
      );

      _activeSessions[session.sessionId] = session;
      
      // Listen to game events and forward them
      game.gameEvents.listen((event) {
        _gameEventController.add(event);
      });

      return session;
    } catch (e) {
      return null;
    }
  }

  /// Get an active session by ID
  GameSession? getSession(String sessionId) {
    return _activeSessions[sessionId];
  }

  /// Get session by lobby ID
  GameSession? getSessionByLobby(String lobbyId) {
    return _activeSessions.values
        .where((session) => session.lobbyId == lobbyId)
        .firstOrNull;
  }

  /// End a game session
  Future<void> endSession(String sessionId) async {
    final session = _activeSessions[sessionId];
    if (session != null) {
      await session.game.endGame();
      session.game.dispose();
      _activeSessions.remove(sessionId);
    }
  }

  /// Get all active sessions
  List<GameSession> get activeSessions => _activeSessions.values.toList();

  /// Dispose the manager
  void dispose() {
    for (final session in _activeSessions.values) {
      session.game.dispose();
    }
    _activeSessions.clear();
    _gameEventController.close();
  }
}