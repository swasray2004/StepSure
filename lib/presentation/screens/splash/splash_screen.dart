import 'dart:math' as math;
import 'dart:ui';
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
  late final AnimationController _gradientController;
  late final AnimationController _floatController;
  late final AnimationController _scanController;
  late final AnimationController _fadeController;
  late final AnimationController _heartbeatController;

  bool _navigate = false;

  @override
  void initState() {
    super.initState();

    _gradientController =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..repeat(reverse: true);

    _floatController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat(reverse: true);

    _scanController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();

    _heartbeatController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);

    _fadeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
          ..forward();

    Future.delayed(const Duration(milliseconds: 4500), () {
      if (!mounted) return;
      setState(() => _navigate = true);
    });
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _floatController.dispose();
    _scanController.dispose();
    _fadeController.dispose();
    _heartbeatController.dispose();
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
        animation: Listenable.merge([
          _gradientController,
          _floatController,
          _scanController,
          _heartbeatController,
          _fadeController
        ]),
        builder: (context, _) {
          final gradientShift =
              math.sin(_gradientController.value * math.pi) * 0.3;

          final floatOffset =
              math.sin(_floatController.value * math.pi * 2) * 10;

          final heartbeatScale =
              1 + (_heartbeatController.value * 0.08);

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1, -1 + gradientShift),
                end: Alignment(1, 1 - gradientShift),
                colors: const [
                  AppColors.heroStart,
                  AppColors.heroMid,
                  AppColors.heroEnd,
                ],
              ),
            ),
            child: Stack(
              children: [

                /// HEARTBEAT GLOW
                Center(
                  child: Transform.scale(
                    scale: heartbeatScale,
                    child: Container(
                      width: 380,
                      height: 380,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.18),
                            Colors.transparent
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                /// PARTICLE SHIMMER
                const Positioned.fill(
                  child: _ParticleLayer(),
                ),

                /// CENTER CONTENT
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      /// STACK FOR SCAN EFFECT
                      Stack(
                        alignment: Alignment.center,
                        children: [

                          /// FLOATING LOTTIE
                          Transform.translate(
                            offset: Offset(0, floatOffset),
                            child: SizedBox(
                              width: 260,
                              height: 260,
                              child: Lottie.asset(
                                'assets/animations/walking2.json',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                          /// SCANNING LINE
                          Positioned(
                            top: 260 * _scanController.value,
                            child: Container(
                              width: 240,
                              height: 3,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withOpacity(0.9),
                                    Colors.transparent
                                  ],
                                ),
                              ),
                            ),
                          ),

                          /// SKELETON WIREFRAME EFFECT
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0.12,
                              child: CustomPaint(
                                painter: _WireframePainter(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      /// GLASS PANEL
                      FadeTransition(
                        opacity: _fadeController,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 18),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.25),
                                ),
                              ),
                              child: Column(
                                children: const [
                                  Text(
                                    'StepSure',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 40,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'AI-Powered Gait Rehabilitation',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
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

class _ParticleLayer extends StatefulWidget {
  const _ParticleLayer();

  @override
  State<_ParticleLayer> createState() => _ParticleLayerState();
}

class _ParticleLayerState extends State<_ParticleLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return CustomPaint(
          painter: _ParticlePainter(_controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 30; i++) {
      final dx = (size.width / 30) * i +
          math.sin(progress * 2 * math.pi + i) * 20;
      final dy = size.height * progress + (i * 30 % size.height);

      canvas.drawCircle(
        Offset(dx % size.width, dy % size.height),
        2.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _WireframePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;

    canvas.drawLine(
        Offset(size.width * 0.5, size.height * 0.1),
        Offset(size.width * 0.5, size.height * 0.9),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}