// ═══════════════════════════════════════════════════════════════════════════════
// HOME SCREEN EXERCISE SECTION
// Drop this widget into home_screen.dart's _HomeTabState build() after the
// "Recovery Tips" section. It shows a quick entry point into Exercise Mode.
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:gait_rehab/core/constants/design_systems.dart';
import 'package:gait_rehab/core/widgets/widgets.dart';
import 'package:gait_rehab/domain/models/exercise_model.dart';
import 'package:gait_rehab/presentation/screens/exercise/exercise_mode_screen.dart';

/// Compact exercise mode entry on the home screen.
/// Shows today's recommended exercises or lets user browse all.
class HomeExerciseBanner extends StatelessWidget {
  /// Pass session data if available, null for no session yet
  final Map<String, dynamic>? lastSession;

  const HomeExerciseBanner({super.key, this.lastSession});

  @override
  Widget build(BuildContext context) {
    final hasSession = lastSession != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: 'Exercise Mode',
          action: 'All exercises',
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExerciseModeScreen(
                exercises: ExerciseLibrary.all.take(6).toList(),
                sessionTitle: 'General Rehab Session',
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // ── Main banner ─────────────────────────────────────────────
        GestureDetector(
          onTap: () {
            final exercises = hasSession
                ? ExerciseLibrary.recommend(
                    symmetry:
                        (lastSession!['symmetry'] as num?)?.toDouble() ?? 55,
                    cadence:
                        (lastSession!['cadence'] as num?)?.toDouble() ?? 65,
                    strideLength:
                        (lastSession!['stride_length'] as num?)?.toDouble() ??
                            0.8,
                    jointDeviation:
                        (lastSession!['joint_deviation'] as num?)?.toDouble() ??
                            30,
                    strideConsistency:
                        (lastSession!['stride_consistency'] as num?)
                                ?.toDouble() ??
                            50,
                    trunkLean: 6.0,
                    fallRisk:
                        lastSession!['fall_risk'] as String? ?? 'moderate',
                  ).map((r) => r.exercise).toList()
                : ExerciseLibrary.all
                    .where((e) => e.difficulty == ExerciseDifficulty.beginner)
                    .take(4)
                    .toList();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ExerciseModeScreen(
                  exercises: exercises,
                  sessionTitle: hasSession
                      ? 'Your AI-Prescribed Session'
                      : 'Beginner Rehab Session',
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.tealDark.withValues(alpha: 0.3),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Dot pattern
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CustomPaint(painter: _DotPainter()),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Icon with glow
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Center(
                          child: Text('🏋️', style: TextStyle(fontSize: 30)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasSession
                                  ? 'Start Today\'s Exercises'
                                  : 'Start Exercise Session',
                              style: const TextStyle(
                                  fontFamily: AppText.fontFamily,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  height: 1.2),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              hasSession
                                  ? 'AI-prescribed based on your last analysis'
                                  : 'Beginner-friendly guided session',
                              style: const TextStyle(
                                  fontFamily: AppText.fontFamily,
                                  color: Colors.white70,
                                  fontSize: 12,
                                  height: 1.3),
                            ),
                            const SizedBox(height: 10),
                            const Row(children: [
                              _MiniChip(
                                icon: Icons.play_circle_rounded,
                                label: 'Start Now',
                              ),
                              SizedBox(width: 8),
                              _MiniChip(
                                icon: Icons.record_voice_over_rounded,
                                label: 'Voice guidance',
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Category quick-select row ────────────────────────────────
      ],
    );
  }

  void _startCategory(
      BuildContext context, ExerciseCategory cat, String title) {
    final exercises =
        ExerciseLibrary.all.where((e) => e.category == cat).toList();
    if (exercises.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ExerciseModeScreen(exercises: exercises, sessionTitle: title),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MiniChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 11),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontFamily: AppText.fontFamily,
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;
  const _CategoryChip(
      {required this.emoji, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: cardShadow,
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontFamily: AppText.fontFamily,
                    fontSize: 12,
                    color: AppColors.textMid,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.07);
    for (double x = 0; x < size.width; x += 18) {
      for (double y = 0; y < size.height; y += 18) {
        canvas.drawCircle(Offset(x, y), 2, p);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
