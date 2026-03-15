import 'package:flutter/material.dart';
import 'package:gait_rehab/domain/models/exercise_model.dart';
import 'package:gait_rehab/presentation/screens/exercise/exercise_mode_screen.dart';

// ── Design tokens (matching your teal reference design) ─────────────────────
class _C {
  static const bgLight = Color(0xFFDFF2F7);
  static const bgMid = Color(0xFFC2E5EF);
  static const heroStart = Color(0xFF6ECECE);
  static const heroMid = Color(0xFF3AABAB);
  static const heroEnd = Color(0xFF1F7A7A);
  static const teal = Color(0xFF3AABAB);
  static const tealDark = Color(0xFF1F7A7A);
  static const tealPale = Color(0xFFE0F5F5);
  static const tealPill = Color(0xFFD0EFEF);
  static const white = Color(0xFFFFFFFF);
  static const cardBorder = Color(0xFFE8F4F4);
  static const textDark = Color(0xFF183232);
  static const textMid = Color(0xFF3D5A5A);
  static const textLight = Color(0xFF7A9E9E);
  static const textHint = Color(0xFFABC8C8);
  static const warning = Color(0xFFF5A623);
  static const danger = Color(0xFFE05454);

  static const heroGradient = LinearGradient(
    colors: [heroStart, heroMid, heroEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const bgGradient = LinearGradient(
    colors: [bgLight, bgMid],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const font = 'Nunito';

  static Color priorityColor(String label) {
    if (label == 'High Priority') return danger;
    if (label == 'Recommended') return warning;
    return teal;
  }

  static List<BoxShadow> get shadow => [
        BoxShadow(
          color: heroEnd.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}

// ═══════════════════════════════════════════════════════════════════════════════
// EXERCISE RECOMMENDATION SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class ExerciseRecommendationScreen extends StatefulWidget {
  /// Pass the gait metrics from your session analysis
  final double symmetry;
  final double cadence;
  final double strideLength;
  final double jointDeviation;
  final double strideConsistency;
  final double trunkLean;
  final String fallRisk;
  final double recoveryScore;

  const ExerciseRecommendationScreen({
    super.key,
    required this.symmetry,
    required this.cadence,
    required this.strideLength,
    required this.jointDeviation,
    required this.strideConsistency,
    required this.trunkLean,
    required this.fallRisk,
    required this.recoveryScore,
  });

  /// Factory: use for testing with mock good metrics
  factory ExerciseRecommendationScreen.fromSession(
      Map<String, dynamic> session) {
    return ExerciseRecommendationScreen(
      symmetry: (session['symmetry'] as num?)?.toDouble() ?? 55,
      cadence: (session['cadence'] as num?)?.toDouble() ?? 65,
      strideLength: (session['stride_length'] as num?)?.toDouble() ?? 0.8,
      jointDeviation: (session['joint_deviation'] as num?)?.toDouble() ?? 35,
      strideConsistency:
          (session['stride_consistency'] as num?)?.toDouble() ?? 45,
      trunkLean: 6.0, // from pose analysis
      fallRisk: session['fall_risk'] as String? ?? 'moderate',
      recoveryScore: (session['recovery_score'] as num?)?.toDouble() ?? 52,
    );
  }

  @override
  State<ExerciseRecommendationScreen> createState() =>
      _ExerciseRecommendationScreenState();
}

class _ExerciseRecommendationScreenState
    extends State<ExerciseRecommendationScreen>
    with SingleTickerProviderStateMixin {
  late List<ExerciseRecommendation> _recommendations;
  late AnimationController _anim;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _recommendations = ExerciseLibrary.recommend(
      symmetry: widget.symmetry,
      cadence: widget.cadence,
      strideLength: widget.strideLength,
      jointDeviation: widget.jointDeviation,
      strideConsistency: widget.strideConsistency,
      trunkLean: widget.trunkLean,
      fallRisk: widget.fallRisk,
    );
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _startAll() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseModeScreen(
          exercises: _recommendations.map((r) => r.exercise).toList(),
          sessionTitle: 'Full Rehab Session',
        ),
      ),
    );
  }

  void _startSingle(ExerciseModel ex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ExerciseModeScreen(exercises: [ex], sessionTitle: ex.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: _C.bgGradient),
        child: CustomScrollView(
          slivers: [
            // ── Hero ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
                child: _HeroCard(
                  score: widget.recoveryScore,
                  recs: _recommendations,
                  onStartAll: _startAll,
                ),
              ),
            ),

            // ── Issue summary chips ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: _IssueChipsRow(recommendations: _recommendations),
              ),
            ),

            // ── Section title ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(children: [
                  const Text('Recommended Exercises',
                      style: TextStyle(
                          fontFamily: _C.font,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _C.textDark)),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _C.tealPill,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_recommendations.length} exercises',
                      style: const TextStyle(
                          fontFamily: _C.font,
                          fontSize: 11,
                          color: _C.teal,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ]),
              ),
            ),

            // ── Exercise list ─────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final delay = i * 80;
                    return AnimatedBuilder(
                      animation: _anim,
                      builder: (_, child) {
                        final t = Curves.easeOutCubic.transform(
                          (((_anim.value * 1000) - delay) / 400)
                              .clamp(0.0, 1.0),
                        );
                        return Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0, 30 * (1 - t)),
                            child: child,
                          ),
                        );
                      },
                      child: _ExerciseCard(
                        rec: _recommendations[i],
                        index: i + 1,
                        isExpanded: _expandedIndex == i,
                        onExpand: () => setState(() =>
                            _expandedIndex = _expandedIndex == i ? null : i),
                        onStart: () =>
                            _startSingle(_recommendations[i].exercise),
                      ),
                    );
                  },
                  childCount: _recommendations.length,
                ),
              ),
            ),

            // ── Bottom CTA ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: _StartAllButton(
                    onTap: _startAll, count: _recommendations.length),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hero card at the top ─────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final double score;
  final List<ExerciseRecommendation> recs;
  final VoidCallback onStartAll;

  const _HeroCard({
    required this.score,
    required this.recs,
    required this.onStartAll,
  });

  @override
  Widget build(BuildContext context) {
    final highPriority = recs.where((r) => r.severity > 0.6).length;

    return Container(
      decoration: BoxDecoration(
        gradient: _C.heroGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Dot pattern
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CustomPaint(painter: _DotPainter()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.fitness_center_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'AI Exercise Plan',
                      style: TextStyle(
                          fontFamily: _C.font,
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                const Text(
                  'Personalised for\nyour gait analysis',
                  style: TextStyle(
                      fontFamily: _C.font,
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      letterSpacing: -0.4),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  _HeroPill(
                    icon: Icons.warning_amber_rounded,
                    label: '$highPriority high priority',
                    color: const Color(0xFFF5A623),
                  ),
                  const SizedBox(width: 8),
                  _HeroPill(
                    icon: Icons.show_chart_rounded,
                    label: 'Score ${score.toStringAsFixed(0)}/100',
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _HeroPill({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (color ?? Colors.white).withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color ?? Colors.white, size: 13),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontFamily: _C.font,
                color: color ?? Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

// ─── Issue chips row ──────────────────────────────────────────────────────────
class _IssueChipsRow extends StatelessWidget {
  final List<ExerciseRecommendation> recommendations;
  const _IssueChipsRow({required this.recommendations});

  @override
  Widget build(BuildContext context) {
    // Collect unique issues
    final issues = <String>{};
    for (final r in recommendations) {
      for (final issue in r.reasonIssues) {
        issues.add(ExerciseRecommendation._issueToLabel(issue));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Detected Issues',
            style: TextStyle(
                fontFamily: _C.font,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _C.textLight)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: issues
              .map((label) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _C.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _C.cardBorder),
                      boxShadow: _C.shadow,
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            color: _C.danger, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(label,
                          style: const TextStyle(
                              fontFamily: _C.font,
                              fontSize: 12,
                              color: _C.textMid,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ─── Individual exercise card ─────────────────────────────────────────────────
class _ExerciseCard extends StatelessWidget {
  final ExerciseRecommendation rec;
  final int index;
  final bool isExpanded;
  final VoidCallback onExpand;
  final VoidCallback onStart;

  const _ExerciseCard({
    required this.rec,
    required this.index,
    required this.isExpanded,
    required this.onExpand,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final ex = rec.exercise;
    final pColor = _C.priorityColor(rec.priorityLabel);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _C.shadow,
        border: isExpanded
            ? Border.all(color: _C.teal.withValues(alpha: 0.4), width: 1.5)
            : null,
      ),
      child: Column(
        children: [
          // ── Header row ───────────────────────────────────────────
          GestureDetector(
            onTap: onExpand,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Number + emoji
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: _C.tealPale,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(ex.iconEmoji,
                              style: const TextStyle(fontSize: 26)),
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _C.teal,
                          shape: BoxShape.circle,
                          border: Border.all(color: _C.white, width: 2),
                        ),
                        child: Center(
                          child: Text('$index',
                              style: const TextStyle(
                                  fontFamily: _C.font,
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ex.name,
                            style: const TextStyle(
                                fontFamily: _C.font,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: _C.textDark)),
                        const SizedBox(height: 3),
                        Text(ex.subtitle,
                            style: const TextStyle(
                                fontFamily: _C.font,
                                fontSize: 12,
                                color: _C.textLight)),
                        const SizedBox(height: 6),
                        // Priority + body focus
                        Row(children: [
                          _SmallPill(label: rec.priorityLabel, color: pColor),
                          const SizedBox(width: 6),
                          _SmallPill(
                              label: _categoryLabel(ex.category),
                              color: _C.teal),
                        ]),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      // Duration chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _C.tealPale,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ex.reps > 0
                              ? '${ex.reps} reps'
                              : '${ex.durationSeconds}s',
                          style: const TextStyle(
                              fontFamily: _C.font,
                              fontSize: 11,
                              color: _C.teal,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('${ex.sets} sets',
                          style: const TextStyle(
                              fontFamily: _C.font,
                              fontSize: 10,
                              color: _C.textLight)),
                      const SizedBox(height: 8),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: _C.textHint,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded detail ──────────────────────────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _ExpandedDetail(exercise: ex, onStart: onStart),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 280),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(ExerciseCategory c) {
    switch (c) {
      case ExerciseCategory.strengthening:
        return 'Strength';
      case ExerciseCategory.balance:
        return 'Balance';
      case ExerciseCategory.flexibility:
        return 'Flexibility';
      case ExerciseCategory.coordination:
        return 'Coordination';
      case ExerciseCategory.posture:
        return 'Posture';
      case ExerciseCategory.cadence:
        return 'Cadence';
    }
  }
}

class _SmallPill extends StatelessWidget {
  final String label;
  final Color color;
  const _SmallPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(label,
          style: TextStyle(
              fontFamily: _C.font,
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w700)),
    );
  }
}

// ─── Expanded card detail ─────────────────────────────────────────────────────
class _ExpandedDetail extends StatelessWidget {
  final ExerciseModel exercise;
  final VoidCallback onStart;

  const _ExpandedDetail({required this.exercise, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: _C.cardBorder, height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description
              Text(exercise.description,
                  style: const TextStyle(
                      fontFamily: _C.font,
                      fontSize: 13.5,
                      color: _C.textMid,
                      height: 1.55)),

              const SizedBox(height: 14),

              // Targets row
              Row(children: [
                const Icon(Icons.gps_fixed_rounded, color: _C.teal, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(exercise.bodyFocus,
                      style: const TextStyle(
                          fontFamily: _C.font,
                          fontSize: 12,
                          color: _C.teal,
                          fontWeight: FontWeight.w600)),
                ),
              ]),

              const SizedBox(height: 14),

              // Step-by-step cues
              const Text('How to do it',
                  style: TextStyle(
                      fontFamily: _C.font,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _C.textDark)),
              const SizedBox(height: 8),
              ...exercise.stepByStepCues.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.only(top: 2, right: 8),
                            decoration: const BoxDecoration(
                              color: _C.tealPale,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text('${e.key + 1}',
                                  style: const TextStyle(
                                      fontFamily: _C.font,
                                      fontSize: 9,
                                      color: _C.teal,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ),
                          Expanded(
                            child: Text(e.value,
                                style: const TextStyle(
                                    fontFamily: _C.font,
                                    fontSize: 12.5,
                                    color: _C.textMid,
                                    height: 1.4)),
                          ),
                        ],
                      ),
                    ),
                  ),

              const SizedBox(height: 12),

              // Common mistakes
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8EE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.warning.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.lightbulb_outline_rounded,
                          color: _C.warning, size: 14),
                      SizedBox(width: 6),
                      Text('Common Mistakes',
                          style: TextStyle(
                              fontFamily: _C.font,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _C.warning)),
                    ]),
                    const SizedBox(height: 6),
                    ...exercise.commonMistakes.map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ',
                                  style: TextStyle(
                                      color: _C.warning, fontSize: 12)),
                              Expanded(
                                child: Text(m,
                                    style: const TextStyle(
                                        fontFamily: _C.font,
                                        fontSize: 12,
                                        color: _C.textMid)),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Start button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('Start This Exercise',
                      style: TextStyle(
                          fontFamily: _C.font,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.teal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Start all button ─────────────────────────────────────────────────────────
class _StartAllButton extends StatelessWidget {
  final VoidCallback onTap;
  final int count;
  const _StartAllButton({required this.onTap, required this.count});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: _C.heroGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _C.heroEnd.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.play_circle_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Start Full Rehab Session',
                    style: TextStyle(
                        fontFamily: _C.font,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                Text('$count exercises · All at once',
                    style: const TextStyle(
                        fontFamily: _C.font,
                        color: Colors.white70,
                        fontSize: 12)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_rounded,
                color: Colors.white70, size: 18),
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
