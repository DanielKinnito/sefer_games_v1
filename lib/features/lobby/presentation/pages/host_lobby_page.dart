import 'package:flutter/material.dart';
// ignore: unused_import
import '../widgets/animated_choice_button.dart';
// ignore: unused_import
import '../widgets/animated_background.dart';
import 'package:sefer_games_v1/core/presentation/widgets/bottom_nav_bar.dart';
import '../widgets/host_details_card.dart';
import '../widgets/player_details_card.dart';
import '../widgets/connection_status.dart';
import '../widgets/primary_button.dart';


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

  void _onCreatePressed() {
    // TODO: Implement create logic
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create Lobby pressed')));
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
                          ConnectionStatus(connected: _connected),
                          const SizedBox(height: 18),
                          PrimaryButton(
                            label: 'Create Lobby',
                            onPressed: _onCreatePressed,
                          ),
                        ],
                      ),
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


