// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../recording/recording_screen.dart';

class InstructionsScreen extends StatefulWidget {
  const InstructionsScreen({super.key});

  @override
  State<InstructionsScreen> createState() => _InstructionsScreenState();
}

class _InstructionsScreenState extends State<InstructionsScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  bool _goingForward = true;

  late AnimationController _slideController;
  late AnimationController _bgController;

  late Animation<Offset> _slideIn;
  late Animation<Offset> _slideOut;
  late Animation<double> _fadeIn;
  late Animation<double> _bgAnim;

  static const _steps = [
    _Step(
      number: '01',
      icon: Icons.phone_android_rounded,
      lottie: 'assets/animations/phone.json',
      useLottie: true,
      gradientA: Color(0xFF6366F1),
      gradientB: Color(0xFF8B5CF6),
      title: 'Place Your Phone',
      body:
          'Position your phone at hip height on a stable stand or propped against a surface.',
      tip: 'A phone stand or leaning against a wall works great.',
      tipIcon: Icons.lightbulb_outline_rounded,
    ),
    _Step(
      number: '02',
      icon: Icons.straighten_rounded,
      lottie: null,
      useLottie: false,
      gradientA: Color(0xFF0A7EA4),
      gradientB: Color(0xFF06B6D4),
      title: 'Keep Your Distance',
      body:
          'Stand ~2 metres (6 ft) from the camera so your full body fits in the frame.',
      tip: 'Check your feet and head are both visible before starting.',
      tipIcon: Icons.crop_free_rounded,
    ),
    _Step(
      number: '03',
      icon: Icons.directions_walk_rounded,
      lottie: 'assets/animations/walking.json',
      useLottie: true,
      gradientA: Color(0xFF00A890),
      gradientB: Color(0xFF10B981),
      title: 'Walk Naturally',
      body:
          'Walk at your normal comfortable pace across the frame. Natural gait gives the best analysis.',
      tip: 'Walk parallel to the camera — not toward it.',
      tipIcon: Icons.swap_horiz_rounded,
    ),
    _Step(
      number: '04',
      icon: Icons.checkroom_rounded,
      lottie: null,
      useLottie: false,
      gradientA: Color(0xFFF59E0B),
      gradientB: Color(0xFFEF4444),
      title: 'Wear Contrasting Clothes',
      body:
          'Dark clothes on a light background (or vice versa) helps the AI detect your joints accurately.',
      tip: 'Avoid baggy clothing — it can hide joint positions.',
      tipIcon: Icons.visibility_rounded,
    ),
    _Step(
      number: '05',
      icon: Icons.wb_sunny_rounded,
      lottie: null,
      useLottie: false,
      gradientA: Color(0xFFEF4444),
      gradientB: Color(0xFFF97316),
      title: 'Good Lighting',
      body:
          'Make sure your recording area is well lit. Natural daylight is ideal. Avoid strong backlighting.',
      tip: 'Face a window rather than having light behind you.',
      tipIcon: Icons.wb_twilight_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _bgAnim = CurvedAnimation(parent: _bgController, curve: Curves.easeInOut);
    _buildSlideAnims(forward: true);
    _slideController.forward();
    _bgController.forward();
  }

  void _buildSlideAnims({required bool forward}) {
    _slideIn = Tween<Offset>(
      begin: Offset(forward ? 0.18 : -0.18, 0),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _slideOut = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(forward ? -0.18 : 0.18, 0),
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeInCubic));

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
  }

  void _goTo(int index, {required bool forward}) {
    if (index < 0 || index >= _steps.length) return;
    _goingForward = forward;
    _buildSlideAnims(forward: forward);
    _slideController.reset();
    _bgController.reset();
    setState(() => _currentStep = index);
    _slideController.forward();
    _bgController.forward();
  }

  void _next() {
    if (_currentStep < _steps.length - 1) {
      _goTo(_currentStep + 1, forward: true);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RecordingScreen()),
      );
    }
  }

  void _prev() {
    if (_currentStep > 0) {
      _goTo(_currentStep - 1, forward: false);
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final isLast = _currentStep == _steps.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FA),
      body: Stack(
        children: [
          // ── Animated gradient background blob ──────────────────────────
          AnimatedBuilder(
            animation: _bgAnim,
            builder: (_, __) => Positioned(
              top: -80,
              right: -80,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      step.gradientA.withValues(alpha: 0.18 * _bgAnim.value),
                      step.gradientA.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -60,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeInOut,
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    step.gradientB.withValues(alpha: 0.12),
                    step.gradientB.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),

          // ── Main content ───────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Top bar ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      _GlassButton(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close_rounded,
                            color: Color(0xFF1A2332), size: 18),
                      ),
                      const Spacer(),
                      // Step fraction label
                      AnimatedBuilder(
                        animation: _fadeIn,
                        builder: (_, __) => Opacity(
                          opacity: _fadeIn.value,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: step.gradientA.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color:
                                      step.gradientA.withValues(alpha: 0.25)),
                            ),
                            child: Text(
                              '${_currentStep + 1} / ${_steps.length}',
                              style: TextStyle(
                                color: step.gradientA,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Progress bar ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _SegmentedProgress(
                    total: _steps.length,
                    current: _currentStep,
                    color: step.gradientA,
                  ),
                ),

                const SizedBox(height: 32),

                // ── Illustration card ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SlideTransition(
                    position: _slideIn,
                    child: FadeTransition(
                      opacity: _fadeIn,
                      child: _IllustrationCard(step: step),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Text content ──────────────────────────────────────────
                Expanded(
                  child: SlideTransition(
                    position: _slideIn,
                    child: FadeTransition(
                      opacity: _fadeIn,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Step number badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    step.gradientA,
                                    step.gradientB,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'STEP ${step.number}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              step.title,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1A2332),
                                letterSpacing: -0.8,
                                height: 1.1,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              step.body,
                              style: TextStyle(
                                fontSize: 14.5,
                                color: Colors.grey.shade600,
                                height: 1.6,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Tip card
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: step.gradientA.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color:
                                        step.gradientA.withValues(alpha: 0.20)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: step.gradientA
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: Icon(step.tipIcon,
                                        color: step.gradientA, size: 15),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      step.tip,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: step.gradientA
                                            .withValues(alpha: 0.90),
                                        fontWeight: FontWeight.w600,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(),

                            // ── Navigation buttons ──────────────────────
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                children: [
                                  // Back button
                                  AnimatedOpacity(
                                    opacity: _currentStep > 0 ? 1.0 : 0.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: _GlassButton(
                                      onTap: _currentStep > 0 ? _prev : () {},
                                      size: 56,
                                      child: Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        color: Colors.grey.shade600,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  if (_currentStep > 0)
                                    const SizedBox(width: 12),

                                  // Next / Start button
                                  Expanded(
                                    child: _NextButton(
                                      isLast: isLast,
                                      gradientA: step.gradientA,
                                      gradientB: step.gradientB,
                                      onTap: _next,
                                    ),
                                  ),
                                ],
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
  }
}

// ─── Illustration Card ────────────────────────────────────────────────────────
class _IllustrationCard extends StatelessWidget {
  final _Step step;
  const _IllustrationCard({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            step.gradientA.withValues(alpha: 0.15),
            step.gradientB.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: step.gradientA.withValues(alpha: 0.20),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: step.gradientA.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: step.gradientA.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -10,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: step.gradientB.withValues(alpha: 0.08),
              ),
            ),
          ),

          // Large step number watermark
          Positioned(
            right: 20,
            bottom: 10,
            child: Text(
              step.number,
              style: TextStyle(
                fontSize: 90,
                fontWeight: FontWeight.w900,
                color: step.gradientA.withValues(alpha: 0.07),
                letterSpacing: -4,
                height: 1,
              ),
            ),
          ),

          // Center content
          Center(
            child: step.useLottie && step.lottie != null
                ? SizedBox(
                    width: 130,
                    height: 130,
                    child: Lottie.asset(
                      step.lottie!,
                      repeat: true,
                      fit: BoxFit.contain,
                    ),
                  )
                : Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [step.gradientA, step.gradientB],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: step.gradientA.withValues(alpha: 0.40),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(step.icon, color: Colors.white, size: 46),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Segmented Progress ───────────────────────────────────────────────────────
class _SegmentedProgress extends StatelessWidget {
  final int total;
  final int current;
  final Color color;

  const _SegmentedProgress({
    required this.total,
    required this.current,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final isDone = i <= current;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            height: 4,
            margin: EdgeInsets.only(right: i < total - 1 ? 5 : 0),
            decoration: BoxDecoration(
              color: isDone ? color : color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Next Button ──────────────────────────────────────────────────────────────
class _NextButton extends StatelessWidget {
  final bool isLast;
  final Color gradientA;
  final Color gradientB;
  final VoidCallback onTap;

  const _NextButton({
    required this.isLast,
    required this.gradientA,
    required this.gradientB,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [gradientA, gradientB],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: gradientA.withValues(alpha: 0.38),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLast) ...[
              const Text('🎬', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
            ],
            Text(
              isLast ? 'Start Recording' : 'Continue',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            if (!isLast) ...[
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Glass Button ─────────────────────────────────────────────────────────────
class _GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final double size;

  const _GlassButton({
    required this.child,
    required this.onTap,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ─── Step Data ────────────────────────────────────────────────────────────────
class _Step {
  final String number;
  final IconData icon;
  final String? lottie;
  final bool useLottie;
  final Color gradientA;
  final Color gradientB;
  final String title;
  final String body;
  final String tip;
  final IconData tipIcon;

  const _Step({
    required this.number,
    required this.icon,
    required this.lottie,
    required this.useLottie,
    required this.gradientA,
    required this.gradientB,
    required this.title,
    required this.body,
    required this.tip,
    required this.tipIcon,
  });
}
