import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/lobby.dart';
import '../../domain/usecases/create_lobby.dart';
import '../../domain/usecases/join_lobby.dart';
import '../../domain/usecases/get_available_lobbies.dart';
import '../../domain/usecases/leave_lobby.dart';

abstract class LobbyEvent {}
class CreateLobbyEvent extends LobbyEvent {
  final String hostId;
  final String gameType;
  CreateLobbyEvent(this.hostId, this.gameType);
}
class JoinLobbyEvent extends LobbyEvent {
  final String lobbyId;
  final String playerId;
  JoinLobbyEvent(this.lobbyId, this.playerId);
}
class LoadLobbiesEvent extends LobbyEvent {}
class LeaveLobbyEvent extends LobbyEvent {
  final String lobbyId;
  final String playerId;
  LeaveLobbyEvent(this.lobbyId, this.playerId);
}

abstract class LobbyState {}
class LobbyInitial extends LobbyState {}
class LobbyLoading extends LobbyState {}
class LobbyLoaded extends LobbyState {
  final List<Lobby> lobbies;
  LobbyLoaded(this.lobbies);
}
class LobbyJoined extends LobbyState {
  final Lobby lobby;
  LobbyJoined(this.lobby);
}
class LobbyError extends LobbyState {
  final String message;
  LobbyError(this.message);
}

class LobbyBloc extends Bloc<LobbyEvent, LobbyState> {
  final CreateLobby createLobby;
  final JoinLobby joinLobby;
  final GetAvailableLobbies getAvailableLobbies;
  final LeaveLobby leaveLobby;

  LobbyBloc({
    required this.createLobby,
    required this.joinLobby,
    required this.getAvailableLobbies,
    required this.leaveLobby,
  }) : super(LobbyInitial()) {
    on<CreateLobbyEvent>((event, emit) async {
      emit(LobbyLoading());
      try {
        final lobby = await createLobby(event.hostId, event.gameType);
        emit(LobbyJoined(lobby));
      } catch (e) {
        emit(LobbyError(e.toString()));
      }
    });
    on<JoinLobbyEvent>((event, emit) async {
      emit(LobbyLoading());
      try {
        final lobby = await joinLobby(event.lobbyId, event.playerId);
        if (lobby != null) {
          emit(LobbyJoined(lobby));
        } else {
          emit(LobbyError('Lobby not found or already joined.'));
        }
      } catch (e) {
        emit(LobbyError(e.toString()));
      }
    });
    on<LoadLobbiesEvent>((event, emit) async {
      emit(LobbyLoading());
      try {
        final lobbies = await getAvailableLobbies();
        emit(LobbyLoaded(lobbies));
      } catch (e) {
        emit(LobbyError(e.toString()));
      }
    });
    on<LeaveLobbyEvent>((event, emit) async {
      emit(LobbyLoading());
      try {
        await leaveLobby(event.lobbyId, event.playerId);
        final lobbies = await getAvailableLobbies();
        emit(LobbyLoaded(lobbies));
      } catch (e) {
        emit(LobbyError(e.toString()));
      }
    });
  }
}
