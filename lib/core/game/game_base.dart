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

/// Metadata for a game type including display information and requirements
class GameMetadata {
  final String gameType;
  final String displayName;
  final String description;
  final int minPlayers;
  final int maxPlayers;
  final Duration estimatedDuration;
  final List<String> requiredPermissions;
  final Map<String, dynamic> defaultConfig;
  final String? iconPath;
  final List<String> tags;

  const GameMetadata({
    required this.gameType,
    required this.displayName,
    required this.description,
    required this.minPlayers,
    required this.maxPlayers,
    required this.estimatedDuration,
    this.requiredPermissions = const [],
    this.defaultConfig = const {},
    this.iconPath,
    this.tags = const [],
  });

  /// Create a copy with updated values
  GameMetadata copyWith({
    String? gameType,
    String? displayName,
    String? description,
    int? minPlayers,
    int? maxPlayers,
    Duration? estimatedDuration,
    List<String>? requiredPermissions,
    Map<String, dynamic>? defaultConfig,
    String? iconPath,
    List<String>? tags,
  }) {
    return GameMetadata(
      gameType: gameType ?? this.gameType,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      minPlayers: minPlayers ?? this.minPlayers,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      requiredPermissions: requiredPermissions ?? this.requiredPermissions,
      defaultConfig: defaultConfig ?? this.defaultConfig,
      iconPath: iconPath ?? this.iconPath,
      tags: tags ?? this.tags,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'gameType': gameType,
      'displayName': displayName,
      'description': description,
      'minPlayers': minPlayers,
      'maxPlayers': maxPlayers,
      'estimatedDurationMinutes': estimatedDuration.inMinutes,
      'requiredPermissions': requiredPermissions,
      'defaultConfig': defaultConfig,
      'iconPath': iconPath,
      'tags': tags,
    };
  }

  /// Create from JSON
  factory GameMetadata.fromJson(Map<String, dynamic> json) {
    return GameMetadata(
      gameType: json['gameType'] as String,
      displayName: json['displayName'] as String,
      description: json['description'] as String,
      minPlayers: json['minPlayers'] as int,
      maxPlayers: json['maxPlayers'] as int,
      estimatedDuration: Duration(minutes: json['estimatedDurationMinutes'] as int),
      requiredPermissions: List<String>.from(json['requiredPermissions'] ?? []),
      defaultConfig: Map<String, dynamic>.from(json['defaultConfig'] ?? {}),
      iconPath: json['iconPath'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}

/// Enhanced game registry for managing different game types with metadata
class GameRegistry {
  static final Map<String, GameBase Function()> _gameFactories = {};
  static final Map<String, GameMetadata> _gameMetadata = {};
  
  /// Register a game type with its factory function
  static void registerGame<T extends GameBase>(String gameType, T Function() factory) {
    _gameFactories[gameType] = factory;
  }

  /// Register a game type with its factory function and metadata
  static void registerGameWithMetadata<T extends GameBase>(
    String gameType, 
    T Function() factory,
    GameMetadata metadata
  ) {
    if (gameType != metadata.gameType) {
      throw ArgumentError('Game type mismatch: $gameType != ${metadata.gameType}');
    }
    
    _gameFactories[gameType] = factory;
    _gameMetadata[gameType] = metadata;
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

  /// Get all available games with metadata
  static List<GameMetadata> getAvailableGames() {
    return _gameMetadata.values.toList();
  }

  /// Get metadata for a specific game type
  static GameMetadata? getGameMetadata(String gameType) {
    return _gameMetadata[gameType];
  }

  /// Get games filtered by player count
  static List<GameMetadata> getGamesForPlayerCount(int playerCount) {
    return _gameMetadata.values
        .where((metadata) => 
            playerCount >= metadata.minPlayers && 
            playerCount <= metadata.maxPlayers)
        .toList();
  }

  /// Get games filtered by tags
  static List<GameMetadata> getGamesByTags(List<String> tags) {
    return _gameMetadata.values
        .where((metadata) => 
            tags.any((tag) => metadata.tags.contains(tag)))
        .toList();
  }

  /// Get games filtered by estimated duration
  static List<GameMetadata> getGamesByDuration(Duration maxDuration) {
    return _gameMetadata.values
        .where((metadata) => metadata.estimatedDuration <= maxDuration)
        .toList();
  }
  
  /// Check if a game type is registered
  static bool isGameTypeSupported(String gameType) {
    return _gameFactories.containsKey(gameType);
  }

  /// Check if a game has metadata registered
  static bool hasGameMetadata(String gameType) {
    return _gameMetadata.containsKey(gameType);
  }

  /// Validate if a game can be played with given player count
  static bool canPlayWithPlayerCount(String gameType, int playerCount) {
    final metadata = _gameMetadata[gameType];
    if (metadata == null) return false;
    
    return playerCount >= metadata.minPlayers && playerCount <= metadata.maxPlayers;
  }
  
  /// Clear all registered games (for testing only)
  static void clearRegistry() {
    _gameFactories.clear();
    _gameMetadata.clear();
  }

  /// Clear only metadata (for testing only)
  static void clearMetadata() {
    _gameMetadata.clear();
  }
}
