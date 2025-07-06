import 'package:flutter/material.dart';

class LobbyCodeInput extends StatelessWidget {
  final TextEditingController controller;
  final bool showError;
  final VoidCallback onSubmitted;
  const LobbyCodeInput({required this.controller, required this.showError, required this.onSubmitted, super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 22, letterSpacing: 2),
      decoration: InputDecoration(
        hintText: 'e.g. 1234AB',
        errorText: showError ? 'Please enter a code' : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      onSubmitted: (_) => onSubmitted(),
    );
  }
}
