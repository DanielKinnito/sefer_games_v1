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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Animated background for modern look
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.18,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: Theme.of(context).brightness == Brightness.dark
                          ? [
                              const Color(0xFF4A4A5A),
                              const Color(0xFF2D2D3A),
                              const Color(0xFF1A1A2E),
                            ]
                          : [
                              const Color(0xFF6377E3),
                              const Color(0xFFB388FF),
                              const Color(0xFFB2FFEA),
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
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.85)
                                : Colors.deepPurple.shade100.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black.withOpacity(0.3)
                                    : Colors.deepPurple.withOpacity(0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.transparent,
                                  child: Image.asset(
                                    'assets/logo.png', // Place your logo asset here
                                    height: 48,
                                    width: 48,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Sefer Games',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : const Color(0xFF3D155F),
                                    shadows: [
                                      Shadow(
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.black.withOpacity(0.5)
                                            : Colors.white,
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (onToggleTheme != null && isDarkMode != null)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: Icon(isDarkMode! ? Icons.light_mode : Icons.dark_mode, color: Colors.deepPurple, size: 28),
                              onPressed: onToggleTheme,
                              tooltip: isDarkMode! ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: AnimatedChoiceButton(
                            label: 'Host',
                            icon: Icons.add_circle_outline,
                            onTap: () {
                              Navigator.of(context).push(
                                _animatedRoute(HostLobbyPage(
                                  onToggleTheme: onToggleTheme,
                                  isDarkMode: isDarkMode,
                                )),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: AnimatedChoiceButton(
                            label: 'Join',
                            icon: Icons.group,
                            onTap: () {
                              Navigator.of(context).push(
                                _animatedRoute(JoinLobbyPage(
                                  onToggleTheme: onToggleTheme,
                                  isDarkMode: isDarkMode,
                                )),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bottom nav bar
                  Padding(
                    padding: const EdgeInsets.only(bottom: 0),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: const BottomNavBar(selectedIndex: 0),
                    ),
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


