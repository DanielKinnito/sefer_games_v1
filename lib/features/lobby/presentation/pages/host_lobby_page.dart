import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// ignore: unused_import
import '../widgets/animated_choice_button.dart';
// ignore: unused_import
import '../widgets/animated_background.dart';
import 'package:sefer_games_v1/core/presentation/widgets/bottom_nav_bar.dart';
import 'package:sefer_games_v1/core/presentation/widgets/loading_overlay.dart';
import 'package:sefer_games_v1/core/presentation/mixins/error_handler_mixin.dart';
import '../widgets/host_details_card.dart';
import '../widgets/player_details_card.dart';
import '../widgets/connection_status.dart';
import '../widgets/primary_button.dart';
import '../widgets/real_time_player_list.dart';
import '../widgets/connection_status_indicator.dart';
import '../bloc/lobby_bloc.dart';
import '../../lobby_di.dart';
import '../../domain/entities/lobby.dart';
import '../../../../core/game/game_base.dart';
import '../../../games/presentation/pages/game_session_page.dart';
import 'host_lobby_info_page.dart';


class HostLobbyPage extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool? isDarkMode;
  const HostLobbyPage({super.key, this.onToggleTheme, this.isDarkMode});

  @override
  State<HostLobbyPage> createState() => _HostLobbyPageState();
}

class _HostLobbyPageState extends State<HostLobbyPage> with ErrorHandlerMixin {
  final TextEditingController _lobbyNameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  int _selectedAvatar = 0;
  late LobbyBloc _lobbyBloc;
  bool _isHosting = false;

  @override
  void initState() {
    super.initState();
    _lobbyBloc = LobbyDI.getBloc();
  }

  void _onCreatePressed() {
    if (_lobbyNameController.text.isEmpty || _nameController.text.isEmpty) {
      showErrorMessage('Please fill in all fields');
      return;
    }

    // Get available game types
    final availableGames = GameRegistry.getAvailableGameTypes();
    final selectedGameType = availableGames.isNotEmpty ? availableGames.first : 'Unknown';

    _lobbyBloc.add(CreateLobbyEvent(
      _lobbyNameController.text,
      _nameController.text,
      'avatar_$_selectedAvatar',
      selectedGameType,
    ));
  }

  String _getLoadingText(LobbyState state) {
    if (state is LobbyLoading) {
      // Try to determine what operation is loading based on previous state
      return 'Creating lobby...';
    }
    return 'Loading...';
  }

  void _startGame(Lobby lobby) async {
    final shouldStart = await showConfirmationDialog(
      title: 'Start Game?',
      message: 'Are you sure you want to start the game with ${lobby.players.length} players?',
      confirmText: 'Start Game',
    );

    if (shouldStart) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => GameSessionPage(
            lobby: lobby,
            onToggleTheme: widget.onToggleTheme,
            isDarkMode: widget.isDarkMode,
          ),
        ),
      );
    }
  }

  @override
  void _retryLobbyOperation() {
    // Retry the last operation - in this case, try creating the lobby again
    if (_lobbyNameController.text.isNotEmpty && _nameController.text.isNotEmpty) {
      _onCreatePressed();
    } else {
      showInfoMessage('Please fill in the lobby details and try again');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text('Host Game', style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor)),
        centerTitle: true,
        iconTheme: IconThemeData(color: Theme.of(context).appBarTheme.foregroundColor),
        actions: [
          if (widget.onToggleTheme != null && widget.isDarkMode != null)
            IconButton(
              icon: Icon(widget.isDarkMode! ? Icons.light_mode : Icons.dark_mode, color: Colors.deepPurple, size: 28),
              onPressed: widget.onToggleTheme,
              tooltip: widget.isDarkMode! ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Main content fills available space above nav bar
            Expanded(
              child: BlocConsumer<LobbyBloc, LobbyState>(
                bloc: _lobbyBloc,
                listener: (context, state) {
                  // Handle errors using the mixin
                  handleLobbyError(state);
                  
                  if (state is LobbyCreated) {
                    showSuccessMessage('Lobby "${state.lobby.name}" created successfully!');
                    // Automatically start hosting
                    _lobbyBloc.add(StartHostingEvent(state.lobby.id));
                  } else if (state is LobbyHosting) {
                    setState(() {
                      _isHosting = true;
                    });
                    showSuccessMessage('Now hosting on ${state.hostAddress}');
                  } else if (state is PlayerJoined) {
                    handlePlayerEvent(state.playerName, true);
                  } else if (state is PlayerLeft) {
                    handlePlayerEvent(state.playerName, false);
                  } else if (state is NetworkDisconnected) {
                    handleConnectionStatus(false, state.reason);
                  } else if (state is NetworkConnected) {
                    handleConnectionStatus(true, null);
                  }
                },
                builder: (context, state) {
                  final isLoading = state is LobbyLoading;
                  
                  return LoadingOverlay(
                    isLoading: isLoading,
                    loadingText: _getLoadingText(state),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              HostDetailsCard(lobbyNameController: _lobbyNameController),
                              const SizedBox(height: 18),
                              PlayerDetailsCard(
                                nameController: _nameController,
                                selectedAvatar: _selectedAvatar,
                                onAvatarSelect: (i) => setState(() => _selectedAvatar = i),
                              ),
                              const SizedBox(height: 18),
                              ConnectionStatusIndicator(lobbyBloc: _lobbyBloc),
                              const SizedBox(height: 18),
                              if (_isHosting) ...[
                                Card(
                                  color: Theme.of(context).cardColor,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.green, size: 48),
                                        const SizedBox(height: 8),
                                        Text('Lobby Created Successfully!', style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).textTheme.bodyLarge?.color,
                                        )),
                                        const SizedBox(height: 8),
                                        if (state is LobbyHosting) ...[
                                          Text('Hosting on: ${state.hostAddress}', style: TextStyle(
                                            color: Theme.of(context).textTheme.bodyMedium?.color,
                                          )),
                                          Text('Game Type: ${state.lobby.gameType}', style: TextStyle(
                                            color: Theme.of(context).textTheme.bodyMedium?.color,
                                          )),
                                          Text('Players: ${state.lobby.players.length}/${state.lobby.maxPlayers}', style: TextStyle(
                                            color: Theme.of(context).textTheme.bodyMedium?.color,
                                          )),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                // Real-time player list
                                RealTimePlayerList(lobbyBloc: _lobbyBloc),
                                const SizedBox(height: 18),
                                // Start Game button (only show when hosting and have enough players)
                                if (state is LobbyHosting && state.lobby.players.length >= 2)
                                  PrimaryButton(
                                    label: 'Start Game',
                                    onPressed: () => _startGame(state.lobby),
                                  ),
                                const SizedBox(height: 18),
                              ],
                              if (!_isHosting)
                                PrimaryButton(
                                  label: isLoading ? 'Creating...' : 'Create Lobby',
                                  onPressed: isLoading ? () {} : _onCreatePressed,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                },
              ),
            ),
            // Bottom nav bar always at the bottom
            const BottomNavBar(selectedIndex: 1),
          ],
        ),
      ),
    );
  }
}


