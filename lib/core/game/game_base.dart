import 'dart:async';

/// Abstract base class for all party games
abstract class GameBase {
  String get gameId;
  String get gameName;
  String get gameType;
  int get minPlayers;
  int get maxPlayers;
  
  /// Current game state as a JSON-serializable map
  Map<String, dynamic> get gameState;
  
  /// Stream of game events for real-time updates
  Stream<GameEvent> get gameEvents;
  
  /// Initialize the game with players
  Future<void> initializeGame(List<String> playerIds);
  
  /// Process a game action from a player
  Future<GameActionResult> processAction(String playerId, GameAction action);
  
  /// Start the game
  Future<void> startGame();
  
  /// End the game
  Future<void> endGame();
  
  /// Check if the game is finished
  bool get isGameFinished;
  
  /// Get current game results/scores
  Map<String, dynamic> get gameResults;
  
  /// Cleanup resources
  void dispose();
}

/// Represents a game action from a player
abstract class GameAction {
  String get type;
  String get playerId;
  Map<String, dynamic> get data;
  DateTime get timestamp;
}

/// Result of processing a game action
class GameActionResult {
  final bool success;
  final String? errorMessage;
  final Map<String, dynamic>? resultData;
  
  const GameActionResult({
    required this.success,
    this.errorMessage,
    this.resultData,
  });
  
  factory GameActionResult.success([Map<String, dynamic>? data]) {
    return GameActionResult(success: true, resultData: data);
  }
  
  factory GameActionResult.error(String message) {
    return GameActionResult(success: false, errorMessage: message);
  }
}

/// Represents a game event for broadcasting to clients
abstract class GameEvent {
  String get type;
  String get gameId;
  Map<String, dynamic> get data;
  DateTime get timestamp;
  List<String>? get targetPlayerIds; // null means broadcast to all
}

/// Basic implementation of GameEvent
class BasicGameEvent implements GameEvent {
  @override
  final String type;
  
  @override
  final String gameId;
  
  @override
  final Map<String, dynamic> data;
  
  @override
  final DateTime timestamp;
  
  @override
  final List<String>? targetPlayerIds;
  
  BasicGameEvent({
    required this.type,
    required this.gameId,
    required this.data,
    DateTime? timestamp,
    this.targetPlayerIds,
  }) : timestamp = timestamp ?? DateTime.now();
  
  BasicGameEvent copyWith({
    String? type,
    String? gameId,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    List<String>? targetPlayerIds,
  }) {
    return BasicGameEvent(
      type: type ?? this.type,
      gameId: gameId ?? this.gameId,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      targetPlayerIds: targetPlayerIds ?? this.targetPlayerIds,
    );
  }
}

/// Basic implementation of GameAction
class BasicGameAction implements GameAction {
  @override
  final String type;
  
  @override
  final String playerId;
  
  @override
  final Map<String, dynamic> data;
  
  @override
  final DateTime timestamp;
  
  BasicGameAction({
    required this.type,
    required this.playerId,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Game registry for managing different game types
class GameRegistry {
  static final Map<String, GameBase Function()> _gameFactories = {};
  
  /// Register a game type with its factory function
  static void registerGame<T extends GameBase>(String gameType, T Function() factory) {
    _gameFactories[gameType] = factory;
  }
  
  /// Create a game instance by type
  static GameBase? createGame(String gameType) {
    final factory = _gameFactories[gameType];
    return factory?.call();
  }
  
  /// Get all registered game types
  static List<String> getAvailableGameTypes() {
    return _gameFactories.keys.toList();
  }
  
  /// Check if a game type is registered
  static bool isGameTypeSupported(String gameType) {
    return _gameFactories.containsKey(gameType);
  }
  
  /// Clear all registered games (for testing only)
  static void clearRegistry() {
    _gameFactories.clear();
  }
}
