import 'package:flutter/material.dart';
import 'package:sefer_games_v1/core/presentation/widgets/bottom_nav_bar.dart';


class LobbyPage extends StatelessWidget {
  final VoidCallback? onToggleTheme;
  final bool? isDarkMode;
  const LobbyPage({super.key, this.onToggleTheme, this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Game Lobby',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (onToggleTheme != null && isDarkMode != null)
            IconButton(
              icon: Icon(isDarkMode! ? Icons.light_mode : Icons.dark_mode, color: Colors.amberAccent, size: 28),
              onPressed: onToggleTheme,
              tooltip: isDarkMode! ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            ),
        ],
      ),
      body: Column(
        children: [
          // SVG-inspired header (placeholder)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 24),
            child: Icon(Icons.sports_esports, size: 64, color: Colors.amberAccent),
          ),
          const Text(
            'Join a game or create your own!',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: 3, // Placeholder for available lobbies
              itemBuilder: (context, index) {
                return Card(
                  color: const Color(0xFF0F3460),
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.amberAccent,
                      child: Text('${index + 1}', style: const TextStyle(color: Colors.black)),
                    ),
                    title: Text(
                      'Lobby #${index + 1}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Host: PlayerX | Game: WordBlitz', style: TextStyle(color: Colors.white70)),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amberAccent,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () {},
                      child: const Text('Join'),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amberAccent,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Create Lobby'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),
          // Bottom nav bar
          BottomNavBar(
            selectedIndex: 0,
            onTap: (index) {
              // TODO: Implement navigation logic for bottom nav bar
            },
          ),
        ],
      ),
    );
  }
}
