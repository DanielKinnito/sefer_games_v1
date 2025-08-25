import '../../../../core/game/game_base.dart';

/// Base class for Word Blitz actions
abstract class WordBlitzAction extends BasicGameAction {
  WordBlitzAction({
    required String type,
    required String playerId,
    required Map<String, dynamic> data,
    DateTime? timestamp,
  }) : super(
          type: type,
          playerId: playerId,
          data: data,
          timestamp: timestamp,
        );
}

/// Action to set the theme for the current round
class SetThemeAction extends WordBlitzAction {
  final String theme;

  SetThemeAction({
    required String playerId,
    required this.theme,
    DateTime? timestamp,
  }) : super(
          type: 'set_theme',
          playerId: playerId,
          data: {'theme': theme},
          timestamp: timestamp,
        );

  factory SetThemeAction.fromAction(GameAction action) {
    if (action.type != 'set_theme') {
      throw ArgumentError('Invalid action type: ${action.type}');
    }
    
    return SetThemeAction(
      playerId: action.playerId,
      theme: action.data['theme'] as String,
      timestamp: action.timestamp,
    );
  }
}

/// Action to generate a random letter for the current theme
class GenerateLetterAction extends WordBlitzAction {
  GenerateLetterAction({
    required String playerId,
    DateTime? timestamp,
  }) : super(
          type: 'generate_letter',
          playerId: playerId,
          data: {},
          timestamp: timestamp,
        );

  factory GenerateLetterAction.fromAction(GameAction action) {
    if (action.type != 'generate_letter') {
      throw ArgumentError('Invalid action type: ${action.type}');
    }
    
    return GenerateLetterAction(
      playerId: action.playerId,
      timestamp: action.timestamp,
    );
  }
}

/// Action to eliminate a player from the current round
class EliminatePlayerAction extends WordBlitzAction {
  final String targetPlayerId;
  final String? reason;

  EliminatePlayerAction({
    required String playerId,
    required this.targetPlayerId,
    this.reason,
    DateTime? timestamp,
  }) : super(
          type: 'eliminate_player',
          playerId: playerId,
          data: {
            'targetPlayerId': targetPlayerId,
            if (reason != null) 'reason': reason,
          },
          timestamp: timestamp,
        );

  factory EliminatePlayerAction.fromAction(GameAction action) {
    if (action.type != 'eliminate_player') {
      throw ArgumentError('Invalid action type: ${action.type}');
    }
    
    return EliminatePlayerAction(
      playerId: action.playerId,
      targetPlayerId: action.data['targetPlayerId'] as String,
      reason: action.data['reason'] as String?,
      timestamp: action.timestamp,
    );
  }
}

/// Action to start a new round
class StartRoundAction extends WordBlitzAction {
  StartRoundAction({
    required String playerId,
    DateTime? timestamp,
  }) : super(
          type: 'start_round',
          playerId: playerId,
          data: {},
          timestamp: timestamp,
        );

  factory StartRoundAction.fromAction(GameAction action) {
    if (action.type != 'start_round') {
      throw ArgumentError('Invalid action type: ${action.type}');
    }
    
    return StartRoundAction(
      playerId: action.playerId,
      timestamp: action.timestamp,
    );
  }
}

/// Action to end the current round
class EndRoundAction extends WordBlitzAction {
  final String? reason;

  EndRoundAction({
    required String playerId,
    this.reason,
    DateTime? timestamp,
  }) : super(
          type: 'end_round',
          playerId: playerId,
          data: {
            if (reason != null) 'reason': reason,
          },
          timestamp: timestamp,
        );

  factory EndRoundAction.fromAction(GameAction action) {
    if (action.type != 'end_round') {
      throw ArgumentError('Invalid action type: ${action.type}');
    }
    
    return EndRoundAction(
      playerId: action.playerId,
      reason: action.data['reason'] as String?,
      timestamp: action.timestamp,
    );
  }
}

/// Action to add a custom theme (if allowed)
class AddCustomThemeAction extends WordBlitzAction {
  final String theme;

  AddCustomThemeAction({
    required String playerId,
    required this.theme,
    DateTime? timestamp,
  }) : super(
          type: 'add_custom_theme',
          playerId: playerId,
          data: {'theme': theme},
          timestamp: timestamp,
        );

  factory AddCustomThemeAction.fromAction(GameAction action) {
    if (action.type != 'add_custom_theme') {
      throw ArgumentError('Invalid action type: ${action.type}');
    }
    
    return AddCustomThemeAction(
      playerId: action.playerId,
      theme: action.data['theme'] as String,
      timestamp: action.timestamp,
    );
  }
}

/// Action to request game state synchronization
class SyncGameStateAction extends WordBlitzAction {
  SyncGameStateAction({
    required String playerId,
    DateTime? timestamp,
  }) : super(
          type: 'sync_game_state',
          playerId: playerId,
          data: {},
          timestamp: timestamp,
        );

  factory SyncGameStateAction.fromAction(GameAction action) {
    if (action.type != 'sync_game_state') {
      throw ArgumentError('Invalid action type: ${action.type}');
    }
    
    return SyncGameStateAction(
      playerId: action.playerId,
      timestamp: action.timestamp,
    );
  }
}

/// Action to pause the current round (host only)
class PauseRoundAction extends WordBlitzAction {
  PauseRoundAction({
    required String playerId,
    DateTime? timestamp,
  }) : super(
          type: 'pause_round',
          playerId: playerId,
          data: {},
          timestamp: timestamp,
        );

  factory PauseRoundAction.fromAction(GameAction action) {
    if (action.type != 'pause_round') {
      throw ArgumentError('Invalid action type: ${action.type}');
    }
    
    return PauseRoundAction(
      playerId: action.playerId,
      timestamp: action.timestamp,
    );
  }
}

/// Action to resume a paused round (host only)
class ResumeRoundAction extends WordBlitzAction {
  ResumeRoundAction({
    required String playerId,
    DateTime? timestamp,
  }) : super(
          type: 'resume_round',
          playerId: playerId,
          data: {},
          timestamp: timestamp,
        );

  factory ResumeRoundAction.fromAction(GameAction action) {
    if (action.type != 'resume_round') {
      throw ArgumentError('Invalid action type: ${action.type}');
    }
    
    return ResumeRoundAction(
      playerId: action.playerId,
      timestamp: action.timestamp,
    );
  }
}

/// Action to reset the current round (host only)
class ResetRoundAction extends WordBlitzAction {
  ResetRoundAction({
    required String playerId,
    DateTime? timestamp,
  }) : super(
          type: 'reset_round',
          playerId: playerId,
          data: {},
          timestamp: timestamp,
        );

  factory ResetRoundAction.fromAction(GameAction action) {
    if (action.type != 'reset_round') {
      throw ArgumentError('Invalid action type: ${action.type}');
    }
    
    return ResetRoundAction(
      playerId: action.playerId,
      timestamp: action.timestamp,
    );
  }
}

/// Factory class for creating Word Blitz actions
class WordBlitzActionFactory {
  /// Create a Word Blitz action from a generic GameAction
  static WordBlitzAction fromGameAction(GameAction action) {
    switch (action.type) {
      case 'set_theme':
        return SetThemeAction.fromAction(action);
      case 'generate_letter':
        return GenerateLetterAction.fromAction(action);
      case 'eliminate_player':
        return EliminatePlayerAction.fromAction(action);
      case 'start_round':
        return StartRoundAction.fromAction(action);
      case 'end_round':
        return EndRoundAction.fromAction(action);
      case 'add_custom_theme':
        return AddCustomThemeAction.fromAction(action);
      case 'sync_game_state':
        return SyncGameStateAction.fromAction(action);
      case 'pause_round':
        return PauseRoundAction.fromAction(action);
      case 'resume_round':
        return ResumeRoundAction.fromAction(action);
      case 'reset_round':
        return ResetRoundAction.fromAction(action);
      default:
        throw ArgumentError('Unknown Word Blitz action type: ${action.type}');
    }
  }

  /// Check if an action type is valid for Word Blitz
  static bool isValidActionType(String actionType) {
    const validTypes = {
      'set_theme',
      'generate_letter',
      'eliminate_player',
      'start_round',
      'end_round',
      'add_custom_theme',
      'sync_game_state',
      'pause_round',
      'resume_round',
      'reset_round',
    };
    
    return validTypes.contains(actionType);
  }

  /// Get all valid action types for Word Blitz
  static Set<String> getValidActionTypes() {
    return {
      'set_theme',
      'generate_letter',
      'eliminate_player',
      'start_round',
      'end_round',
      'add_custom_theme',
      'sync_game_state',
      'pause_round',
      'resume_round',
      'reset_round',
    };
  }

  /// Check if an action requires host permissions
  static bool requiresHostPermission(String actionType) {
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
    
    return hostOnlyActions.contains(actionType);
  }

  /// Validate action data for a specific action type
  static bool validateActionData(String actionType, Map<String, dynamic> data) {
    switch (actionType) {
      case 'set_theme':
        return data.containsKey('theme') && 
               data['theme'] is String && 
               (data['theme'] as String).isNotEmpty;
      
      case 'eliminate_player':
        return data.containsKey('targetPlayerId') && 
               data['targetPlayerId'] is String && 
               (data['targetPlayerId'] as String).isNotEmpty;
      
      case 'add_custom_theme':
        return data.containsKey('theme') && 
               data['theme'] is String && 
               (data['theme'] as String).isNotEmpty;
      
      case 'generate_letter':
      case 'start_round':
      case 'end_round':
      case 'sync_game_state':
      case 'pause_round':
      case 'resume_round':
      case 'reset_round':
        return true; // These actions don't require specific data
      
      default:
        return false;
    }
  }
}