import '../../../../core/game/game_base.dart';
import '../../../../core/game/game_selection_manager.dart';
import '../mafia_game.dart';

/// Mafia game state
class MafiaState {
  final String gameId;
  final Map<String, PlayerRole> playerRoles;
  final List<MafiaPlayerStatus> players;
  final GamePhase currentPhase;
  final int currentDay;
  final bool isGameFinished;
  final String? winner;
  final Map<String, String> votes;
  final Map<String, int> voteCounts;
  final MafiaConfig config;

  const MafiaState({
    required this.gameId,
    required this.playerRoles,
    required this.players,
    required this.currentPhase,
    required this.currentDay,
    required this.isGameFinished,
    this.winner,
    required this.votes,
    required this.voteCounts,
    required this.config,
  });

  /// Create initial state
  factory MafiaState.initial({
    required String gameId,
    required List<String> playerIds,
    required List<String> playerNames,
    required MafiaConfig config,
  }) {
    final players = playerIds.asMap().entries.map((entry) {
      final index = entry.key;
      final playerId = entry.value;
      final playerName = index < playerNames.length ? playerNames[index] : 'Player ${index + 1}';
      
      return MafiaPlayerStatus(
        playerId: playerId,
        playerName: playerName,
        role: PlayerRole.civilian, // Will be assigned later
        isAlive: true,
        votedBy: [],
      );
    }).toList();

    return MafiaState(
      gameId: gameId,
      playerRoles: {},
      players: players,
      currentPhase: GamePhase.setup,
      currentDay: 0,
      isGameFinished: false,
      winner: null,
      votes: {},
      voteCounts: {},
      config: config,
    );
  }

  /// Create a copy with updated values
  MafiaState copyWith({
    String? gameId,
    Map<String, PlayerRole>? playerRoles,
    List<MafiaPlayerStatus>? players,
    GamePhase? currentPhase,
    int? currentDay,
    bool? isGameFinished,
    String? winner,
    Map<String, String>? votes,
    Map<String, int>? voteCounts,
    MafiaConfig? config,
  }) {
    return MafiaState(
      gameId: gameId ?? this.gameId,
      playerRoles: playerRoles ?? this.playerRoles,
      players: players ?? this.players,
      currentPhase: currentPhase ?? this.currentPhase,
      currentDay: currentDay ?? this.currentDay,
      isGameFinished: isGameFinished ?? this.isGameFinished,
      winner: winner ?? this.winner,
      votes: votes ?? this.votes,
      voteCounts: voteCounts ?? this.voteCounts,
      config: config ?? this.config,
    );
  }

  /// Get alive players
  List<MafiaPlayerStatus> get alivePlayers => players.where((p) => p.isAlive).toList();

  /// Get dead players
  List<MafiaPlayerStatus> get deadPlayers => players.where((p) => !p.isAlive).toList();

  /// Get players by role
  List<MafiaPlayerStatus> getPlayersByRole(PlayerRole role) {
    return players.where((p) => playerRoles[p.playerId] == role).toList();
  }

  /// Get player by ID
  MafiaPlayerStatus? getPlayer(String playerId) {
    try {
      return players.firstWhere((p) => p.playerId == playerId);
    } catch (e) {
      return null;
    }
  }

  /// Get player role
  PlayerRole? getPlayerRole(String playerId) {
    return playerRoles[playerId];
  }
}

/// Player status in Mafia game
class MafiaPlayerStatus {
  final String playerId;
  final String playerName;
  final PlayerRole role;
  final bool isAlive;
  final List<String> votedBy;
  final bool hasVoted;
  final bool hasActed; // For night actions

  const MafiaPlayerStatus({
    required this.playerId,
    required this.playerName,
    required this.role,
    required this.isAlive,
    required this.votedBy,
    this.hasVoted = false,
    this.hasActed = false,
  });

  /// Create a copy with updated values
  MafiaPlayerStatus copyWith({
    String? playerId,
    String? playerName,
    PlayerRole? role,
    bool? isAlive,
    List<String>? votedBy,
    bool? hasVoted,
    bool? hasActed,
  }) {
    return MafiaPlayerStatus(
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      role: role ?? this.role,
      isAlive: isAlive ?? this.isAlive,
      votedBy: votedBy ?? this.votedBy,
      hasVoted: hasVoted ?? this.hasVoted,
      hasActed: hasActed ?? this.hasActed,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MafiaPlayerStatus && other.playerId == playerId;
  }

  @override
  int get hashCode => playerId.hashCode;

  @override
  String toString() {
    return 'MafiaPlayerStatus(playerId: $playerId, playerName: $playerName, role: $role, isAlive: $isAlive)';
  }
}

/// Mafia game configuration
class MafiaConfig extends GameConfig {
  final int mafiaCount;
  final int policeCount;
  final int doctorCount;
  final int jokerCount;
  final bool doctorCanSaveSamePerson;
  final bool doctorCanSaveSelf;
  final Duration dayDuration;
  final Duration nightDuration;
  final Duration votingDuration;

  MafiaConfig({
    required List<String> playerIds,
    required String hostId,
    required this.mafiaCount,
    required this.policeCount,
    required this.doctorCount,
    required this.jokerCount,
    required this.doctorCanSaveSamePerson,
    required this.doctorCanSaveSelf,
    required this.dayDuration,
    required this.nightDuration,
    required this.votingDuration,
    DateTime? createdAt,
  }) : super(
          gameType: 'mafia',
          playerIds: playerIds,
          hostId: hostId,
          settings: {
            'mafiaCount': mafiaCount,
            'policeCount': policeCount,
            'doctorCount': doctorCount,
            'jokerCount': jokerCount,
            'doctorCanSaveSamePerson': doctorCanSaveSamePerson,
            'doctorCanSaveSelf': doctorCanSaveSelf,
            'dayDurationMinutes': dayDuration.inMinutes,
            'nightDurationMinutes': nightDuration.inMinutes,
            'votingDurationMinutes': votingDuration.inMinutes,
          },
          createdAt: createdAt,
        );

  /// Create from GameConfig
  factory MafiaConfig.fromGameConfig(GameConfig config) {
    if (config.gameType != 'mafia') {
      throw ArgumentError('Invalid game type: ${config.gameType}');
    }

    return MafiaConfig(
      playerIds: config.playerIds,
      hostId: config.hostId,
      mafiaCount: config.settings['mafiaCount'] as int? ?? 2,
      policeCount: config.settings['policeCount'] as int? ?? 1,
      doctorCount: config.settings['doctorCount'] as int? ?? 1,
      jokerCount: config.settings['jokerCount'] as int? ?? 0,
      doctorCanSaveSamePerson: config.settings['doctorCanSaveSamePerson'] as bool? ?? false,
      doctorCanSaveSelf: config.settings['doctorCanSaveSelf'] as bool? ?? true,
      dayDuration: Duration(minutes: config.settings['dayDurationMinutes'] as int? ?? 10),
      nightDuration: Duration(minutes: config.settings['nightDurationMinutes'] as int? ?? 5),
      votingDuration: Duration(minutes: config.settings['votingDurationMinutes'] as int? ?? 3),
      createdAt: config.createdAt,
    );
  }

  /// Create default configuration
  factory MafiaConfig.defaultConfig({
    required List<String> playerIds,
    required String hostId,
  }) {
    final playerCount = playerIds.length;
    final mafiaCount = (playerCount / 4).ceil(); // ~25% mafia
    
    return MafiaConfig(
      playerIds: playerIds,
      hostId: hostId,
      mafiaCount: mafiaCount,
      policeCount: 1,
      doctorCount: 1,
      jokerCount: 0,
      doctorCanSaveSamePerson: false,
      doctorCanSaveSelf: true,
      dayDuration: Duration(minutes: 10),
      nightDuration: Duration(minutes: 5),
      votingDuration: Duration(minutes: 3),
    );
  }

  /// Get minimum players required
  int get minPlayersRequired => mafiaCount + policeCount + doctorCount + jokerCount + 2;

  /// Get role distribution
  Map<String, int> get roleDistribution {
    final totalSpecialRoles = mafiaCount + policeCount + doctorCount + jokerCount;
    final civilianCount = playerIds.length - totalSpecialRoles;
    
    return {
      'mafia': mafiaCount,
      'police': policeCount,
      'doctor': doctorCount,
      'joker': jokerCount,
      'civilian': civilianCount,
    };
  }

  @override
  MafiaConfig copyWith({
    String? gameType,
    Map<String, dynamic>? settings,
    List<String>? playerIds,
    String? hostId,
    DateTime? createdAt,
  }) {
    return MafiaConfig(
      playerIds: playerIds ?? this.playerIds,
      hostId: hostId ?? this.hostId,
      mafiaCount: settings?['mafiaCount'] as int? ?? mafiaCount,
      policeCount: settings?['policeCount'] as int? ?? policeCount,
      doctorCount: settings?['doctorCount'] as int? ?? doctorCount,
      jokerCount: settings?['jokerCount'] as int? ?? jokerCount,
      doctorCanSaveSamePerson: settings?['doctorCanSaveSamePerson'] as bool? ?? doctorCanSaveSamePerson,
      doctorCanSaveSelf: settings?['doctorCanSaveSelf'] as bool? ?? doctorCanSaveSelf,
      dayDuration: settings != null
          ? Duration(minutes: settings['dayDurationMinutes'] as int? ?? dayDuration.inMinutes)
          : dayDuration,
      nightDuration: settings != null
          ? Duration(minutes: settings['nightDurationMinutes'] as int? ?? nightDuration.inMinutes)
          : nightDuration,
      votingDuration: settings != null
          ? Duration(minutes: settings['votingDurationMinutes'] as int? ?? votingDuration.inMinutes)
          : votingDuration,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}