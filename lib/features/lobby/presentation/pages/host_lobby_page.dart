import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// ignore: unused_import
import '../widgets/animated_choice_button.dart';
// ignore: unused_import
import '../widgets/animated_background.dart';
import 'package:sefer_games_v1/core/presentation/widgets/bottom_nav_bar.dart';
import '../widgets/host_details_card.dart';
import '../widgets/player_details_card.dart';
import '../widgets/connection_status.dart';
import '../widgets/primary_button.dart';
import '../bloc/lobby_bloc.dart';
import '../../lobby_di.dart';
import '../../../../core/game/game_base.dart';


class HostLobbyPage extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool? isDarkMode;
  const HostLobbyPage({super.key, this.onToggleTheme, this.isDarkMode});

  @override
  State<HostLobbyPage> createState() => _HostLobbyPageState();
}

class _HostLobbyPageState extends State<HostLobbyPage> {
  final TextEditingController _lobbyNameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  int _selectedAvatar = 0;
  final bool _connected = true;
  late LobbyBloc _lobbyBloc;

  @override
  void initState() {
    super.initState();
    _lobbyBloc = LobbyDI.getBloc();
  }

  void _onCreatePressed() {
    if (_lobbyNameController.text.isEmpty || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
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
                  if (state is LobbyError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${state.message}')),
                    );
                  } else if (state is LobbyCreated) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lobby "${state.lobby.name}" created successfully!')),
                    );
                    // Automatically start hosting
                    _lobbyBloc.add(StartHostingEvent(state.lobby.id));
                  } else if (state is LobbyHosting) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Hosting on ${state.hostAddress}')),
                    );
                  }
                },
                builder: (context, state) {
                  final isLoading = state is LobbyLoading;
                  
                  return Padding(
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
                              ConnectionStatus(connected: _connected),
                              const SizedBox(height: 18),
                              if (state is LobbyHosting) ...[
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
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                              ],
                              PrimaryButton(
                                label: isLoading ? 'Creating...' : 'Create Lobby',
                                onPressed: isLoading ? () {} : _onCreatePressed,
                              ),
                            ],
                          ),
                        ),
                      ],
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


