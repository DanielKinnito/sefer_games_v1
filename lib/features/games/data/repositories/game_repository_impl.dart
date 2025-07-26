import 'package:sefer_games_v1/features/games/domain/entities/game_info.dart';
import 'package:sefer_games_v1/features/games/domain/repositories/game_repository.dart';

class GameRepositoryImpl implements GameRepository {
  @override
  Future<List<GameInfo>> getGames() async {
    // In a real app, this would fetch from a server or database
    return [
      GameInfo(
        id: 'number_guessing',
        title: 'Number Guessing',
        description: 'Guess the number between 1 and 100.',
        iconPath: 'assets/images/number_guessing_icon.png',
      ),
      // Add more games here
    ];
  }
}
