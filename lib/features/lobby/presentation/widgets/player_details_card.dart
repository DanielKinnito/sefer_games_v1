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
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
          child: Text('Your Player Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: 'Enter your name',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      border: Border.all(color: selectedAvatar == i ? Colors.blue : Colors.transparent, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade100,
                    ),
                    width: 48,
                    height: 48,
                    child: Icon(avatars[i], color: selectedAvatar == i ? Colors.blue : Colors.grey, size: 32),
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
