import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:sefer_games_v1/features/lobby/presentation/pages/lobby_page.dart';

void main() {
  testWidgets('LobbyPage displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LobbyPage()));
    expect(find.text('Lobby Page'), findsOneWidget);
  });
}
