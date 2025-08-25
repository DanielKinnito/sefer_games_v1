import '../../../core/game/game_base.dart';
import 'number_guessing/number_guessing_game.dart';
import 'word_blitz/word_blitz_registration.dart';
import 'mafia/mafia_game.dart';

/// Initialize and register all available games
void initializeGames() {
  // Register the number guessing game with metadata
  _registerNumberGuessingGame();
  
  // Register Word Blitz game with metadata
  WordBlitzRegistration.registerGame();
  
  // Register Mafia game with metadata
  _registerMafiaGame();
  
  // TODO: Register other games here as they are implemented
  // GameRegistry.registerGame('20Questions', () => TwentyQuestionsGame());
}

/// Register Number Guessing game with metadata
void _registerNumberGuessingGame() {
  final metadata = GameMetadata(
    gameType: NumberGuessingGame.gameTypeId,
    displayName: 'Number Guessing',
    description: 'Classic number guessing game where players try to guess a secret number within a range. Great for warming up!',
    minPlayers: 2,
    maxPlayers: 8,
    estimatedDuration: Duration(minutes: 10),
    requiredPermissions: [],
    defaultConfig: {
      'minNumber': 1,
      'maxNumber': 100,
      'maxGuesses': 10,
      'maxRounds': 3,
    },
    iconPath: 'assets/games/number_guessing_icon.png',
    tags: ['classic', 'number', 'quick', 'easy'],
  );

  GameRegistry.registerGameWithMetadata(
    NumberGuessingGame.gameTypeId,
    () => NumberGuessingGame(),
    metadata,
  );
}
/// Register Mafia game with metadata
void _registerMafiaGame() {
  final metadata = GameMetadata(
    gameType: MafiaGame.gameTypeId,
    displayName: 'Mafia',
    description: 'Classic social deduction game where players are secretly assigned roles. Mafia members try to eliminate others while remaining hidden, and town members try to identify and vote out the mafia.',
    minPlayers: 6,
    maxPlayers: 20,
    estimatedDuration: Duration(minutes: 30),
    requiredPermissions: [],
    defaultConfig: {
      'mafiaCount': 2,
      'policeCount': 1,
      'doctorCount': 1,
      'jokerCount': 0,
      'doctorCanSaveSamePerson': false,
      'doctorCanSaveSelf': true,
      'dayDurationMinutes': 10,
      'nightDurationMinutes': 5,
      'votingDurationMinutes': 3,
    },
    iconPath: 'assets/games/mafia_icon.png',
    tags: ['social', 'deduction', 'strategy', 'party', 'long'],
  );

  GameRegistry.registerGameWithMetadata(
    MafiaGame.gameTypeId,
    () => MafiaGame(),
    metadata,
  );
}