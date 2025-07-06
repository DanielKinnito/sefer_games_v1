import 'package:flutter/material.dart';

class LobbyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const LobbyCard({required this.child, this.padding, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      color: Colors.white.withOpacity(0.95),
      child: Padding(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: child,
      ),
    );
  }
}
