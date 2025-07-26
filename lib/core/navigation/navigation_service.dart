import 'package:flutter/material.dart';
import 'package:sefer_games_v1/features/games/presentation/pages/games_page.dart';

class NavigationService {
  static void handleBottomNavigation(BuildContext context, int index) {
    final currentIndex = getCurrentIndex(context);
    if (currentIndex == index) return;

    switch (index) {
      case 0: // Home
        // Navigate to home and clear the stack
        Navigator.of(context).popUntil((route) => route.isFirst);
        break;
      case 1: // Games
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const GamesPage(),
            settings: const RouteSettings(name: '/games'),
          ),
        );
        break;
      case 2: // Settings
        // Show coming soon message for now
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings screen coming soon!')),
        );
        break;
      default:
        break;
    }
  }

  static int getCurrentIndex(BuildContext context) {
    final currentRouteName = ModalRoute.of(context)?.settings.name;

    if (currentRouteName == '/games') {
      return 1;
    } else if (currentRouteName == '/settings') {
      return 2;
    }
    // Default to home for any other route, including '/', '/host', '/join'
    return 0;
  }
}
