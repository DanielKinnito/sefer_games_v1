import 'package:flutter/material.dart';

class RetryWidget extends StatelessWidget {
  final String message;
  final String? subtitle;
  final VoidCallback onRetry;
  final IconData? icon;
  final String retryText;

  const RetryWidget({
    super.key,
    required this.message,
    required this.onRetry,
    this.subtitle,
    this.icon,
    this.retryText = 'Retry',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(retryText),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NetworkRetryWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final String? customMessage;

  const NetworkRetryWidget({
    super.key,
    required this.onRetry,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return RetryWidget(
      message: customMessage ?? 'Network Connection Failed',
      subtitle: 'Please check your WiFi connection and try again.',
      icon: Icons.wifi_off,
      onRetry: onRetry,
      retryText: 'Retry Connection',
    );
  }
}

class LobbyRetryWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final String? customMessage;

  const LobbyRetryWidget({
    super.key,
    required this.onRetry,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return RetryWidget(
      message: customMessage ?? 'Failed to Load Lobbies',
      subtitle: 'Make sure you\'re on the same network as other players.',
      icon: Icons.group_off,
      onRetry: onRetry,
      retryText: 'Refresh Lobbies',
    );
  }
}