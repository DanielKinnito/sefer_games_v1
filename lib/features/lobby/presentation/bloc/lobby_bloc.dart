import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/lobby.dart';
import '../../domain/usecases/create_lobby.dart';
import '../../domain/usecases/join_lobby.dart';
import '../../domain/usecases/get_available_lobbies.dart';
import '../../domain/usecases/leave_lobby.dart';
import '../../domain/usecases/start_hosting.dart';
import '../../domain/usecases/discover_local_lobbies.dart';

abstract class LobbyEvent {}

class CreateLobbyEvent extends LobbyEvent {
  final String lobbyName;
  final String hostName;
  final String hostAvatarId;
  final String gameType;
  final int maxPlayers;
  
  CreateLobbyEvent(this.lobbyName, this.hostName, this.hostAvatarId, this.gameType, {this.maxPlayers = 8});
}

class JoinLobbyEvent extends LobbyEvent {
  final String lobbyId;
  final String playerName;
  final String playerAvatarId;
  
  JoinLobbyEvent(this.lobbyId, this.playerName, this.playerAvatarId);
}

class LoadLobbiesEvent extends LobbyEvent {}

class LeaveLobbyEvent extends LobbyEvent {
  final String lobbyId;
  final String playerId;
  
  LeaveLobbyEvent(this.lobbyId, this.playerId);
}

class StartHostingEvent extends LobbyEvent {
  final String lobbyId;
  final int port;
  
  StartHostingEvent(this.lobbyId, {this.port = 8080});
}

class DiscoverLocalLobbiesEvent extends LobbyEvent {}

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

class LobbyCreated extends LobbyState {
  final Lobby lobby;
  LobbyCreated(this.lobby);
}

class LobbyHosting extends LobbyState {
  final Lobby lobby;
  final String hostAddress;
  LobbyHosting(this.lobby, this.hostAddress);
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
  final StartHosting startHosting;
  final DiscoverLocalLobbies discoverLocalLobbies;

  LobbyBloc({
    required this.createLobby,
    required this.joinLobby,
    required this.getAvailableLobbies,
    required this.leaveLobby,
    required this.startHosting,
    required this.discoverLocalLobbies,
  }) : super(LobbyInitial()) {
    
    on<CreateLobbyEvent>((event, emit) async {
      emit(LobbyLoading());
      try {
        final lobby = await createLobby(
          event.lobbyName, 
          event.hostName, 
          event.hostAvatarId, 
          event.gameType, 
          maxPlayers: event.maxPlayers
        );
        emit(LobbyCreated(lobby));
      } catch (e) {
        emit(LobbyError(e.toString()));
      }
    });
    
    on<JoinLobbyEvent>((event, emit) async {
      emit(LobbyLoading());
      try {
        final lobby = await joinLobby(event.lobbyId, event.playerName, event.playerAvatarId);
        if (lobby != null) {
          emit(LobbyJoined(lobby));
        } else {
          emit(LobbyError('Lobby not found or already full.'));
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

    on<StartHostingEvent>((event, emit) async {
      emit(LobbyLoading());
      try {
        final hostAddress = await startHosting(event.lobbyId, port: event.port);
        // Get the updated lobby to show hosting status
        final lobbies = await getAvailableLobbies();
        final lobby = lobbies.firstWhere((l) => l.id == event.lobbyId);
        emit(LobbyHosting(lobby, hostAddress));
      } catch (e) {
        emit(LobbyError(e.toString()));
      }
    });

    on<DiscoverLocalLobbiesEvent>((event, emit) async {
      emit(LobbyLoading());
      try {
        final lobbies = await discoverLocalLobbies();
        emit(LobbyLoaded(lobbies));
      } catch (e) {
        emit(LobbyError(e.toString()));
      }
    });
  }
}
