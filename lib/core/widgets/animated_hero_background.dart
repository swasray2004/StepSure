import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AnimatedHeroBackground extends StatefulWidget {
  final Widget child;
  const AnimatedHeroBackground({required this.child, super.key});

  @override
  State<AnimatedHeroBackground> createState() => _AnimatedHeroBackgroundState();
}

class _AnimatedHeroBackgroundState extends State<AnimatedHeroBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final shift = math.sin(_controller.value * math.pi) * 0.3;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1, -1 + shift),
              end: Alignment(1, 1 - shift),
              colors: const [
                AppColors.heroStart,
                AppColors.heroMid,
                AppColors.heroEnd,
              ],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}
