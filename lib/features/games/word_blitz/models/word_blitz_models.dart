import '../../../../core/game/game_base.dart';
import '../../../../core/game/game_selection_manager.dart';

/// Word Blitz specific game state
class WordBlitzState {
  final String gameId;
  final String currentTheme;
  final String? currentLetter;
  final List<PlayerStatus> players;
  final int currentRound;
  final bool isRoundActive;
  final String? winner;
  final DateTime? roundStartTime;
  final int roundsToWin;
  final Duration roundTimeout;
  final List<String> availableThemes;
  final bool allowCustomThemes;

  const WordBlitzState({
    required this.gameId,
    required this.currentTheme,
    this.currentLetter,
    required this.players,
    required this.currentRound,
    required this.isRoundActive,
    this.winner,
    this.roundStartTime,
    required this.roundsToWin,
    required this.roundTimeout,
    required this.availableThemes,
    required this.allowCustomThemes,
  });

  /// Create initial state
  factory WordBlitzState.initial({
    required String gameId,
    required List<String> playerIds,
    required List<String> playerNames,
    required int roundsToWin,
    required Duration roundTimeout,
    required List<String> availableThemes,
    required bool allowCustomThemes,
  }) {
    final players = playerIds.asMap().entries.map((entry) {
      final index = entry.key;
      final playerId = entry.value;
      final playerName = index < playerNames.length ? playerNames[index] : 'Player ${index + 1}';
      
      return PlayerStatus(
        playerId: playerId,
        playerName: playerName,
        isActive: true,
        isEliminated: false,
        roundsWon: 0,
      );
    }).toList();

    return WordBlitzState(
      gameId: gameId,
      currentTheme: '',
      currentLetter: null,
      players: players,
      currentRound: 0,
      isRoundActive: false,
      winner: null,
      roundStartTime: null,
      roundsToWin: roundsToWin,
      roundTimeout: roundTimeout,
      availableThemes: availableThemes,
      allowCustomThemes: allowCustomThemes,
    );
  }

  /// Create a copy with updated values
  WordBlitzState copyWith({
    String? gameId,
    String? currentTheme,
    String? currentLetter,
    List<PlayerStatus>? players,
    int? currentRound,
    bool? isRoundActive,
    String? winner,
    DateTime? roundStartTime,
    int? roundsToWin,
    Duration? roundTimeout,
    List<String>? availableThemes,
    bool? allowCustomThemes,
  }) {
    return WordBlitzState(
      gameId: gameId ?? this.gameId,
      currentTheme: currentTheme ?? this.currentTheme,
      currentLetter: currentLetter ?? this.currentLetter,
      players: players ?? this.players,
      currentRound: currentRound ?? this.currentRound,
      isRoundActive: isRoundActive ?? this.isRoundActive,
      winner: winner ?? this.winner,
      roundStartTime: roundStartTime ?? this.roundStartTime,
      roundsToWin: roundsToWin ?? this.roundsToWin,
      roundTimeout: roundTimeout ?? this.roundTimeout,
      availableThemes: availableThemes ?? this.availableThemes,
      allowCustomThemes: allowCustomThemes ?? this.allowCustomThemes,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'currentTheme': currentTheme,
      'currentLetter': currentLetter,
      'players': players.map((p) => p.toJson()).toList(),
      'currentRound': currentRound,
      'isRoundActive': isRoundActive,
      'winner': winner,
      'roundStartTime': roundStartTime?.toIso8601String(),
      'roundsToWin': roundsToWin,
      'roundTimeoutMinutes': roundTimeout.inMinutes,
      'availableThemes': availableThemes,
      'allowCustomThemes': allowCustomThemes,
    };
  }

  /// Create from JSON
  factory WordBlitzState.fromJson(Map<String, dynamic> json) {
    return WordBlitzState(
      gameId: json['gameId'] as String,
      currentTheme: json['currentTheme'] as String? ?? '',
      currentLetter: json['currentLetter'] as String?,
      players: (json['players'] as List<dynamic>?)
          ?.map((p) => PlayerStatus.fromJson(p as Map<String, dynamic>))
          .toList() ?? [],
      currentRound: json['currentRound'] as int? ?? 0,
      isRoundActive: json['isRoundActive'] as bool? ?? false,
      winner: json['winner'] as String?,
      roundStartTime: json['roundStartTime'] != null
          ? DateTime.parse(json['roundStartTime'] as String)
          : null,
      roundsToWin: json['roundsToWin'] as int? ?? 3,
      roundTimeout: Duration(minutes: json['roundTimeoutMinutes'] as int? ?? 2),
      availableThemes: List<String>.from(json['availableThemes'] ?? []),
      allowCustomThemes: json['allowCustomThemes'] as bool? ?? false,
    );
  }

  /// Get active players
  List<PlayerStatus> get activePlayers => players.where((p) => p.isActive).toList();

  /// Get eliminated players
  List<PlayerStatus> get eliminatedPlayers => players.where((p) => p.isEliminated).toList();

  /// Get player by ID
  PlayerStatus? getPlayer(String playerId) {
    try {
      return players.firstWhere((p) => p.playerId == playerId);
    } catch (e) {
      return null;
    }
  }

  /// Check if game is finished
  bool get isGameFinished => winner != null;

  /// Get remaining time for current round
  Duration? get remainingTime {
    if (!isRoundActive || roundStartTime == null) return null;
    
    final elapsed = DateTime.now().difference(roundStartTime!);
    final remaining = roundTimeout - elapsed;
    
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Get leaderboard sorted by rounds won
  List<PlayerStatus> get leaderboard {
    final sortedPlayers = List<PlayerStatus>.from(players);
    sortedPlayers.sort((a, b) => b.roundsWon.compareTo(a.roundsWon));
    return sortedPlayers;
  }
}

/// Player status in Word Blitz game
class PlayerStatus {
  final String playerId;
  final String playerName;
  final bool isActive;
  final bool isEliminated;
  final int roundsWon;

  const PlayerStatus({
    required this.playerId,
    required this.playerName,
    required this.isActive,
    required this.isEliminated,
    required this.roundsWon,
  });

  /// Create a copy with updated values
  PlayerStatus copyWith({
    String? playerId,
    String? playerName,
    bool? isActive,
    bool? isEliminated,
    int? roundsWon,
  }) {
    return PlayerStatus(
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      isActive: isActive ?? this.isActive,
      isEliminated: isEliminated ?? this.isEliminated,
      roundsWon: roundsWon ?? this.roundsWon,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'playerName': playerName,
      'isActive': isActive,
      'isEliminated': isEliminated,
      'roundsWon': roundsWon,
    };
  }

  /// Create from JSON
  factory PlayerStatus.fromJson(Map<String, dynamic> json) {
    return PlayerStatus(
      playerId: json['playerId'] as String,
      playerName: json['playerName'] as String,
      isActive: json['isActive'] as bool? ?? true,
      isEliminated: json['isEliminated'] as bool? ?? false,
      roundsWon: json['roundsWon'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayerStatus && other.playerId == playerId;
  }

  @override
  int get hashCode => playerId.hashCode;

  @override
  String toString() {
    return 'PlayerStatus(playerId: $playerId, playerName: $playerName, isActive: $isActive, isEliminated: $isEliminated, roundsWon: $roundsWon)';
  }
}

/// Word Blitz specific configuration
class WordBlitzConfig extends GameConfig {
  final List<String> availableThemes;
  final int roundsToWin;
  final Duration roundTimeout;
  final bool allowCustomThemes;

  WordBlitzConfig({
    required List<String> playerIds,
    required String hostId,
    required this.availableThemes,
    required this.roundsToWin,
    required this.roundTimeout,
    required this.allowCustomThemes,
    DateTime? createdAt,
  }) : super(
          gameType: 'word_blitz',
          playerIds: playerIds,
          hostId: hostId,
          settings: {
            'availableThemes': availableThemes,
            'roundsToWin': roundsToWin,
            'roundTimeoutMinutes': roundTimeout.inMinutes,
            'allowCustomThemes': allowCustomThemes,
          },
          createdAt: createdAt,
        );

  /// Create from GameConfig
  factory WordBlitzConfig.fromGameConfig(GameConfig config) {
    if (config.gameType != 'word_blitz') {
      throw ArgumentError('Invalid game type: ${config.gameType}');
    }

    return WordBlitzConfig(
      playerIds: config.playerIds,
      hostId: config.hostId,
      availableThemes: List<String>.from(config.settings['availableThemes'] ?? []),
      roundsToWin: config.settings['roundsToWin'] as int? ?? 3,
      roundTimeout: Duration(minutes: config.settings['roundTimeoutMinutes'] as int? ?? 2),
      allowCustomThemes: config.settings['allowCustomThemes'] as bool? ?? false,
      createdAt: config.createdAt,
    );
  }

  /// Create default configuration
  factory WordBlitzConfig.defaultConfig({
    required List<String> playerIds,
    required String hostId,
  }) {
    return WordBlitzConfig(
      playerIds: playerIds,
      hostId: hostId,
      availableThemes: [
        'Countries',
        'Famous People',
        'Capital Cities',
        'Movies',
        'TV Series',
        'Animals',
        'Food',
        'Sports',
      ],
      roundsToWin: 3,
      roundTimeout: Duration(minutes: 2),
      allowCustomThemes: false,
    );
  }

  @override
  WordBlitzConfig copyWith({
    String? gameType,
    Map<String, dynamic>? settings,
    List<String>? playerIds,
    String? hostId,
    DateTime? createdAt,
  }) {
    return WordBlitzConfig(
      playerIds: playerIds ?? this.playerIds,
      hostId: hostId ?? this.hostId,
      availableThemes: settings != null 
          ? List<String>.from(settings['availableThemes'] ?? availableThemes)
          : availableThemes,
      roundsToWin: settings?['roundsToWin'] as int? ?? roundsToWin,
      roundTimeout: settings != null
          ? Duration(minutes: settings['roundTimeoutMinutes'] as int? ?? roundTimeout.inMinutes)
          : roundTimeout,
      allowCustomThemes: settings?['allowCustomThemes'] as bool? ?? allowCustomThemes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Word Blitz specific events
enum WordBlitzEventType {
  themeSelected,
  letterGenerated,
  playerEliminated,
  roundStarted,
  roundEnded,
  roundWon,
  roundTimeout,
  gameWon,
  customThemeAdded,
}

/// Word Blitz game event
class WordBlitzEvent extends BasicGameEvent {
  final WordBlitzEventType wordBlitzType;

  WordBlitzEvent({
    required this.wordBlitzType,
    required String gameId,
    required Map<String, dynamic> data,
    DateTime? timestamp,
    List<String>? targetPlayerIds,
  }) : super(
          type: wordBlitzType.toString().split('.').last,
          gameId: gameId,
          data: data,
          timestamp: timestamp,
          targetPlayerIds: targetPlayerIds,
        );

  /// Create theme selected event
  factory WordBlitzEvent.themeSelected({
    required String gameId,
    required String theme,
    required String selectedBy,
  }) {
    return WordBlitzEvent(
      wordBlitzType: WordBlitzEventType.themeSelected,
      gameId: gameId,
      data: {
        'theme': theme,
        'selectedBy': selectedBy,
      },
    );
  }

  /// Create letter generated event
  factory WordBlitzEvent.letterGenerated({
    required String gameId,
    required String letter,
    required String theme,
    required String generatedBy,
  }) {
    return WordBlitzEvent(
      wordBlitzType: WordBlitzEventType.letterGenerated,
      gameId: gameId,
      data: {
        'letter': letter,
        'theme': theme,
        'generatedBy': generatedBy,
      },
    );
  }

  /// Create player eliminated event
  factory WordBlitzEvent.playerEliminated({
    required String gameId,
    required String eliminatedPlayer,
    required String eliminatedBy,
    required List<String> activePlayers,
    required List<String> eliminatedPlayers,
  }) {
    return WordBlitzEvent(
      wordBlitzType: WordBlitzEventType.playerEliminated,
      gameId: gameId,
      data: {
        'eliminatedPlayer': eliminatedPlayer,
        'eliminatedBy': eliminatedBy,
        'activePlayers': activePlayers,
        'eliminatedPlayers': eliminatedPlayers,
      },
    );
  }

  /// Create round started event
  factory WordBlitzEvent.roundStarted({
    required String gameId,
    required int round,
    required String theme,
    required DateTime startTime,
    required int timeoutMinutes,
  }) {
    return WordBlitzEvent(
      wordBlitzType: WordBlitzEventType.roundStarted,
      gameId: gameId,
      data: {
        'round': round,
        'theme': theme,
        'startTime': startTime.toIso8601String(),
        'timeoutMinutes': timeoutMinutes,
      },
    );
  }

  /// Create round won event
  factory WordBlitzEvent.roundWon({
    required String gameId,
    required String winner,
    required int round,
    required Map<String, int> playerWins,
  }) {
    return WordBlitzEvent(
      wordBlitzType: WordBlitzEventType.roundWon,
      gameId: gameId,
      data: {
        'winner': winner,
        'round': round,
        'playerWins': playerWins,
      },
    );
  }

  /// Create game won event
  factory WordBlitzEvent.gameWon({
    required String gameId,
    required String winner,
    required Map<String, int> playerWins,
    required int totalRounds,
  }) {
    return WordBlitzEvent(
      wordBlitzType: WordBlitzEventType.gameWon,
      gameId: gameId,
      data: {
        'winner': winner,
        'playerWins': playerWins,
        'totalRounds': totalRounds,
      },
    );
  }
}