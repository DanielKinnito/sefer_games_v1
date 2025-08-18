import 'package:flutter/material.dart';
import '../../../../core/game/game_base.dart';
import '../../domain/entities/game_session.dart';

class GameActionPanel extends StatelessWidget {
  final GameSession session;
  final Map<String, dynamic> gameState;
  final String? currentPlayer;
  final Function(GameAction) onGameAction;

  const GameActionPanel({
    super.key,
    required this.session,
    required this.gameState,
    required this.onGameAction,
    this.currentPlayer,
  });

  @override
  Widget build(BuildContext context) {
    // This is a generic action panel that can be customized per game type
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.touch_app,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Game Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildGameSpecificActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildGameSpecificActions(BuildContext context) {
    switch (session.gameType) {
      case 'NumberGuessing':
        return _buildNumberGuessingActions(context);
      default:
        return _buildGenericActions(context);
    }
  }

  Widget _buildNumberGuessingActions(BuildContext context) {
    final isFinished = gameState['isFinished'] as bool? ?? false;
    final currentGuesser = gameState['currentGuesser'] as String?;
    final isMyTurn = currentGuesser == currentPlayer;

    if (isFinished) {
      return Column(
        children: [
          const Text('Game finished! Check the results above.'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final action = BasicGameAction(
                  type: 'next_round',
                  playerId: currentPlayer ?? 'unknown',
                  data: {},
                );
                onGameAction(action);
              },
              child: const Text('Start New Round'),
            ),
          ),
        ],
      );
    }

    if (!isMyTurn) {
      return Text(
        'Waiting for $currentGuesser to make a guess...',
        style: TextStyle(
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return const Text(
      'Use the input field above to make your guess!',
      style: TextStyle(
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildGenericActions(BuildContext context) {
    return Column(
      children: [
        const Text('Game-specific actions will appear here.'),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // Generic action
              final action = BasicGameAction(
                type: 'generic_action',
                playerId: currentPlayer ?? 'unknown',
                data: {},
              );
              onGameAction(action);
            },
            child: const Text('Perform Action'),
          ),
        ),
      ],
    );
  }
}