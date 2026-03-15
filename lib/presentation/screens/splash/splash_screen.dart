import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../core/constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({required this.next, super.key});
  final Widget next;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _floatController;
  late final Animation<double> _textFade;
  bool _navigate = false;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..forward();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _textFade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    Future.delayed(const Duration(milliseconds: 4200), () {
      if (!mounted) return;
      setState(() => _navigate = true);
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_navigate) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 700),
        child: widget.next,
      );
    }

    return Scaffold(
      body: AnimatedBuilder(
        animation: _floatController,
        builder: (context, _) {
          final floatOffset =
              math.sin(_floatController.value * math.pi * 2) * 12;

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.heroStart,
                  AppColors.heroMid,
                  AppColors.heroEnd,
                ],
              ),
            ),
            child: Stack(
              children: [
                /// Radial Glow Center
                Center(
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.15),
                          Colors.transparent
                        ],
                      ),
                    ),
                  ),
                ),

                /// Main Content Perfectly Centered
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      /// Floating Lottie
                      Transform.translate(
                        offset: Offset(0, floatOffset),
                        child: SizedBox(
                          width: 280,
                          height: 280,
                          child: Lottie.asset(
                            'assets/animations/walking2.json',
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      FadeTransition(
                        opacity: _textFade,
                        child: const Text(
                          'StepSure',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      FadeTransition(
                        opacity: _textFade,
                        child: Text(
                          'Smart AI for Confident Walking',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 15.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      FadeTransition(
                        opacity: _textFade,
                        child: SizedBox(
                          width: 200,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: LinearProgressIndicator(
                              value: _mainController.value,
                              minHeight: 6,
                              backgroundColor: Colors.white.withValues(alpha: 0.25),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
