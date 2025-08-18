import 'dart:async';
import '../../../../core/game/game_base.dart';
import 'lan_service.dart';

/// Manages game sessions and bridges lobby system with game instances
class GameSessionManager {
  static final GameSessionManager _instance = GameSessionManager._internal();
  factory GameSessionManager() => _instance;
  GameSessionManager._internal();

  final Map<String, GameSession> _activeSessions = {};
  final StreamController<GameEvent> _gameEventController = StreamController.broadcast();
  final LanService _lanService = LanService();

  /// Stream of game events f