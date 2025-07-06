import 'package:flutter/material.dart';
import 'animated_choice_button.dart';
import 'lobby_card.dart';
import 'lobby_title.dart';
import 'lobby_subtitle.dart';

class HostLobbyContent extends StatelessWidget {
  final VoidCallback onHost;
  const HostLobbyContent({required this.onHost, super.key});

  @override
  Widget build(BuildContext context) {
    return LobbyCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LobbyTitle('Create a New Lobby'),
          const SizedBox(height: 24),
          AnimatedChoiceButton(
            label: 'Start Hosting',
            icon: Icons.play_circle_fill,
            onTap: onHost,
          ),
          const SizedBox(height: 16),
          const LobbySubtitle('Share the code with friends to join your game!'),
        ],
      ),
    );
  }
}
