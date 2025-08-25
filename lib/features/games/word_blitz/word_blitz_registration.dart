import '../../../core/game/game_base.dart';
import 'word_blitz_game.dart';

/// Registration utility for Word Blitz game
class WordBlitzRegistration {
  /// Register Word Blitz game with the game registry
  static void registerGame() {
    final metadata = GameMetadata(
      gameType: WordBlitzGame.gameTypeId,
      displayName: 'Word Blitz',
      description: 'Fast-paced word game where players think of words starting with a random letter. The host eliminates the player who says a word last until only one remains!',
      minPlayers: 3,
      maxPlayers: 10,
      estimatedDuration: Duration(minutes: 15),
      requiredPermissions: [],
      defaultConfig: {
        'availableThemes': [
          'Countries',
          'Famous People',
          'Capital Cities',
          'Movies',
          'TV Series',
          'Animals',
          'Food',
          'Sports',
        ],
        'roundsToWin': 3,
        'roundTimeoutMinutes': 2,
        'allowCustomThemes': false,
      },
      iconPath: 'assets/games/word_blitz_icon.png',
      tags: ['party', 'word', 'quick', 'elimination', 'easy'],
    );

    GameRegistry.registerGameWithMetadata(
      WordBlitzGame.gameTypeId,
      () => WordBlitzGame(),
      metadata,
    );
  }

  /// Create a Word Blitz game instance with custom configuration
  static WordBlitzGame createGame({
    String? gameId,
    List<String>? availableThemes,
    int roundsToWin = 3,
    Duration roundTimeout = const Duration(minutes: 2),
    bool allowCustomThemes = false,
  }) {
    return WordBlitzGame(
      gameId: gameId,
      availableThemes: availableThemes,
      roundsToWin: roundsToWin,
      roundTimeout: roundTimeout,
      allowCustomThemes: allowCustomThemes,
    );
  }

  /// Create a Word Blitz game from GameConfig
  static WordBlitzGame createGameFromConfig(Map<String, dynamic> config) {
    return WordBlitzGame(
      gameId: config['gameId'] as String?,
      availableThemes: config['availableThemes'] != null
          ? List<String>.from(config['availableThemes'])
          : null,
      roundsToWin: config['roundsToWin'] as int? ?? 3,
      roundTimeout: Duration(
        minutes: config['roundTimeoutMinutes'] as int? ?? 2,
      ),
      allowCustomThemes: config['allowCustomThemes'] as bool? ?? false,
    );
  }

  /// Get Word Blitz game metadata
  static GameMetadata? getMetadata() {
    return GameRegistry.getGameMetadata(WordBlitzGame.gameTypeId);
  }

  /// Check if Word Blitz is registered
  static bool isRegistered() {
    return GameRegistry.isGameTypeSupported(WordBlitzGame.gameTypeId);
  }

  /// Validate Word Blitz configuration
  static bool validateConfig(Map<String, dynamic> config) {
    // Check required fields
    if (!config.containsKey('availableThemes') ||
        !config.containsKey('roundsToWin') ||
        !config.containsKey('roundTimeoutMinutes')) {
      return false;
    }

    // Validate themes
    final themes = config['availableThemes'];
    if (themes is! List || themes.isEmpty) {
      return false;
    }

    // Validate rounds to win
    final roundsToWin = config['roundsToWin'];
    if (roundsToWin is! int || roundsToWin < 1 || roundsToWin > 10) {
      return false;
    }

    // Validate timeout
    final timeoutMinutes = config['roundTimeoutMinutes'];
    if (timeoutMinutes is! int || timeoutMinutes < 1 || timeoutMinutes > 10) {
      return false;
    }

    return true;
  }

  /// Get default themes for Word Blitz
  static List<String> getDefaultThemes() {
    return [
      'Countries',
      'Famous People',
      'Capital Cities',
      'Movies',
      'TV Series',
      'Animals',
      'Food',
      'Sports',
      'Books',
      'Music',
      'Colors',
      'Professions',
      'Brands',
      'Video Games',
      'Cartoon Characters',
    ];
  }

  /// Get recommended player counts for different group sizes
  static Map<String, int> getRecommendedPlayerCounts() {
    return {
      'small': 4,  // Small group
      'medium': 6, // Medium group
      'large': 8,  // Large group
    };
  }

  /// Get difficulty recommendations based on player count
  static String getDifficultyRecommendation(int playerCount) {
    if (playerCount <= 4) {
      return 'Easy - Perfect for small groups';
    } else if (playerCount <= 6) {
      return 'Medium - Great for medium groups';
    } else {
      return 'Challenging - Exciting for large groups';
    }
  }

  /// Get estimated game duration based on configuration
  static Duration getEstimatedDuration({
    required int playerCount,
    required int roundsToWin,
    required Duration roundTimeout,
  }) {
    // Base calculation: rounds * timeout * average elimination rate
    final averageRoundsPerGame = roundsToWin * 1.5; // Account for multiple rounds
    final averageRoundDuration = roundTimeout * 0.7; // Most rounds don't timeout
    final setupTime = Duration(minutes: 2); // Theme selection, etc.
    
    return Duration(
      milliseconds: (setupTime.inMilliseconds + 
                    (averageRoundsPerGame * averageRoundDuration.inMilliseconds)).round(),
    );
  }
}