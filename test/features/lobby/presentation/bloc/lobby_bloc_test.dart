import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:sefer_games_v1/features/lobby/presentation/bloc/lobby_bloc.dart';
import 'package:sefer_games_v1/features/lobby/data/repositories/lobby_repository_impl.dart';
import 'package:sefer_games_v1/features/lobby/domain/usecases/create_lobby.dart';
import 'package:sefer_games_v1/features/lobby/domain/usecases/join_lobby.dart';
import 'package:sefer_games_v1/features/lobby/domain/usecases/get_available_lobbies.dart';
import 'package:sefer_games_v1/features/lobby/domain/usecases/leave_lobby.dart';
import 'package:sefer_games_v1/features/lobby/domain/usecases/start_hosting.dart';
import 'package:sefer_games_v1/features/lobby/domain/usecases/discover_local_lobbies.dart';

void main() {
  group('LobbyBloc', () {
    final repository = LobbyRepositoryImpl();
    final createLobby = CreateLobby(repository);
    final joinLobby = JoinLobby(repository);
    final getAvailableLobbies = GetAvailableLobbies(repository);
    final leaveLobby = LeaveLobby(repository);
    final startHosting = StartHosting(repository);
    final discoverLocalLobbies = DiscoverLocalLobbies(repository);
    late LobbyBloc bloc;

    setUp(() {
      bloc = LobbyBloc(
        createLobby: createLobby,
        joinLobby: joinLobby,
        getAvailableLobbies: getAvailableLobbies,
        leaveLobby: leaveLobby,
        startHosting: startHosting,
        discoverLocalLobbies: discoverLocalLobbies,
      );
    });

    blocTest<LobbyBloc, LobbyState>(
      'emits [LobbyLoading, LobbyCreated] when CreateLobbyEvent is added',
      build: () => bloc,
      act: (bloc) => bloc.add(CreateLobbyEvent('Test Lobby', 'Host1', 'avatar1', 'WordBlitz')),
      expect: () => [isA<LobbyLoading>(), isA<LobbyCreated>()],
    );
  });
}
