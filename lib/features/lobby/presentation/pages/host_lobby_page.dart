import 'package:flutter/material.dart';
// ignore: unused_import
import '../widgets/animated_choice_button.dart';
// ignore: unused_import
import '../widgets/animated_background.dart';
import '../widgets/host_details_card.dart';
import '../widgets/player_details_card.dart';
import '../widgets/connection_status.dart';
import '../widgets/primary_button.dart';

class HostLobbyPage extends StatefulWidget {
  const HostLobbyPage({super.key});

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
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Host Game', style: TextStyle(color: Colors.black)),
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
