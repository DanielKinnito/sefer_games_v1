import 'package:flutter_test/flutter_test.dart';
import 'package:lan_party_app/features/games/word_blitz/errors/word_blitz_errors.dart';

void main() {
  group('WordBlitzError', () {
    test('should create error with message and type', () {
      final error = WordBlitzError(
        'Test error message',
        WordBlitzErrorType.invalidTheme,
        context: {'theme': 'InvalidTheme'},
      );

      expect(error.message, 'Test error message');
      expect(error.wordBlitzErrorType, WordBlitzErrorType.invalidTheme);
      expect(error.context, {'theme': 'InvalidTheme'});
    });

    test('should have correct string representation', () {
      final error = WordBlitzError(
        'Test error',
        WordBlitzErrorType.hostPermissionRequired,
      );

      expect(error.toString(), contains('WordBlitzError: Test error'));
      expect(error.toString(), contains('hostPermissionRequired'));
    });
  });

  group('WordBlitzErrorHandler', () {
    test('should return user-friendly messages for Word Blitz errors', () {
      final invalidThemeError = WordBlitzError(
        'Invalid theme',
        WordBlitzErrorType.invalidTheme,
      );

      final message = WordBlitzErrorHandler.getUserFriendlyMessage(invalidThemeError);
      expect(message, contains('theme is not available'));
    });

    test('should return user-friendly messages for all error types', () {
      final testCases = [
        (WordBlitzErrorType.invalidTheme, 'theme is not available'),
        (WordBlitzErrorType.noActivePlayers, 'No active players'),
        (WordBlitzErrorType.roundNotActive, 'No round is currently active'),
        (WordBlitzErrorType.hostPermissionRequired, 'Only the host'),
        (WordBlitzErrorType.playerAlreadyEliminated, 'already been eliminated'),
        (WordBlitzErrorType.themeNotAvailable, 'not in the available themes'),
        (WordBlitzErrorType.customThemesDisabled, 'Custom themes are not allowed'),
        (WordBlitzErrorType.invalidPlayerCount, 'Invalid number of players'),
        (WordBlitzErrorType.gameNotInitialized, 'not been initialized'),
        (WordBlitzErrorType.roundTimeout, 'timed out'),
        (WordBlitzErrorType.invalidConfiguration, 'Invalid game configuration'),
      ];

      for (final (errorType, expectedText) in testCases) {
        final error = WordBlitzError('Test', errorType);
        final message = WordBlitzErrorHandler.getUserFriendlyMessage(error);
        expect(message.toLowerCase(), contains(expectedText.toLowerCase()),
            reason: 'Error type $errorType should contain "$expectedText"');
      }
    });

    test('should identify retryable errors correctly', () {
      final retryableErrors = [
        WordBlitzErrorType.roundTimeout,
        WordBlitzErrorType.gameNotInitialized,
        WordBlitzErrorType.invalidTheme,
        WordBlitzErrorType.noActivePlayers,
      ];

      final nonRetryableErrors = [
        WordBlitzErrorType.hostPermissionRequired,
        WordBlitzErrorType.customThemesDisabled,
        WordBlitzErrorType.invalidPlayerCount,
        WordBlitzErrorType.invalidConfiguration,
      ];

      for (final errorType in retryableErrors) {
        final error = WordBlitzError('Test', errorType);
        expect(WordBlitzErrorHandler.isRetryableError(error), isTrue,
            reason: '$errorType should be retryable');
      }

      for (final errorType in nonRetryableErrors) {
        final error = WordBlitzError('Test', errorType);
        expect(WordBlitzErrorHandler.isRetryableError(error), isFalse,
            reason: '$errorType should not be retryable');
      }
    });

    test('should provide recovery actions for errors', () {
      final testCases = [
        (WordBlitzErrorType.invalidTheme, 'Select a theme'),
        (WordBlitzErrorType.noActivePlayers, 'Start a new round'),
        (WordBlitzErrorType.roundNotActive, 'start a new round'),
        (WordBlitzErrorType.hostPermissionRequired, 'Only the host'),
        (WordBlitzErrorType.customThemesDisabled, 'predefined themes'),
      ];

      for (final (errorType, expectedText) in testCases) {
        final error = WordBlitzError('Test', errorType);
        final recoveryAction = WordBlitzErrorHandler.getRecoveryAction(error);
        expect(recoveryAction, isNotNull);
        expect(recoveryAction!.toLowerCase(), contains(expectedText.toLowerCase()),
            reason: 'Recovery action for $errorType should contain "$expectedText"');
      }
    });

    test('should create specific error instances', () {
      final invalidThemeError = WordBlitzErrorHandler.invalidTheme('TestTheme');
      expect(invalidThemeError.wordBlitzErrorType, WordBlitzErrorType.invalidTheme);
      expect(invalidThemeError.context?['theme'], 'TestTheme');

      final noActivePlayersError = WordBlitzErrorHandler.noActivePlayers();
      expect(noActivePlayersError.wordBlitzErrorType, WordBlitzErrorType.noActivePlayers);

      final hostPermissionError = WordBlitzErrorHandler.hostPermissionRequired('test_action');
      expect(hostPermissionError.wordBlitzErrorType, WordBlitzErrorType.hostPermissionRequired);
      expect(hostPermissionError.context?['action'], 'test_action');

      final playerEliminatedError = WordBlitzErrorHandler.playerAlreadyEliminated('player1');
      expect(playerEliminatedError.wordBlitzErrorType, WordBlitzErrorType.playerAlreadyEliminated);
      expect(playerEliminatedError.context?['playerId'], 'player1');

      final invalidPlayerCountError = WordBlitzErrorHandler.invalidPlayerCount(2);
      expect(invalidPlayerCountError.wordBlitzErrorType, WordBlitzErrorType.invalidPlayerCount);
      expect(invalidPlayerCountError.context?['playerCount'], 2);
    });
  });

  group('WordBlitzValidator', () {
    test('should validate theme selection correctly', () {
      final availableThemes = ['Countries', 'Movies', 'Animals'];

      // Valid theme
      expect(
        () => WordBlitzValidator.validateTheme('Countries', availableThemes, false),
        returnsNormally,
      );

      // Invalid theme with custom themes disabled
      expect(
        () => WordBlitzValidator.validateTheme('CustomTheme', availableThemes, false),
        throwsA(isA<WordBlitzError>()),
      );

      // Invalid theme with custom themes enabled (should pass)
      expect(
        () => WordBlitzValidator.validateTheme('CustomTheme', availableThemes, true),
        returnsNormally,
      );

      // Empty theme
      expect(
        () => WordBlitzValidator.validateTheme('', availableThemes, true),
        throwsA(isA<WordBlitzError>()),
      );
    });

    test('should validate player count correctly', () {
      // Valid player counts
      for (int count = 3; count <= 10; count++) {
        expect(
          () => WordBlitzValidator.validatePlayerCount(count),
          returnsNormally,
          reason: 'Player count $count should be valid',
        );
      }

      // Invalid player counts
      final invalidCounts = [0, 1, 2, 11, 15, 100];
      for (final count in invalidCounts) {
        expect(
          () => WordBlitzValidator.validatePlayerCount(count),
          throwsA(isA<WordBlitzError>()),
          reason: 'Player count $count should be invalid',
        );
      }
    });

    test('should validate round state for actions correctly', () {
      // Actions that require active round
      final activeRoundActions = ['eliminate_player', 'end_round', 'pause_round'];
      
      for (final action in activeRoundActions) {
        // Should pass when round is active
        expect(
          () => WordBlitzValidator.validateRoundActive(true, action),
          returnsNormally,
          reason: 'Action $action should be valid when round is active',
        );

        // Should fail when round is not active
        expect(
          () => WordBlitzValidator.validateRoundActive(false, action),
          throwsA(isA<WordBlitzError>()),
          reason: 'Action $action should be invalid when round is not active',
        );
      }

      // Actions that don't require active round
      final nonActiveRoundActions = ['set_theme', 'start_round', 'add_custom_theme'];
      
      for (final action in nonActiveRoundActions) {
        expect(
          () => WordBlitzValidator.validateRoundActive(false, action),
          returnsNormally,
          reason: 'Action $action should be valid when round is not active',
        );
      }
    });

    test('should validate player elimination correctly', () {
      final activePlayers = ['player1', 'player2', 'player3'];

      // Valid elimination
      expect(
        () => WordBlitzValidator.validatePlayerElimination('player1', activePlayers),
        returnsNormally,
      );

      // Invalid elimination (player not active)
      expect(
        () => WordBlitzValidator.validatePlayerElimination('player4', activePlayers),
        throwsA(isA<WordBlitzError>()),
      );
    });

    test('should validate host permissions correctly', () {
      final hostOnlyActions = ['set_theme', 'eliminate_player', 'start_round'];
      final playerActions = ['add_custom_theme', 'sync_game_state'];

      // Host should be able to perform host-only actions
      for (final action in hostOnlyActions) {
        expect(
          () => WordBlitzValidator.validateHostPermission(true, action),
          returnsNormally,
          reason: 'Host should be able to perform $action',
        );

        // Non-host should not be able to perform host-only actions
        expect(
          () => WordBlitzValidator.validateHostPermission(false, action),
          throwsA(isA<WordBlitzError>()),
          reason: 'Non-host should not be able to perform $action',
        );
      }

      // Both host and non-host should be able to perform player actions
      for (final action in playerActions) {
        expect(
          () => WordBlitzValidator.validateHostPermission(true, action),
          returnsNormally,
          reason: 'Host should be able to perform $action',
        );

        expect(
          () => WordBlitzValidator.validateHostPermission(false, action),
          returnsNormally,
          reason: 'Non-host should be able to perform $action',
        );
      }
    });

    test('should validate custom theme addition correctly', () {
      // Valid custom theme
      expect(
        () => WordBlitzValidator.validateCustomTheme(true, 'MyCustomTheme'),
        returnsNormally,
      );

      // Custom themes disabled
      expect(
        () => WordBlitzValidator.validateCustomTheme(false, 'MyCustomTheme'),
        throwsA(isA<WordBlitzError>()),
      );

      // Empty theme
      expect(
        () => WordBlitzValidator.validateCustomTheme(true, ''),
        throwsA(isA<WordBlitzError>()),
      );

      // Theme too long
      final longTheme = 'A' * 51; // 51 characters
      expect(
        () => WordBlitzValidator.validateCustomTheme(true, longTheme),
        throwsA(isA<WordBlitzError>()),
      );
    });

    test('should validate game configuration correctly', () {
      // Valid configuration
      final validConfig = {
        'availableThemes': ['Countries', 'Movies'],
        'roundsToWin': 3,
        'roundTimeoutMinutes': 2,
        'allowCustomThemes': false,
      };

      expect(
        () => WordBlitzValidator.validateGameConfiguration(validConfig),
        returnsNormally,
      );

      // Missing themes
      final noThemesConfig = {
        'availableThemes': <String>[],
        'roundsToWin': 3,
        'roundTimeoutMinutes': 2,
      };

      expect(
        () => WordBlitzValidator.validateGameConfiguration(noThemesConfig),
        throwsA(isA<WordBlitzError>()),
      );

      // Invalid rounds to win
      final invalidRoundsConfig = {
        'availableThemes': ['Countries'],
        'roundsToWin': 0,
        'roundTimeoutMinutes': 2,
      };

      expect(
        () => WordBlitzValidator.validateGameConfiguration(invalidRoundsConfig),
        throwsA(isA<WordBlitzError>()),
      );

      // Invalid timeout
      final invalidTimeoutConfig = {
        'availableThemes': ['Countries'],
        'roundsToWin': 3,
        'roundTimeoutMinutes': 0,
      };

      expect(
        () => WordBlitzValidator.validateGameConfiguration(invalidTimeoutConfig),
        throwsA(isA<WordBlitzError>()),
      );
    });
  });
}