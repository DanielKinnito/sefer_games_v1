import 'package:sefer_games_v1/features/games/domain/entities/game_info.dart';

abstract class GameRepository {
  Future<List<GameInfo>> getGames();
}
