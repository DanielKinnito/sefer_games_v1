import 'package:equatable/equatable.dart';
import 'package:sefer_games_v1/features/games/domain/entities/game_info.dart';

abstract class GamesState extends Equatable {
  const GamesState();

  @override
  List<Object> get props => [];
}

class GamesInitial extends GamesState {}

class GamesLoading extends GamesState {}

class GamesLoaded extends GamesState {
  final List<GameInfo> games;

  const GamesLoaded(this.games);

  @override
  List<Object> get props => [games];
}

class GamesError extends GamesState {
  final String message;

  const GamesError(this.message);

  @override
  List<Object> get props => [message];
}
