import 'package:flutter/material.dart';
import 'package:gait_rehab/domain/models/exercise_model.dart';

class _C {
  static const bg = Color(0xFF0D2B2B);
  static const surface = Color(0xFF153535);
  static const card = Color(0xFF1C4040);
  static const teal = Color(0xFF3AABAB);
  static const tealLt = Color(0xFF7DD4D4);
  static const tealDk = Color(0xFF1F7A7A);
  static const tealPale = Color(0xFF1C4040);
  static const white = Colors.white;
  static const white70 = Color(0xB3FFFFFF);
  static const font = 'Nunito';
  static const warning = Color(0xFFF5A623);

  static List<BoxShadow> get glow => [
        BoxShadow(
            color: teal.withValues(alpha: 0.35), blurRadius: 24, spreadRadius: 2),
      ];
}

// ═══════════════════════════════════════════════════════════════════════════════
// SESSION COMPLETE SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class ExerciseCompleteScreen extends StatefulWidget {
  final List<ExerciseModel> exercises;
  final String sessionTitle;

  const ExerciseCompleteScreen({
    super.key,
    required this.exercises,
    required this.sessionTitle,
  });

  @override
  State<ExerciseCompleteScreen> createState() => _ExerciseCompleteScreenState();
}

class _ExerciseCompleteScreenState extends State<ExerciseCompleteScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  // Calculate session stats
  int get _totalReps =>
      widget.exercises.fold(0, (sum, e) => sum + e.reps * e.sets);
  int get _totalSets => widget.exercises.fold(0, (sum, e) => sum + e.sets);
  int get _totalMins {
    final totalSec =
        widget.exercises.fold(0, (sum, e) => sum + e.durationSeconds * e.sets);
    return (totalSec / 60).ceil();
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // ── Trophy animation ────────────────────────────────
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _C.tealDk.withValues(alpha: 0.3),
                      boxShadow: _C.glow,
                    ),
                    child: const Center(
                      child: Text('🏆', style: TextStyle(fontSize: 64)),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text('Session Complete!',
                    style: TextStyle(
                        fontFamily: _C.font,
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5)),
                const SizedBox(height: 8),
                Text(widget.sessionTitle,
                    style: const TextStyle(
                        fontFamily: _C.font, color: _C.white70, fontSize: 15),
                    textAlign: TextAlign.center),

                const SizedBox(height: 28),

                // ── Session stats ───────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _C.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _C.teal.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        emoji: '🏋️',
                        value: '${widget.exercises.length}',
                        label: 'Exercises',
                      ),
                      _Divider(),
                      _StatItem(
                        emoji: '🔁',
                        value: '$_totalSets',
                        label: 'Total Sets',
                      ),
                      _Divider(),
                      _StatItem(
                        emoji: '⏱️',
                        value: '~$_totalMins',
                        label: 'Minutes',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Exercises completed list ────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: _C.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _C.teal.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(children: const [
                          Icon(Icons.check_circle_rounded,
                              color: _C.teal, size: 16),
                          SizedBox(width: 8),
                          Text('Completed',
                              style: TextStyle(
                                  fontFamily: _C.font,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                        ]),
                      ),
                      const Divider(color: Color(0xFF1C4040), height: 1),
                      ...widget.exercises
                          .asMap()
                          .entries
                          .map((e) => _ExerciseRow(
                                index: e.key + 1,
                                exercise: e.value,
                                isLast: e.key == widget.exercises.length - 1,
                              )),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Motivational message ────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _C.tealDk.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _C.teal.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Text('💪', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Every session brings you one step closer to your recovery goal. Well done!',
                          style: TextStyle(
                              fontFamily: _C.font,
                              color: _C.tealLt,
                              fontSize: 13,
                              height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── CTA buttons ─────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.popUntil(context, (r) => r.isFirst),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Back to Home',
                        style: TextStyle(
                            fontFamily: _C.font,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.teal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: _C.teal.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.replay_rounded, color: _C.tealLt),
                    label: const Text('Repeat Session',
                        style: TextStyle(
                            fontFamily: _C.font,
                            color: _C.tealLt,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      side: BorderSide(color: _C.teal.withValues(alpha: 0.4)),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _StatItem(
      {required this.emoji, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontFamily: _C.font,
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22)),
        Text(label,
            style: const TextStyle(
                fontFamily: _C.font, color: _C.white70, fontSize: 11)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 50,
        color: _C.teal.withValues(alpha: 0.15),
      );
}

class _ExerciseRow extends StatelessWidget {
  final int index;
  final ExerciseModel exercise;
  final bool isLast;
  const _ExerciseRow(
      {required this.index, required this.exercise, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _C.teal.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(exercise.iconEmoji,
                      style: const TextStyle(fontSize: 15)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exercise.name,
                        style: const TextStyle(
                            fontFamily: _C.font,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    Text(
                      '${exercise.sets} sets · ${exercise.reps > 0 ? '${exercise.reps} reps' : '${exercise.durationSeconds}s'}',
                      style: const TextStyle(
                          fontFamily: _C.font, color: _C.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.check_circle_rounded, color: _C.teal, size: 20),
            ],
          ),
        ),
        if (!isLast)
          const Divider(color: Color(0xFF1C4040), height: 1, indent: 16),
      ],
    );
  }
}
