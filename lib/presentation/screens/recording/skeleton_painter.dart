import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class SkeletonPainter extends CustomPainter {
  final Pose pose;
  final Size imageSize;
  final bool isFrontCamera;

  SkeletonPainter({
    required this.pose,
    required this.imageSize,
    this.isFrontCamera = false,
  });

  final _bonePaint = Paint()
    ..color = const Color(0xFF00E5FF)
    ..strokeWidth = 3.0
    ..style = PaintingStyle.stroke;

  final _jointPaint = Paint()
    ..color = const Color(0xFFFFEB3B)
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
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;

    Offset _toOffset(PoseLandmark lm) {
      double x = lm.x * scaleX;
      double y = lm.y * scaleY;
      if (isFrontCamera) x = size.width - x;
      return Offset(x, y);
    }

    // Draw bones
    for (final conn in _connections) {
      final a = pose.landmarks[conn[0]];
      final b = pose.landmarks[conn[1]];
      if (a != null && b != null && a.likelihood > 0.5 && b.likelihood > 0.5) {
        canvas.drawLine(_toOffset(a), _toOffset(b), _bonePaint);
      }
    }

    // Draw joints
    for (final lm in pose.landmarks.values) {
      if (lm.likelihood > 0.5) {
        canvas.drawCircle(_toOffset(lm), 6, _jointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(SkeletonPainter old) => true;
}
