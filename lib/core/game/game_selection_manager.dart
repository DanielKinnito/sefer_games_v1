import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_base.dart';

/// Configuration for a specific game instance
class GameConfig {
  final String gameType;
  final Map<String, dynamic> settings;
  final List<String> playerIds;
  final String hostId;
  final DateTime createdAt;

  GameConfig({
    required this.gameType,
    required this.settings,
    required this.playerIds,
    required this.hostId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create a copy with updated values
  GameConfig copyWith({
    String? gameType,
    Map<String, dynamic>? settings,
    List<String>? playerIds,
    String? hostId,
    DateTime? createdAt,
  }) {
    return GameConfig(
      gameType: gameType ?? this.gameType,
      settings: settings ?? this.settings,
      playerIds: playerIds ?? this.playerIds,
      hostId: hostId ?? this.hostId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'gameType': gameType,
      'settings': settings,
      'playerIds': playerIds,
      'hostId': hostId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory GameConfig.fromJson(Map<String, dynamic> json) {
    return GameConfig(
      gameType: json['gameType'] as String,
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
      playerIds: List<String>.from(json['playerIds'] ?? []),
      hostId: json['hostId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Factory for Word Blitz game configuration
  factory GameConfig.wordBlitz({
    required List<String> playerIds,
    required String hostId,
    List<String>? availableThemes,
    int roundsToWin = 3,
    Duration roundTimeout = const Duration(minutes: 2),
    bool allowCustomThemes = false,
  }) {
    return GameConfig(
      gameType: 'word_blitz',
      playerIds: playerIds,
      hostId: hostId,
      settings: {
        'availableThemes': availableThemes ?? [
          'Countries',
          'Famous People',
          'Capital Cities',
          'Movies',
          'TV Series',
          'Animals',
          'Food',
          'Sports',
        ],
        'roundsToWin': roundsToWin,
        'roundTimeoutMinutes': roundTimeout.inMinutes,
        'allowCustomThemes': allowCustomThemes,
      },
    );
  }

  /// Factory for Number Guessing game configuration
  factory GameConfig.numberGuessing({
    required List<String> playerIds,
    required String hostId,
    int minNumber = 1,
    int maxNumber = 100,
    int maxGuesses = 10,
  }) {
    return GameConfig(
      gameType: 'number_guessing',
      playerIds: playerIds,
      hostId: hostId,
      settings: {
        'minNumber': minNumber,
        'maxNumber': maxNumber,
        'maxGuesses': maxGuesses,
      },
    );
  }
}

/// Result of game selection process
class GameSelectionResult {
  final String? gameType;
  final GameConfig? config;
  final bool cancelled;
  final String? errorMessage;

  const GameSelectionResult({
    this.gameType,
    this.config,
    required this.cancelled,
    this.errorMessage,
  });

  /// Create a successful selection result
  factory GameSelectionResult.success(String gameType, GameConfig config) {
    return GameSelectionResult(
      gameType: gameType,
      config: config,
      cancelled: false,
    );
  }

  /// Create a cancelled selection result
  factory GameSelectionResult.cancelled() {
    return const GameSelectionResult(cancelled: true);
  }

  /// Create an error selection result
  factory GameSelectionResult.error(String message) {
    return GameSelectionResult(
      cancelled: true,
      errorMessage: message,
    );
  }

  bool get isSuccess => !cancelled && gameType != null && config != null;
  bool get hasError => errorMessage != null;
}

/// Manages game selection UI and configuration
class GameSelectionManager {
  static const String _preferencesKey = 'game_preferences';
  
  /// Show game selection dialog and return the result
  Future<GameSelectionResult> showGameSelection(
    BuildContext context, {
    List<String>? playerIds,
    String? hostId,
    int? playerCount,
  }) async {
    try {
      // Get available games
      final availableGames = GameRegistry.getAvailableGames();
      
      if (availableGames.isEmpty) {
        return GameSelectionResult.error('No games available');
      }

      // Filter games by player count if provided
      final filteredGames = playerCount != null
          ? availableGames.where((game) => 
              playerCount >= game.minPlayers && playerCount <= game.maxPlayers).toList()
          : availableGames;

      if (filteredGames.isEmpty) {
        return GameSelectionResult.error(
          'No games available for $playerCount players'
        );
      }

      // Show selection dialog (this would be implemented in the UI layer)
      // For now, return the first available game as a placeholder
      final selectedGame = filteredGames.first;
      
      // Create default configuration
      final config = await _createDefaultConfig(
        selectedGame.gameType,
        playerIds ?? [],
        hostId ?? '',
      );

      return GameSelectionResult.success(selectedGame.gameType, config);
    } catch (e) {
      return GameSelectionResult.error('Failed to show game selection: $e');
    }
  }

  /// Configure a specific game with custom settings
  Future<GameConfig> configureGame(
    String gameType, 
    Map<String, dynamic> initialConfig, {
    List<String>? playerIds,
    String? hostId,
  }) async {
    final metadata = GameRegistry.getGameMetadata(gameType);
    if (metadata == null) {
      throw ArgumentError('Unknown game type: $gameType');
    }

    // Merge initial config with default config
    final mergedSettings = <String, dynamic>{
      ...metadata.defaultConfig,
      ...initialConfig,
    };

    return GameConfig(
      gameType: gameType,
      settings: mergedSettings,
      playerIds: playerIds ?? [],
      hostId: hostId ?? '',
    );
  }

  /// Save game preferences for future use
  Future<void> saveGamePreferences(String gameType, GameConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = prefs.getString(_preferencesKey);
      
      Map<String, dynamic> preferences = {};
      if (preferencesJson != null) {
        preferences = json.decode(preferencesJson) as Map<String, dynamic>;
      }

      preferences[gameType] = {
        'settings': config.settings,
        'lastUsed': DateTime.now().toIso8601String(),
      };

      await prefs.setString(_preferencesKey, json.encode(preferences));
    } catch (e) {
      // Log error but don't throw - preferences are not critical
      debugPrint('Failed to save game preferences: $e');
    }
  }

  /// Load saved game preferences
  Future<Map<String, dynamic>?> loadGamePreferences(String gameType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = prefs.getString(_preferencesKey);
      
      if (preferencesJson == null) return null;

      final preferences = json.decode(preferencesJson) as Map<String, dynamic>;
      final gamePrefs = preferences[gameType] as Map<String, dynamic>?;
      
      return gamePrefs?['settings'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Failed to load game preferences: $e');
      return null;
    }
  }

  /// Get recently used games
  Future<List<String>> getRecentlyUsedGames({int limit = 5}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = prefs.getString(_preferencesKey);
      
      if (preferencesJson == null) return [];

      final preferences = json.decode(preferencesJson) as Map<String, dynamic>;
      
      // Sort by last used date
      final sortedEntries = preferences.entries.toList()
        ..sort((a, b) {
          final aDate = DateTime.parse(a.value['lastUsed'] as String);
          final bDate = DateTime.parse(b.value['lastUsed'] as String);
          return bDate.compareTo(aDate); // Most recent first
        });

      return sortedEntries
          .take(limit)
          .map((entry) => entry.key)
          .toList();
    } catch (e) {
      debugPrint('Failed to get recently used games: $e');
      return [];
    }
  }

  /// Clear all game preferences
  Future<void> clearGamePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_preferencesKey);
    } catch (e) {
      debugPrint('Failed to clear game preferences: $e');
    }
  }

  /// Validate game configuration
  bool validateGameConfig(GameConfig config) {
    final metadata = GameRegistry.getGameMetadata(config.gameType);
    if (metadata == null) return false;

    // Check player count
    final playerCount = config.playerIds.length;
    if (playerCount < metadata.minPlayers || playerCount > metadata.maxPlayers) {
      return false;
    }

    // Check required settings based on game type
    switch (config.gameType) {
      case 'word_blitz':
        return _validateWordBlitzConfig(config);
      case 'number_guessing':
        return _validateNumberGuessingConfig(config);
      default:
        return true; // Unknown games are considered valid by default
    }
  }

  /// Create default configuration for a game type
  Future<GameConfig> _createDefaultConfig(
    String gameType,
    List<String> playerIds,
    String hostId,
  ) async {
    // Load saved preferences if available
    final savedSettings = await loadGamePreferences(gameType);
    
    switch (gameType) {
      case 'word_blitz':
        return GameConfig.wordBlitz(
          playerIds: playerIds,
          hostId: hostId,
          availableThemes: savedSettings?['availableThemes']?.cast<String>(),
          roundsToWin: savedSettings?['roundsToWin'] ?? 3,
          roundTimeout: Duration(
            minutes: savedSettings?['roundTimeoutMinutes'] ?? 2,
          ),
          allowCustomThemes: savedSettings?['allowCustomThemes'] ?? false,
        );
      
      case 'number_guessing':
        return GameConfig.numberGuessing(
          playerIds: playerIds,
          hostId: hostId,
          minNumber: savedSettings?['minNumber'] ?? 1,
          maxNumber: savedSettings?['maxNumber'] ?? 100,
          maxGuesses: savedSettings?['maxGuesses'] ?? 10,
        );
      
      default:
        // Generic configuration
        final metadata = GameRegistry.getGameMetadata(gameType);
        return GameConfig(
          gameType: gameType,
          playerIds: playerIds,
          hostId: hostId,
          settings: savedSettings ?? metadata?.defaultConfig ?? {},
        );
    }
  }

  /// Validate Word Blitz specific configuration
  bool _validateWordBlitzConfig(GameConfig config) {
    final settings = config.settings;
    
    // Check required settings
    if (!settings.containsKey('availableThemes') ||
        !settings.containsKey('roundsToWin') ||
        !settings.containsKey('roundTimeoutMinutes')) {
      return false;
    }

    // Validate themes
    final themes = settings['availableThemes'] as List?;
    if (themes == null || themes.isEmpty) {
      return false;
    }

    // Validate rounds to win
    final roundsToWin = settings['roundsToWin'] as int?;
    if (roundsToWin == null || roundsToWin < 1 || roundsToWin > 10) {
      return false;
    }

    // Validate timeout
    final timeoutMinutes = settings['roundTimeoutMinutes'] as int?;
    if (timeoutMinutes == null || timeoutMinutes < 1 || timeoutMinutes > 10) {
      return false;
    }

    return true;
  }

  /// Validate Number Guessing specific configuration
  bool _validateNumberGuessingConfig(GameConfig config) {
    final settings = config.settings;
    
    // Check required settings
    if (!settings.containsKey('minNumber') ||
        !settings.containsKey('maxNumber') ||
        !settings.containsKey('maxGuesses')) {
      return false;
    }

    final minNumber = settings['minNumber'] as int?;
    final maxNumber = settings['maxNumber'] as int?;
    final maxGuesses = settings['maxGuesses'] as int?;

    if (minNumber == null || maxNumber == null || maxGuesses == null) {
      return false;
    }

    // Validate number range
    if (minNumber >= maxNumber || minNumber < 1 || maxNumber > 10000) {
      return false;
    }

    // Validate max guesses
    if (maxGuesses < 1 || maxGuesses > 100) {
      return false;
    }

    return true;
  }
}