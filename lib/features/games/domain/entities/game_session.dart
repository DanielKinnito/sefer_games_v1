import '../../../../core/game/game_base.dart';

enum GameSessionStatus { 
  initializing, 
  active, 
  paused, 
  finished,
  error 
}

abstract class GameSession {
  String get sessionId;
  String get lobbyId;
  String get gameType;
  List<String> get playerIds;
  GameBase get gameInstance;
  DateTime get startedAt;
  GameSessionStatus get status;
  DateTime? get endedAt;
  Map<String, dynamic>? get gameResults;
}

class GameSessionEntity implements GameSession {
  @override
  final String sessionId;
  
  @override
  final String lobbyId;
  
  @override
  final String gameType;
  
  @override
  final List<String> playerIds;
  
  @override
  final GameBase gameInstance;
  
  @override
  final DateTime startedAt;
  
  @override
  final GameSessionStatus status;
  
  @override
  final DateTime? endedAt;
  
  @override
  final Map<String, dynamic>? gameResults;

  GameSessionEntity({
    required this.sessionId,
    required this.lobbyId,
    required this.gameType,
    required this.playerIds,
    required this.gameInstance,
    DateTime? startedAt,
    this.status = GameSessionStatus.initializing,
    this.endedAt,
    this.gameResults,
  }) : startedAt = startedAt ?? DateTime.now();

  GameSessionEntity copyWith({
    String? sessionId,
    String? lobbyId,
    String? gameType,
    List<String>? playerIds,
    GameBase? gameInstance,
    DateTime? startedAt,
    GameSessionStatus? status,
    DateTime? endedAt,
    Map<String, dynamic>? gameResults,
  }) {
    return GameSessionEntity(
      sessionId: sessionId ?? this.sessionId,
      lobbyId: lobbyId ?? this.lobbyId,
      gameType: gameType ?? this.gameType,
      playerIds: playerIds ?? this.playerIds,
      gameInstance: gameInstance ?? this.gameInstance,
      startedAt: startedAt ?? this.startedAt,
      status: status ?? this.status,
      endedAt: endedAt ?? this.endedAt,
      gameResults: gameResults ?? this.gameResults,
    );
  }
}