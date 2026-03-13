// ═══════════════════════════════════════════════════════════════════════════════
// EXERCISE MODEL
// ═══════════════════════════════════════════════════════════════════════════════

enum GaitIssue {
  lowStrideLength,
  kneeDeviation,
  poorSymmetry,
  lowCadence,
  forwardLean,
  balanceInstability,
  reducedHipFlexion,
  ankleWeakness,
}

enum ExerciseDifficulty { beginner, intermediate, advanced }

enum ExerciseCategory {
  strengthening,
  balance,
  flexibility,
  coordination,
  posture,
  cadence,
}

class ExerciseModel {
  final String id;
  final String name;
  final String subtitle;
  final String description;
  final String voiceInstruction;
  final List<String> stepByStepCues;
  final int durationSeconds;
  final int reps;
  final int sets;
  final ExerciseCategory category;
  final ExerciseDifficulty difficulty;
  final List<GaitIssue> targetsIssues;
  final String animationAsset; // icon fallback used in our implementation
  final String iconEmoji;
  final String bodyFocus;
  final List<String> commonMistakes;
  final String restBetweenSets; // e.g. "30 seconds"

  const ExerciseModel({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.voiceInstruction,
    required this.stepByStepCues,
    required this.durationSeconds,
    required this.reps,
    required this.sets,
    required this.category,
    required this.difficulty,
    required this.targetsIssues,
    required this.animationAsset,
    required this.iconEmoji,
    required this.bodyFocus,
    required this.commonMistakes,
    required this.restBetweenSets,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// COMPLETE EXERCISE LIBRARY — 18 exercises
// ═══════════════════════════════════════════════════════════════════════════════
class ExerciseLibrary {
  static const List<ExerciseModel> all = [
    // ── STRIDE LENGTH ──────────────────────────────────────────────────────────
    ExerciseModel(
      id: 'step_length_training',
      name: 'Step-Length Training',
      subtitle: 'Equal stride practice',
      description:
          'Walk forward placing each foot on a marked target to train equal step length on both sides.',
      voiceInstruction:
          'Step forward evenly with both legs. Focus on equal distance with every step. Left... right... left... right.',
      stepByStepCues: [
        'Stand tall with feet hip-width apart',
        'Take a deliberate step forward with your weaker leg',
        'Match the same step length with your stronger leg',
        'Keep your gaze forward, not at your feet',
        'Swing your arms naturally in opposition to your legs',
        'Repeat for the full set',
      ],
      durationSeconds: 60,
      reps: 20,
      sets: 3,
      category: ExerciseCategory.coordination,
      difficulty: ExerciseDifficulty.beginner,
      targetsIssues: [GaitIssue.lowStrideLength, GaitIssue.poorSymmetry],
      animationAsset: 'assets/animations/step_length.json',
      iconEmoji: '👣',
      bodyFocus: 'Hip flexors · Hamstrings',
      commonMistakes: [
        'Rushing — take your time with each step',
        'Looking down instead of forward',
        'Uneven arm swing',
      ],
      restBetweenSets: '30 seconds',
    ),

    ExerciseModel(
      id: 'exaggerated_marching',
      name: 'Exaggerated Marching',
      subtitle: 'High knee stride drill',
      description:
          'March in place lifting each knee high to build hip flexor strength and improve stride length.',
      voiceInstruction:
          'Lift your knee high with each step. Drive your knee up toward your chest. March in rhythm.',
      stepByStepCues: [
        'Stand near a wall or chair for support if needed',
        'Lift your right knee to hip height',
        'Hold for 1 second at the top',
        'Lower and repeat with the left knee',
        'Swing opposite arm with each knee lift',
        'Maintain an upright posture throughout',
      ],
      durationSeconds: 45,
      reps: 16,
      sets: 3,
      category: ExerciseCategory.strengthening,
      difficulty: ExerciseDifficulty.beginner,
      targetsIssues: [GaitIssue.lowStrideLength, GaitIssue.reducedHipFlexion],
      animationAsset: 'assets/animations/marching.json',
      iconEmoji: '🦵',
      bodyFocus: 'Hip flexors · Core',
      commonMistakes: [
        'Leaning backward as the knee rises',
        'Not holding the raised position',
        'Shuffling feet instead of lifting',
      ],
      restBetweenSets: '30 seconds',
    ),

    // ── KNEE DEVIATION ─────────────────────────────────────────────────────────
    ExerciseModel(
      id: 'knee_stability',
      name: 'Knee Stability Exercise',
      subtitle: 'Lateral knee control',
      description:
          'Squat slowly while keeping your knees aligned over your second toe. Builds VMO strength to correct knee deviation during walking.',
      voiceInstruction:
          'Bend slowly, keep your knee pointing straight forward. Do not let your knee cave inward. Squeeze at the top.',
      stepByStepCues: [
        'Stand with feet shoulder-width apart',
        'Place a resistance band just above the knees',
        'Slowly lower into a quarter squat over 3 seconds',
        'Keep knees aligned directly over your 2nd toe',
        'Hold the lowered position for 2 seconds',
        'Rise slowly over 3 seconds, squeezing glutes at top',
      ],
      durationSeconds: 90,
      reps: 12,
      sets: 3,
      category: ExerciseCategory.strengthening,
      difficulty: ExerciseDifficulty.intermediate,
      targetsIssues: [GaitIssue.kneeDeviation],
      animationAsset: 'assets/animations/knee_squat.json',
      iconEmoji: '🦿',
      bodyFocus: 'VMO · Glutes · Hip abductors',
      commonMistakes: [
        'Knees caving inward (valgus)',
        'Squatting too deep too soon',
        'Heel lifting off the floor',
      ],
      restBetweenSets: '45 seconds',
    ),

    ExerciseModel(
      id: 'terminal_knee_extension',
      name: 'Terminal Knee Extension',
      subtitle: 'Final-range knee strengthening',
      description:
          'Using a resistance band, straighten your knee from a slightly bent position. Builds the last 30 degrees of knee extension critical for normal gait.',
      voiceInstruction:
          'Straighten your knee fully. Squeeze your quad at the end range. Hold for two seconds.',
      stepByStepCues: [
        'Loop a resistance band around a fixed object at knee height',
        'Step back so the band is taut with your knee slightly bent',
        'Straighten your knee fully, squeezing your quad',
        'Hold the fully extended position for 2 seconds',
        'Slowly bend the knee back to the start position',
        'Keep your foot flat on the floor throughout',
      ],
      durationSeconds: 60,
      reps: 15,
      sets: 3,
      category: ExerciseCategory.strengthening,
      difficulty: ExerciseDifficulty.beginner,
      targetsIssues: [GaitIssue.kneeDeviation],
      animationAsset: 'assets/animations/tke.json',
      iconEmoji: '🏋️',
      bodyFocus: 'Quadriceps · VMO',
      commonMistakes: [
        'Not fully extending the knee',
        'Moving the hip instead of isolating the knee',
        'Rushing through the motion',
      ],
      restBetweenSets: '30 seconds',
    ),

    // ── POOR SYMMETRY ──────────────────────────────────────────────────────────
    ExerciseModel(
      id: 'alternating_step_drill',
      name: 'Alternating Step Drill',
      subtitle: 'Left-right symmetry training',
      description:
          'Step up and down on a low step, alternating which foot leads each time. Trains equal loading and weight transfer between sides.',
      voiceInstruction:
          'Lead with your left leg, then your right. Keep the rhythm even. Left up, right up, left down, right down.',
      stepByStepCues: [
        'Stand in front of a 10–15 cm step',
        'Step up with your left foot, then bring your right foot up',
        'Step down with your left foot, then right',
        'Repeat leading with your RIGHT foot next',
        'Keep the tempo identical for both sides',
        'Hold a wall for balance if needed',
      ],
      durationSeconds: 60,
      reps: 20,
      sets: 3,
      category: ExerciseCategory.coordination,
      difficulty: ExerciseDifficulty.beginner,
      targetsIssues: [GaitIssue.poorSymmetry],
      animationAsset: 'assets/animations/step_up.json',
      iconEmoji: '🪜',
      bodyFocus: 'Glutes · Quads · Hip stabilisers',
      commonMistakes: [
        'Always leading with the same foot',
        'Stepping too quickly on the weaker side',
        'Gripping the wall too tightly',
      ],
      restBetweenSets: '30 seconds',
    ),

    ExerciseModel(
      id: 'weight_shift',
      name: 'Lateral Weight Shift',
      subtitle: 'Side-to-side loading drill',
      description:
          'Slowly shift your body weight from one leg to the other in a standing position. Trains equal single-leg loading critical for gait symmetry.',
      voiceInstruction:
          'Shift your weight slowly to your left side. Hold. Now shift to the right. Feel equal pressure through both feet.',
      stepByStepCues: [
        'Stand with feet hip-width apart, arms out to the sides lightly',
        'Slowly shift 100% of your weight onto your left leg',
        'Hold for 5 seconds — feel the pressure on your left sole',
        'Slowly shift back through centre, then onto the right leg',
        'Hold for 5 seconds on the right',
        'Return to centre and repeat',
      ],
      durationSeconds: 60,
      reps: 10,
      sets: 2,
      category: ExerciseCategory.balance,
      difficulty: ExerciseDifficulty.beginner,
      targetsIssues: [GaitIssue.poorSymmetry, GaitIssue.balanceInstability],
      animationAsset: 'assets/animations/weight_shift.json',
      iconEmoji: '⚖️',
      bodyFocus: 'Hip abductors · Core · Ankle stabilisers',
      commonMistakes: [
        'Leaning the trunk instead of shifting the pelvis',
        'Rushing through the hold',
        'Holding breath during the shift',
      ],
      restBetweenSets: '20 seconds',
    ),

    // ── LOW CADENCE ────────────────────────────────────────────────────────────
    ExerciseModel(
      id: 'metronome_walking',
      name: 'Metronome Walking',
      subtitle: 'Rhythmic cadence drill',
      description:
          'Walk in step with an auditory beat to train and increase your walking cadence. Start at 60 BPM and progress toward 90 BPM over sessions.',
      voiceInstruction:
          'Match each step to the beat. Left on the beat, right on the next beat. Stay with the rhythm — do not rush ahead.',
      stepByStepCues: [
        'Enable the in-app metronome or use a metronome app at 60 BPM',
        'Stand ready to walk in a clear straight path',
        'Place each foot down exactly on the beat',
        'Keep your steps light and controlled',
        'After 30 seconds, try increasing to 70 BPM',
        'Rest, then repeat at your target cadence',
      ],
      durationSeconds: 120,
      reps: 0, // duration-based
      sets: 3,
      category: ExerciseCategory.cadence,
      difficulty: ExerciseDifficulty.beginner,
      targetsIssues: [GaitIssue.lowCadence],
      animationAsset: 'assets/animations/metronome_walk.json',
      iconEmoji: '🎵',
      bodyFocus: 'Full gait pattern · Timing',
      commonMistakes: [
        'Rushing ahead of the beat instead of staying on it',
        'Taking too large a step to compensate for slow cadence',
        'Stopping when you lose the rhythm — just re-join it',
      ],
      restBetweenSets: '60 seconds',
    ),

    ExerciseModel(
      id: 'fast_feet',
      name: 'Fast Feet Drill',
      subtitle: 'Rapid step-rate training',
      description:
          'Rapidly alternate feet in place at a quick tempo to train your nervous system for faster step frequency.',
      voiceInstruction:
          'Tap your feet quickly — left right left right. Keep the rhythm fast and light. Stay on your toes.',
      stepByStepCues: [
        'Stand with feet hip-width apart near a wall',
        'Begin tapping feet alternately as fast as comfortable',
        'Keep taps light — barely lift the foot off the floor',
        'Maintain for 20 seconds, rest, repeat',
        'Focus on the speed of alternation, not height of lift',
        'Keep your upper body still and relaxed',
      ],
      durationSeconds: 20,
      reps: 0,
      sets: 5,
      category: ExerciseCategory.cadence,
      difficulty: ExerciseDifficulty.intermediate,
      targetsIssues: [GaitIssue.lowCadence],
      animationAsset: 'assets/animations/fast_feet.json',
      iconEmoji: '⚡',
      bodyFocus: 'Ankle · Calves · Neural timing',
      commonMistakes: [
        'Lifting the feet too high — keep it small and fast',
        'Tensing the shoulders and arms',
        'Stopping abruptly instead of gradually slowing',
      ],
      restBetweenSets: '30 seconds',
    ),

    // ── FORWARD LEAN ───────────────────────────────────────────────────────────
    ExerciseModel(
      id: 'posture_correction',
      name: 'Posture Correction Exercise',
      subtitle: 'Trunk alignment training',
      description:
          'Wall-stand posture resets and chin tucks to correct forward trunk lean during walking.',
      voiceInstruction:
          'Stand tall. Pull your chin back gently. Squeeze your shoulder blades together. Feel your spine lengthen upward.',
      stepByStepCues: [
        'Stand with your back against a flat wall',
        'Your heels, buttocks, upper back and head should touch the wall',
        'Gently tuck your chin down and back (not forward)',
        'Hold for 10 seconds, breathing normally',
        'Walk away from the wall maintaining the posture',
        'Return to the wall to reset every 30 seconds',
      ],
      durationSeconds: 60,
      reps: 8,
      sets: 3,
      category: ExerciseCategory.posture,
      difficulty: ExerciseDifficulty.beginner,
      targetsIssues: [GaitIssue.forwardLean],
      animationAsset: 'assets/animations/posture.json',
      iconEmoji: '🧍',
      bodyFocus: 'Thoracic extensors · Deep neck flexors · Core',
      commonMistakes: [
        'Forcing the head back instead of tucking the chin',
        'Holding breath during the hold',
        'Returning to a slouch as soon as walking begins',
      ],
      restBetweenSets: '20 seconds',
    ),

    ExerciseModel(
      id: 'chest_opener',
      name: 'Doorway Chest Opener',
      subtitle: 'Pectoral stretch for posture',
      description:
          'Stretch the chest and shoulder muscles shortened by prolonged forward posture.',
      voiceInstruction:
          'Place both hands on the door frame. Step through slowly until you feel a stretch across your chest. Breathe deeply.',
      stepByStepCues: [
        'Stand in a doorway with arms bent to 90 degrees on the frame',
        'Step one foot through the doorway',
        'Lean gently forward until you feel a stretch across the chest',
        'Hold for 30 seconds, breathing deeply throughout',
        'Return to start, then repeat on the other foot forward',
        'Do not bounce or force the stretch',
      ],
      durationSeconds: 60,
      reps: 3,
      sets: 2,
      category: ExerciseCategory.flexibility,
      difficulty: ExerciseDifficulty.beginner,
      targetsIssues: [GaitIssue.forwardLean],
      animationAsset: 'assets/animations/chest_stretch.json',
      iconEmoji: '🚪',
      bodyFocus: 'Pectorals · Anterior deltoids',
      commonMistakes: [
        'Shrugging the shoulders up during the stretch',
        'Leaning too aggressively — go slowly',
        'Only holding for a few seconds',
      ],
      restBetweenSets: '15 seconds',
    ),

    // ── BALANCE INSTABILITY ────────────────────────────────────────────────────
    ExerciseModel(
      id: 'single_leg_balance',
      name: 'Single-Leg Balance Drill',
      subtitle: 'Static balance training',
      description:
          'Stand on one leg to build ankle stability and proprioception. Progress from eyes open to eyes closed.',
      voiceInstruction:
          'Lift one foot off the floor. Hold steady. Focus on a fixed point in front of you. Feel the ankle micro-adjusting.',
      stepByStepCues: [
        'Stand near a wall or chair for safety',
        'Shift weight onto your right leg',
        'Lift your left foot slightly off the ground',
        'Hold for 30 seconds with eyes open',
        'If stable, try closing your eyes for 10 seconds',
        'Switch to the other leg and repeat',
      ],
      durationSeconds: 30,
      reps: 4,
      sets: 3,
      category: ExerciseCategory.balance,
      difficulty: ExerciseDifficulty.beginner,
      targetsIssues: [GaitIssue.balanceInstability, GaitIssue.poorSymmetry],
      animationAsset: 'assets/animations/single_leg.json',
      iconEmoji: '🦩',
      bodyFocus: 'Ankle stabilisers · Glutes · Core',
      commonMistakes: [
        'Gripping the wall for support instead of just touching lightly',
        'Holding breath',
        'Tilting the pelvis sideways instead of keeping it level',
      ],
      restBetweenSets: '20 seconds',
    ),

    ExerciseModel(
      id: 'tandem_walking',
      name: 'Tandem / Tightrope Walking',
      subtitle: 'Narrow base balance drill',
      description:
          'Walk heel-to-toe along a straight line on the floor, like walking a tightrope. Challenges balance with a narrow base of support.',
      voiceInstruction:
          'Place your heel directly in front of your toes with every step. Arms out wide for balance. Eyes forward.',
      stepByStepCues: [
        'Stick a line of tape on the floor as your guide',
        'Stand at one end, arms out to the sides',
        'Step forward placing your right heel directly in front of your left toes',
        'Continue for 10 steps in one direction',
        'Turn carefully and walk back',
        'Try 3 lengths without losing balance',
      ],
      durationSeconds: 90,
      reps: 10,
      sets: 3,
      category: ExerciseCategory.balance,
      difficulty: ExerciseDifficulty.intermediate,
      targetsIssues: [GaitIssue.balanceInstability],
      animationAsset: 'assets/animations/tandem_walk.json',
      iconEmoji: '🤸',
      bodyFocus: 'Ankle · Core · Vestibular system',
      commonMistakes: [
        'Looking down at the feet instead of ahead',
        'Walking too fast',
        'Arms remaining by sides — keep them out',
      ],
      restBetweenSets: '30 seconds',
    ),

    // ── HIP FLEXION ────────────────────────────────────────────────────────────
    ExerciseModel(
      id: 'hip_flexor_stretch',
      name: 'Hip Flexor Lunge Stretch',
      subtitle: 'Anterior hip mobility',
      description:
          'Lunge position stretch that lengthens the hip flexors shortened by reduced walking activity.',
      voiceInstruction:
          'Drop into a lunge. Keep your back straight. Press your hip forward gently. Breathe into the stretch.',
      stepByStepCues: [
        'Kneel on your right knee, left foot forward in a lunge',
        'Keep your left knee directly above the left ankle',
        'Gently press your right hip forward until you feel a stretch at the front',
        'Keep your trunk upright — do not lean forward',
        'Hold for 30 seconds, then switch sides',
        'For a deeper stretch, raise the right arm overhead',
      ],
      durationSeconds: 60,
      reps: 3,
      sets: 2,
      category: ExerciseCategory.flexibility,
      difficulty: ExerciseDifficulty.beginner,
      targetsIssues: [GaitIssue.reducedHipFlexion, GaitIssue.lowStrideLength],
      animationAsset: 'assets/animations/hip_stretch.json',
      iconEmoji: '🧎',
      bodyFocus: 'Hip flexors · Iliopsoas',
      commonMistakes: [
        'Leaning the trunk forward',
        'Front knee drifting past the toes',
        'Bouncing into the stretch',
      ],
      restBetweenSets: '15 seconds',
    ),

    // ── ANKLE WEAKNESS ─────────────────────────────────────────────────────────
    ExerciseModel(
      id: 'calf_raises',
      name: 'Calf Raises',
      subtitle: 'Push-off strength training',
      description:
          'Rise up onto the balls of your feet to strengthen the calf muscles essential for the push-off phase of walking.',
      voiceInstruction:
          'Rise up slowly on your toes. Hold at the top. Lower slowly. Control the descent — do not drop.',
      stepByStepCues: [
        'Stand facing a wall, fingertips lightly touching for balance',
        'Rise up on both toes over 2 seconds',
        'Hold at the top for 2 seconds',
        'Lower slowly over 3 seconds — slower than you rose',
        'Repeat without fully resting between reps',
        'Progress to single-leg when both-leg version is easy',
      ],
      durationSeconds: 60,
      reps: 15,
      sets: 3,
      category: ExerciseCategory.strengthening,
      difficulty: ExerciseDifficulty.beginner,
      targetsIssues: [GaitIssue.ankleWeakness, GaitIssue.lowCadence],
      animationAsset: 'assets/animations/calf_raise.json',
      iconEmoji: '🦶',
      bodyFocus: 'Gastrocnemius · Soleus',
      commonMistakes: [
        'Rolling outward onto the little toe side',
        'Dropping down too fast',
        'Bending the knees during the movement',
      ],
      restBetweenSets: '30 seconds',
    ),
  ];

  // ── RECOMMENDATION ENGINE ───────────────────────────────────────────────────
  /// Given gait metrics from a session, returns a prioritised list of exercises
  static List<ExerciseRecommendation> recommend({
    required double symmetry,
    required double cadence,
    required double strideLength,
    required double jointDeviation,
    required double strideConsistency,
    required double trunkLean,
    required String fallRisk,
  }) {
    final detected = <GaitIssue, double>{};

    // Rule-based detection with severity scores
    if (symmetry < 60) {
      detected[GaitIssue.poorSymmetry] = (60 - symmetry) / 60;
    }
    if (cadence < 70) {
      detected[GaitIssue.lowCadence] = (70 - cadence) / 70;
    }
    if (strideLength < 0.9) {
      detected[GaitIssue.lowStrideLength] = (0.9 - strideLength) / 0.9;
    }
    if (jointDeviation > 30) {
      detected[GaitIssue.kneeDeviation] = (jointDeviation - 30) / 70;
    }
    if (trunkLean.abs() > 8) {
      detected[GaitIssue.forwardLean] = (trunkLean.abs() - 8) / 20;
    }
    if (fallRisk == 'high' || fallRisk == 'moderate') {
      detected[GaitIssue.balanceInstability] = fallRisk == 'high' ? 1.0 : 0.6;
    }
    if (strideConsistency < 50) {
      detected[GaitIssue.reducedHipFlexion] = (50 - strideConsistency) / 50;
    }

    // Score each exercise
    final scored = <String, double>{};
    for (final ex in all) {
      double score = 0;
      for (final issue in ex.targetsIssues) {
        final severity = detected[issue] ?? 0;
        score += severity;
      }
      if (score > 0) scored[ex.id] = score;
    }

    // Sort by score descending, take top 6
    final sorted = scored.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topIds = sorted.take(6).map((e) => e.key).toSet();
    final topExercises = all.where((e) => topIds.contains(e.id)).toList();

    return topExercises
        .map((ex) => ExerciseRecommendation(
              exercise: ex,
              severity: scored[ex.id]!,
              reasonIssues: ex.targetsIssues
                  .where((i) => detected.containsKey(i))
                  .toList(),
            ))
        .toList()
      ..sort((a, b) => b.severity.compareTo(a.severity));
  }
}

// ─── Recommendation wrapper ───────────────────────────────────────────────────
class ExerciseRecommendation {
  final ExerciseModel exercise;
  final double severity; // 0.0–1.0
  final List<GaitIssue> reasonIssues;

  ExerciseRecommendation({
    required this.exercise,
    required this.severity,
    required this.reasonIssues,
  });

  String get priorityLabel {
    if (severity > 0.6) return 'High Priority';
    if (severity > 0.3) return 'Recommended';
    return 'Optional';
  }

  String get issueLabel {
    if (reasonIssues.isEmpty) return '';
    return reasonIssues.map(_issueToLabel).join(' · ');
  }

  static String _issueToLabel(GaitIssue issue) {
    switch (issue) {
      case GaitIssue.lowStrideLength:
        return 'Low stride length';
      case GaitIssue.kneeDeviation:
        return 'Knee deviation';
      case GaitIssue.poorSymmetry:
        return 'Poor symmetry';
      case GaitIssue.lowCadence:
        return 'Low cadence';
      case GaitIssue.forwardLean:
        return 'Forward lean';
      case GaitIssue.balanceInstability:
        return 'Balance instability';
      case GaitIssue.reducedHipFlexion:
        return 'Reduced hip flexion';
      case GaitIssue.ankleWeakness:
        return 'Ankle weakness';
    }
  }
}

// ─── Exercise session state ───────────────────────────────────────────────────
class ExerciseSessionState {
  final ExerciseModel exercise;
  int currentSet;
  int currentRep;
  int secondsElapsed;
  bool isResting;
  bool isComplete;

  ExerciseSessionState({
    required this.exercise,
    this.currentSet = 1,
    this.currentRep = 0,
    this.secondsElapsed = 0,
    this.isResting = false,
    this.isComplete = false,
  });

  double get progressFraction {
    final totalReps = exercise.reps * exercise.sets;
    if (totalReps == 0) {
      // Duration-based
      return (secondsElapsed / (exercise.durationSeconds * exercise.sets))
          .clamp(0.0, 1.0);
    }
    final completed = (currentSet - 1) * exercise.reps + currentRep;
    return (completed / totalReps).clamp(0.0, 1.0);
  }
}
