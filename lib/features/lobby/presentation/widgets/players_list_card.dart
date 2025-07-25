import 'package:flutter/material.dart';
import '../../domain/entities/player.dart';

class PlayersListCard extends StatelessWidget {
  final List<Player> players;
  final Map<String, int> leaderboard;
  final bool showScores;

  const PlayersListCard({
    super.key,
    required this.players,
    this.leaderboard = const {},
    this.showScores = false,
  });

  @override
  Widget build(BuildContext context) {
    final sortedPlayers = showScores ? _getSortedPlayersByScore() : players;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  showScores ? Icons.leaderboard : Icons.group,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  showScores ? 'Leaderboard' : 'Players (${players.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (players.isNotEmpty && !showScores)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${players.where((p) => p.isConnected).length} online',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (sortedPlayers.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.person_add_outlined,
                        size: 48,
                        color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No players yet',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedPlayers.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final player = sortedPlayers[index];
                  return _buildPlayerTile(context, player, index);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerTile(BuildContext context, Player player, int index) {
    final score = leaderboard[player.id] ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: player.isHost 
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Theme.of(context).cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: player.isHost 
              ? Theme.of(context).primaryColor.withOpacity(0.3)
              : Theme.of(context).dividerColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Position number for leaderboard
          if (showScores) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _getRankColor(context, index),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
            child: Text(
              player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        player.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (player.isHost)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'HOST',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      player.isConnected ? Icons.circle : Icons.circle_outlined,
                      color: player.isConnected ? Colors.green : Colors.grey,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      player.isConnected ? 'Online' : 'Offline',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: player.isConnected ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Score for leaderboard
          if (showScores) ...[
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$score',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                Text(
                  'points',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<Player> _getSortedPlayersByScore() {
    final playersList = List<Player>.from(players);
    playersList.sort((a, b) {
      final scoreA = leaderboard[a.id] ?? 0;
      final scoreB = leaderboard[b.id] ?? 0;
      return scoreB.compareTo(scoreA); // Descending order
    });
    return playersList;
  }

  Color _getRankColor(BuildContext context, int rank) {
    switch (rank) {
      case 0: return Colors.amber; // Gold
      case 1: return Colors.grey; // Silver
      case 2: return Colors.brown; // Bronze
      default: return Theme.of(context).primaryColor;
    }
  }
}
