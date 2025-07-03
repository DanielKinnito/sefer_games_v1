import 'package:flutter/material.dart';
import '../widgets/animated_choice_button.dart';
import '../widgets/animated_background.dart';

class JoinLobbyPage extends StatefulWidget {
  const JoinLobbyPage({super.key});

  @override
  State<JoinLobbyPage> createState() => _JoinLobbyPageState();
}

class _JoinLobbyPageState extends State<JoinLobbyPage> with SingleTickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 16).chain(CurveTween(curve: Curves.elasticIn)).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _onJoinPressed() {
    setState(() {
      if (_codeController.text.trim().isEmpty) {
        _showError = true;
        _animationController.forward(from: 0);
      } else {
        _showError = false;
        // TODO: Attempt to join lobby
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Join a Game', style: TextStyle(fontWeight: FontWeight.bold)),
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
                right: -60,
                diameter: 180,
                gradient: LinearGradient(
                  colors: [Color(0xFFFFECB3), Color(0xFFFFC107)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              AnimatedCircle(
                bottom: -40,
                left: -40,
                diameter: 120,
                color: Color(0x332D155F),
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
                      'Enter Lobby Code',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_showError ? _shakeAnimation.value : 0, 0),
                          child: child,
                        );
                      },
                      child: TextField(
                        controller: _codeController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, letterSpacing: 2),
                        decoration: InputDecoration(
                          hintText: 'e.g. 1234AB',
                          errorText: _showError ? 'Please enter a code' : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onSubmitted: (_) => _onJoinPressed(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimatedChoiceButton(
                      label: 'Join Lobby',
                      icon: Icons.login,
                      onTap: _onJoinPressed,
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
