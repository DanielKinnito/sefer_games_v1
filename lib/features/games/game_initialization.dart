import '../../../core/game/game_base.dart';
import 'number_guessing/number_guessing_game.dart';

/// Initialize and register all available games
void initializeGames() {
  // Register the number guessing game
  GameRegistry.registerGame(
    NumberGuessingGame.gameTypeId,
    () => NumberGuessingGame(),
  );
  
  // TODO: Register other games here as they are implemented
  // GameRegistry.registerGame('WordBlitz', () => WordBlitzGame());
  // GameRegistry.registerGame('Mafia', () => MafiaGame());
  // GameRegistry.registerGame('20Questions', () => TwentyQuestionsGame());
}
