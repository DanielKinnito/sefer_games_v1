import 'package:flutter/material.dart';
import '../widgets/error_dialog.dart';
import '../../../features/lobby/presentation/bloc/lobby_bloc.dart';
import '../../../features/games/presentation/bloc/game_bloc.dart';

mixin ErrorHandlerMixin<T extends StatefulWidget> on State<T> {
  
  /// Handle lobby-related errors
  void handleLobbyError(LobbyState state) {
    if (state is LobbyError) {
      final canRetry = state.canRetry;
      
      switch (state.errorType) {
        case LobbyErrorType.network:
          ErrorDialog.showNetworkError(
            context,
            message: state.message,
            onRetry: canRetry ? () => _retryLobbyOperation() : null,
          );
          break;
        case LobbyErrorType.validation:
          ErrorDialog.showLobbyError(
            context,
            message: state.message,
            onRetry: canRetry ? () => _retryLobbyOperation() : null,
          );
          break;
        case LobbyErrorType.timeout:
          ErrorDialog.showNetworkError(
            context,
            message: 'Connection timed out. ${state.message}',
            onRetry: canRetry ? () => _retryLobbyOperation() : null,
          );
          break;
        case LobbyErrorType.serverError:
          ErrorDialog.showLobbyError(
            context,
            message: 'Server error: ${state.message}',
            onRetry: canRetry ? () => _retryLobbyOperation() : null,
          );
          break;
        default:
          ErrorDialog.showGenericError(
            context,
            message: state.message,
            title: 'Lobby Error',
          );
      }
    }
  }

  /// Handle game-related errors
  void handleGameError(GameState state) {
    if (state is GameError) {
      final canRetry = state.canRetry;
      
      switch (state.errorType) {
        case GameErrorType.network:
          ErrorDialog.showNetworkError(
            context,
            message: state.message,
            onRetry: canRetry ? () => _retryGameOperation() : null,
          );
          break;
        case GameErrorType.gameLogic:
          ErrorDialog.showGameError(
            context,
            message: state.message,
            onRetry: canRetry ? () => _retryGameOperation() : null,
          );
          break;
        case GameErrorType.validation:
          ErrorDialog.showGameError(
            context,
            message: state.message,
          );
          break;
        case GameErrorType.synchronization:
          ErrorDialog.showNetworkError(
            context,
            message: 'Game synchronization failed. ${state.message}',
            onRetry: canRetry ? () => _retryGameOperation() : null,
          );
          break;
        default:
          ErrorDialog.showGenericError(
            context,
            message: state.message,
            title: 'Game Error',
          );
      }
    }
  }

  /// Show success message
  void showSuccessMessage(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor ?? Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Show warning message
  void showWarningMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Show error message as snackbar
  void showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show info message
  void showInfoMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Handle connection status changes
  void handleConnectionStatus(bool isConnected, String? reason) {
    if (isConnected) {
      showSuccessMessage('Connected successfully!');
    } else {
      showErrorMessage('Connection lost${reason != null ? ': $reason' : ''}');
    }
  }

  /// Handle player events
  void handlePlayerEvent(String playerName, bool joined) {
    if (joined) {
      showSuccessMessage('$playerName joined the lobby!');
    } else {
      showWarningMessage('$playerName left the lobby');
    }
  }

  /// Retry lobby operation - to be implemented by the page
  void _retryLobbyOperation() {
    // Override in the page that uses this mixin
  }

  /// Retry game operation - to be implemented by the page
  void _retryGameOperation() {
    // Override in the page that uses this mixin
  }

  /// Show confirmation dialog
  Future<bool> showConfirmationDialog({
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
}