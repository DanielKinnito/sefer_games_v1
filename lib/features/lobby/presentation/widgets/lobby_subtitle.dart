import 'package:flutter/material.dart';

class LobbySubtitle extends StatelessWidget {
  final String text;
  const LobbySubtitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
      textAlign: TextAlign.center,
    );
  }
}
