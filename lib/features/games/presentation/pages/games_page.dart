import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:sefer_games_v1/core/game/game_base.dart';
import 'package:sefer_games_v1/features/games/presentation/widgets/game_card.dart';

class GamesPage extends StatelessWidget {
  final VoidCallback? onToggleTheme;
  final bool? isDarkMode;
  final int playerCount;
  
  const GamesPage({
    super.key,
    this.onToggleTheme,
    this.isDarkMode,
    this.playerCount = 4, // Default player count
  });

  @override
  Widget build(BuildContext context) {
    // Get available games from the registry
    final availableGames = GameRegistry.getAvailableGames();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Games'),
        actions: [
          if (onToggleTheme != null)
            IconButton(
              icon: Icon(isDarkMode == true ? Icons.light_mode : Icons.dark_mode),
              onPressed: onToggleTheme,
            ),
        ],
      ),
      body: availableGames.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.games, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No games available',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Games will appear here once they are registered',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : MasonryGridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: _getCrossAxisCount(context),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              itemCount: availableGames.length,
              itemBuilder: (context, index) {
                final gameMetadata = availableGames[index];
                return GameCard(
                  gameMetadata: gameMetadata,
                  playerCount: playerCount,
                  onTap: () => _onGameSelected(context, gameMetadata),
                );
              },
            ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }

  void _onGameSelected(BuildContext context, GameMetadata gameMetadata) {
    // Navigate to game configuration or lobby
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected ${gameMetadata.displayName}'),
        duration: const Duration(seconds: 2),
      ),
    );
    
    // TODO: Navigate to game configuration page
    // Navigator.of(context).push(
    //   MaterialPageRoute(
    //     builder: (context) => GameConfigurationPage(gameMetadata: gameMetadata),
    //   ),
    // );
  }
}
