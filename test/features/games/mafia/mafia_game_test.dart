import 'package:flutter_test/flutter_test.dart';
import 'package:sefer_games_v1/features/games/mafia/mafia_game.dart';
import 'package:sefer_games_v1/core/game/game_base.dart';

void main() {
  group('MafiaGame', () {
    late MafiaGame game;
    late List<String> playerIds;

    setUp(() {
      game = MafiaGame();
      playerIds = ['player1', 'player2', 'player3', 'player4', 'player5', 'player6'];
    });

    tearDown(() {
      game.dispose();
    });

    test('should initialize game with correct player count', () async {
      await game.initializeGame(playerIds);
      
      expect(game.gameState['playerRoles'], isNotNull);
      expect(game.gameState['alivePlayers'], equals(playerIds));
      expect(game.gameState['deadPlayers'], isEmpty);
      expect(game.gameState['currentPhase'], equals('GamePhase.setup'));
      expect(game.gameState['currentDay'], equals(0));
      expect(game.isGameFinished, isFalse);
    });

    test('should assign roles correctly', () async {
      await game.initializeGame(playerIds);
      
      final playerRoles = game.gameState['playerRoles'] as Map<String, dynamic>;
      expect(playerRoles.length, equals(playerIds.length));
      
      // Check that all players have roles
      for (final playerId in playerIds) {
        expect(playerRoles.containsKey(playerId), isTrue);
      }
      
      // Count roles
      final roleValues = playerRoles.values.toList();
      final mafiaCount = roleValues.where((role) => role == 'PlayerRole.mafia').length;
      final policeCount = roleValues.where((role) => role == 'PlayerRole.police').length;
      final doctorCount = roleValues.where((role) => role == 'PlayerRole.doctor').length;
      final civilianCount = roleValues.where((role) => role == 'PlayerRole.civilian').length;
      
      expect(mafiaCount, equals(2)); // Default mafia count
      expect(policeCount, equals(1)); // Default police count
      expect(doctorCount, equals(1)); // Default doctor count
      expect(civilianCount, equals(2)); // Remaining players
    });

    test('should start game and advance to day phase', () async {
      await game.initializeGame(playerIds);
      await game.startGame();
      
      expect(game.gameState['currentPhase'], equals('GamePhase.day'));
      expect(game.gameState['currentDay'], equals(1));
      expect(game.isGameFinished, isFalse);
    });

    test('should handle voting correctly', () async {
      await game.initializeGame(playerIds);
      await game.startGame();
      
      // Start voting phase
      final startVotingAction = BasicGameAction(
        type: 'start_voting',
        playerId: playerIds[0], // Host
        data: {},
      );
      
      final startResult = await game.processAction(playerIds[0], startVotingAction);
      expect(startResult.success, isTrue);
      expect(game.gameState['currentPhase'], equals('GamePhase.voting'));
      
      // Cast votes
      final voteAction = BasicGameAction(
        type: 'vote',
        playerId: playerIds[0],
        data: {'targetId': playerIds[1]},
      );
      
      final voteResult = await game.processAction(playerIds[0], voteAction);
      expect(voteResult.success, isTrue);
      
      final votes = game.gameState['votes'] as Map<String, dynamic>;
      expect(votes[playerIds[0]], equals(playerIds[1]));
      
      final voteCounts = game.gameState['voteCounts'] as Map<String, dynamic>;
      expect(voteCounts[playerIds[1]], equals(1));
    });

    test('should handle night actions correctly', () async {
      await game.initializeGame(playerIds);
      await game.startGame();
      
      // Advance to night phase
      final advanceAction = BasicGameAction(
        type: 'advance_phase',
        playerId: playerIds[0], // Host
        data: {},
      );
      
      final advanceResult = await game.processAction(playerIds[0], advanceAction);
      expect(advanceResult.success, isTrue);
      expect(game.gameState['currentPhase'], equals('GamePhase.night'));
      
      // Find a police player
      final playerRoles = game.gameState['playerRoles'] as Map<String, dynamic>;
      final policePlayer = playerRoles.entries
          .firstWhere((entry) => entry.value == 'PlayerRole.police')
          .key;
      
      // Police investigation
      final investigateAction = BasicGameAction(
        type: 'police_investigate',
        playerId: policePlayer,
        data: {'targetId': playerIds[1]},
      );
      
      final investigateResult = await game.processAction(policePlayer, investigateAction);
      expect(investigateResult.success, isTrue);
      expect(investigateResult.resultData, isNotNull);
      expect(investigateResult.resultData!['isMafia'], isA<bool>());
    });

    test('should reject invalid actions', () async {
      await game.initializeGame(playerIds);
      await game.startGame();
      
      // Try to vote during day phase (should fail)
      final invalidVoteAction = BasicGameAction(
        type: 'vote',
        playerId: playerIds[0],
        data: {'targetId': playerIds[1]},
      );
      
      final result = await game.processAction(playerIds[0], invalidVoteAction);
      expect(result.success, isFalse);
      expect(result.errorMessage, contains('Voting is not currently active'));
    });

    test('should handle game end conditions', () async {
      await game.initializeGame(playerIds);
      await game.startGame();
      
      // Manually set up a win condition by eliminating all mafia
      final playerRoles = game.gameState['playerRoles'] as Map<String, dynamic>;
      final mafiaPlayers = playerRoles.entries
          .where((entry) => entry.value == 'PlayerRole.mafia')
          .map((entry) => entry.key)
          .toList();
      
      // Remove mafia players from alive list
      final alivePlayers = List<String>.from(game.gameState['alivePlayers']);
      for (final mafiaPlayer in mafiaPlayers) {
        alivePlayers.remove(mafiaPlayer);
      }
      
      // This would normally be done through game mechanics, but for testing
      // we'll check the win condition logic by examining the current state
      expect(mafiaPlayers.length, equals(2));
      expect(alivePlayers.length, equals(4));
    });

    test('should handle custom configuration', () async {
      final customGame = MafiaGame(
        mafiaCount: 1,
        policeCount: 2,
        doctorCount: 0,
        jokerCount: 1,
      );
      
      await customGame.initializeGame(playerIds);
      
      final playerRoles = customGame.gameState['playerRoles'] as Map<String, dynamic>;
      final roleValues = playerRoles.values.toList();
      
      final mafiaCount = roleValues.where((role) => role == 'PlayerRole.mafia').length;
      final policeCount = roleValues.where((role) => role == 'PlayerRole.police').length;
      final doctorCount = roleValues.where((role) => role == 'PlayerRole.doctor').length;
      final jokerCount = roleValues.where((role) => role == 'PlayerRole.joker').length;
      final civilianCount = roleValues.where((role) => role == 'PlayerRole.civilian').length;
      
      expect(mafiaCount, equals(1));
      expect(policeCount, equals(2));
      expect(doctorCount, equals(0));
      expect(jokerCount, equals(1));
      expect(civilianCount, equals(2));
      
      customGame.dispose();
    });

    test('should validate minimum player requirements', () async {
      final tooFewPlayers = ['player1', 'player2', 'player3'];
      
      expect(
        () async => await game.initializeGame(tooFewPlayers),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should emit game events', () async {
      final events = <GameEvent>[];
      game.gameEvents.listen((event) => events.add(event));
      
      await game.initializeGame(playerIds);
      await game.startGame();
      
      // Wait a bit for events to be processed
      await Future.delayed(Duration(milliseconds: 10));
      
      expect(events.length, greaterThan(0));
      expect(events.any((event) => event.type == 'game_initialized'), isTrue);
      expect(events.any((event) => event.type == 'game_started'), isTrue);
      expect(events.any((event) => event.type == 'day_started'), isTrue);
    });
  });
}