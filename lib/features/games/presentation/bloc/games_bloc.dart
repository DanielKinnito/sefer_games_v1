import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sefer_games_v1/features/games/domain/repositories/game_repository.dart';
import 'package:sefer_games_v1/features/games/presentation/bloc/games_event.dart';
import 'package:sefer_games_v1/features/games/presentation/bloc/games_state.dart';

class GamesBloc extends Bloc<GamesEvent, GamesState> {
  final GameRepository gameRepository;

  GamesBloc({required this.gameRepository}) : super(GamesInitial()) {
    on<LoadGames>((event, emit) async {
      emit(GamesLoading());
      try {
        final games = await gameRepository.getGames();
        emit(GamesLoaded(games));
      } catch (e) {
        emit(GamesError(e.toString()));
      }
    });
  }
}
