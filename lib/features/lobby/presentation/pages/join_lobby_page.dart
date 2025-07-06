import 'package:flutter/material.dart';
import '../widgets/lobby_list.dart';
import '../widgets/player_details_card.dart';
import '../widgets/connection_status.dart';
import '../widgets/primary_button.dart';

class JoinLobbyPage extends StatefulWidget {
  const JoinLobbyPage({super.key});

  @override
  State<JoinLobbyPage> createState() => _JoinLobbyPageState();
}

class _JoinLobbyPageState extends State<JoinLobbyPage> {
  final TextEditingController _nameController = TextEditingController();
  int _selectedLobby = 0;
  int _selectedAvatar = 0;
  final bool _connected = true;

  final lobbies = [
    LobbyListItemData(title: "Friends' Game Night", subtitle: 'Host: John • 3/8 Players'),
    LobbyListItemData(title: 'Family Fun Time', subtitle: 'Host: Jane • 5/6 Players'),
    LobbyListItemData(title: 'Weekend Warriors', subtitle: 'Host: Mike • 2/4 Players'),
  ];

  void _onJoinPressed() {
    // TODO: Implement join logic
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Join pressed')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Join Game', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Lobbies
              LobbyList(
                lobbies: lobbies,
                selectedIndex: _selectedLobby,
                onSelect: (i) => setState(() => _selectedLobby = i),
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
              const SizedBox(height: 12),
              // Bottom nav (placeholder)
              Container(
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    Icon(Icons.home, color: Colors.blue),
                    Text('Lobby', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    Icon(Icons.videogame_asset, color: Colors.grey),
                    Text('Games', style: TextStyle(color: Colors.grey)),
                    Icon(Icons.settings, color: Colors.grey),
                    Text('Settings', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
