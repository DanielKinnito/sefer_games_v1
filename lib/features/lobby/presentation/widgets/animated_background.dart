import 'package:flutter/material.dart';

class AnimatedBackground extends StatelessWidget {
  final List<AnimatedCircle> circles;
  const AnimatedBackground({required this.circles, super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: circles,
    );
  }
}

class AnimatedCircle extends StatelessWidget {
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double diameter;
  final Color? color;
  final Gradient? gradient;

  const AnimatedCircle({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.diameter,
    this.color,
    this.gradient,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: AnimatedContainer(
        duration: const Duration(seconds: 1),
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          gradient: gradient,
        ),
      ),
    );
  }
}
