import '../../../../core/error/error_handler.dart';

/// Word Blitz specific error types
enum WordBlitzErrorType {
  invalidTheme,
  noActivePlayers,
  roundNotActive,
  hostPermissionRequired,
  playerAlreadyEliminated,
  themeNotAvailable,
  customThemesDisabled,
  invalidPlayerCount,
  gameNotInitialized,
  roundTimeout,
  invalidConfiguration,
}

/// Word Blitz specific error class
class WordBlitzError extends Error {
  final String message;
  final WordBlitzErrorType wordBlitzErrorType;
  final Map<String, dynamic>? context;

  WordBlitzError(
    this.message,
    this.wordBlitzErrorType, {
    this.context,
  });

  @override
  String toString() {
    return 'WordBlitzError: $message (Type: $wordBlitzErrorType)';
  }
}

/// Word Blitz error handler utility
class WordBlitzErrorHandler {
  /// Convert Word Blitz errors to user-friendly messages
  static String getUserFriendlyMessage(
    dynamic error, {
    Map<String, dynamic>? context,
  }) {
    if (error is WordBlitzError) {
      return _getWordBlitzErrorMessage(error);
    }

    // Fallback to general error handler
    return ErrorHandler.getUserFriendlyMessage(error, ErrorContext.game);
  }

  /// Get user-friendly message for Word Blitz specific errors
  static String _getWordBlitzErrorMessage(WordBlitzError error) {
    switch (error.wordBlitzErrorType) {
      case WordBlitzErrorType.invalidTheme:
        return 'The selected theme is not available. Please choose a different theme.';
      
      case WordBlitzErrorType.noActivePlayers:
        return 'No active players remaining. The round cannot continue.';
      
      case WordBlitzErrorType.roundNotActive:
        return 'No round is currently active. Please start a new round first.';
      
      case WordBlitzErrorType.hostPermissionRequired:
        return 'Only the host can perform this action.';
      
      case WordBlitzErrorType.playerAlreadyEliminated:
        return 'This player has already been eliminated from the current round.';
      
      case WordBlitzErrorType.themeNotAvailable:
        return 'The requested theme is not in the available themes list.';
      
      case WordBlitzErrorType.customThemesDisabled:
        return 'Custom themes are not allowed in this game.';
      
      case WordBlitzErrorType.invalidPlayerCount:
        return 'Invalid number of players. Word Blitz requires 3-10 players.';
      
      case WordBlitzErrorType.gameNotInitialized:
        return 'The game has not been initialized yet. Please wait for the host to start.';
      
      case WordBlitzErrorType.roundTimeout:
        return 'The round has timed out. Starting a new round.';
      
      case WordBlitzErrorType.invalidConfiguration:
        return 'Invalid game configuration. Please check your settings.';
      
      default:
        return error.message;
    }
  }

  /// Check if a Word Blitz error is retryable
  static bool isRetryableError(dynamic error) {
    if (error is WordBlitzError) {
      switch (error.wordBlitzErrorType) {
        case WordBlitzErrorType.roundTimeout:
        case WordBlitzErrorType.gameNotInitialized:
          return true;
        
        case WordBlitzErrorType.hostPermissionRequired:
        case WordBlitzErrorType.customThemesDisabled:
        case WordBlitzErrorType.invalidPlayerCount:
        case WordBlitzErrorType.invalidConfiguration:
          return false;
        
        default:
          return true;
      }
    }

    // Fallback to general error handler
    return ErrorHandler.isRetryableError(error);
  }

  /// Get suggested recovery action for Word Blitz errors
  static String? getRecoveryAction(WordBlitzError error) {
    switch (error.wordBlitzErrorType) {
      case WordBlitzErrorType.invalidTheme:
        return 'Select a theme from the available list';
      
      case WordBlitzErrorType.noActivePlayers:
        return 'Start a new round to reset player status';
      
      case WordBlitzErrorType.roundNotActive:
        return 'Ask the host to start a new round';
      
      case WordBlitzErrorType.hostPermissionRequired:
        return 'Only the host can perform this action';
      
      case WordBlitzErrorType.playerAlreadyEliminated:
        return 'Wait for the next round to participate';
      
      case WordBlitzErrorType.themeNotAvailable:
        return 'Choose from the available themes or add it as a custom theme';
      
      case WordBlitzErrorType.customThemesDisabled:
        return 'Select from the predefined themes';
      
      case WordBlitzErrorType.invalidPlayerCount:
        return 'Ensure you have 3-10 players before starting';
      
      case WordBlitzErrorType.gameNotInitialized:
        return 'Wait for the host to initialize the game';
      
      case WordBlitzErrorType.roundTimeout:
        return 'The host will start a new round';
      
      case WordBlitzErrorType.invalidConfiguration:
        return 'Check game settings and try again';
      
      default:
        return null;
    }
  }

  /// Create specific Word Blitz errors
  static WordBlitzError invalidTheme(String theme) {
    return WordBlitzError(
      'Invalid theme: $theme',
      WordBlitzErrorType.invalidTheme,
      context: {'theme': theme},
    );
  }

  static WordBlitzError noActivePlayers() {
    return WordBlitzError(
      'No active players remaining',
      WordBlitzErrorType.noActivePlayers,
    );
  }

  static WordBlitzError roundNotActive() {
    return WordBlitzError(
      'No round is currently active',
      WordBlitzErrorType.roundNotActive,
    );
  }

  static WordBlitzError hostPermissionRequired(String action) {
    return WordBlitzError(
      'Host permission required for action: $action',
      WordBlitzErrorType.hostPermissionRequired,
      context: {'action': action},
    );
  }

  static WordBlitzError playerAlreadyEliminated(String playerId) {
    return WordBlitzError(
      'Player already eliminated: $playerId',
      WordBlitzErrorType.playerAlreadyEliminated,
      context: {'playerId': playerId},
    );
  }

  static WordBlitzError themeNotAvailable(String theme) {
    return WordBlitzError(
      'Theme not available: $theme',
      WordBlitzErrorType.themeNotAvailable,
      context: {'theme': theme},
    );
  }

  static WordBlitzError customThemesDisabled() {
    return WordBlitzError(
      'Custom themes are disabled',
      WordBlitzErrorType.customThemesDisabled,
    );
  }

  static WordBlitzError invalidPlayerCount(int count) {
    return WordBlitzError(
      'Invalid player count: $count. Must be between 3 and 10.',
      WordBlitzErrorType.invalidPlayerCount,
      context: {'playerCount': count},
    );
  }

  static WordBlitzError gameNotInitialized() {
    return WordBlitzError(
      'Game not initialized',
      WordBlitzErrorType.gameNotInitialized,
    );
  }

  static WordBlitzError roundTimeout() {
    return WordBlitzError(
      'Round timed out',
      WordBlitzErrorType.roundTimeout,
    );
  }

  static WordBlitzError invalidConfiguration(String reason) {
    return WordBlitzError(
      'Invalid configuration: $reason',
      WordBlitzErrorType.invalidConfiguration,
      context: {'reason': reason},
    );
  }
}

/// Word Blitz validation utilities
class WordBlitzValidator {
  /// Validate theme selection
  static void validateTheme(String theme, List<String> availableThemes, bool allowCustomThemes) {
    if (theme.isEmpty) {
      throw WordBlitzErrorHandler.invalidTheme('Theme cannot be empty');
    }

    if (!allowCustomThemes && !availableThemes.contains(theme)) {
      throw WordBlitzErrorHandler.themeNotAvailable(theme);
    }
  }

  /// Validate player count
  static void validatePlayerCount(int count) {
    if (count < 3 || count > 10) {
      throw WordBlitzErrorHandler.invalidPlayerCount(count);
    }
  }

  /// Validate round state for actions
  static void validateRoundActive(bool isRoundActive, String action) {
    if (!isRoundActive && _requiresActiveRound(action)) {
      throw WordBlitzErrorHandler.roundNotActive();
    }
  }

  /// Validate player elimination
  static void validatePlayerElimination(String playerId, List<String> activePlayers) {
    if (!activePlayers.contains(playerId)) {
      throw WordBlitzErrorHandler.playerAlreadyEliminated(playerId);
    }
  }

  /// Validate host permissions
  static void validateHostPermission(bool isHost, String action) {
    if (!isHost && _requiresHostPermission(action)) {
      throw WordBlitzErrorHandler.hostPermissionRequired(action);
    }
  }

  /// Validate custom theme addition
  static void validateCustomTheme(bool allowCustomThemes, String theme) {
    if (!allowCustomThemes) {
      throw WordBlitzErrorHandler.customThemesDisabled();
    }

    if (theme.isEmpty || theme.length > 50) {
      throw WordBlitzErrorHandler.invalidTheme('Theme must be 1-50 characters');
    }
  }

  /// Validate game configuration
  static void validateGameConfiguration(Map<String, dynamic> config) {
    // Validate themes
    final themes = config['availableThemes'] as List<dynamic>?;
    if (themes == null || themes.isEmpty) {
      throw WordBlitzErrorHandler.invalidConfiguration('At least one theme is required');
    }

    // Validate rounds to win
    final roundsToWin = config['roundsToWin'] as int?;
    if (roundsToWin == null || roundsToWin < 1 || roundsToWin > 10) {
      throw WordBlitzErrorHandler.invalidConfiguration('Rounds to win must be between 1 and 10');
    }

    // Validate timeout
    final timeoutMinutes = config['roundTimeoutMinutes'] as int?;
    if (timeoutMinutes == null || timeoutMinutes < 1 || timeoutMinutes > 10) {
      throw WordBlitzErrorHandler.invalidConfiguration('Round timeout must be between 1 and 10 minutes');
    }
  }

  static bool _requiresActiveRound(String action) {
    const activeRoundActions = {
      'eliminate_player',
      'end_round',
      'pause_round',
      'resume_round',
    };
    return activeRoundActions.contains(action);
  }

  static bool _requiresHostPermission(String action) {
    const hostOnlyActions = {
      'set_theme',
      'generate_letter',
      'eliminate_player',
      'start_round',
      'end_round',
      'pause_round',
      'resume_round',
      'reset_round',
    };
    return hostOnlyActions.contains(action);
  }
}