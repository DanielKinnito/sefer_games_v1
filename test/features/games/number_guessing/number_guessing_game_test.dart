import 'package:flutter_test/flutter_test.dart';
import 'package:sefer_games_v1/features/games/number_guessing/number_guessing_game.dart';
import 'package:sefer_games_v1/core/game/game_base.dart';

void main() {
  group('NumberGuessingGame', () {
    late NumberGuessingGame game;

    setUp(() {
      game = NumberGuessingGame();
    });

    tearDown(() {
      game.dispose();
    });

    group('Game Properties', () {
      test('should have correct game properties', () {
        expect(game.gameName, 'Number Guessing Game');
        expect(game.gameType, 'NumberGuessing');
        expect(game.minPlayers, 2);
        expect(game.maxPlayers, 8);
        expect(game.isGameFinished, false);
      });

      test('should have unique game ID after initialization', () async {
        await game.initializeGame(['player1', 'player2']);
        expect(game.gameId, isNotEmpty);
        expect(game.gameId, startsWith('number_game_'));
      });
    });

    group('Game Initialization', () {
      test('should initialize game with players', () async {
        final players = ['player1', 'player2', 'player3'];
        await game.initializeGame(players);

        final state = game.gameState;
        expect(state['players'], players);
        expect(state['currentRound'], 1);
        expect(state['maxRounds'], 3);
        expect(state['currentGuesser'], 'player1');
        expect(state['scores'], {
          'player1': 0,
          'player2': 0,
          'player3': 0,
        });
        expect(state['targetNumber'], isA<int>());
        expect(state['targetNumber'], inInclusiveRange(1, 100));
      });

      test('should handle empty player list', () async {
        await game.initializeGame([]);
        
        final state = game.gameState;
        expect(state['players'], isEmpty);
        expect(state['currentGuesser'], isNull);
      });
    });

    group('Game Flow', () {
      setUp(() async {
        await game.initializeGame(['player1', 'player2']);
        await game.startGame();
      });

      test('should start game successfully', () async {
        final state = game.gameState;
        expect(state['currentGuesser'], 'player1');
        expect(state['currentRound'], 1);
      });

      test('should handle correct guess', () async {
        final state = game.gameState;
        final targetNumber = state['targetNumber'] as int;

        final action = BasicGameAction(
          type: 'make_guess',
          playerId: 'player1',
          data: {'guess': targetNumber},
        );

        final result = await game.processAction('player1', action);

        expect(result.success, true);
        expect(result.resultData!['result'], 'correct');
        expect(result.resultData!['points'], 10);

        final updatedState = game.gameState;
        expect(updatedState['scores']['player1'], 10);
      });

      test('should handle incorrect guess - too low', () async {
        final state = game.gameState;
        final targetNumber = state['targetNumber'] as int;

        final action = BasicGameAction(
          type: 'make_guess',
          playerId: 'player1',
          data: {'guess': targetNumber - 10}, // Definitely too low
        );

        final result = await game.processAction('player1', action);

        expect(result.success, true);
        expect(result.resultData!['result'], 'too_low');
        expect(result.resultData!['points'], 0);
        expect(result.resultData!['nextGuesser'], 'player2');
      });

      test('should handle incorrect guess - too high', () async {
        final state = game.gameState;
        final targetNumber = state['targetNumber'] as int;

        final action = BasicGameAction(
          type: 'make_guess',
          playerId: 'player1',
          data: {'guess': targetNumber + 10}, // Definitely too high
        );

        final result = await game.processAction('player1', action);

        expect(result.success, true);
        expect(result.resultData!['result'], 'too_high');
        expect(result.resultData!['points'], 0);
      });

      test('should reject guess from wrong player', () async {
        final action = BasicGameAction(
          type: 'make_guess',
          playerId: 'player2', // Not current guesser
          data: {'guess': 50},
        );

        final result = await game.processAction('player2', action);

        expect(result.success, false);
        expect(result.errorMessage, contains('Not your turn'));
      });

      test('should reject invalid guess', () async {
        final action = BasicGameAction(
          type: 'make_guess',
          playerId: 'player1',
          data: {}, // No guess provided
        );

        final result = await game.processAction('player1', action);

        expect(result.success, false);
        expect(result.errorMessage, contains('Invalid guess'));
      });

      test('should handle unknown action type', () async {
        final action = BasicGameAction(
          type: 'unknown_action',
          playerId: 'player1',
          data: {},
        );

        final result = await game.processAction('player1', action);

        expect(result.success, false);
        expect(result.errorMessage, contains('Unknown action type'));
      });
    });

    group('Game Rounds', () {
      setUp(() async {
        await game.initializeGame(['player1', 'player2']);
        await game.startGame();
      });

      test('should advance to next round after correct guess', () async {
        final state = game.gameState;
        final targetNumber = state['targetNumber'] as int;

        // Make correct guess
        final action = BasicGameAction(
          type: 'make_guess',
          playerId: 'player1',
          data: {'guess': targetNumber},
        );

        await game.processAction('player1', action);

        final updatedState = game.gameState;
        expect(updatedState['currentRound'], 2);
        expect(updatedState['targetNumber'], isNot(targetNumber)); // New number
      });

      test('should finish game after max rounds', () async {
        // Play through all rounds
        for (int round = 1; round <= 3; round++) {
          final state = game.gameState;
          final targetNumber = state['targetNumber'] as int;

          final action = BasicGameAction(
            type: 'make_guess',
            playerId: 'player1',
            data: {'guess': targetNumber},
          );

          await game.processAction('player1', action);
        }

        expect(game.isGameFinished, true);
        
        final results = game.gameResults;
        expect(results['finalScores'], isA<Map>());
        expect(results['winner'], 'player1');
        expect(results['rankings'], isA<List>());
      });

      test('should handle next round action', () async {
        final action = BasicGameAction(
          type: 'next_round',
          playerId: 'player1',
          data: {},
        );

        final result = await game.processAction('player1', action);

        expect(result.success, true);
        expect(result.resultData!['newRound'], 2);

        final state = game.gameState;
        expect(state['currentRound'], 2);
        expect(state['currentGuesser'], 'player1'); // Reset to first player
      });

      test('should reject next round when game is finished', () async {
        // Manually set game as finished
        game.dispose(); // This might not be the best way, but for testing
        game = NumberGuessingGame();
        await game.initializeGame(['player1', 'player2']);
        await game.startGame();

        // Play through all rounds to finish game
        for (int round = 1; round <= 3; round++) {
          final state = game.gameState;
          final targetNumber = state['targetNumber'] as int;

          final action = BasicGameAction(
            type: 'make_guess',
            playerId: 'player1',
            data: {'guess': targetNumber},
          );

          await game.processAction('player1', action);
        }

        // Try to advance round when game is finished
        final nextRoundAction = BasicGameAction(
          type: 'next_round',
          playerId: 'player1',
          data: {},
        );

        final result = await game.processAction('player1', nextRoundAction);

        expect(result.success, false);
        expect(result.errorMessage, contains('already finished'));
      });
    });

    group('Game Events', () {
      test('should emit events on game actions', () async {
        final events = <GameEvent>[];
        final subscription = game.gameEvents.listen(events.add);

        await game.initializeGame(['player1', 'player2']);
        await game.startGame();

        // Wait a bit for events to be emitted
        await Future.delayed(const Duration(milliseconds: 10));

        expect(events, isNotEmpty);
        expect(events.any((e) => e.type == 'game_initialized'), true);
        expect(events.any((e) => e.type == 'game_started'), true);

        subscription.cancel();
      });

      test('should emit guess events', () async {
        await game.initializeGame(['player1', 'player2']);
        await game.startGame();

        final events = <GameEvent>[];
        final subscription = game.gameEvents.listen((event) {
          if (event.type.contains('guess')) {
            events.add(event);
          }
        });

        final action = BasicGameAction(
          type: 'make_guess',
          playerId: 'player1',
          data: {'guess': 50},
        );

        await game.processAction('player1', action);

        await Future.delayed(const Duration(milliseconds: 10));

        expect(events, isNotEmpty);
        expect(events.any((e) => e.type == 'guess_made'), true);

        subscription.cancel();
      });
    });

    group('Player Turn Management', () {
      setUp(() async {
        await game.initializeGame(['player1', 'player2', 'player3']);
        await game.startGame();
      });

      test('should rotate between players correctly', () async {
        // Player 1's turn
        expect(game.gameState['currentGuesser'], 'player1');

        // Make a wrong guess to move to next player
        await game.processAction('player1', BasicGameAction(
          type: 'make_guess',
          playerId: 'player1',
          data: {'guess': 1}, // Likely wrong
        ));

        // Should be player 2's turn
        expect(game.gameState['currentGuesser'], 'player2');

        // Make another wrong guess
        await game.processAction('player2', BasicGameAction(
          type: 'make_guess',
          playerId: 'player2',
          data: {'guess': 1}, // Likely wrong
        ));

        // Should be player 3's turn
        expect(game.gameState['currentGuesser'], 'player3');
      });
    });
  });
}
