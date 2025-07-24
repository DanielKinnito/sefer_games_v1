import 'package:flutter/material.dart';

class SplashLoadingIndicator extends StatefulWidget {
  final Color? color;
  final String? text;

  const SplashLoadingIndicator({
    super.key,
    this.color,
    this.text,
  });

  @override
  State<SplashLoadingIndicator> createState() => _SplashLoadingIndicatorState();
}

class _SplashLoadingIndicatorState extends State<SplashLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _dotsController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _dotsController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Colors.white;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Custom loading animation with dots
          AnimatedBuilder(
            animation: _dotsController,
            builder: (context, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final delay = index * 0.2;
                  final animationValue = _dotsController.value;
                  
                  double opacity = 0.3;
                  if (animationValue >= delay && animationValue <= delay + 0.4) {
                    opacity = 1.0;
                  } else if (animationValue > delay + 0.4 && animationValue <= delay + 0.6) {
                    opacity = 0.3;
                  }
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: CircleAvatar(
                      radius: 4,
                      backgroundColor: color.withOpacity(opacity),
                    ),
                  );
                }),
              );
            },
          ),
          
          if (widget.text != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.text!,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 14,
                letterSpacing: 1,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
