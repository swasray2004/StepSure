import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'skeleton_3d_math.dart';
import 'exercise_poses.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// SKELETON 3D AVATAR WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

class SkeletalAvatar3D extends StatefulWidget {
  final String exerciseId;
  final bool isActive;
  final double size;
  final bool orbitCamera;
  final double? externalT;

  const SkeletalAvatar3D({
    super.key,
    required this.exerciseId,
    this.isActive = true,
    this.size = 320,
    this.orbitCamera = true,
    this.externalT,
  });

  @override
  State<SkeletalAvatar3D> createState() => _SkeletalAvatar3DState();
}

class _SkeletalAvatar3DState extends State<SkeletalAvatar3D>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  double _camAngle = 0.35;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: _durationFor(widget.exerciseId),
    );
    if (widget.isActive && widget.externalT == null) {
      _ctrl.repeat(reverse: true);
    }
    _ctrl.addListener(() {
      if (widget.orbitCamera && widget.isActive) {
        setState(() {
          _camAngle = 0.35 + math.sin(_ctrl.value * math.pi * 2) * 0.26;
        });
      }
    });
  }

  @override
  void didUpdateWidget(SkeletalAvatar3D old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !_ctrl.isAnimating && widget.externalT == null) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.isActive) {
      _ctrl.stop();
    }
  }

  Duration _durationFor(String id) {
    switch (id) {
      case 'fast_feet':
        return const Duration(milliseconds: 400);
      case 'metronome_walking':
        return const Duration(milliseconds: 800);
      case 'step_length_training':
      case 'alternating_step_drill':
      case 'tandem_walking':
        return const Duration(milliseconds: 1000);
      case 'exaggerated_marching':
        return const Duration(milliseconds: 900);
      case 'single_leg_balance':
      case 'weight_shift':
        return const Duration(milliseconds: 2200);
      case 'posture_correction':
        return const Duration(milliseconds: 2500);
      case 'calf_raises':
      case 'knee_stability':
      case 'terminal_knee_extension':
        return const Duration(milliseconds: 1600);
      case 'hip_flexor_stretch':
      case 'chest_opener':
        return const Duration(milliseconds: 3000);
      default:
        return const Duration(milliseconds: 1400);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = widget.externalT ?? _ctrl.value;
        final poses = ExercisePoses.forExercise(widget.exerciseId);

        final Pose currentPose;
        if (poses.length == 1) {
          currentPose = poses[0];
        } else {
          final smoothT = _smoothStep(t);
          currentPose = lerpPose(poses[0], poses[1], smoothT);
        }

        // Precise framing calculation:
        // Pose Y range: toes ≈ 0.01 (bottom), head ≈ 1.72+headRadius (top).
        // Camera projection: screenY = cy - worldY * scale * depthFactor
        // At depth=0, depthFactor≈1. Head radius adds ~14px.
        //
        // We want:
        //   headTop  → padding (e.g. 18px from top)
        //   toeBot   → size - padding (e.g. 14px from bottom)
        //
        // headTopScreen  = cy - 1.82 * scale = topPad       → cy = topPad + 1.82*scale
        // toeBottomScreen= cy - 0.01 * scale = size-botPad  → cy = size - botPad + 0.01*scale
        //
        // Solving: topPad + 1.82*s = size - botPad + 0.01*s
        //          1.81*s = size - botPad - topPad
        //          s = (size - botPad - topPad) / 1.81
        //
        const double topPad = 20.0;
        const double botPad = 16.0;
        final double scale = (widget.size - topPad - botPad) / 1.81;
        final double cy = topPad + 1.82 * scale;

        final cam = Camera3D(
          fov: 3.0,
          cx: widget.size / 2,
          cy: cy,
          scale: scale,
          rotY: _camAngle,
        );

        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _SkeletonPainter3D(
            pose: currentPose,
            camera: cam,
            isPaused: !widget.isActive,
          ),
        );
      },
    );
  }

  double _smoothStep(double t) => t * t * (3 - 2 * t);
}

// ═══════════════════════════════════════════════════════════════════════════════
// 3D SKELETON PAINTER
// ═══════════════════════════════════════════════════════════════════════════════
class _SkeletonPainter3D extends CustomPainter {
  final Pose pose;
  final Camera3D camera;
  final bool isPaused;

  static const Vec3 _lightDir = Vec3(-0.4, 0.7, 0.6);

  _SkeletonPainter3D({
    required this.pose,
    required this.camera,
    required this.isPaused,
  });

  static const Color _boneBase = Color(0xFF3AABAB);
  static const Color _boneDark = Color(0xFF1F7A7A);
  static const Color _boneLight = Color(0xFF8DD8D8);
  static const Color _boneHighlit = Color(0xFFBBEEEE);
  static const Color _jointBase = Color(0xFF2D9090);
  static const Color _jointLight = Color(0xFF7DD4D4);
  static const Color _headColor = Color(0xFF1F7A7A);
  static const Color _headHighlit = Color(0xFF5BBFBF);
  static const Color _shadowColor = Color(0x553AABAB);

  @override
  void paint(Canvas canvas, Size size) {
    final projected = pose.map((j) => camera.project(j)).toList();

    _drawGroundShadow(canvas, size, projected);

    final sortedBones = _sortedBones(projected);
    for (final bone in sortedBones) {
      _drawVolumeBone(canvas, bone[0], bone[1], projected);
    }

    _drawJoints(canvas, projected);
    _drawHead(canvas, projected[J.head], projected[J.neck]);
    _drawSpineHighlight(canvas, projected);
  }

  void _drawGroundShadow(Canvas canvas, Size size, List<ProjectedPoint> pts) {
    final lFoot = pts[J.lToe];
    final rFoot = pts[J.rToe];
    final midX = (lFoot.x + rFoot.x) / 2;
    final midY = (lFoot.y + rFoot.y) / 2 + 4;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(midX, midY), width: 70, height: 12),
      Paint()
        ..color = _shadowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  List<List<int>> _sortedBones(List<ProjectedPoint> pts) {
    return List.of(kBones)
      ..sort((a, b) {
        final depthA = (pts[a[0]].depth + pts[a[1]].depth) / 2;
        final depthB = (pts[b[0]].depth + pts[b[1]].depth) / 2;
        return depthA.compareTo(depthB);
      });
  }

  void _drawVolumeBone(
    Canvas canvas,
    int idxA,
    int idxB,
    List<ProjectedPoint> pts,
  ) {
    final pA = pts[idxA];
    final pB = pts[idxB];
    final offA = pA.offset;
    final offB = pB.offset;

    final worldA = pose[idxA];
    final worldB = pose[idxB];
    final boneVec = (worldB - worldA).normalized;

    final avgDepth = (pA.depth + pB.depth) / 2;
    final depthDarken = ((avgDepth + 1.0) * 0.12).clamp(0.0, 0.5);

    final lightDot = boneVec.dot(_lightDir.normalized).clamp(-1.0, 1.0);
    final lightFactor = (lightDot * 0.5 + 0.5).clamp(0.2, 1.0);

    final baseRadius = boneRadius(idxA, idxB);
    final rA = baseRadius * pA.depthFactor.clamp(0.5, 1.4);
    final rB = baseRadius * pB.depthFactor.clamp(0.5, 1.4);
    final avgRadius = (rA + rB) / 2;

    final dx = offB.dx - offA.dx;
    final dy = offB.dy - offA.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 0.5) return;

    final perpX = -dy / len;
    final perpY = dx / len;

    final c1 = Offset(offA.dx + perpX * rA, offA.dy + perpY * rA);
    final c2 = Offset(offA.dx - perpX * rA, offA.dy - perpY * rA);
    final c3 = Offset(offB.dx - perpX * rB, offB.dy - perpY * rB);
    final c4 = Offset(offB.dx + perpX * rB, offB.dy + perpY * rB);

    final path = Path()
      ..moveTo(c1.dx, c1.dy)
      ..lineTo(c4.dx, c4.dy)
      ..lineTo(c3.dx, c3.dy)
      ..lineTo(c2.dx, c2.dy)
      ..close();

    final baseColor = Color.lerp(_boneDark, _boneBase, lightFactor)!;
    final shadedColor = Color.lerp(baseColor, Colors.black, depthDarken)!;

    final perpOff = Offset(perpX * avgRadius, perpY * avgRadius);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Color.lerp(shadedColor, _boneHighlit, 0.4)!,
            shadedColor,
            Color.lerp(shadedColor, _boneDark, 0.5)!,
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment(perpX, perpY),
          end: Alignment(-perpX, -perpY),
        ).createShader(Rect.fromPoints(offA - perpOff, offA + perpOff)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = _boneDark.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    canvas.drawLine(
      c1,
      c4,
      Paint()
        ..color = _boneHighlit.withValues(alpha: 0.35 * lightFactor)
        ..strokeWidth = avgRadius * 0.35
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawJoints(Canvas canvas, List<ProjectedPoint> pts) {
    const skipJoints = {J.head};
    for (int i = 0; i < J.count; i++) {
      if (skipJoints.contains(i)) continue;
      _drawJointSphere(canvas, pts[i], _jointRadiusFor(i));
    }
  }

  double _jointRadiusFor(int idx) {
    switch (idx) {
      case J.neck:
        return 5.5;
      case J.lShoulder:
      case J.rShoulder:
        return 6.5;
      case J.lElbow:
      case J.rElbow:
        return 5.0;
      case J.lWrist:
      case J.rWrist:
        return 4.0;
      case J.hips:
        return 7.0;
      case J.spine:
        return 5.5;
      case J.lHip:
      case J.rHip:
        return 6.0;
      case J.lKnee:
      case J.rKnee:
        return 6.5;
      case J.lAnkle:
      case J.rAnkle:
        return 5.0;
      default:
        return 3.5;
    }
  }

  void _drawJointSphere(Canvas canvas, ProjectedPoint p, double baseRadius) {
    final r = (baseRadius * p.depthFactor).clamp(2.0, baseRadius * 1.5);
    final c = p.offset;

    final depthDarken = ((p.depth + 1.0) * 0.1).clamp(0.0, 0.45);
    final baseColor = Color.lerp(_jointBase, Colors.black, depthDarken)!;

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          colors: [
            Color.lerp(baseColor, _jointLight, 0.7)!,
            baseColor,
            Color.lerp(baseColor, _boneDark, 0.6)!,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    canvas.drawCircle(
      Offset(c.dx - r * 0.28, c.dy - r * 0.32),
      r * 0.25,
      Paint()..color = _boneHighlit.withValues(alpha: 0.7),
    );

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = _boneDark.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  void _drawHead(Canvas canvas, ProjectedPoint headPt, ProjectedPoint neckPt) {
    final r = (14.0 * headPt.depthFactor).clamp(8.0, 20.0);
    final c = headPt.offset;
    final depthDarken = ((headPt.depth + 1.0) * 0.1).clamp(0.0, 0.45);
    final baseColor = Color.lerp(_headColor, Colors.black, depthDarken)!;

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [
            Color.lerp(baseColor, _headHighlit, 0.6)!,
            baseColor,
            Color.lerp(baseColor, _boneDark, 0.7)!,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    canvas.drawCircle(
      Offset(c.dx - r * 0.3, c.dy - r * 0.36),
      r * 0.28,
      Paint()..color = _boneHighlit.withValues(alpha: 0.6),
    );

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = _boneDark.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    final neckDir = Offset(
      c.dx - neckPt.offset.dx,
      c.dy - neckPt.offset.dy,
    );
    final faceX =
        c.dx - neckDir.dx * 0.3 + (camera.rotY > 0 ? r * 0.25 : -r * 0.25);
    final faceY = c.dy + r * 0.1;

    canvas.drawCircle(
      Offset(faceX - r * 0.16, faceY - r * 0.05),
      r * 0.08,
      Paint()..color = _boneHighlit.withValues(alpha: 0.55),
    );
    canvas.drawCircle(
      Offset(faceX + r * 0.16, faceY - r * 0.05),
      r * 0.08,
      Paint()..color = _boneHighlit.withValues(alpha: 0.55),
    );
  }

  void _drawSpineHighlight(Canvas canvas, List<ProjectedPoint> pts) {
    final spine = pts[J.spine].offset;
    final neck = pts[J.neck].offset;
    final hips = pts[J.hips].offset;

    canvas.drawLine(
      neck,
      spine,
      Paint()
        ..color = _boneHighlit.withValues(alpha: 0.10)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      spine,
      hips,
      Paint()
        ..color = _boneHighlit.withValues(alpha: 0.10)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SkeletonPainter3D old) =>
      old.pose != pose ||
      old.camera.rotY != camera.rotY ||
      old.isPaused != isPaused;
}

// ═══════════════════════════════════════════════════════════════════════════════
// AVATAR ANIMATION CARD — self-contained card used in ExerciseModeScreen
// Drop-in for _AnimationCard. Handles its own height + figure framing.
// ═══════════════════════════════════════════════════════════════════════════════
class AvatarAnimationCard extends StatelessWidget {
  final String exerciseId;
  final String exerciseEmoji;
  final double setProgress;
  final bool isActive;
  final Animation<double> pulseAnim;

  const AvatarAnimationCard({
    super.key,
    required this.exerciseId,
    required this.exerciseEmoji,
    required this.setProgress,
    required this.isActive,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF3AABAB);
    const tealDk = Color(0xFF1F7A7A);
    const surface = Color(0xFF153535);

    // Card height 290px comfortably contains the 270px avatar canvas.
    return Container(
      width: double.infinity,
      height: 290,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: teal.withValues(alpha: 0.2)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background grid dots
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CustomPaint(painter: _GridDots()),
            ),
          ),

          // Radial glow
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [teal.withValues(alpha: 0.09), Colors.transparent],
              ),
            ),
          ),

          // Floor disc — anchored near bottom of card
          Positioned(
            bottom: 14,
            child: Container(
              width: 100,
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: RadialGradient(
                  colors: [teal.withValues(alpha: 0.25), Colors.transparent],
                ),
              ),
            ),
          ),

          // Progress arc — sized to card
          SizedBox(
            width: 268,
            height: 268,
            child: CircularProgressIndicator(
              value: setProgress,
              backgroundColor: tealDk.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(teal.withValues(alpha: 0.28)),
              strokeWidth: 5,
              strokeCap: StrokeCap.round,
            ),
          ),

          // 3D SKELETAL AVATAR
          // Size matches card height so figure has full vertical room.
          ScaleTransition(
            scale: isActive ? pulseAnim : const AlwaysStoppedAnimation(1.0),
            child: ClipRect(
              child: SkeletalAvatar3D(
                exerciseId: exerciseId,
                isActive: isActive,
                size: 270,
                orbitCamera: true,
              ),
            ),
          ),

          // Exercise emoji badge
          Positioned(
            top: 12,
            right: 14,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1C4040),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: teal.withValues(alpha: 0.25)),
              ),
              child: Text(exerciseEmoji, style: const TextStyle(fontSize: 20)),
            ),
          ),

          // "3D" label badge
          Positioned(
            top: 12,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tealDk.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.view_in_ar_rounded,
                      color: Color(0xFF7DD4D4), size: 12),
                  SizedBox(width: 4),
                  Text('3D',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: Color(0xFF7DD4D4),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      )),
                ],
              ),
            ),
          ),

          // Pause overlay
          if (!isActive)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child:
                    Icon(Icons.pause_rounded, color: Colors.white54, size: 56),
              ),
            ),
        ],
      ),
    );
  }
}

class _GridDots extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFF3AABAB).withValues(alpha: 0.05);
    for (double x = 0; x < size.width; x += 22) {
      for (double y = 0; y < size.height; y += 22) {
        canvas.drawCircle(Offset(x, y), 1.5, p);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// RECOMMENDATION SCREEN PREVIEW AVATAR — smaller, simpler for list cards
// ═══════════════════════════════════════════════════════════════════════════════
class AvatarPreviewWidget extends StatelessWidget {
  final String exerciseId;
  final double size;

  const AvatarPreviewWidget({
    super.key,
    required this.exerciseId,
    this.size = 90,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFE0F5F5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: SkeletalAvatar3D(
        exerciseId: exerciseId,
        isActive: true,
        size: size,
        orbitCamera: false,
      ),
    );
  }
}
