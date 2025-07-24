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
import 'package:sefer_games_v1/features/lobby/domain/entities/lobby.dart';

void main() {
  group('LobbyBloc', () {
    late LobbyRepositoryImpl repository;
    late CreateLobby createLobby;
    late JoinLobby joinLobby;
    late GetAvailableLobbies getAvailableLobbies;
    late LeaveLobby leaveLobby;
    late StartHosting startHosting;
    late DiscoverLocalLobbies discoverLocalLobbies;
    late LobbyBloc bloc;

    setUp(() {
      repository = LobbyRepositoryImpl();
      createLobby = CreateLobby(repository);
      joinLobby = JoinLobby(repository);
      getAvailableLobbies = GetAvailableLobbies(repository);
      leaveLobby = LeaveLobby(repository);
      startHosting = StartHosting(repository);
      discoverLocalLobbies = DiscoverLocalLobbies(repository);
      
      bloc = LobbyBloc(
        createLobby: createLobby,
        joinLobby: joinLobby,
        getAvailableLobbies: getAvailableLobbies,
        leaveLobby: leaveLobby,
        startHosting: startHosting,
        discoverLocalLobbies: discoverLocalLobbies,
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state is LobbyInitial', () {
      expect(bloc.state, equals(LobbyInitial()));
    });

    group('CreateLobbyEvent', () {
      blocTest<LobbyBloc, LobbyState>(
        'emits [LobbyLoading, LobbyCreated] when CreateLobbyEvent is added',
        build: () => bloc,
        act: (bloc) => bloc.add(CreateLobbyEvent('Test Lobby', 'Host1', 'avatar1', 'NumberGuessing')),
        expect: () => [
          isA<LobbyLoading>(),
          isA<LobbyCreated>().having(
            (state) => state.lobby.name,
            'lobby name',
            'Test Lobby',
          ),
        ],
      );

      blocTest<LobbyBloc, LobbyState>(
        'emits [LobbyLoading, LobbyCreated] with custom max players',
        build: () => bloc,
        act: (bloc) => bloc.add(CreateLobbyEvent('Small Lobby', 'Host1', 'avatar1', 'NumberGuessing', maxPlayers: 4)),
        expect: () => [
          isA<LobbyLoading>(),
          isA<LobbyCreated>().having(
            (state) => state.lobby.maxPlayers,
            'max players',
            4,
          ),
        ],
      );

      blocTest<LobbyBloc, LobbyState>(
        'emits [LobbyLoading, LobbyError] when create lobby fails',
        build: () => bloc,
        act: (bloc) => bloc.add(CreateLobbyEvent('', '', '', '')), // Invalid inputs
        expect: () => [
          isA<LobbyLoading>(),
          isA<LobbyError>(),
        ],
      );
    });

    group('JoinLobbyEvent', () {
      blocTest<LobbyBloc, LobbyState>(
        'emits [LobbyLoading, LobbyJoined] when joining existing lobby',
        build: () => bloc,
        seed: () {
          // Pre-create a lobby for joining
          return LobbyInitial();
        },
        act: (bloc) async {
          // First create a lobby
          final testLobby = await repository.createLobby('Test Lobby', 'Host1', 'avatar1', 'NumberGuessing');
          // Then join it
          bloc.add(JoinLobbyEvent(testLobby.id, 'Player1', 'avatar2'));
        },
        expect: () => [
          isA<LobbyLoading>(),
          isA<LobbyJoined>().having(
            (state) => state.lobby.players.length,
            'players count',
            2,
          ),
        ],
      );

      blocTest<LobbyBloc, LobbyState>(
        'emits [LobbyLoading, LobbyError] when joining non-existent lobby',
        build: () => bloc,
        act: (bloc) => bloc.add(JoinLobbyEvent('non-existent-id', 'Player1', 'avatar1')),
        expect: () => [
          isA<LobbyLoading>(),
          isA<LobbyError>().having(
            (state) => state.message,
            'error message',
            contains('not found'),
          ),
        ],
      );
    });

    group('LoadLobbiesEvent', () {
      blocTest<LobbyBloc, LobbyState>(
        'emits [LobbyLoading, LobbyLoaded] when loading lobbies',
        build: () => bloc,
        setUp: () async {
          // Pre-create some lobbies
          await repository.createLobby('Lobby 1', 'Host1', 'avatar1', 'NumberGuessing');
          await repository.createLobby('Lobby 2', 'Host2', 'avatar1', 'NumberGuessing');
        },
        act: (bloc) => bloc.add(LoadLobbiesEvent()),
        expect: () => [
          isA<LobbyLoading>(),
          isA<LobbyLoaded>().having(
            (state) => state.lobbies.length,
            'lobbies count',
            greaterThanOrEqualTo(2),
          ),
        ],
      );
    });

    group('LeaveLobbyEvent', () {
      blocTest<LobbyBloc, LobbyState>(
        'emits [LobbyLoading, LobbyLoaded] when leaving lobby',
        build: () => bloc,
        act: (bloc) async {
          // Create and join a lobby first
          final testLobby = await repository.createLobby('Test Lobby', 'Host1', 'avatar1', 'NumberGuessing');
          await repository.joinLobby(testLobby.id, 'Player1', 'avatar2');
          
          // Get player to leave
          final lobby = await repository.getLobby(testLobby.id);
          final player = lobby!.players.firstWhere((p) => p.name == 'Player1');
          
          bloc.add(LeaveLobbyEvent(testLobby.id, player.id));
        },
        expect: () => [
          isA<LobbyLoading>(),
          isA<LobbyLoaded>(),
        ],
      );
    });

    group('StartHostingEvent', () {
      blocTest<LobbyBloc, LobbyState>(
        'emits [LobbyLoading, LobbyHosting] when starting to host',
        build: () => bloc,
        act: (bloc) async {
          // Create a lobby first
          final testLobby = await repository.createLobby('Host Test', 'Host1', 'avatar1', 'NumberGuessing');
          bloc.add(StartHostingEvent(testLobby.id));
        },
        expect: () => [
          isA<LobbyLoading>(),
          isA<LobbyHosting>().having(
            (state) => state.hostAddress,
            'host address',
            isNotEmpty,
          ),
        ],
      );

      blocTest<LobbyBloc, LobbyState>(
        'emits [LobbyLoading, LobbyError] when hosting non-existent lobby',
        build: () => bloc,
        act: (bloc) => bloc.add(StartHostingEvent('non-existent-id')),
        expect: () => [
          isA<LobbyLoading>(),
          isA<LobbyError>(),
        ],
      );
    });

    group('DiscoverLocalLobbiesEvent', () {
      blocTest<LobbyBloc, LobbyState>(
        'emits [LobbyLoading, LobbyLoaded] when discovering lobbies',
        build: () => bloc,
        setUp: () async {
          // Create and host some lobbies
          final lobby1 = await repository.createLobby('Discoverable 1', 'Host1', 'avatar1', 'NumberGuessing');
          final lobby2 = await repository.createLobby('Discoverable 2', 'Host2', 'avatar1', 'NumberGuessing');
          await repository.startHosting(lobby1.id);
          await repository.startHosting(lobby2.id);
        },
        act: (bloc) => bloc.add(DiscoverLocalLobbiesEvent()),
        expect: () => [
          isA<LobbyLoading>(),
          isA<LobbyLoaded>(),
        ],
      );
    });

    group('State Transitions', () {
      test('LobbyCreated state contains correct lobby data', () {
        final testLobby = LobbyEntity(
          id: 'test-id',
          name: 'Test Lobby',
          hostId: 'host-1',
          players: const [],
          gameType: 'NumberGuessing',
        );
        
        final state = LobbyCreated(testLobby);
        expect(state.lobby.id, 'test-id');
        expect(state.lobby.name, 'Test Lobby');
        expect(state.lobby.gameType, 'NumberGuessing');
      });

      test('LobbyJoined state contains updated lobby', () {
        final testLobby = LobbyEntity(
          id: 'test-id',
          name: 'Test Lobby',
          hostId: 'host-1',
          players: const [],
          gameType: 'NumberGuessing',
        );
        
        final state = LobbyJoined(testLobby);
        expect(state.lobby, equals(testLobby));
      });

      test('LobbyLoaded state contains lobby list', () {
        final testLobbies = [
          LobbyEntity(
            id: 'test-id-1',
            name: 'Test Lobby 1',
            hostId: 'host-1',
            players: const [],
            gameType: 'NumberGuessing',
          ),
          LobbyEntity(
            id: 'test-id-2',
            name: 'Test Lobby 2',
            hostId: 'host-2',
            players: [],
            gameType: 'NumberGuessing',
          ),
        ];
        
        final state = LobbyLoaded(testLobbies);
        expect(state.lobbies.length, 2);
        expect(state.lobbies.first.name, 'Test Lobby 1');
      });

      test('LobbyHosting state contains host address', () {
        final testLobby = LobbyEntity(
          id: 'test-id',
          name: 'Test Lobby',
          hostId: 'host-1',
          players: const [],
          gameType: 'NumberGuessing',
        );
        
        final state = LobbyHosting(testLobby, '192.168.1.100:8080');
        expect(state.lobby, equals(testLobby));
        expect(state.hostAddress, '192.168.1.100:8080');
      });

      test('LobbyError state contains error message', () {
        final state = LobbyError('Test error message');
        expect(state.message, 'Test error message');
      });
    });
  });
}
