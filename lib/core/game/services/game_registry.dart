import '../models/game_models.dart';

abstract class GameRegistry {
  List<GameConfig> get availableGames;
  GameConfig? getGameConfig(String gameType);
  GameEngine createGameEngine(String gameType);
}

class GameRegistryImpl implements GameRegistry {
  final Map<String, GameConfig> _games = {};
  final Map<String, GameEngine Function()> _engineFactories = {};

  @override
  List<GameConfig> get availableGames => _games.values.toList();

  @override
  GameConfig? getGameConfig(String gameType) => _games[gameType];

  @override
  GameEngine createGameEngine(String gameType) {
    final factory = _engineFactories[gameType];
    if (factory == null) {
      throw ArgumentError('Game type "$gameType" not registered');
    }
    return factory();
  }

  void registerGame(GameConfig config, GameEngine Function() engineFactory) {
    _games[config.gameType] = config;
    _engineFactories[config.gameType] = engineFactory;
  }

  void unregisterGame(String gameType) {
    _games.remove(gameType);
    _engineFactories.remove(gameType);
  }
}
