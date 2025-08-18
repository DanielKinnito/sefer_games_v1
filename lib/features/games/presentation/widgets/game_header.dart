import 'package:flutter/material.dart';

class GameHeader extends StatelessWidget {
  final String lobbyName;
  final String gameType;
  final VoidCallback onReturnToLobby;
  final VoidCallback? onToggleTheme;
  final bool? isDarkMode;

  const GameHeader({
    super.key,
    required this.lobbyName,
    required this.gameType,
    required this.onReturnToLobby,
    this.onToggleTheme,
    this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: onReturnToLobby,
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Return to Lobby',
          ),
          
          const SizedBox(width: 8),
          
          // Game info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lobbyName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).appBarTheme.foregroundColor,
                  ),
                ),
                Text(
                  gameType,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).appBarTheme.foregroundColor?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          
          // Theme toggle
          if (onToggleTheme != null && isDarkMode != null)
            IconButton(
              onPressed: onToggleTheme,
              icon: Icon(
                isDarkMode! ? Icons.light_mode : Icons.dark_mode,
                color: Colors.deepPurple,
              ),
              tooltip: isDarkMode! ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            ),
        ],
      ),
    );
  }
}