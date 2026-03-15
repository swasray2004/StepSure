import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter/foundation.dart';

class PoseService {
  late final PoseDetector _detector;
  bool _isProcessing = false;

  PoseService() {
    _detector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.base,
      ),
    );
  }

  Future<Pose?> detectPose(InputImage inputImage) async {
    if (_isProcessing) return null;
    _isProcessing = true;
    try {
      final poses = await _detector.processImage(inputImage);
      debugPrint('[ML] Poses detected: ${poses.length}');
      return poses.isNotEmpty ? poses.first : null;
    } finally {
      _isProcessing = false;
    }
  }

  void dispose() {
    _detector.close();
  }
}
