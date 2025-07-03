import 'package:flutter/material.dart';

import '../widgets/animated_choice_button.dart';
import 'host_lobby_page.dart';
import 'join_lobby_page.dart';

class LobbyHomePage extends StatelessWidget {
  const LobbyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 32),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade100,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: Text(
                    'Sefer Games',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Color(0xFF3D155F),
                    ),
                  ),
                ),
              ),
              AnimatedChoiceButton(
                label: 'Host',
                onTap: () {
                  Navigator.of(context).push(
                    _animatedRoute(const HostLobbyPage()),
                  );
                },
              ),
              const SizedBox(height: 24),
              AnimatedChoiceButton(
                label: 'Join',
                onTap: () {
                  Navigator.of(context).push(
                    _animatedRoute(const JoinLobbyPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Route _animatedRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.easeInOut;
      final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
  );
}


