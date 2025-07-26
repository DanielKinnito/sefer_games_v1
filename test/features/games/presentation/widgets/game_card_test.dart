import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sefer_games_v1/features/games/domain/entities/game_info.dart';
import 'package:sefer_games_v1/features/games/presentation/widgets/game_card.dart';

void main() {
  testWidgets('GameCard displays game title and icon', (WidgetTester tester) async {
    final game = GameInfo(
      id: 'test_game',
      title: 'Test Game',
      description: 'A test game.',
      iconPath: 'assets/images/number_guessing_icon.png',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameCard(game: game),
        ),
      ),
    );

    // Verify that the game title is displayed.
    expect(find.text('Test Game'), findsOneWidget);

    // Verify that the game icon is displayed.
    expect(find.byType(Image), findsOneWidget);
  });
}
