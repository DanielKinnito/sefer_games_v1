import 'data/repositories/lobby_repository_impl.dart';
import 'data/services/lan_service.dart';
import 'domain/usecases/create_lobby.dart';
import 'domain/usecases/join_lobby.dart';
import 'domain/usecases/get_available_lobbies.dart';
import 'domain/usecases/leave_lobby.dart';
import 'domain/usecases/start_hosting.dart';
import 'domain/usecases/discover_local_lobbies.dart';
import 'presentation/bloc/lobby_bloc.dart';

/// Dependency injection for lobby feature
class LobbyDI {
  static LobbyRepositoryImpl? _repository;
  static LanService? _lanService;
  static LobbyBloc? _bloc;
  
  /// Get LAN service instance (singleton)
  static LanService getLanService() {
    return _lanService ??= LanService();
  }
  
  /// Get repository instance (singleton)
  static LobbyRepositoryImpl getRepository() {
    return _repository ??= LobbyRepositoryImpl();
  }
  
  /// Get BLoC instance (singleton)
  static LobbyBloc getBloc() {
    if (_bloc != null) return _bloc!;
    
    final repository = getRepository();
    final lanService = getLanService();
    
    _bloc = LobbyBloc(
      createLobby: CreateLobby(repository),
      joinLobby: JoinLobby(repository),
      getAvailableLobbies: GetAvailableLobbies(repository),
      leaveLobby: LeaveLobby(repository),
      startHosting: StartHosting(repository),
      discoverLocalLobbies: DiscoverLocalLobbies(repository),
      lanService: lanService,
    );
    
    return _bloc!;
  }
  
  /// Dispose resources
  static void dispose() {
    _bloc?.close();
    _bloc = null;
    _repository = null;
    _lanService?.dispose();
    _lanService = null;
  }
}
