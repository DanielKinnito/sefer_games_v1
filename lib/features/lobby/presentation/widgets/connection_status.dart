import 'package:flutter/material.dart';

class ConnectionStatus extends StatelessWidget {
  final bool connected;
  const ConnectionStatus({required this.connected, super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(
          Icons.wifi,
          color: connected
              ? (isDark ? Theme.of(context).colorScheme.primary.withOpacity(0.7) : Colors.grey)
              : Colors.redAccent,
          size: 20,
        ),
        const SizedBox(width: 6),
        Text(
          connected ? 'LAN Connected' : 'No Connection',
          style: TextStyle(
            color: connected
                ? (isDark ? Theme.of(context).colorScheme.onSurfaceVariant : Colors.grey[600])
                : Colors.redAccent,
            fontSize: 14,
            fontWeight: connected ? FontWeight.w500 : FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
