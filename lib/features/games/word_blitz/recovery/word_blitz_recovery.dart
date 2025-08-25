import 'dart:async';
import '../../../../core/game/game_base.dart';
import '../models/word_blitz_models.dart';
import '../actions/word_blitz_actions.dart';
import '../word_blitz_game.dart';

/// Recovery strategies for Word Blitz game errors
class WordBlitzRecoveryManager {
  final WordBlitzGame game;
  final String hostId;
  final Function(WordBlitzAction) onAction;
  final Function(String) onShowMessage;

  WordBlitzRecoveryManager({
    required this.game,
    required this.hostId,
    required this.onAction,
    required this.onShowMessage,
  });

  /// Attempt to recover from a Word Blitz error
  Future<bool> recoverFromError(WordBlitzError error) async {
    try {
      switch (error.wordBlitzErrorType) {
        case WordBlitzErrorType.invalidTheme:
          return await _recoverFromInvalidTheme(error);
        
        case WordBlitzErrorType.noActivePlayers:
          return await _recoverFromNoActivePlayers();
        
        case WordBlitzErrorType.roundNotActive:
          return await _recoverFromRoundNotActive();
        
        case WordBlitzErrorType.playerAlreadyEliminated:
          return await _recoverFromPlayerAlreadyEliminated(error);
        
        case WordBlitzErrorType.themeNotAvailable:
          return await _recoverFromThemeNotAvailable(error);
        
        case WordBlitzErrorType.roundTimeout:
          return await _recoverFromRoundTimeout();
        
        case WordBlitzErrorType.gameNotInitialized:
          return await _recoverFromGameNotInitialized();
        
        default:
          return false;
      }
    } catch (e) {
      onShowMessage('Recovery failed: $e');
      return false;
    }
  }

  /// Recover from invalid theme error by selecting a fallback theme
  Future<bool> _recoverFromInvalidTheme(WordBlitzError error) async {
    final availableThemes = game.availableThemes;
    if (availableThemes.isEmpty) {
      onShowMessage('No themes available');
      return false;
    }

    // Select the first available theme as fallback
    final fallbackTheme = availableThemes.first;
    final action = SetThemeAction(
      playerId: hostId,
      theme: fallbackTheme,
    );

    onAction(action);
    onShowMessage('Selected fallback theme: $fallbackTheme');
    return true;
  }

  /// Recover from no active players by starting a new round
  Future<bool> _recoverFromNoActivePlayers() async {
    if (!game.isRoundActive) {
      // Start a new round to reset player status
      final action = StartRoundAction(playerId: hostId);
      onAction(action);
      onShowMessage('Starting new round to reset players');
      return true;
    }

    onShowMessage('Cannot recover: round is still active');
    return false;
  }

  /// Recover from round not active by providing guidance
  Future<bool> _recoverFromRoundNotActive() async {
    if (game.currentTheme.isEmpty) {
      onShowMessage('Please select a theme first, then start a round');
    } else {
      onShowMessage('Please start a round to continue playing');
    }
    return false; // Cannot auto-recover, requires host action
  }

  /// Recover from player already eliminated by showing current status
  Future<bool> _recoverFromPlayerAlreadyEliminated(WordBlitzError error) async {
    final playerId = error.context?['playerId'] as String?;
    if (playerId != null) {
      onShowMessage('Player $playerId is already eliminated from this round');
    } else {
      onShowMessage('Player is already eliminated from this round');
    }
    return false; // Cannot auto-recover
  }

  /// Recover from theme not available by adding it as custom theme
  Future<bool> _recoverFromThemeNotAvailable(WordBlitzError error) async {
    final theme = error.context?['theme'] as String?;
    if (theme == null || !game.allowCustomThemes) {
      return await _recoverFromInvalidTheme(error);
    }

    // Try to add as custom theme
    final action = AddCustomThemeAction(
      playerId: hostId,
      theme: theme,
    );

    onAction(action);
    onShowMessage('Added "$theme" as custom theme');
    return true;
  }

  /// Recover from round timeout by starting a new round
  Future<bool> _recoverFromRoundTimeout() async {
    onShowMessage('Round timed out. Starting new round...');
    
    // End current round first
    final endAction = EndRoundAction(playerId: hostId);
    onAction(endAction);
    
    // Wait a moment then start new round
    await Future.delayed(Duration(seconds: 1));
    
    final startAction = StartRoundAction(playerId: hostId);
    onAction(startAction);
    
    return true;
  }

  /// Recover from game not initialized
  Future<bool> _recoverFromGameNotInitialized() async {
    onShowMessage('Game is not initialized. Please wait for the host to start the game.');
    return false; // Cannot auto-recover
  }
}

/// Automatic recovery strategies for common Word Blitz issues
class WordBlitzAutoRecovery {
  static const Duration _recoveryDelay = Duration(seconds: 2);
  static const int _maxRecoveryAttempts = 3;

  /// Automatically recover from network synchronization issues
  static Future<bool> recoverFromSyncError(
    WordBlitzGame game,
    Function() onRequestSync,
  ) async {
    int attempts = 0;
    
    while (attempts < _maxRecoveryAttempts) {
      attempts++;
      
      try {
        // Request state synchronization
        onRequestSync();
        
        // Wait for sync to complete
        await Future.delayed(_recoveryDelay);
        
        // Check if game state is valid
        if (_isGameStateValid(game)) {
          return true;
        }
      } catch (e) {
        // Continue to next attempt
      }
      
      // Exponential backoff
      await Future.delayed(Duration(seconds: attempts * 2));
    }
    
    return false;
  }

  /// Automatically recover from connection issues
  static Future<bool> recoverFromConnectionError(
    Function() onReconnect,
    Function() onRequestSync,
  ) async {
    int attempts = 0;
    
    while (attempts < _maxRecoveryAttempts) {
      attempts++;
      
      try {
        // Attempt to reconnect
        onReconnect();
        
        // Wait for connection to establish
        await Future.delayed(_recoveryDelay * attempts);
        
        // Request state sync after reconnection
        onRequestSync();
        
        return true;
      } catch (e) {
        // Continue to next attempt
      }
      
      // Exponential backoff
      await Future.delayed(Duration(seconds: attempts * 3));
    }
    
    return false;
  }

  /// Automatically recover from theme selection issues
  static Future<String?> recoverThemeSelection(
    List<String> availableThemes,
    String? invalidTheme,
  ) async {
    if (availableThemes.isEmpty) {
      return null;
    }

    // If invalid theme was provided, try to find similar theme
    if (invalidTheme != null && invalidTheme.isNotEmpty) {
      final similarTheme = _findSimilarTheme(invalidTheme, availableThemes);
      if (similarTheme != null) {
        return similarTheme;
      }
    }

    // Return first available theme as fallback
    return availableThemes.first;
  }

  /// Automatically recover from player elimination conflicts
  static List<String> recoverPlayerElimination(
    List<String> activePlayers,
    List<String> eliminatedPlayers,
    String? conflictPlayerId,
  ) {
    final recoveredActivePlayers = List<String>.from(activePlayers);
    
    // Remove any players that are in both lists
    recoveredActivePlayers.removeWhere((player) => eliminatedPlayers.contains(player));
    
    // If conflict player is specified, ensure they're in the correct list
    if (conflictPlayerId != null) {
      if (eliminatedPlayers.contains(conflictPlayerId)) {
        recoveredActivePlayers.remove(conflictPlayerId);
      }
    }
    
    return recoveredActivePlayers;
  }

  /// Check if game state is valid
  static bool _isGameStateValid(WordBlitzGame game) {
    try {
      final state = game.gameState;
      
      // Check required fields
      if (state['gameId'] == null || state['activePlayers'] == null) {
        return false;
      }
      
      // Check player consistency
      final activePlayers = state['activePlayers'] as List<dynamic>;
      final eliminatedPlayers = state['eliminatedPlayers'] as List<dynamic>;
      
      // No player should be in both lists
      final activeSet = Set.from(activePlayers);
      final eliminatedSet = Set.from(eliminatedPlayers);
      
      if (activeSet.intersection(eliminatedSet).isNotEmpty) {
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Find similar theme in available themes
  static String? _findSimilarTheme(String target, List<String> availableThemes) {
    final targetLower = target.toLowerCase();
    
    // Exact match (case insensitive)
    for (final theme in availableThemes) {
      if (theme.toLowerCase() == targetLower) {
        return theme;
      }
    }
    
    // Partial match
    for (final theme in availableThemes) {
      if (theme.toLowerCase().contains(targetLower) || 
          targetLower.contains(theme.toLowerCase())) {
        return theme;
      }
    }
    
    return null;
  }
}

/// Host-specific recovery actions for Word Blitz
class WordBlitzHostRecovery {
  final WordBlitzGame game;
  final String hostId;
  final Function(WordBlitzAction) onAction;

  WordBlitzHostRecovery({
    required this.game,
    required this.hostId,
    required this.onAction,
  });

  /// Manually adjust player status (host only)
  Future<void> manuallyAdjustPlayerStatus({
    required String playerId,
    required bool isActive,
  }) async {
    if (isActive) {
      // Reactivate player (custom action)
      final action = BasicGameAction(
        type: 'reactivate_player',
        playerId: hostId,
        data: {'targetPlayerId': playerId},
      );
      
      // Note: This would need to be implemented in the game logic
      // onAction(action);
    } else {
      // Eliminate player
      final action = EliminatePlayerAction(
        playerId: hostId,
        targetPlayerId: playerId,
        reason: 'Manual adjustment by host',
      );
      
      onAction(action);
    }
  }

  /// Reset round state (host only)
  Future<void> resetRoundState() async {
    // End current round
    if (game.isRoundActive) {
      final endAction = EndRoundAction(
        playerId: hostId,
        reason: 'Host reset',
      );
      onAction(endAction);
    }
    
    // Wait a moment
    await Future.delayed(Duration(milliseconds: 500));
    
    // Start new round
    if (game.currentTheme.isNotEmpty) {
      final startAction = StartRoundAction(playerId: hostId);
      onAction(startAction);
    }
  }

  /// Force theme selection (host only)
  Future<void> forceThemeSelection(String theme) async {
    final action = SetThemeAction(
      playerId: hostId,
      theme: theme,
    );
    onAction(action);
  }

  /// Emergency game reset (host only)
  Future<void> emergencyGameReset() async {
    // This would require implementing a reset action in the game
    final action = BasicGameAction(
      type: 'emergency_reset',
      playerId: hostId,
      data: {'reason': 'Host emergency reset'},
    );
    
    // Note: This would need to be implemented in the game logic
    // onAction(action);
  }
}