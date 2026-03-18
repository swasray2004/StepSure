import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gait_rehab/data/exercise_session_controller.dart';
import 'package:gait_rehab/domain/models/exercise_model.dart';
import 'package:gait_rehab/presentation/screens/exercise/exercise_complete_screen.dart';
import 'skeletal_avatar_3d.dart'; // ← now uses 3D avatar card directly

// ── Design tokens ─────────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFF0D2B2B);
  static const surface = Color(0xFF153535);
  static const card = Color(0xFF1C4040);
  static const teal = Color(0xFF3AABAB);
  static const tealLt = Color(0xFF7DD4D4);
  static const tealDk = Color(0xFF1F7A7A);
  static const white = Colors.white;
  static const white70 = Color(0xB3FFFFFF);
  static const white40 = Color(0x66FFFFFF);
  static const warning = Color(0xFFF5A623);
  static const danger = Color(0xFFE05454);
  static const success = Color(0xFF3AABAB);
  static const font = 'Nunito';

  static List<BoxShadow> get glow => [
        BoxShadow(
            color: teal.withValues(alpha: 0.35),
            blurRadius: 24,
            spreadRadius: 2),
      ];
}

// ═══════════════════════════════════════════════════════════════════════════════
// EXERCISE MODE SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class ExerciseModeScreen extends StatefulWidget {
  final List<ExerciseModel> exercises;
  final String sessionTitle;

  const ExerciseModeScreen({
    super.key,
    required this.exercises,
    required this.sessionTitle,
  });

  @override
  State<ExerciseModeScreen> createState() => _ExerciseModeScreenState();
}

class _ExerciseModeScreenState extends State<ExerciseModeScreen>
    with TickerProviderStateMixin {
  late ExerciseSessionController _session;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _session = ExerciseSessionController(exercises: widget.exercises);
    _session.addListener(_onSessionChange);
    _session.start();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(_pulseCtrl);
  }

  void _onSessionChange() {
    if (!mounted) return;
    if (_session.sessionComplete) _navigateToComplete();
    setState(() {});
  }

  void _navigateToComplete() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseCompleteScreen(
          exercises: widget.exercises,
          sessionTitle: widget.sessionTitle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _session.removeListener(_onSessionChange);
    _session.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _session.currentController;
    final ex = _session.currentExercise;

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              sessionTitle: widget.sessionTitle,
              exerciseIndex: _session.exerciseIndex,
              totalExercises: _session.totalExercises,
              overallProgress:
                  (_session.exerciseIndex / _session.totalExercises)
                      .clamp(0.0, 1.0),
              onClose: _showExitDialog,
            ),
            Expanded(child: _buildPhaseContent(ctrl, ex)),
            _BottomControls(
              ctrl: ctrl,
              onSkip: () => _session.skipToNext(),
              onPause: () {
                ctrl.togglePause();
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseContent(SingleExerciseController ctrl, ExerciseModel ex) {
    switch (ctrl.phase) {
      case ExercisePhase.warmup:
        return _WarmupView(exercise: ex, countdown: ctrl.secondsLeft);
      case ExercisePhase.active:
        return _ActiveView(exercise: ex, ctrl: ctrl, pulseAnim: _pulseAnim);
      case ExercisePhase.rest:
        return _RestView(
          exercise: ex,
          ctrl: ctrl,
          nextSet: ctrl.currentSet + 1,
          totalSets: ex.sets,
        );
      case ExercisePhase.complete:
        return _ExerciseDoneView(exercise: ex);
    }
  }

  void _showExitDialog() {
    _session.currentController.pause();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _C.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Leave Session?',
            style: TextStyle(
                fontFamily: _C.font,
                color: Colors.white,
                fontWeight: FontWeight.w800)),
        content: const Text('Your progress in this session will be lost.',
            style: TextStyle(fontFamily: _C.font, color: _C.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _session.currentController.resume();
            },
            child: const Text('Keep Going',
                style: TextStyle(color: _C.teal, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Leave', style: TextStyle(color: _C.danger)),
          ),
        ],
      ),
    );
  }
}

// ─── Top bar ─────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String sessionTitle;
  final int exerciseIndex;
  final int totalExercises;
  final double overallProgress;
  final VoidCallback onClose;

  const _TopBar({
    required this.sessionTitle,
    required this.exerciseIndex,
    required this.totalExercises,
    required this.overallProgress,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onClose,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: _C.card, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.close_rounded,
                      color: _C.white70, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sessionTitle,
                        style: const TextStyle(
                            fontFamily: _C.font,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text('Exercise ${exerciseIndex + 1} of $totalExercises',
                        style: const TextStyle(
                            fontFamily: _C.font,
                            color: _C.white70,
                            fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _C.tealDk.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${exerciseIndex + 1}/$totalExercises',
                    style: const TextStyle(
                        fontFamily: _C.font,
                        color: _C.tealLt,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: overallProgress,
              backgroundColor: _C.card,
              valueColor: const AlwaysStoppedAnimation(_C.teal),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Warmup countdown ─────────────────────────────────────────────────────────
class _WarmupView extends StatelessWidget {
  final ExerciseModel exercise;
  final int countdown;
  const _WarmupView({required this.exercise, required this.countdown});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(exercise.name,
              style: const TextStyle(
                  fontFamily: _C.font,
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(exercise.subtitle,
              style: const TextStyle(
                  fontFamily: _C.font, color: _C.white70, fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 36),
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _C.tealDk.withValues(alpha: 0.2),
                    boxShadow: _C.glow,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: child,
                  ),
                  child: Text('$countdown',
                      key: ValueKey(countdown),
                      style: const TextStyle(
                          fontFamily: _C.font,
                          color: _C.tealLt,
                          fontSize: 72,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
                color: _C.card, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.gps_fixed_rounded, color: _C.teal, size: 14),
                const SizedBox(width: 7),
                Text(exercise.bodyFocus,
                    style: const TextStyle(
                        fontFamily: _C.font,
                        color: _C.tealLt,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _InfoChip(
                  label: 'Sets',
                  value: '${exercise.sets}',
                  icon: Icons.repeat_rounded),
              const SizedBox(width: 12),
              _InfoChip(
                  label: exercise.reps > 0 ? 'Reps' : 'Duration',
                  value: exercise.reps > 0
                      ? '${exercise.reps}'
                      : '${exercise.durationSeconds}s',
                  icon: exercise.reps > 0
                      ? Icons.loop_rounded
                      : Icons.timer_outlined),
              const SizedBox(width: 12),
              _InfoChip(
                  label: 'Rest',
                  value: exercise.restBetweenSets,
                  icon: Icons.pause_circle_outline_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Active exercise view ─────────────────────────────────────────────────────
class _ActiveView extends StatelessWidget {
  final ExerciseModel exercise;
  final SingleExerciseController ctrl;
  final Animation<double> pulseAnim;

  const _ActiveView({
    required this.exercise,
    required this.ctrl,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        children: [
          // Set indicator
          _SetIndicator(currentSet: ctrl.currentSet, totalSets: exercise.sets),
          const SizedBox(height: 14),

          // ── 3D Avatar card (replaces old _AnimationCard) ────────────────
          // FIX: pass pulseAnim so the subtle scale pulse is preserved
          AvatarAnimationCard(
            exerciseId: exercise.id,
            exerciseEmoji: exercise.iconEmoji,
            setProgress: ctrl.setProgress,
            isActive: !ctrl.isPaused,
            pulseAnim: pulseAnim,
          ),
          const SizedBox(height: 14),

          // Rep counter or timer
          ctrl.isTimeBased
              ? _TimerDisplay(secondsLeft: ctrl.secondsLeft, exercise: exercise)
              : _RepCounter(
                  current: ctrl.currentRep,
                  total: exercise.reps,
                  onTap: () => ctrl.completeRep(),
                ),
          const SizedBox(height: 14),

          // Voice cue banner
          _VoiceCueBanner(cue: exercise.voiceInstruction),
          const SizedBox(height: 12),

          // Step-by-step cues
          _CueCard(exercise: exercise),
        ],
      ),
    );
  }
}

// ─── Set indicator dots ───────────────────────────────────────────────────────
class _SetIndicator extends StatelessWidget {
  final int currentSet;
  final int totalSets;
  const _SetIndicator({required this.currentSet, required this.totalSets});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Set ',
            style: TextStyle(
                fontFamily: _C.font, color: _C.white70, fontSize: 13)),
        ...List.generate(
          totalSets,
          (i) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i < currentSet ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i < currentSet ? _C.teal : _C.card,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const Text(' done',
            style: TextStyle(
                fontFamily: _C.font, color: _C.white70, fontSize: 13)),
        Text(' · Set $currentSet of $totalSets',
            style: const TextStyle(
                fontFamily: _C.font,
                color: _C.tealLt,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ─── Timer display ────────────────────────────────────────────────────────────
class _TimerDisplay extends StatelessWidget {
  final int secondsLeft;
  final ExerciseModel exercise;
  const _TimerDisplay({required this.secondsLeft, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final mins = secondsLeft ~/ 60;
    final secs = secondsLeft % 60;
    final timeStr =
        mins > 0 ? '$mins:${secs.toString().padLeft(2, '0')}' : '$secondsLeft';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.teal.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_rounded, color: _C.teal, size: 28),
          const SizedBox(width: 12),
          Text(timeStr,
              style: const TextStyle(
                  fontFamily: _C.font,
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2)),
          const SizedBox(width: 8),
          const Text('sec',
              style: TextStyle(
                  fontFamily: _C.font, color: _C.white70, fontSize: 16)),
        ],
      ),
    );
  }
}

// ─── Rep counter ──────────────────────────────────────────────────────────────
class _RepCounter extends StatelessWidget {
  final int current;
  final int total;
  final VoidCallback onTap;

  const _RepCounter(
      {required this.current, required this.total, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final done = current >= total;
    return GestureDetector(
      onTap: done ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        decoration: BoxDecoration(
          color: done ? _C.teal.withValues(alpha: 0.2) : _C.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: done ? _C.teal : _C.teal.withValues(alpha: 0.2),
            width: done ? 2 : 1,
          ),
          boxShadow: done ? _C.glow : null,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$current',
                    style: TextStyle(
                        fontFamily: _C.font,
                        color: done ? _C.tealLt : Colors.white,
                        fontSize: 64,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -2)),
                Text(' / $total',
                    style: const TextStyle(
                        fontFamily: _C.font,
                        color: _C.white70,
                        fontSize: 28,
                        fontWeight: FontWeight.w400)),
              ],
            ),
            Text(
              done ? '✓  Set Complete!' : 'Tap each time you complete a rep',
              style: TextStyle(
                  fontFamily: _C.font,
                  color: done ? _C.tealLt : _C.white70,
                  fontSize: 13,
                  fontWeight: done ? FontWeight.w700 : FontWeight.normal),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(
                total,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: i < current ? 14 : 10,
                  height: i < current ? 14 : 10,
                  decoration: BoxDecoration(
                    color:
                        i < current ? _C.teal : _C.teal.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    boxShadow: i < current
                        ? [
                            BoxShadow(
                                color: _C.teal.withValues(alpha: 0.5),
                                blurRadius: 6)
                          ]
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Voice cue banner ─────────────────────────────────────────────────────────
class _VoiceCueBanner extends StatelessWidget {
  final String cue;
  const _VoiceCueBanner({required this.cue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.tealDk.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.teal.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: _C.teal.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: const Icon(Icons.record_voice_over_rounded,
                color: _C.tealLt, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text('"$cue"',
                style: const TextStyle(
                    fontFamily: _C.font,
                    color: _C.tealLt,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    height: 1.45)),
          ),
        ],
      ),
    );
  }
}

// ─── Step-by-step cue card ────────────────────────────────────────────────────
class _CueCard extends StatelessWidget {
  final ExerciseModel exercise;
  const _CueCard({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.teal.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.list_alt_rounded, color: _C.teal, size: 16),
            SizedBox(width: 8),
            Text('Step-by-Step',
                style: TextStyle(
                    fontFamily: _C.font,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ]),
          const SizedBox(height: 10),
          ...exercise.stepByStepCues.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.only(top: 2, right: 8),
                      decoration: BoxDecoration(
                          color: _C.tealDk.withValues(alpha: 0.5),
                          shape: BoxShape.circle),
                      child: Center(
                        child: Text('${e.key + 1}',
                            style: const TextStyle(
                                fontFamily: _C.font,
                                fontSize: 9,
                                color: _C.tealLt,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                    Expanded(
                      child: Text(e.value,
                          style: const TextStyle(
                              fontFamily: _C.font,
                              color: _C.white70,
                              fontSize: 12.5,
                              height: 1.45)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ─── Rest view ────────────────────────────────────────────────────────────────
class _RestView extends StatelessWidget {
  final ExerciseModel exercise;
  final SingleExerciseController ctrl;
  final int nextSet;
  final int totalSets;

  const _RestView({
    required this.exercise,
    required this.ctrl,
    required this.nextSet,
    required this.totalSets,
  });

  @override
  Widget build(BuildContext context) {
    final secs = ctrl.restSecondsLeft;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value:
                        secs / (_parseRestSecs(exercise.restBetweenSets) + 1),
                    backgroundColor: _C.card,
                    valueColor: const AlwaysStoppedAnimation(_C.teal),
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$secs',
                        style: const TextStyle(
                            fontFamily: _C.font,
                            color: Colors.white,
                            fontSize: 56,
                            fontWeight: FontWeight.w800)),
                    const Text('seconds',
                        style: TextStyle(
                            fontFamily: _C.font,
                            color: _C.white70,
                            fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text('Rest',
              style: TextStyle(
                  fontFamily: _C.font,
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Set $nextSet of $totalSets coming up',
              style: const TextStyle(
                  fontFamily: _C.font, color: _C.white70, fontSize: 14)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.teal.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _C.tealDk.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      const Icon(Icons.air_rounded, color: _C.tealLt, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Breathe',
                          style: TextStyle(
                              fontFamily: _C.font,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      Text('Take slow, deep breaths during rest.',
                          style: TextStyle(
                              fontFamily: _C.font,
                              color: _C.white70,
                              fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _parseRestSecs(String text) {
    final n = RegExp(r'\d+').firstMatch(text);
    return n != null ? int.parse(n.group(0)!) : 30;
  }
}

// ─── Exercise done view ───────────────────────────────────────────────────────
class _ExerciseDoneView extends StatelessWidget {
  final ExerciseModel exercise;
  const _ExerciseDoneView({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _C.teal.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              boxShadow: _C.glow,
            ),
            child: const Icon(Icons.check_rounded, color: _C.tealLt, size: 52),
          ),
          const SizedBox(height: 20),
          const Text('Exercise Complete!',
              style: TextStyle(
                  fontFamily: _C.font,
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Loading next exercise...',
              style: TextStyle(
                  fontFamily: _C.font, color: _C.white70, fontSize: 14)),
        ],
      ),
    );
  }
}

// ─── Bottom controls ──────────────────────────────────────────────────────────
class _BottomControls extends StatelessWidget {
  final SingleExerciseController ctrl;
  final VoidCallback onSkip;
  final VoidCallback onPause;

  const _BottomControls(
      {required this.ctrl, required this.onSkip, required this.onPause});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: BoxDecoration(
        color: _C.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onSkip,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: _C.card, borderRadius: BorderRadius.circular(14)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.skip_next_rounded, color: _C.white70, size: 20),
                  SizedBox(width: 4),
                  Text('Skip',
                      style: TextStyle(
                          fontFamily: _C.font,
                          color: _C.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (!ctrl.isTimeBased && ctrl.phase == ExercisePhase.active)
            Expanded(
              child: GestureDetector(
                onTap: () => ctrl.completeRep(),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF3AABAB), Color(0xFF1F7A7A)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _C.glow,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_rounded, color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text('Rep Done',
                          style: TextStyle(
                              fontFamily: _C.font,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                    ],
                  ),
                ),
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onPause,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ctrl.isPaused ? _C.teal : _C.card,
                borderRadius: BorderRadius.circular(14),
                boxShadow: ctrl.isPaused ? _C.glow : null,
              ),
              child: Icon(
                ctrl.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info chip ────────────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _InfoChip(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.teal.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: _C.teal, size: 16),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontFamily: _C.font,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
          Text(label,
              style: const TextStyle(
                  fontFamily: _C.font, color: _C.white70, fontSize: 10)),
        ],
      ),
    );
  }
}
