import '../../../../core/game/game_base.dart';
import '../mafia_game.dart';

/// Base class for Mafia actions
abstract class MafiaAction extends BasicGameAction {
  MafiaAction({
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

/// Action to cast a vote during voting phase
class VoteAction extends MafiaAction {
  final String targetId;

  VoteAction({
    required String playerId,
    required this.targetId,
    DateTime? timestamp,
  }) : super(
          type: 'vote',
          playerId: playerId,
          data: {'targetId': targetId},
          timestamp: timestamp,
        );

  factory VoteAction.fromAction(GameAction action) {
    if (action.type != 'vote') {
      throw ArgumentError('Invalid action type: ${action.type}');
    }
    
    return VoteAction(
      playerId: action.playerId,
      targetId: action.data['targetId'] as String,
      timestamp: action.timestamp,
    );
  }
}

/// Action for police to investigate a player during night
class PoliceInvestigateAction extends MafiaAction {
  final String targetId;

  PoliceInvestigateAction({
    required String playerId,
    required this.targetId,
    DateTime? timestamp,
  }) : super(
          type: 'police_investigate',
          playerId: playerId,
          data: {'targetId': targetId},
          timestamp: timestamp,
        );

  factory PoliceInvestigateAction.fromAction(GameAction action) {
    if (action.type != 'police_investigate') {
      throw ArgumentError('Invalid action type: ${action.type}');
    }
    
    return PoliceInvestigateAction(
      playerId: action.playerId,
      targetId: action.data['targetId'] as String,
      timestamp: action.timestamp,
    );
  }
}

/// Action for doctor to heal a player during night
class DoctorHealAction extends MafiaAction {
  final String targetId;

  DoctorHealAction({
    required String playerId,
    required this.targetId,
    DateTime? timestamp,
  }) : super(
          type: 'doctor_heal',
          playerId: playerId,
          data: {'targetId': targetId},
          timestamp: timestamp,
        );

  factory DoctorHealAction.fromAction(GameAction action) {
    if (action.type != 'doctor_heal') {
      throw ArgumentError('Invalid action type: ${action.type}');
    }
    
    return DoctorHealAction(
      playerId: action.playerId,
      targetId: action.data['targetId'] as String,
      timestamp: action.timestamp,
    );
  }
}

/// Action for mafia to kill a player during night
class MafiaKillAction extends MafiaAction {
  final String targetId;

  MafiaKillAction({
    required String playerId,
    required this.targetId,
    DateTime? timestamp,
  }) : super(
          type: 'mafia_kill',
          playerId: playerId,
          data: {'targetId': targetId},
          timestamp: timestamp,
        );

  factory MafiaKillAction.fromAction(GameAction action) {
    if (action.type != 'mafia_kill') {
      throw ArgumentError('Invalid action type: ${action.type}');
    }
    
    return MafiaKillAction(
      playerId: action.playerId,
      targetId: action.data['targetId'] as String,
      timestamp: action.timestamp,
    );
  }
}

/// Action to advance to the next phase (host only)
class AdvancePhaseAction extends MafiaAction {
  AdvancePhaseAction({
    required String playerId,
    DateTime? timestamp,
  }) : super(
          type: 'advance_phase',
          playerId: playerId,
          data: {},
          timestamp: timestamp,
        );

  factory AdvancePhaseAction.fromAction(GameAction action) {
    if (action.type != 'advance_phase') {
      throw ArgumentError('Invalid action type: ${action.type}');
    }
    
    return AdvancePhaseAction(
      playerId: action.playerId,
      timestamp: action.timestamp,
    );
  }
}

/// Action to start voting phase (host only)
class StartVotingAction extends MafiaAction {
  StartVotingAction({
    required String playerId,
    DateTime? timestamp,
  }) : super(
          type: 'start_voting',
          playerId: playerId,
          data: {},
          timestamp: timestamp,
        );

  factory StartVotingAction.fromAction(GameAction action) {
    if (action.type != 'start_voting') {
      throw ArgumentError('Invalid action type: ${action.type}');
    }
    
    return StartVotingAction(
      playerId: action.playerId,
      timestamp: action.timestamp,
    );
  }
}

/// Action to end voting phase (host only)
class EndVotingAction extends MafiaAction {
  EndVotingAction({
    required String playerId,
    DateTime? timestamp,
  }) : super(
          type: 'end_voting',
          playerId: playerId,
          data: {},
          timestamp: timestamp,
        );

  factory EndVotingAction.fromAction(GameAction action) {
    if (action.type != 'end_voting') {
      throw ArgumentError('Invalid action type: ${action.type}');
    }
    
    return EndVotingAction(
      playerId: action.playerId,
      timestamp: action.timestamp,
    );
  }
}

/// Factory class for creating Mafia actions
class MafiaActionFactory {
  /// Create a Mafia action from a generic GameAction
  static MafiaAction fromGameAction(GameAction action) {
    switch (action.type) {
      case 'vote':
        return VoteAction.fromAction(action);
      case 'police_investigate':
        return PoliceInvestigateAction.fromAction(action);
      case 'doctor_heal':
        return DoctorHealAction.fromAction(action);
      case 'mafia_kill':
        return MafiaKillAction.fromAction(action);
      case 'advance_phase':
        return AdvancePhaseAction.fromAction(action);
      case 'start_voting':
        return StartVotingAction.fromAction(action);
      case 'end_voting':
        return EndVotingAction.fromAction(action);
      default:
        throw ArgumentError('Unknown Mafia action type: ${action.type}');
    }
  }

  /// Check if an action type is valid for Mafia
  static bool isValidActionType(String actionType) {
    const validTypes = {
      'vote',
      'police_investigate',
      'doctor_heal',
      'mafia_kill',
      'advance_phase',
      'start_voting',
      'end_voting',
    };
    
    return validTypes.contains(actionType);
  }

  /// Check if an action requires host permissions
  static bool requiresHostPermission(String actionType) {
    const hostOnlyActions = {
      'advance_phase',
      'start_voting',
      'end_voting',
    };
    
    return hostOnlyActions.contains(actionType);
  }

  /// Check if an action requires specific role
  static PlayerRole? getRequiredRole(String actionType) {
    switch (actionType) {
      case 'police_investigate':
        return PlayerRole.police;
      case 'doctor_heal':
        return PlayerRole.doctor;
      case 'mafia_kill':
        return PlayerRole.mafia;
      default:
        return null; // No specific role required
    }
  }

  /// Check if an action is valid for current phase
  static bool isValidForPhase(String actionType, GamePhase phase) {
    switch (actionType) {
      case 'vote':
        return phase == GamePhase.voting;
      case 'police_investigate':
      case 'doctor_heal':
      case 'mafia_kill':
        return phase == GamePhase.night;
      case 'advance_phase':
      case 'start_voting':
      case 'end_voting':
        return true; // Host actions can be performed in any phase
      default:
        return false;
    }
  }
}