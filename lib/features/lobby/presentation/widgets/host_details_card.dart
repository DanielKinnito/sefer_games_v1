import 'package:flutter/material.dart';

class HostDetailsCard extends StatelessWidget {
  final TextEditingController lobbyNameController;
  const HostDetailsCard({required this.lobbyNameController, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.95)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.outline.withOpacity(0.18)
              : Theme.of(context).dividerColor.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lobby Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: lobbyNameController,
            decoration: InputDecoration(
              hintText: 'Enter lobby name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.outline.withOpacity(0.18)
                      : Theme.of(context).dividerColor.withOpacity(0.12),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.95)
                  : Theme.of(context).cardColor,
              hintStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7)
                    : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
