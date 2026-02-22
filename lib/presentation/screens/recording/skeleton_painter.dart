import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class SkeletonPainter extends CustomPainter {
  final Pose pose;
  final Size imageSize;
  final bool isFrontCamera;
  final InputImageRotation rotation;

  SkeletonPainter({
    required this.pose,
    required this.imageSize,
    this.isFrontCamera = false,
    this.rotation = InputImageRotation.rotation0deg,
  });

  final _bonePaint = Paint()
    ..color = const Color(0xFF00E5FF)
    ..strokeWidth = 5.0
    ..style = PaintingStyle.stroke;

  final _jointPaint = Paint()
    ..color = const Color(0xFFFFEB3B)
    ..style = PaintingStyle.fill;

  final _importantJointPaint = Paint()
    ..color = const Color(0xFF00FF00)
    ..style = PaintingStyle.fill;

  static const _connections = [
    // Torso
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
    // Left leg
    [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
    [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
    // Right leg
    [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
    [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
    // Arms
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
    [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
    [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // ML Kit returns landmark coordinates in the raw (unrotated) camera buffer
    // space. We remap them to screen space accounting for sensor rotation so
    // the skeleton overlay aligns with the body in the CameraPreview.
    Offset toOffset(PoseLandmark lm) {
      final imgW = imageSize.width;
      final imgH = imageSize.height;
      final screenW = size.width;
      final screenH = size.height;
      double sx, sy;

      switch (rotation) {
        case InputImageRotation.rotation90deg:
          // Buffer is landscape. The buffer's x-axis maps to screen y (inverted)
          // and buffer's y-axis maps to screen x.
          sx = isFrontCamera
              ? (1.0 - lm.y / imgH) * screenW
              : (lm.y / imgH) * screenW;
          sy = (1.0 - lm.x / imgW) * screenH;
        case InputImageRotation.rotation270deg:
          sx = isFrontCamera
              ? (lm.y / imgH) * screenW
              : (1.0 - lm.y / imgH) * screenW;
          sy = (lm.x / imgW) * screenH;
        case InputImageRotation.rotation180deg:
          sx = isFrontCamera
              ? (lm.x / imgW) * screenW
              : (1.0 - lm.x / imgW) * screenW;
          sy = (1.0 - lm.y / imgH) * screenH;
        default: // rotation0deg
          sx = (lm.x / imgW) * screenW;
          sy = (lm.y / imgH) * screenH;
          if (isFrontCamera) sx = screenW - sx;
      }

      return Offset(sx, sy);
    }

    // Draw bones with thicker lines and filter low-confidence
    for (final conn in _connections) {
      final a = pose.landmarks[conn[0]];
      final b = pose.landmarks[conn[1]];
      if (a != null && b != null && a.likelihood > 0.6 && b.likelihood > 0.6) {
        canvas.drawLine(toOffset(a), toOffset(b), _bonePaint);
      }
    }

    // Highlight important joints (shoulders, hips, knees, ankles)
    final important = [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    ];
    for (final type in important) {
      final lm = pose.landmarks[type];
      if (lm != null && lm.likelihood > 0.7) {
        canvas.drawCircle(toOffset(lm), 10, _importantJointPaint);
      }
    }

    // Draw other joints
    for (final lm in pose.landmarks.values) {
      if (lm.likelihood > 0.6 && !important.contains(lm.type)) {
        canvas.drawCircle(toOffset(lm), 7, _jointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(SkeletonPainter old) =>
      old.rotation != rotation || old.isFrontCamera != isFrontCamera || true;
}
