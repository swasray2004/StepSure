import 'dart:math' as math;
import 'skeleton_3d_math.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// EXERCISE POSE LIBRARY
// Every exercise has at least 2 keyframes (A and B).
// The renderer interpolates between them using sin/easing curves.
// ═══════════════════════════════════════════════════════════════════════════════

class ExercisePoses {
  /// Returns [poseA, poseB] keyframes for the given exercise ID.
  static List<Pose> forExercise(String exerciseId) {
    switch (exerciseId) {
      case 'step_length_training':
      case 'alternating_step_drill':
        return _walkingPoses;
      case 'exaggerated_marching':
        return _marchingPoses;
      case 'knee_stability':
        return _squatPoses;
      case 'terminal_knee_extension':
        return _tknePoses;
      case 'single_leg_balance':
        return _singleLegPoses;
      case 'tandem_walking':
        return _tandemPoses;
      case 'weight_shift':
        return _weightShiftPoses;
      case 'metronome_walking':
        return _walkingPoses;
      case 'fast_feet':
        return _fastFeetPoses;
      case 'posture_correction':
        return _posturePoses;
      case 'calf_raises':
        return _calfRaisePoses;
      case 'hip_flexor_stretch':
        return _hipStretchPoses;
      case 'chest_opener':
        return _chestOpenerPoses;
      default:
        return [standPose, standPose];
    }
  }

  // ─── WALKING — mid-stride, left leg forward ──────────────────────────────
  static List<Pose> get _walkingPoses => [
        // Key A: left foot forward, right arm forward
        [
          const Vec3(0.0, 1.72, 0.02), // head  (slight forward lean)
          const Vec3(0.0, 1.52, 0.01), // neck
          const Vec3(-0.20, 1.45, 0.05), // lShoulder
          const Vec3(0.20, 1.45, -0.05), // rShoulder
          const Vec3(-0.30, 1.20, 0.15), // lElbow  (left arm back)
          const Vec3(0.30, 1.25, -0.12), // rElbow  (right arm forward)
          const Vec3(-0.28, 0.96, 0.18), // lWrist
          const Vec3(0.28, 1.05, -0.16), // rWrist
          const Vec3(0.0, 1.10, 0.01), // spine
          const Vec3(0.0, 0.95, 0.0), // hips
          const Vec3(-0.10, 0.92, 0.0), // lHip
          const Vec3(0.10, 0.92, 0.0), // rHip
          const Vec3(-0.13, 0.62,
              -0.10), // lKnee  (left leg forward, knee slightly bent)
          const Vec3(0.12, 0.42, 0.14), // rKnee  (right leg back, bent)
          const Vec3(-0.13, 0.08, -0.18), // lAnkle (forward)
          const Vec3(0.12, 0.10, 0.18), // rAnkle (back, heel lifted)
          const Vec3(-0.19, 0.01, -0.24), // lToe
          const Vec3(0.18, 0.14, 0.20), // rToe
        ],
        // Key B: right foot forward, left arm forward (mirror)
        [
          const Vec3(0.0, 1.72, 0.02),
          const Vec3(0.0, 1.52, 0.01),
          const Vec3(-0.20, 1.45, -0.05), // lShoulder
          const Vec3(0.20, 1.45, 0.05), // rShoulder
          const Vec3(-0.30, 1.25, -0.12), // lElbow forward
          const Vec3(0.30, 1.20, 0.15), // rElbow back
          const Vec3(-0.28, 1.05, -0.16), // lWrist
          const Vec3(0.28, 0.96, 0.18), // rWrist
          const Vec3(0.0, 1.10, 0.01),
          const Vec3(0.0, 0.95, 0.0),
          const Vec3(-0.10, 0.92, 0.0),
          const Vec3(0.10, 0.92, 0.0),
          const Vec3(-0.12, 0.42, 0.14), // lKnee back
          const Vec3(0.13, 0.62, -0.10), // rKnee forward
          const Vec3(-0.12, 0.10, 0.18), // lAnkle back
          const Vec3(0.13, 0.08, -0.18), // rAnkle forward
          const Vec3(-0.18, 0.14, 0.20),
          const Vec3(0.19, 0.01, -0.24),
        ],
      ];

  // ─── MARCHING — high knee ────────────────────────────────────────────────
  static List<Pose> get _marchingPoses => [
        // A: left knee high
        [
          const Vec3(0.0, 1.74, 0.0), // head tall
          const Vec3(0.0, 1.54, 0.0), // neck
          const Vec3(-0.21, 1.48, 0.0), // lShoulder
          const Vec3(0.21, 1.48, 0.0), // rShoulder
          const Vec3(-0.28, 1.18, -0.12), // lElbow back (left arm swings back)
          const Vec3(0.28, 1.22, 0.12), // rElbow forward
          const Vec3(-0.25, 0.92, -0.14), // lWrist
          const Vec3(0.25, 0.98, 0.14), // rWrist
          const Vec3(0.0, 1.14, 0.0), // spine
          const Vec3(0.0, 0.97, 0.0), // hips
          const Vec3(-0.10, 0.94, 0.0), // lHip
          const Vec3(0.10, 0.94, 0.0), // rHip
          const Vec3(-0.12, 0.70, 0.08), // lKnee HIGH (thigh near horizontal)
          const Vec3(0.12, 0.50, 0.0), // rKnee planted
          const Vec3(-0.10, 0.60, 0.06), // lAnkle (tucked)
          const Vec3(0.12, 0.07, 0.0), // rAnkle planted
          const Vec3(-0.12, 0.54, 0.08), // lToe tucked
          const Vec3(0.18, 0.01, 0.0), // rToe
        ],
        // B: right knee high (mirror)
        [
          const Vec3(0.0, 1.74, 0.0),
          const Vec3(0.0, 1.54, 0.0),
          const Vec3(-0.21, 1.48, 0.0),
          const Vec3(0.21, 1.48, 0.0),
          const Vec3(-0.28, 1.22, 0.12), // lElbow forward
          const Vec3(0.28, 1.18, -0.12), // rElbow back
          const Vec3(-0.25, 0.98, 0.14),
          const Vec3(0.25, 0.92, -0.14),
          const Vec3(0.0, 1.14, 0.0),
          const Vec3(0.0, 0.97, 0.0),
          const Vec3(-0.10, 0.94, 0.0),
          const Vec3(0.10, 0.94, 0.0),
          const Vec3(-0.12, 0.50, 0.0), // lKnee planted
          const Vec3(0.12, 0.70, 0.08), // rKnee HIGH
          const Vec3(-0.12, 0.07, 0.0),
          const Vec3(0.10, 0.60, 0.06),
          const Vec3(-0.18, 0.01, 0.0),
          const Vec3(0.12, 0.54, 0.08),
        ],
      ];

  // ─── SQUAT ───────────────────────────────────────────────────────────────
  static List<Pose> get _squatPoses => [
        // A: standing
        standPose,
        // B: quarter-squat, arms extended for balance
        [
          const Vec3(0.0, 1.56, -0.05), // head (slight forward lean)
          const Vec3(0.0, 1.38, -0.03), // neck
          const Vec3(-0.21, 1.32, 0.0), // lShoulder
          const Vec3(0.21, 1.32, 0.0), // rShoulder
          const Vec3(-0.36, 1.18, -0.10), // lElbow (arms forward-down)
          const Vec3(0.36, 1.18, -0.10), // rElbow
          const Vec3(-0.42, 1.05, -0.18), // lWrist
          const Vec3(0.42, 1.05, -0.18), // rWrist
          const Vec3(0.0, 0.98, -0.02), // spine
          const Vec3(0.0, 0.82, 0.0), // hips (dropped 14cm)
          const Vec3(-0.14, 0.79, 0.0), // lHip
          const Vec3(0.14, 0.79, 0.0), // rHip
          const Vec3(-0.16, 0.42, 0.04), // lKnee (bent ~45°)
          const Vec3(0.16, 0.42, 0.04), // rKnee
          const Vec3(-0.14, 0.07, 0.0), // lAnkle
          const Vec3(0.14, 0.07, 0.0), // rAnkle
          const Vec3(-0.20, 0.01, 0.0), // lToe
          const Vec3(0.20, 0.01, 0.0), // rToe
        ],
      ];

  // ─── TERMINAL KNEE EXTENSION — resistance band knee straighten ───────────
  static List<Pose> get _tknePoses => [
        // A: knee slightly bent (start)
        [
          const Vec3(0.0, 1.72, 0.0),
          const Vec3(0.0, 1.52, 0.0),
          const Vec3(-0.20, 1.45, 0.0),
          const Vec3(0.20, 1.45, 0.0),
          const Vec3(-0.30, 1.22, 0.0),
          const Vec3(0.30, 1.22, 0.0),
          const Vec3(-0.28, 0.98, 0.0),
          const Vec3(0.28, 0.98, 0.0),
          const Vec3(0.0, 1.10, 0.0),
          const Vec3(0.0, 0.95, 0.0),
          const Vec3(-0.11, 0.92, 0.0),
          const Vec3(0.11, 0.92, 0.0),
          const Vec3(-0.12, 0.52, 0.06), // lKnee bent slightly
          const Vec3(0.12, 0.50, 0.0),
          const Vec3(-0.12, 0.10, 0.08), // lAnkle (corresponding)
          const Vec3(0.12, 0.07, 0.0),
          const Vec3(-0.18, 0.03, 0.10),
          const Vec3(0.18, 0.01, 0.0),
        ],
        // B: knee fully extended (squeeze quad)
        standPose,
      ];

  // ─── SINGLE LEG BALANCE ──────────────────────────────────────────────────
  static List<Pose> get _singleLegPoses => [
        // A: stable on right leg, left knee lifted to 90°
        [
          const Vec3(0.02, 1.72, 0.0), // head slight sway
          const Vec3(0.01, 1.52, 0.0), // neck
          const Vec3(-0.22, 1.46, 0.0), // lShoulder (arms slightly out)
          const Vec3(0.22, 1.46, 0.0), // rShoulder
          const Vec3(-0.38, 1.30, 0.0), // lElbow (arms out for balance)
          const Vec3(0.38, 1.30, 0.0), // rElbow
          const Vec3(-0.50, 1.20, 0.0), // lWrist
          const Vec3(0.50, 1.20, 0.0), // rWrist
          const Vec3(0.01, 1.12, 0.0), // spine
          const Vec3(0.01, 0.96, 0.0), // hips
          const Vec3(-0.10, 0.93, 0.0), // lHip
          const Vec3(0.11, 0.93, 0.0), // rHip
          const Vec3(-0.10, 0.68, 0.04), // lKnee lifted (thigh ~45° up)
          const Vec3(0.12, 0.50, 0.0), // rKnee planted, straight
          const Vec3(-0.10, 0.56, 0.06), // lAnkle tucked
          const Vec3(0.12, 0.07, 0.0), // rAnkle planted
          const Vec3(-0.12, 0.50, 0.08), // lToe
          const Vec3(0.18, 0.01, 0.0), // rToe
        ],
        // B: slight sway — same pose with 2° lateral tilt
        [
          const Vec3(-0.02, 1.72, 0.0),
          const Vec3(-0.01, 1.52, 0.0),
          const Vec3(-0.22, 1.46, 0.0),
          const Vec3(0.22, 1.46, 0.0),
          const Vec3(-0.38, 1.32, 0.02),
          const Vec3(0.38, 1.28, -0.02),
          const Vec3(-0.50, 1.22, 0.04),
          const Vec3(0.50, 1.18, -0.04),
          const Vec3(-0.01, 1.12, 0.0),
          const Vec3(-0.01, 0.96, 0.0),
          const Vec3(-0.12, 0.93, 0.0),
          const Vec3(0.10, 0.93, 0.0),
          const Vec3(-0.10, 0.68, 0.04),
          const Vec3(0.12, 0.50, 0.0),
          const Vec3(-0.10, 0.56, 0.06),
          const Vec3(0.12, 0.07, 0.0),
          const Vec3(-0.12, 0.50, 0.08),
          const Vec3(0.18, 0.01, 0.0),
        ],
      ];

  // ─── TANDEM / TIGHTROPE WALKING ──────────────────────────────────────────
  static List<Pose> get _tandemPoses => [
        // A: left foot in front, heel-to-toe, arms wide
        [
          const Vec3(0.0, 1.72, 0.0),
          const Vec3(0.0, 1.52, 0.0),
          const Vec3(-0.24, 1.46, 0.0),
          const Vec3(0.24, 1.46, 0.0),
          const Vec3(-0.46, 1.30, 0.0), // lElbow wide
          const Vec3(0.46, 1.30, 0.0), // rElbow wide
          const Vec3(-0.60, 1.22, 0.0), // lWrist wide
          const Vec3(0.60, 1.22, 0.0), // rWrist wide
          const Vec3(0.0, 1.10, 0.0),
          const Vec3(0.0, 0.95, 0.0),
          const Vec3(-0.06, 0.92, 0.0), // hips narrower (tandem)
          const Vec3(0.06, 0.92, 0.0),
          const Vec3(-0.06, 0.55, -0.12), // lKnee forward
          const Vec3(0.06, 0.42, 0.10), // rKnee back
          const Vec3(-0.02, 0.08, -0.20), // lAnkle forward
          const Vec3(0.02, 0.08, 0.16), // rAnkle back
          const Vec3(-0.04, 0.01, -0.26), // lToe
          const Vec3(0.04, 0.12, 0.18), // rToe
        ],
        // B: right foot in front (alternates)
        [
          const Vec3(0.0, 1.72, 0.0),
          const Vec3(0.0, 1.52, 0.0),
          const Vec3(-0.24, 1.46, 0.0),
          const Vec3(0.24, 1.46, 0.0),
          const Vec3(-0.46, 1.30, 0.0),
          const Vec3(0.46, 1.30, 0.0),
          const Vec3(-0.60, 1.22, 0.0),
          const Vec3(0.60, 1.22, 0.0),
          const Vec3(0.0, 1.10, 0.0),
          const Vec3(0.0, 0.95, 0.0),
          const Vec3(-0.06, 0.92, 0.0),
          const Vec3(0.06, 0.92, 0.0),
          const Vec3(-0.06, 0.42, 0.10), // lKnee back
          const Vec3(0.06, 0.55, -0.12), // rKnee forward
          const Vec3(-0.02, 0.08, 0.16),
          const Vec3(0.02, 0.08, -0.20),
          const Vec3(-0.04, 0.12, 0.18),
          const Vec3(0.04, 0.01, -0.26),
        ],
      ];

  // ─── WEIGHT SHIFT ─────────────────────────────────────────────────────────
  static List<Pose> get _weightShiftPoses => [
        // A: weight on left leg (torso shifted left, right hip raised)
        [
          const Vec3(-0.06, 1.72, 0.0), // head shifted left
          const Vec3(-0.04, 1.52, 0.0),
          const Vec3(-0.25, 1.46, 0.0),
          const Vec3(0.17, 1.46, 0.0),
          const Vec3(-0.36, 1.22, 0.0),
          const Vec3(0.28, 1.22, 0.0),
          const Vec3(-0.34, 0.98, 0.0),
          const Vec3(0.26, 0.98, 0.0),
          const Vec3(-0.03, 1.10, 0.0),
          const Vec3(-0.02, 0.95, 0.0),
          const Vec3(-0.13, 0.94, 0.0), // lHip bearing weight (slightly lower)
          const Vec3(0.10, 0.96, 0.0), // rHip raised
          const Vec3(-0.14, 0.50, 0.0), // lKnee
          const Vec3(0.11, 0.52, 0.0), // rKnee (slight unload)
          const Vec3(-0.14, 0.07, 0.0),
          const Vec3(0.11, 0.07, 0.0),
          const Vec3(-0.20, 0.01, 0.0),
          const Vec3(0.17, 0.01, 0.0),
        ],
        // B: weight on right leg (mirror)
        [
          const Vec3(0.06, 1.72, 0.0),
          const Vec3(0.04, 1.52, 0.0),
          const Vec3(-0.17, 1.46, 0.0),
          const Vec3(0.25, 1.46, 0.0),
          const Vec3(-0.28, 1.22, 0.0),
          const Vec3(0.36, 1.22, 0.0),
          const Vec3(-0.26, 0.98, 0.0),
          const Vec3(0.34, 0.98, 0.0),
          const Vec3(0.03, 1.10, 0.0),
          const Vec3(0.02, 0.95, 0.0),
          const Vec3(-0.10, 0.96, 0.0),
          const Vec3(0.13, 0.94, 0.0),
          const Vec3(-0.11, 0.52, 0.0),
          const Vec3(0.14, 0.50, 0.0),
          const Vec3(-0.11, 0.07, 0.0),
          const Vec3(0.14, 0.07, 0.0),
          const Vec3(-0.17, 0.01, 0.0),
          const Vec3(0.20, 0.01, 0.0),
        ],
      ];

  // ─── FAST FEET — rapid alternating taps ──────────────────────────────────
  static List<Pose> get _fastFeetPoses => [
        // A: left foot slightly raised
        [
          const Vec3(0.0, 1.72, 0.0),
          const Vec3(0.0, 1.52, 0.0),
          const Vec3(-0.20, 1.45, 0.0),
          const Vec3(0.20, 1.45, 0.0),
          const Vec3(-0.28, 1.22, 0.0),
          const Vec3(0.28, 1.22, 0.0),
          const Vec3(-0.26, 0.98, 0.0),
          const Vec3(0.26, 0.98, 0.0),
          const Vec3(0.0, 1.10, 0.0),
          const Vec3(0.0, 0.95, 0.0),
          const Vec3(-0.12, 0.92, 0.0),
          const Vec3(0.12, 0.92, 0.0),
          const Vec3(-0.13, 0.52, 0.0), // lKnee slightly flexed
          const Vec3(0.13, 0.50, 0.0),
          const Vec3(-0.13, 0.16, 0.0), // lAnkle raised 9cm
          const Vec3(0.13, 0.07, 0.0),
          const Vec3(-0.19, 0.10, 0.0),
          const Vec3(0.19, 0.01, 0.0),
        ],
        // B: right foot slightly raised (mirror)
        [
          const Vec3(0.0, 1.72, 0.0),
          const Vec3(0.0, 1.52, 0.0),
          const Vec3(-0.20, 1.45, 0.0),
          const Vec3(0.20, 1.45, 0.0),
          const Vec3(-0.28, 1.22, 0.0),
          const Vec3(0.28, 1.22, 0.0),
          const Vec3(-0.26, 0.98, 0.0),
          const Vec3(0.26, 0.98, 0.0),
          const Vec3(0.0, 1.10, 0.0),
          const Vec3(0.0, 0.95, 0.0),
          const Vec3(-0.12, 0.92, 0.0),
          const Vec3(0.12, 0.92, 0.0),
          const Vec3(-0.13, 0.50, 0.0),
          const Vec3(0.13, 0.52, 0.0), // rKnee flexed
          const Vec3(-0.13, 0.07, 0.0),
          const Vec3(0.13, 0.16, 0.0), // rAnkle raised
          const Vec3(-0.19, 0.01, 0.0),
          const Vec3(0.19, 0.10, 0.0),
        ],
      ];

  // ─── POSTURE CORRECTION — wall stand, chin tuck ──────────────────────────
  static List<Pose> get _posturePoses => [
        // A: forward head posture (before)
        [
          const Vec3(0.04, 1.70, 0.08), // head forward + slightly down
          const Vec3(0.02, 1.50, 0.04), // neck
          const Vec3(-0.21, 1.44, 0.02),
          const Vec3(0.21, 1.44, 0.02),
          const Vec3(-0.30, 1.20, 0.0),
          const Vec3(0.30, 1.20, 0.0),
          const Vec3(-0.28, 0.96, 0.0),
          const Vec3(0.28, 0.96, 0.0),
          const Vec3(0.02, 1.08, 0.04), // spine slight forward
          const Vec3(0.0, 0.93, 0.0),
          const Vec3(-0.11, 0.90, 0.0),
          const Vec3(0.11, 0.90, 0.0),
          const Vec3(-0.12, 0.48, 0.0),
          const Vec3(0.12, 0.48, 0.0),
          const Vec3(-0.12, 0.06, 0.0),
          const Vec3(0.12, 0.06, 0.0),
          const Vec3(-0.18, 0.0, 0.0),
          const Vec3(0.18, 0.0, 0.0),
        ],
        // B: corrected posture — tall, chin tucked, shoulders back
        [
          const Vec3(0.0, 1.76, -0.02), // head back and UP
          const Vec3(0.0, 1.55, -0.01), // neck elongated
          const Vec3(-0.22, 1.48, -0.02), // shoulders back
          const Vec3(0.22, 1.48, -0.02),
          const Vec3(-0.31, 1.24, 0.0),
          const Vec3(0.31, 1.24, 0.0),
          const Vec3(-0.29, 0.99, 0.0),
          const Vec3(0.29, 0.99, 0.0),
          const Vec3(0.0, 1.14, -0.01), // spine tall
          const Vec3(0.0, 0.98, 0.0),
          const Vec3(-0.11, 0.95, 0.0),
          const Vec3(0.11, 0.95, 0.0),
          const Vec3(-0.12, 0.52, 0.0),
          const Vec3(0.12, 0.52, 0.0),
          const Vec3(-0.12, 0.08, 0.0),
          const Vec3(0.12, 0.08, 0.0),
          const Vec3(-0.18, 0.01, 0.0),
          const Vec3(0.18, 0.01, 0.0),
        ],
      ];

  // ─── CALF RAISES — rising onto toes ──────────────────────────────────────
  static List<Pose> get _calfRaisePoses => [
        // A: flat foot
        standPose,
        // B: full plantar flexion (on toes)
        [
          const Vec3(0.0, 1.80, 0.0), // whole body rises ~8cm
          const Vec3(0.0, 1.60, 0.0),
          const Vec3(-0.21, 1.53, 0.0),
          const Vec3(0.21, 1.53, 0.0),
          const Vec3(
              -0.30, 1.28, 0.05), // arms slightly forward (touching wall)
          const Vec3(0.30, 1.28, 0.05),
          const Vec3(-0.28, 1.04, 0.08),
          const Vec3(0.28, 1.04, 0.08),
          const Vec3(0.0, 1.18, 0.0),
          const Vec3(0.0, 1.03, 0.0),
          const Vec3(-0.11, 1.00, 0.0),
          const Vec3(0.11, 1.00, 0.0),
          const Vec3(-0.12, 0.58, 0.0),
          const Vec3(0.12, 0.58, 0.0),
          const Vec3(-0.12, 0.15, -0.04), // ankles raised
          const Vec3(0.12, 0.15, -0.04),
          const Vec3(-0.14, 0.08, 0.02), // toes on ground
          const Vec3(0.14, 0.08, 0.02),
        ],
      ];

  // ─── HIP FLEXOR STRETCH — lunge ──────────────────────────────────────────
  static List<Pose> get _hipStretchPoses => [
        // A: entry lunge
        [
          const Vec3(0.0, 1.50, -0.04), // head (torso upright)
          const Vec3(0.0, 1.32, -0.02), // neck
          const Vec3(-0.20, 1.26, -0.02), // lShoulder
          const Vec3(0.20, 1.26, -0.02), // rShoulder
          const Vec3(-0.28, 1.02, 0.0), // lElbow (hands on knee)
          const Vec3(0.28, 1.02, 0.0), // rElbow
          const Vec3(-0.22, 0.78, 0.02), // lWrist
          const Vec3(0.22, 0.78, 0.02), // rWrist
          const Vec3(0.0, 0.94, -0.02), // spine
          const Vec3(0.0, 0.76, 0.0), // hips low
          const Vec3(-0.16, 0.74, -0.12), // lHip forward
          const Vec3(0.14, 0.74, 0.16), // rHip back
          const Vec3(-0.18, 0.38, -0.14), // lKnee forward (90°)
          const Vec3(0.14, 0.38, 0.18), // rKnee on ground
          const Vec3(-0.18, 0.06, -0.20), // lAnkle forward
          const Vec3(0.14, 0.04, 0.24), // rAnkle ground
          const Vec3(-0.24, 0.0, -0.26), // lToe
          const Vec3(0.16, 0.0, 0.26), // rToe
        ],
        // B: deepen stretch — hip pressed further forward
        [
          const Vec3(0.02, 1.48, -0.06),
          const Vec3(0.01, 1.30, -0.04),
          const Vec3(-0.20, 1.24, -0.04),
          const Vec3(0.20, 1.24, -0.04),
          const Vec3(-0.28, 1.00, -0.02),
          const Vec3(0.28, 1.00, -0.02),
          const Vec3(-0.22, 0.76, 0.0),
          const Vec3(0.22, 0.76, 0.0),
          const Vec3(0.01, 0.92, -0.04),
          const Vec3(0.01, 0.73, 0.02), // hips even lower
          const Vec3(-0.16, 0.71, -0.14),
          const Vec3(0.14, 0.71, 0.20), // rHip further back
          const Vec3(-0.18, 0.36, -0.14),
          const Vec3(0.14, 0.34, 0.22),
          const Vec3(-0.18, 0.05, -0.20),
          const Vec3(0.14, 0.03, 0.26),
          const Vec3(-0.24, 0.0, -0.26),
          const Vec3(0.16, 0.0, 0.28),
        ],
      ];

  // ─── CHEST OPENER — doorway stretch ──────────────────────────────────────
  static List<Pose> get _chestOpenerPoses => [
        // A: hands on door frame, ready
        [
          const Vec3(0.0, 1.72, -0.04),
          const Vec3(0.0, 1.52, -0.02),
          const Vec3(-0.22, 1.46, 0.0),
          const Vec3(0.22, 1.46, 0.0),
          const Vec3(-0.38, 1.46, 0.02), // arms out to sides (at frame)
          const Vec3(0.38, 1.46, 0.02),
          const Vec3(-0.42, 1.32, 0.04), // wrists on frame
          const Vec3(0.42, 1.32, 0.04),
          const Vec3(0.0, 1.10, -0.02),
          const Vec3(0.0, 0.95, 0.0),
          const Vec3(-0.11, 0.92, 0.0),
          const Vec3(0.11, 0.92, 0.0),
          const Vec3(-0.13, 0.50, 0.0),
          const Vec3(0.13, 0.50, 0.0),
          const Vec3(-0.12, 0.08, -0.04), // one foot forward
          const Vec3(0.12, 0.08, 0.0),
          const Vec3(-0.18, 0.01, -0.10),
          const Vec3(0.18, 0.01, 0.0),
        ],
        // B: lean through doorway — chest presses forward
        [
          const Vec3(0.04, 1.70, -0.12), // head forward
          const Vec3(0.02, 1.50, -0.08),
          const Vec3(-0.22, 1.46, 0.02), // shoulders stay back (chest opens)
          const Vec3(0.22, 1.46, 0.02),
          const Vec3(-0.38, 1.48, 0.04), // elbows planted on frame
          const Vec3(0.38, 1.48, 0.04),
          const Vec3(-0.42, 1.34, 0.06),
          const Vec3(0.42, 1.34, 0.06),
          const Vec3(0.02, 1.08, -0.06), // spine forward
          const Vec3(0.01, 0.93, -0.02),
          const Vec3(-0.11, 0.90, -0.02),
          const Vec3(0.11, 0.90, -0.02),
          const Vec3(-0.13, 0.48, -0.02),
          const Vec3(0.13, 0.48, -0.02),
          const Vec3(-0.12, 0.07, -0.08),
          const Vec3(0.12, 0.07, 0.0),
          const Vec3(-0.18, 0.01, -0.14),
          const Vec3(0.18, 0.01, 0.0),
        ],
      ];
}
