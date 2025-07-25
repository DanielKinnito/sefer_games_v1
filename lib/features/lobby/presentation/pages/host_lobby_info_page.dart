import 'package:flutter/material.dart';
import 'package:sefer_games_v1/core/presentation/widgets/bottom_nav_bar.dart';

class HostLobbyInfoPage extends StatelessWidget {
  final String lobbyName;
  final String lobbyCode;
  final List<Map<String, dynamic>> players;
  final List<Map<String, dynamic>> leaderboard;

  const HostLobbyInfoPage({
    super.key,
    required this.lobbyName,
    required this.lobbyCode,
    required this.players,
    required this.leaderboard,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lobby Info'),
        centerTitle: true,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: kBottomNavigationBarHeight),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Lobby Name: $lobbyName', style: Theme.of(context).textTheme.titleLarge),
                    Text('Lobby Code: $lobbyCode', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 16),
                    Text('Players', style: Theme.of(context).textTheme.titleMedium),
                    ...players.map((player) => ListTile(
                      leading: CircleAvatar(child: Text(player['avatar'] ?? '?')),
                      title: Text(player['name'] ?? ''),
                      subtitle: Text(player['id'] ?? ''),
                    )),
                    const SizedBox(height: 16),
                    Text('Leaderboard', style: Theme.of(context).textTheme.titleMedium),
                    ...leaderboard.map((entry) => ListTile(
                      leading: Icon(Icons.emoji_events),
                      title: Text(entry['name'] ?? ''),
                      trailing: Text('Score: ${entry['score'] ?? 0}'),
                    )),
                  ],
                ),
              ),
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: BottomNavBar(selectedIndex: 0),
            ),
          ],
        ),
      ),
    );
  }
}
