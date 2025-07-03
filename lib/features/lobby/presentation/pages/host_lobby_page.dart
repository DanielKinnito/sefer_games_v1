import 'package:flutter/material.dart';
import '../widgets/animated_choice_button.dart';
import '../widgets/animated_background.dart';

class HostLobbyPage extends StatelessWidget {
  const HostLobbyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Host a Game', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.deepPurple),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          const AnimatedBackground(
            circles: [
              AnimatedCircle(
                top: -60,
                left: -60,
                diameter: 200,
                gradient: LinearGradient(
                  colors: [Color(0xFFB39DDB), Color(0xFF673AB7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              AnimatedCircle(
                bottom: -40,
                right: -40,
                diameter: 120,
                color: Color(0x4DFFC107),
              ),
            ],
          ),
          Center(
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              color: Colors.white.withOpacity(0.95),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Create a New Lobby',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimatedChoiceButton(
                      label: 'Start Hosting',
                      icon: Icons.play_circle_fill,
                      onTap: () {
                        // TODO: Connect to BLoC to create lobby
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Share the code with friends to join your game!',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
