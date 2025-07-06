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
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
          child: Text('Available Lobbies', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
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
                color: selected ? Colors.blue.shade100 : Colors.transparent,
                child: ListTile(
                  title: Text(item.title, style: TextStyle(fontWeight: FontWeight.bold, color: selected ? Colors.blue : Colors.black)),
                  subtitle: Text(item.subtitle, style: TextStyle(color: Colors.grey[700])),
                  trailing: selected ? const Icon(Icons.arrow_forward_ios, color: Colors.blue) : null,
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
