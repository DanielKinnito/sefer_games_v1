import 'package:flutter/material.dart';

import '../widgets/animated_choice_button.dart';
import 'package:sefer_games_v1/core/presentation/widgets/bottom_nav_bar.dart';
import 'host_lobby_page.dart';
import 'join_lobby_page.dart';


class LobbyHomePage extends StatelessWidget {
  final VoidCallback? onToggleTheme;
  final bool? isDarkMode;
  const LobbyHomePage({super.key, this.onToggleTheme, this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          // Animated background for modern look
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.18,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF6377E3),
                        Color(0xFFB388FF),
                        Color(0xFFB2FFEA),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 32),
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade100.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepPurple.withOpacity(0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Sefer Games',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: Color(0xFF3D155F),
                                shadows: [
                                  Shadow(
                                    color: Colors.white,
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (onToggleTheme != null && isDarkMode != null)
                        IconButton(
                          icon: Icon(isDarkMode! ? Icons.light_mode : Icons.dark_mode, color: Colors.deepPurple, size: 32),
                          onPressed: onToggleTheme,
                          tooltip: isDarkMode! ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                        ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AnimatedChoiceButton(
                          label: 'Host',
                          icon: Icons.add_circle_outline,
                          onTap: () {
                            Navigator.of(context).push(
                              _animatedRoute(const HostLobbyPage()),
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        AnimatedChoiceButton(
                          label: 'Join',
                          icon: Icons.group,
                          onTap: () {
                            Navigator.of(context).push(
                              _animatedRoute(const JoinLobbyPage()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Bottom nav bar
                  BottomNavBar(
                    selectedIndex: 0,
                    onTap: (index) {
                      // TODO: Implement navigation logic for bottom nav bar
                      // Example: if (index == 1) Navigator.pushReplacementNamed(context, '/games');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Reuse the same bottom nav bar as other screens for consistency


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


