import 'package:flutter/material.dart';
import '../../domain/entities/game_session.dart';

class GamePlayerList extends StatelessWidget {
  final GameSession session;
  final Map<String, dynamic> gameState;
  final String? currentPlayer;

  const GamePlayerList({
    super.key,
    required this.session,
    required this.gameState,
    this.currentPlayer,
  });

  @override
  Widget build(BuildContext context) {
    final players = session.playerIds;
    final scores = gameState['scores'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.people,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Players',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...players.map((playerId) => _buildPlayerTile(
              context,
              playerId,
              scores[playerId] as int? ?? 0,
              playerId == currentPlayer,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerTile(BuildContext context, String playerId, int score, bool isCurrentPlayer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentPlayer
            ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
            : Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]?.withValues(alpha: 0.3)
                : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: isCurrentPlayer
            ? Border.all(color: Theme.of(context).primaryColor, width: 2)
            : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
            child: Text(
              playerId.isNotEmpty ? playerId[0].toUpperCase() : '?',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playerId,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                if (isCurrentPlayer)
                  Text(
                    'Current Turn',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '$score pts',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}