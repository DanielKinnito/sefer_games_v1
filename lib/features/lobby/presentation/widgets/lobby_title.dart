import 'package:flutter/material.dart';

class LobbyTitle extends StatelessWidget {
  final String text;
  const LobbyTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple,
      ),
      textAlign: TextAlign.center,
    );
  }
}
