import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const PrimaryButton({required this.label, required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF7C4DFF) // Vivid purple for dark mode
              : const Color(0xFF6377E3), // Modern blue-violet for light mode
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(vertical: 20),
          elevation: 4,
          shadowColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.black.withOpacity(0.4)
              : Colors.deepPurple.withOpacity(0.12),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.1,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
