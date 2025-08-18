import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/game/game_base.dart';
import '../../domain/entities/game_session.dart';

class NumberGuessingUI extends StatefulWidget {
  final GameSession session;
  final Map<String, dynamic> gameState;
  final String? currentPlayer;
  final Function(GameAction) onGameAction;

  const NumberGuessingUI({
    super.key,
    required this.session,
    required this.gameState,
    required this.onGameAction,
    this.currentPlayer,
  });

  @override
  State<NumberGuessingUI> createState() => _NumberGuessingUIState();
}

class _NumberGuessingUIState extends State<NumberGuessingUI> {
  final TextEditingController _guessController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _guessController.dispose();
    super.dispose();
  }

  void _submitGuess() {
    final guessText = _guessController.text.trim();
    if (guessText.isEmpty) return;

    final guess = int.tryParse(guessText);
    if (guess == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number')),
      );
      return;
    }

    if (guess < 1 || guess > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a number between 1 and 100')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final action = BasicGameAction(
      type: 'make_guess',
      playerId: 'current_player', // TODO: Get actual player ID
      data: {'guess': guess},
    );

    widget.onGameAction(action);

    _guessController.clear();
    
    // Reset submitting state after a delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentRound = widget.gameState['currentRound'] as int? ?? 1;
    final maxRounds = widget.gameState['maxRounds'] as int? ?? 3;
    final scores = widget.gameState['scores'] as Map<String, dynamic>? ?? {};
    final lastGuesses = widget.gameState['lastGuesses'] as Map<String, dynamic>? ?? {};
    final currentGuesser = widget.gameState['currentGuesser'] as String?;
    final isFinished = widget.gameState['isFinished'] as bool? ?? false;
    final players = widget.gameState['players'] as List? ?? [];

    final isMyTurn = currentGuesser == 'current_player'; // TODO: Compare with actual player ID

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Game status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Round $currentRound of $maxRounds',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!isFinished) ...[
                    Text(
                      isMyTurn ? 'Your turn!' : 'Waiting for $currentGuesser...',
                      style: TextStyle(
                        fontSize: 16,
                        color: isMyTurn ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Game Finished!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Scores
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scores',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...scores.entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(child: Text(entry.key)),
                        Text('${entry.value} pts'),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Last guesses
          if (lastGuesses.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Guesses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...lastGuesses.entries.map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(child: Text(entry.key)),
                          Text('${entry.value}'),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),

          const Spacer(),

          // Guess input (only show if it's the player's turn and game is not finished)
          if (isMyTurn && !isFinished)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Guess a number between 1 and 100',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _guessController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                            decoration: const InputDecoration(
                              hintText: 'Enter your guess',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _submitGuess(),
                            enabled: !_isSubmitting,
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitGuess,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Guess'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}