import 'package:flutter/material.dart';
import '../widgets/lobby_list.dart';
import '../widgets/player_details_card.dart';
import '../widgets/connection_status.dart';
import '../widgets/primary_button.dart';
import 'package:sefer_games_v1/core/presentation/widgets/bottom_nav_bar.dart';


class JoinLobbyPage extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool? isDarkMode;
  const JoinLobbyPage({super.key, this.onToggleTheme, this.isDarkMode});

  @override
  State<JoinLobbyPage> createState() => _JoinLobbyPageState();
}

class _JoinLobbyPageState extends State<JoinLobbyPage> {
  final TextEditingController _nameController = TextEditingController();
  int _selectedLobby = 0;
  int _selectedAvatar = 0;
  final bool _connected = true;

  // Placeholder lobbies removed. Will be populated dynamically in the future.
  final List<LobbyListItemData> lobbies = [];

  void _onJoinPressed() {
    // TODO: Implement join logic
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Join pressed')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text('Join Game', style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor)),
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Lobbies (scrollable area, even if empty)
                    Expanded(
                      child: LobbyList(
                        lobbies: lobbies,
                        selectedIndex: _selectedLobby,
                        onSelect: (i) => setState(() => _selectedLobby = i),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Player details
                    PlayerDetailsCard(
                      nameController: _nameController,
                      selectedAvatar: _selectedAvatar,
                      onAvatarSelect: (i) => setState(() => _selectedAvatar = i),
                    ),
                    const SizedBox(height: 18),
                    // Connection status
                    ConnectionStatus(connected: _connected),
                    const SizedBox(height: 18),
                    // Join button
                    PrimaryButton(
                      label: 'Join Lobby',
                      onPressed: _onJoinPressed,
                    ),
                  ],
                ),
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


