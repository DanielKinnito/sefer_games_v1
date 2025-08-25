import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sefer_games_v1/core/game/game_base.dart';
import 'package:sefer_games_v1/features/games/presentation/widgets/game_card.dart';

void main() {
  testWidgets('GameCard displays game title and icon', (WidgetTester tester) async {
    final gameMetadata = GameMetadata(
      gameType: 'test_game',
      displayName: 'Test Game',
      description: 'A test game.',
      minPlayers: 2,
      maxPlayers: 8,
      estimatedDuration: Duration(minutes: 10),
      iconPath: 'assets/images/number_guessing_icon.png',
      tags: ['test', 'easy'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameCard(
            gameMetadata: gameMetadata,
            playerCount: 4,
            onTap: () {},
          ),
        ),
      ),
    );

    // Verify that the game title is displayed.
    expect(find.text('Test Game'), findsOneWidget);

    // Verify that the game description is displayed.
    expect(find.text('A test game.'), findsOneWidget);
  });
}
