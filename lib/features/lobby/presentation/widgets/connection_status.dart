import 'package:flutter/material.dart';

class ConnectionStatus extends StatelessWidget {
  final bool connected;
  const ConnectionStatus({required this.connected, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.wifi, color: connected ? Colors.grey : Colors.red, size: 20),
        const SizedBox(width: 6),
        Text(
          connected ? 'LAN Connected' : 'No Connection',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }
}
