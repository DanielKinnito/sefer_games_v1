import 'package:flutter/material.dart';
import '../../../../core/game/game_base.dart';
import '../../domain/entities/game_session.dart';
import 'number_guessing_ui.dart';

class GameUIContainer extends StatelessWidget {
  final GameSession session;
  final Map<String, dynamic> gameState;
  final String? currentPlayer;
  final Function(GameAction) onGameAction;

  const GameUIContainer({
    super.key,
    required this.session,
    required this.gameState,
    required this.onGameAction,
    this.currentPlayer,
  });

  @override
  Widget build(BuildContext context) {
    // Route to appropriate game UI based on game type
    switch (session.gameType) {
      case 'NumberGuessing':
        return NumberGuessingUI(
          session: session,
          gameState: gameState,
          currentPlayer: currentPlayer,
          onGameAction: onGameAction,
        );
      
      // Add other game UIs here as they are implemented
      // case 'WordBlitz':
      //   return WordBlitzUI(...);
      // case 'Mafia':
      //   return MafiaUI(...);
      
      default:
        return _buildUnsupportedGameUI(context);
    }
  }

  Widget _buildUnsupportedGameUI(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.games,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Unsupported Game Type',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Game type "${session.gameType}" is not yet supported.',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Return to lobby
              Navigator.of(context).pop();
            },
            child: const Text('Return to Lobby'),
          ),
        ],
      ),
    );
  }
}