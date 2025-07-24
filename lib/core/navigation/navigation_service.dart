import 'package:flutter/material.dart';

class NavigationService {
  static void handleBottomNavigation(BuildContext context, int index) {
    switch (index) {
      case 0: // Home
        // Navigate to home and clear the stack
        Navigator.of(context).popUntil((route) => route.isFirst);
        break;
      case 1: // Games
        // Show coming soon message for now
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Games screen coming soon!')),
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
    final currentRoute = ModalRoute.of(context)?.settings.name;
    
    // Determine which tab should be selected based on current route
    if (currentRoute == '/host' || currentRoute == '/join') {
      return 1; // Games tab for host/join pages
    } else if (currentRoute == '/settings') {
      return 2; // Settings tab
    } else {
      return 0; // Home tab (default)
    }
  }
}
