// ═══════════════════════════════════════════════════════════════════════════════
// RESULTS SCREEN — EXERCISE SECTION PATCH
// Add this widget inside your existing ResultsScreen after the "Risk Assessment"
// section. It wires the gait metrics to the ExerciseRecommendationScreen.
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:gait_rehab/core/constants/design_systems.dart';
import 'package:gait_rehab/core/widgets/widgets.dart';
import 'package:gait_rehab/domain/models/exercise_model.dart';
import 'package:gait_rehab/presentation/screens/exercise/exercise_recommendation_screen.dart';

/// Drop this into ResultsScreen's body after the risk assessment card.
///
/// Usage:
///   ExerciseSectionWidget(session: session, report: report)
///
class ExerciseSectionWidget extends StatelessWidget {
  final Map<String, dynamic> session;
  final Map<String, dynamic> report;

  const ExerciseSectionWidget({
    super.key,
    required this.session,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Recommended Exercises'),
        const SizedBox(height: 8),

        // Teaser — shows top 3 exercise names
        _ExerciseTeaserCard(session: session),

        const SizedBox(height: 12),

        // Full CTA button
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExerciseRecommendationScreen.fromSession(session),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.tealDark.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.fitness_center_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('View Full Exercise Plan',
                          style: TextStyle(
                              fontFamily: AppText.fontFamily,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                      SizedBox(height: 2),
                      Text('AI-prescribed · Guided sessions',
                          style: TextStyle(
                              fontFamily: AppText.fontFamily,
                              color: Colors.white70,
                              fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white70, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Teaser card showing top exercises inline ─────────────────────────────────
class _ExerciseTeaserCard extends StatelessWidget {
  final Map<String, dynamic> session;
  const _ExerciseTeaserCard({required this.session});

  @override
  Widget build(BuildContext context) {
    // Get recommendations from the engine
    final recs = ExerciseLibrary.recommend(
      symmetry: (session['symmetry'] as num?)?.toDouble() ?? 55,
      cadence: (session['cadence'] as num?)?.toDouble() ?? 65,
      strideLength: (session['stride_length'] as num?)?.toDouble() ?? 0.8,
      jointDeviation: (session['joint_deviation'] as num?)?.toDouble() ?? 35,
      strideConsistency:
          (session['stride_consistency'] as num?)?.toDouble() ?? 45,
      trunkLean: 6.0,
      fallRisk: session['fall_risk'] as String? ?? 'moderate',
    );

    final top = recs.take(4).toList();

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.tealPale,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.teal, size: 14),
            ),
            const SizedBox(width: 8),
            const Text('AI Prescribed',
                style: TextStyle(
                    fontFamily: AppText.fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textDark)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.tealPale,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${recs.length} exercises',
                style: const TextStyle(
                    fontFamily: AppText.fontFamily,
                    fontSize: 10,
                    color: AppColors.teal,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ]),

          const SizedBox(height: 12),
          const Divider(color: AppColors.cardBorder, height: 1),
          const SizedBox(height: 10),

          // Exercise list
          ...top.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    // Number
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.tealPale,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${e.key + 1}',
                            style: const TextStyle(
                                fontFamily: AppText.fontFamily,
                                fontSize: 10,
                                color: AppColors.teal,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Emoji
                    Text(e.value.exercise.iconEmoji,
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),

                    // Name + issue
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.value.exercise.name,
                              style: const TextStyle(
                                  fontFamily: AppText.fontFamily,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.textDark)),
                          Text(e.value.issueLabel,
                              style: const TextStyle(
                                  fontFamily: AppText.fontFamily,
                                  fontSize: 11,
                                  color: AppColors.textLight),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),

                    // Priority badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: _priorityColor(e.value.priorityLabel)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        e.value.priorityLabel,
                        style: TextStyle(
                            fontFamily: AppText.fontFamily,
                            fontSize: 9,
                            color: _priorityColor(e.value.priorityLabel),
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              )),

          if (recs.length > 4) ...[
            const Divider(color: AppColors.cardBorder, height: 1),
            const SizedBox(height: 8),
            Text(
              '+ ${recs.length - 4} more exercises in your plan',
              style: const TextStyle(
                  fontFamily: AppText.fontFamily,
                  color: AppColors.teal,
                  fontWeight: FontWeight.w600,
                  fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Color _priorityColor(String label) {
    if (label == 'High Priority') return const Color(0xFFE05454);
    if (label == 'Recommended') return const Color(0xFFF5A623);
    return AppColors.teal;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// IMPORT SHIM — bring ExerciseLibrary into scope from results_screen.dart
// Add this import to results_screen.dart:
//   import 'package:your_app/domain/models/exercise_model.dart';
// ═══════════════════════════════════════════════════════════════════════════════
