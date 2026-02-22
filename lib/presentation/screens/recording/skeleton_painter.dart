import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// ML Kit returns landmark (x, y) in pixel coords of the **rotated** image.
/// For a 90° sensor with raw frame 1280×720:
///   - ML Kit internally rotates the image → effective size becomes 720×1280
///   - landmarks are in [0..720] × [0..1280] (portrait space already)
/// So we just scale those to screen size — NO manual rotation needed.
///
/// For front camera, ML Kit does NOT mirror, but CameraPreview does,
/// so we mirror x ourselves.
Offset _landmarkToScreen({
  required double lx,
  required double ly,
  required Size effectiveImage, // after rotation: (rawH, rawW) for 90/270 deg
  required Size screen,
  required bool isFront,
}) {
  double x = lx;
  double y = ly;

  if (isFront) {
    x = effectiveImage.width - x;
  }

  return Offset(
    x / effectiveImage.width * screen.width,
    y / effectiveImage.height * screen.height,
  );
}

class SkeletonPainter extends CustomPainter {
  final Pose pose;
  final Size imageSize; // raw CameraImage size (UNROTATED, e.g. 1280×720)
  final int sensorOrientation; // degrees: 0, 90, 180, 270
  final bool isFrontCamera;

  SkeletonPainter({
    required this.pose,
    required this.imageSize,
    required this.sensorOrientation,
    required this.isFrontCamera,
  });

  static const double _confidenceThreshold = 0.40;

  final _bonePaint = Paint()
    ..strokeWidth = 3.0
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  final _jointPaint = Paint()..style = PaintingStyle.fill;

  final _borderPaint = Paint()
    ..color = Colors.white.withOpacity(0.80)
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;

  static const _connections = <(PoseLandmarkType, PoseLandmarkType)>[
    (PoseLandmarkType.leftEar, PoseLandmarkType.leftEye),
    (PoseLandmarkType.leftEye, PoseLandmarkType.nose),
    (PoseLandmarkType.nose, PoseLandmarkType.rightEye),
    (PoseLandmarkType.rightEye, PoseLandmarkType.rightEar),
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder),
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow),
    (PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist),
    (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow),
    (PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist),
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip),
    (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip),
    (PoseLandmarkType.leftHip, PoseLandmarkType.rightHip),
    (PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee),
    (PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle),
    (PoseLandmarkType.leftAnkle, PoseLandmarkType.leftHeel),
    (PoseLandmarkType.leftHeel, PoseLandmarkType.leftFootIndex),
    (PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee),
    (PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle),
    (PoseLandmarkType.rightAnkle, PoseLandmarkType.rightHeel),
    (PoseLandmarkType.rightHeel, PoseLandmarkType.rightFootIndex),
  ];

  /// The effective (post-rotation) image size that ML Kit outputs landmarks in.
  Size get _effectiveSize {
    if (sensorOrientation == 90 || sensorOrientation == 270) {
      // Sensor was landscape, ML Kit rotated it to portrait
      // raw: width=1280, height=720 → effective: width=720, height=1280
      return Size(imageSize.height, imageSize.width);
    }
    return imageSize;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (pose.landmarks.isEmpty) return;

    final effective = _effectiveSize;
    final pts = <PoseLandmarkType, Offset>{};
    final conf = <PoseLandmarkType, double>{};

    for (final e in pose.landmarks.entries) {
      final lm = e.value;
      conf[e.key] = lm.likelihood;
      pts[e.key] = _landmarkToScreen(
        lx: lm.x,
        ly: lm.y,
        effectiveImage: effective,
        screen: size,
        isFront: isFrontCamera,
      );
    }

    // Draw bones
    for (final c in _connections) {
      final a = pts[c.$1], b = pts[c.$2];
      final ca = conf[c.$1] ?? 0, cb = conf[c.$2] ?? 0;
      if (a == null || b == null) continue;
      if (ca < _confidenceThreshold || cb < _confidenceThreshold) continue;
      final alpha = ((ca + cb) / 2).clamp(0.0, 1.0);
      _bonePaint.color = Color.fromRGBO(0, 229, 204, alpha);
      canvas.drawLine(a, b, _bonePaint);
    }

    // Draw joints
    for (final e in pts.entries) {
      final pt = e.value;
      final c = conf[e.key] ?? 0;
      if (c < _confidenceThreshold) {
        canvas.drawCircle(
          pt,
          4,
          Paint()
            ..color = Colors.yellow.withOpacity(0.5)
            ..style = PaintingStyle.fill,
        );
        continue;
      }
      final r = 5.0 + 2.0 * c;
      _jointPaint.color = Color.fromRGBO(0, 255, 200, c.clamp(0.5, 1.0));
      canvas.drawCircle(pt, r, _jointPaint);
      canvas.drawCircle(pt, r, _borderPaint);
    }
  }

  @override
  bool shouldRepaint(SkeletonPainter old) =>
      old.pose != pose ||
      old.imageSize != imageSize ||
      old.sensorOrientation != sensorOrientation ||
      old.isFrontCamera != isFrontCamera;
}
