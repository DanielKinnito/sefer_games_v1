import 'package:flutter/material.dart';

class PlayerDetailsCard extends StatelessWidget {
  final TextEditingController nameController;
  final int selectedAvatar;
  final ValueChanged<int> onAvatarSelect;
  const PlayerDetailsCard({required this.nameController, required this.selectedAvatar, required this.onAvatarSelect, super.key});

  @override
  Widget build(BuildContext context) {
    final avatars = [
      Icons.rocket_launch, Icons.casino, Icons.cake, Icons.emoji_events,
      Icons.star, Icons.diamond, Icons.flash_on
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
          child: Text(
            'Your Player Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : Colors.black,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.95)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.outline.withOpacity(0.18)
                  : Theme.of(context).dividerColor.withOpacity(0.12),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.outline.withOpacity(0.18)
                          : Theme.of(context).dividerColor.withOpacity(0.12),
                    ),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.95)
                      : Theme.of(context).cardColor,
                  hintStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7)
                        : Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(avatars.length, (i) => GestureDetector(
                  onTap: () => onAvatarSelect(i),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selectedAvatar == i
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.7)
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    width: 48,
                    height: 48,
                    child: Icon(
                      avatars[i],
                      color: selectedAvatar == i
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).iconTheme.color?.withOpacity(0.5),
                      size: 32,
                    ),
                  ),
                )),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
