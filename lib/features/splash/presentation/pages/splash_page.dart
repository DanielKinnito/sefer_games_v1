import 'package:flutter/material.dart';
import '../../../lobby/presentation/pages/lobby_home_page.dart';
import '../widgets/animated_logo.dart';
import '../widgets/splash_loading_indicator.dart';
import '../constants/splash_constants.dart';

class SplashPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const SplashPage({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: SplashConstants.animationDuration,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));
    
    _startSplashSequence();
  }

  void _startSplashSequence() async {
    // Start the animation
    _animationController.forward();
    
    // Wait for animation to complete + extra display time
    await Future.delayed(SplashConstants.splashDisplayDuration);
    
    // Navigate to lobby home page
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => LobbyHomePage(
            onToggleTheme: widget.onToggleTheme,
            isDarkMode: widget.isDarkMode,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: SplashConstants.navigationTransitionDuration,
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [
                    const Color(0xFF1A1B2E),
                    const Color(0xFF16213E),
                    const Color(0xFF0F3460),
                  ]
                : [
                    const Color(0xFF667EEA),
                    const Color(0xFF764BA2),
                    const Color(0xFF6B73FF),
                  ],
          ),
        ),
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: Image.asset(
                SplashConstants.splashBackground,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Return a simple colored background if image fails to load
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isDarkMode
                            ? [
                                const Color(0xFF1A1B2E),
                                const Color(0xFF16213E),
                                const Color(0xFF0F3460),
                              ]
                            : [
                                const Color(0xFF667EEA),
                                const Color(0xFF764BA2),
                                const Color(0xFF6B73FF),
                              ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Overlay gradient for better logo visibility
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.transparent,
                      Colors.black.withOpacity(0.4),
                    ],
                  ),
                ),
              ),
            ),
            
            // Logo and app name
            Center(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo using the AnimatedLogo widget
                          AnimatedLogo(
                            size: SplashConstants.logoSize,
                            useTransparentLogo: true,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // App name
                          Text(
                            'SEFER GAMES',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 3,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.7),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Tagline
                          Text(
                            'Play Together, Laugh Together',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 1,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 5,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Loading indicator at bottom
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return const SplashLoadingIndicator(
                    color: Colors.white,
                    text: 'Loading...',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
