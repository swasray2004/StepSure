import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:gait_rehab/core/constants/app_colors.dart';
import '../recording/recording_screen.dart';
import 'primary_button.dart';

class InstructionsScreen extends StatefulWidget {
  const InstructionsScreen({super.key});

  @override
  State<InstructionsScreen> createState() => _InstructionsScreenState();
}

class _InstructionsScreenState extends State<InstructionsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  int _currentStep = 0;

  final _steps = [
    _Step(
      icon: Icons.phone_android_rounded,
      iconColor: Color(0xFF6366F1),
      title: 'Place Your Phone',
      body:
          'Position your phone at hip height, either mounted on a stand or propped against a stable surface.',
      tip: 'Use a phone stand or lean it against a wall for best results.',
    ),
    _Step(
      icon: Icons.straighten_rounded,
      iconColor: Color(0xFF0A7EA4),
      title: 'Keep Your Distance',
      body:
          'Stand approximately 2 metres (6 feet) away from the camera so your full body is visible in the frame.',
      tip:
          'Test the framing before starting — check your feet and head are both visible.',
    ),
    _Step(
      icon: Icons.directions_walk_rounded,
      iconColor: Color(0xFF00A890),
      title: 'Walk Naturally',
      body:
          'Walk at your normal comfortable pace across the camera frame. Don\'t try to walk perfectly — natural gait gives the best analysis.',
      tip: 'Walk parallel to the camera, not toward it.',
    ),
    _Step(
      icon: Icons.checkroom_rounded,
      iconColor: Color(0xFFF59E0B),
      title: 'Wear Contrasting Clothes',
      body:
          'Wear clothing that contrasts with your background — dark clothes on a light background works best.',
      tip: 'Avoid baggy clothing as it can obscure joint positions.',
    ),
    _Step(
      icon: Icons.lightbulb_outline_rounded,
      iconColor: Color(0xFFEF4444),
      title: 'Good Lighting',
      body:
          'Make sure the recording area is well lit. Natural daylight is ideal. Avoid strong backlight.',
      tip: 'If indoors, face a window rather than having it behind you.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep < _steps.length - 1) {
      _controller.reset();
      setState(() => _currentStep++);
      _controller.forward();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RecordingScreen()),
      );
    }
  }

  void _prev() {
    if (_currentStep > 0) {
      _controller.reset();
      setState(() => _currentStep--);
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final isLast = _currentStep == _steps.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Session Setup'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _steps.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _currentStep ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _currentStep
                          ? AppColors.primary
                          : i < _currentStep
                              ? AppColors.primary.withOpacity(0.4)
                              : AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Step counter
              Text(
                'Step ${_currentStep + 1} of ${_steps.length}',
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 32),

              // Icon illustration or Lottie animation for steps
              FadeTransition(
                opacity: _fadeIn,
                child: step.title == 'Place Your Phone'
                    ? SizedBox(
                        width: 120,
                        height: 120,
                        child: Lottie.asset(
                          'assets/animations/phone.json',
                          repeat: true,
                          fit: BoxFit.contain,
                        ),
                      )
                    : step.title == 'Walk Naturally'
                        ? SizedBox(
                            width: 120,
                            height: 120,
                            child: Lottie.asset(
                              'assets/animations/walking.json',
                              repeat: true,
                              fit: BoxFit.contain,
                            ),
                          )
                        : Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: step.iconColor.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(step.icon,
                                color: step.iconColor, size: 52),
                          ),
              ),

              const SizedBox(height: 32),

              // Content
              FadeTransition(
                opacity: _fadeIn,
                child: Column(
                  children: [
                    Text(
                      step.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      step.body,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Tip box
              FadeTransition(
                opacity: _fadeIn,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: step.iconColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: step.iconColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.tips_and_updates_outlined,
                          color: step.iconColor, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          step.tip,
                          style: TextStyle(
                              fontSize: 12.5,
                              color: step.iconColor.withOpacity(0.85),
                              fontWeight: FontWeight.w500,
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Buttons
              Row(
                children: [
                  if (_currentStep > 0) ...[
                    SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _prev,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          side: BorderSide(
                              color: AppColors.primary.withOpacity(0.2)),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: PrimaryButton(
                      label: isLast ? '🎬  Start Recording' : 'Next',
                      icon: isLast ? null : Icons.arrow_forward_rounded,
                      color: isLast ? AppColors.success : AppColors.primary,
                      onTap: _next,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String tip;

  const _Step({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.tip,
  });
}
