abstract class GameConfig {
  String get gameType;
  String get displayName;
  String get description;
  int get minPlayers;
  int get maxPlayers;
  Duration get estimatedDuration;
  Map<String, dynamic> get defaultSettings;
}

abstract class GameState {
  String get gameId;
  String get gameType;
  List<String> get playerIds;
  Map<String, dynamic> get data;
  DateTime get lastUpdated;
}

abstract class GameAction {
  String get type;
  String get playerId;
  Map<String, dynamic> get data;
  DateTime get timestamp;
}

abstract class GameEngine {
  GameConfig get config;
  GameState get currentState;
  Stream<GameState> get stateStream;
  
  Future<void> initializeGame(List<String> playerIds, Map<String, dynamic> settings);
  Future<GameState> processAction(GameAction action);
  Future<void> pauseGame();
  Future<void> resumeGame();
  Future<void> endGame();
  bool isValidAction(GameAction action);
}
