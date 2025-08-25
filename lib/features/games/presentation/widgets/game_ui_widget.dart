import 'package:flutter/material.dart';
import '../../../../core/game/game_base.dart';

/// Base class for game UI widgets that provides common functionality
abstract class GameUIWidget extends StatefulWidget {
  final GameBase game;
  final bool isHost;
  final String currentPlayerId;
  final VoidCallback? onExitGame;

  const GameUIWidget({
    Key? key,
    required this.game,
    required this.isHost,
    required this.currentPlayerId,
    this.onExitGame,
  }) : super(key: key);
}

/// Base state class for game UI widgets
abstract class GameUIState<T extends GameUIWidget> extends State<T> {
  /// Override this to handle game events
  void onGameEvent(GameEvent event) {}

  /// Override this to handle game state changes
  void onGameStateChanged(Map<String, dynamic> gameState) {}

  /// Show a snackbar with a message
  void showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError 
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show a confirmation dialog
  Future<bool> showConfirmationDialog({
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  /// Build a common app bar for games
  PreferredSizeWidget buildGameAppBar({
    required String title,
    List<Widget>? actions,
    bool showBackButton = true,
  }) {
    return AppBar(
      title: Text(title),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      automaticallyImplyLeading: showBackButton,
      actions: [
        ...?actions,
        if (widget.onExitGame != null)
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              final shouldExit = await showConfirmationDialog(
                title: 'Exit Game',
                message: 'Are you sure you want to exit the game?',
                confirmText: 'Exit',
              );
              
              if (shouldExit) {
                widget.onExitGame!();
              }
            },
          ),
      ],
    );
  }

  /// Build a loading overlay
  Widget buildLoadingOverlay({String? message}) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                if (message != null) ...[
                  SizedBox(height: 16),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build an error widget
  Widget buildErrorWidget({
    required String message,
    VoidCallback? onRetry,
    IconData icon = Icons.error_outline,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(height: 16),
            Text(
              'Oops!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh),
                label: Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build a responsive layout that adapts to screen size
  Widget buildResponsiveLayout({
    required Widget child,
    double maxWidth = 800,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}