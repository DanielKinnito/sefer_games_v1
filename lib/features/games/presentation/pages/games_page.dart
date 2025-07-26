import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:sefer_games_v1/features/games/data/repositories/game_repository_impl.dart';
import 'package:sefer_games_v1/features/games/presentation/bloc/games_bloc.dart';
import 'package:sefer_games_v1/features/games/presentation/bloc/games_event.dart';
import 'package:sefer_games_v1/features/games/presentation/bloc/games_state.dart';
import 'package:sefer_games_v1/features/games/presentation/widgets/game_card.dart';

class GamesPage extends StatelessWidget {
  const GamesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GamesBloc(
        gameRepository: GameRepositoryImpl(),
      )..add(LoadGames()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Games'),
        ),
        body: BlocBuilder<GamesBloc, GamesState>(
          builder: (context, state) {
            if (state is GamesLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is GamesLoaded) {
              return MasonryGridView.count(
                padding: const EdgeInsets.all(8),
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                itemCount: state.games.length,
                itemBuilder: (context, index) {
                  final game = state.games[index];
                  // Use a pseudo-random height for demonstration
                  final height = (game.title.length % 5 + 1) * 100.0;
                  return SizedBox(
                    height: height,
                    child: GameCard(game: game),
                  );
                },
              );
            } else if (state is GamesError) {
              return Center(child: Text(state.message));
            }
            return const Center(child: Text('Select a game to start!'));
          },
        ),
      ),
    );
  }
}
