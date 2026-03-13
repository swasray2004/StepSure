import 'dart:math' as math;
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// 3D MATH PRIMITIVES
// ═══════════════════════════════════════════════════════════════════════════════

class Vec3 {
  final double x, y, z;
  const Vec3(this.x, this.y, this.z);

  Vec3 operator +(Vec3 o) => Vec3(x + o.x, y + o.y, z + o.z);
  Vec3 operator -(Vec3 o) => Vec3(x - o.x, y - o.y, z - o.z);
  Vec3 operator *(double s) => Vec3(x * s, y * s, z * s);

  Vec3 lerp(Vec3 o, double t) =>
      Vec3(x + (o.x - x) * t, y + (o.y - y) * t, z + (o.z - z) * t);

  double get length => math.sqrt(x * x + y * y + z * z);
  Vec3 get normalized {
    final l = length;
    return l == 0 ? const Vec3(0, 0, 0) : Vec3(x / l, y / l, z / l);
  }

  double dot(Vec3 o) => x * o.x + y * o.y + z * o.z;
  Vec3 cross(Vec3 o) => Vec3(
        y * o.z - z * o.y,
        z * o.x - x * o.z,
        x * o.y - y * o.x,
      );

  /// Rotate around Y axis (left/right spin)
  Vec3 rotateY(double angle) {
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    return Vec3(x * cos + z * sin, y, -x * sin + z * cos);
  }

  /// Rotate around X axis (forward/back tilt)
  Vec3 rotateX(double angle) {
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    return Vec3(x, y * cos - z * sin, y * sin + z * cos);
  }

  @override
  String toString() => 'Vec3($x, $y, $z)';
}

// ═══════════════════════════════════════════════════════════════════════════════
// PERSPECTIVE CAMERA
// ═══════════════════════════════════════════════════════════════════════════════

class Camera3D {
  final double fov; // field of view distance
  final double cx, cy; // canvas centre
  final double scale; // world scale
  final double rotY; // camera rotation around Y (avatar spin)

  const Camera3D({
    required this.fov,
    required this.cx,
    required this.cy,
    required this.scale,
    this.rotY = 0,
  });

  /// Projects a 3D world point to 2D screen coordinates + depth factor
  ProjectedPoint project(Vec3 p) {
    // Apply camera Y rotation
    final r = p.rotateY(rotY);
    // Perspective divide
    final depth = r.z + fov;
    final factor = depth > 0 ? fov / depth : 0;
    return ProjectedPoint(
      x: cx + r.x * scale * factor,
      y: cy - r.y * scale * factor,
      depth: r.z,
      depthFactor: factor.clamp(0.3, 1.5) as double,
    );
  }
}

class ProjectedPoint {
  final double x, y, depth, depthFactor;
  const ProjectedPoint({
    required this.x,
    required this.y,
    required this.depth,
    required this.depthFactor,
  });

  Offset get offset => Offset(x, y);
}

// ═══════════════════════════════════════════════════════════════════════════════
// SKELETON JOINT INDICES — standard humanoid rig
// ═══════════════════════════════════════════════════════════════════════════════
class J {
  static const int head = 0;
  static const int neck = 1;
  static const int lShoulder = 2;
  static const int rShoulder = 3;
  static const int lElbow = 4;
  static const int rElbow = 5;
  static const int lWrist = 6;
  static const int rWrist = 7;
  static const int spine = 8;
  static const int hips = 9;
  static const int lHip = 10;
  static const int rHip = 11;
  static const int lKnee = 12;
  static const int rKnee = 13;
  static const int lAnkle = 14;
  static const int rAnkle = 15;
  static const int lToe = 16;
  static const int rToe = 17;
  static const int count = 18;
}

// ═══════════════════════════════════════════════════════════════════════════════
// BONE CONNECTIONS — pairs of joint indices
// ═══════════════════════════════════════════════════════════════════════════════
const List<List<int>> kBones = [
  [J.head, J.neck],
  [J.neck, J.lShoulder],
  [J.neck, J.rShoulder],
  [J.neck, J.spine],
  [J.lShoulder, J.lElbow],
  [J.rShoulder, J.rElbow],
  [J.lElbow, J.lWrist],
  [J.rElbow, J.rWrist],
  [J.spine, J.hips],
  [J.hips, J.lHip],
  [J.hips, J.rHip],
  [J.lHip, J.lKnee],
  [J.rHip, J.rKnee],
  [J.lKnee, J.lAnkle],
  [J.rKnee, J.rAnkle],
  [J.lAnkle, J.lToe],
  [J.rAnkle, J.rToe],
];

// ═══════════════════════════════════════════════════════════════════════════════
// BONE THICKNESS TABLE — radius at each joint
// ═══════════════════════════════════════════════════════════════════════════════
const Map<String, double> kBoneRadius = {
  '0-1': 7.0, // head-neck
  '1-2': 5.0, // neck-lShoulder
  '1-3': 5.0, // neck-rShoulder
  '1-8': 6.0, // neck-spine
  '2-4': 5.5, // lShoulder-lElbow
  '3-5': 5.5, // rShoulder-rElbow
  '4-6': 4.5, // lElbow-lWrist
  '5-7': 4.5, // rElbow-rWrist
  '8-9': 7.0, // spine-hips
  '9-10': 6.5, // hips-lHip
  '9-11': 6.5, // hips-rHip
  '10-12': 7.0, // lHip-lKnee  (thigh)
  '11-13': 7.0, // rHip-rKnee
  '12-14': 5.5, // lKnee-lAnkle (shin)
  '13-15': 5.5, // rKnee-rAnkle
  '14-16': 3.5, // lAnkle-lToe
  '15-17': 3.5, // rAnkle-rToe
};

double boneRadius(int a, int b) {
  final key1 = '$a-$b';
  final key2 = '$b-$a';
  return kBoneRadius[key1] ?? kBoneRadius[key2] ?? 5.0;
}

// ═══════════════════════════════════════════════════════════════════════════════
// POSE — array of 18 Vec3 joint positions in world space
// Convention: Y up, X right, Z toward camera, units = cm-ish
// ═══════════════════════════════════════════════════════════════════════════════
typedef Pose = List<Vec3>;

/// Linearly interpolate between two poses
Pose lerpPose(Pose a, Pose b, double t) {
  return List.generate(J.count, (i) => a[i].lerp(b[i], t));
}

// ─── NEUTRAL T-POSE (reference) ───────────────────────────────────────────────
Pose get neutralPose => [
      const Vec3(0.0, 1.70, 0), // 0  head
      const Vec3(0.0, 1.50, 0), // 1  neck
      const Vec3(-0.20, 1.45, 0), // 2  lShoulder
      const Vec3(0.20, 1.45, 0), // 3  rShoulder
      const Vec3(-0.40, 1.45, 0), // 4  lElbow
      const Vec3(0.40, 1.45, 0), // 5  rElbow
      const Vec3(-0.60, 1.45, 0), // 6  lWrist
      const Vec3(0.60, 1.45, 0), // 7  rWrist
      const Vec3(0.0, 1.10, 0), // 8  spine
      const Vec3(0.0, 0.95, 0), // 9  hips
      const Vec3(-0.11, 0.92, 0), // 10 lHip
      const Vec3(0.11, 0.92, 0), // 11 rHip
      const Vec3(-0.12, 0.50, 0), // 12 lKnee
      const Vec3(0.12, 0.50, 0), // 13 rKnee
      const Vec3(-0.12, 0.08, 0), // 14 lAnkle
      const Vec3(0.12, 0.08, 0), // 15 rAnkle
      const Vec3(-0.18, 0.02, 0), // 16 lToe
      const Vec3(0.18, 0.02, 0), // 17 rToe
    ];

// ─── STAND POSE ───────────────────────────────────────────────────────────────
Pose get standPose => [
      const Vec3(0.0, 1.72, 0), // head
      const Vec3(0.0, 1.52, 0), // neck
      const Vec3(-0.21, 1.46, 0), // lShoulder
      const Vec3(0.21, 1.46, 0), // rShoulder
      const Vec3(-0.32, 1.22, 0), // lElbow  (arms natural down)
      const Vec3(0.32, 1.22, 0), // rElbow
      const Vec3(-0.30, 0.98, 0), // lWrist
      const Vec3(0.30, 0.98, 0), // rWrist
      const Vec3(0.0, 1.12, 0), // spine
      const Vec3(0.0, 0.96, 0), // hips
      const Vec3(-0.11, 0.93, 0), // lHip
      const Vec3(0.11, 0.93, 0), // rHip
      const Vec3(-0.12, 0.50, 0), // lKnee
      const Vec3(0.12, 0.50, 0), // rKnee
      const Vec3(-0.12, 0.07, 0), // lAnkle
      const Vec3(0.12, 0.07, 0), // rAnkle
      const Vec3(-0.18, 0.01, 0), // lToe
      const Vec3(0.18, 0.01, 0), // rToe
    ];
