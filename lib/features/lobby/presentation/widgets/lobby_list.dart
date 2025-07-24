import 'package:flutter/material.dart';

class LobbyList extends StatelessWidget {
  final List<LobbyListItemData> lobbies;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;
  const LobbyList({required this.lobbies, this.selectedIndex, required this.onSelect, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
          child: Text(
            'Available Lobbies',
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
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: lobbies.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final item = lobbies[i];
              final selected = selectedIndex == i;
              return Material(
                color: selected
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.10)
                    : Colors.transparent,
                child: ListTile(
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  subtitle: Text(
                    item.subtitle,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
                  ),
                  trailing: selected
                      ? Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () => onSelect(i),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class LobbyListItemData {
  final String title;
  final String subtitle;
  LobbyListItemData({required this.title, required this.subtitle});
}
