import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/lobby_list.dart';
import '../widgets/player_details_card.dart';
import '../widgets/connection_status.dart';
import '../widgets/primary_button.dart';
import '../widgets/connection_status_indicator.dart';
import '../widgets/real_time_lobby_discovery.dart';
import 'package:sefer_games_v1/core/presentation/widgets/bottom_nav_bar.dart';
import 'package:sefer_games_v1/core/presentation/widgets/loading_overlay.dart';
import 'package:sefer_games_v1/core/presentation/widgets/retry_widget.dart';
import 'package:sefer_games_v1/core/presentation/mixins/error_handler_mixin.dart';
import '../bloc/lobby_bloc.dart';
import '../../lobby_di.dart';

class JoinLobbyPage extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool? isDarkMode;
  const JoinLobbyPage({super.key, this.onToggleTheme, this.isDarkMode});

  @override
  State<JoinLobbyPage> createState() => _JoinLobbyPageState();
}

class _JoinLobbyPageState extends State<JoinLobbyPage> with ErrorHandlerMixin {
  final TextEditingController _nameController = TextEditingController();
  int _selectedLobby = 0;
  int _selectedAvatar = 0;
  late LobbyBloc _lobbyBloc;
  String? _selectedLobbyId;

  @override
  void initState() {
    super.initState();
    _lobbyBloc = LobbyDI.getBloc();
    _loadLobbies();
  }

  void _loadLobbies() {
    _lobbyBloc.add(DiscoverLocalLobbiesEvent());
  }

  void _onLobbySelected(String lobbyId) {
    setState(() {
      _selectedLobbyId = lobbyId;
    });
  }

  void _onJoinPressed() {
    if (_nameController.text.isEmpty) {
      showErrorMessage('Please enter your name');
      return;
    }

    if (_selectedLobbyId == null) {
      showErrorMessage('Please select a lobby to join');
      return;
    }

    _lobbyBloc.add(
      JoinLobbyEvent(
        _selectedLobbyId!,
        _nameController.text,
        'avatar_$_selectedAvatar',
      ),
    );
  }

  String _getLoadingText(LobbyState state) {
    if (state is LobbyLoading) {
      return 'Discovering lobbies...';
    }
    return 'Loading...';
  }

  @override
  void _retryLobbyOperation() {
    _loadLobbies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Join Game',
          style: TextStyle(
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Theme.of(context).appBarTheme.foregroundColor,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLobbies,
            tooltip: 'Refresh Lobbies',
          ),
          if (widget.onToggleTheme != null && widget.isDarkMode != null)
            IconButton(
              icon: Icon(
                widget.isDarkMode! ? Icons.light_mode : Icons.dark_mode,
                color: Colors.deepPurple,
                size: 28,
              ),
              onPressed: widget.onToggleTheme,
              tooltip: widget.isDarkMode!
                  ? 'Switch to Light Mode'
                  : 'Switch to Dark Mode',
            ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                bottom: kBottomNavigationBarHeight,
              ),
              child: BlocConsumer<LobbyBloc, LobbyState>(
                bloc: _lobbyBloc,
                listener: (context, state) {
                  // Handle errors using the mixin
                  handleLobbyError(state);

                  if (state is LobbyJoined) {
                    showSuccessMessage(
                      'Successfully joined ${state.lobby.name}!',
                    );
                    // Navigate to lobby waiting room or game
                  } else if (state is NetworkDisconnected) {
                    handleConnectionStatus(false, state.reason);
                  } else if (state is NetworkConnected) {
                    handleConnectionStatus(true, null);
                  }
                },
                builder: (context, state) {
                  final isLoading = state is LobbyLoading;

                  // Show retry widget for persistent errors
                  if (state is LobbyError &&
                      state.errorType == LobbyErrorType.network) {
                    return NetworkRetryWidget(
                      onRetry: _loadLobbies,
                      customMessage: state.message,
                    );
                  }

                  return LoadingOverlay(
                    isLoading: isLoading,
                    loadingText: _getLoadingText(state),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Real-time lobby discovery
                          RealTimeLobbyDiscovery(
                            onLobbySelected: _onLobbySelected,
                            selectedLobbyId: _selectedLobbyId,
                            lobbyBloc: _lobbyBloc,
                          ),
                          const SizedBox(height: 18),
                          // Player details
                          PlayerDetailsCard(
                            nameController: _nameController,
                            selectedAvatar: _selectedAvatar,
                            onAvatarSelect: (i) =>
                                setState(() => _selectedAvatar = i),
                          ),
                          const SizedBox(height: 18),
                          // Connection status
                          ConnectionStatusIndicator(lobbyBloc: _lobbyBloc),
                          const SizedBox(height: 18),
                          // Join button
                          PrimaryButton(
                            label: isLoading ? 'Joining...' : 'Join Lobby',
                            onPressed: isLoading ? () {} : _onJoinPressed,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Bottom nav bar always at the bottom
            const Align(
              alignment: Alignment.bottomCenter,
              child: BottomNavBar(selectedIndex: 1),
            ),
          ],
        ),
      ),
    );
  }
}
