import 'package:flutter/material.dart';

class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final bool canRetry;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
    this.canRetry = false,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[600],
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          if (canRetry) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can try again or check your network connection.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (onDismiss != null)
          TextButton(
            onPressed: onDismiss,
            child: Text(
              'Dismiss',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        if (canRetry && onRetry != null)
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        if (onAction != null)
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(actionText ?? 'OK'),
          ),
        if (onAction == null && (!canRetry || onRetry == null))
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
      ],
    );
  }

  /// Show error dialog with network error styling
  static Future<void> showNetworkError(
    BuildContext context, {
    required String message,
    VoidCallback? onRetry,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        title: 'Network Error',
        message: message,
        canRetry: true,
        onRetry: onRetry,
      ),
    );
  }

  /// Show error dialog with game error styling
  static Future<void> showGameError(
    BuildContext context, {
    required String message,
    VoidCallback? onRetry,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        title: 'Game Error',
        message: message,
        canRetry: onRetry != null,
        onRetry: onRetry,
      ),
    );
  }

  /// Show error dialog with lobby error styling
  static Future<void> showLobbyError(
    BuildContext context, {
    required String message,
    VoidCallback? onRetry,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        title: 'Lobby Error',
        message: message,
        canRetry: onRetry != null,
        onRetry: onRetry,
      ),
    );
  }

  /// Show generic error dialog
  static Future<void> showGenericError(
    BuildContext context, {
    required String message,
    String? title,
    VoidCallback? onAction,
    String? actionText,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        title: title ?? 'Error',
        message: message,
        onAction: onAction,
        actionText: actionText,
      ),
    );
  }
}