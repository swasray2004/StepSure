import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:video_player/video_player.dart';
import '../domain/feedback_engine.dart';
import '../domain/gait_analysis_service.dart';
import '../domain/score_calculator.dart';

/// Analyses a video file for gait metrics using Google ML Kit pose detection.
///
/// Because ML Kit processes images (not video), frames are extracted by
/// seeking a [VideoPlayerController] and capturing the rendered widget via a
/// [RenderRepaintBoundary] whose [GlobalKey] is owned by [UploadScreen].
///
/// Sampling rate: 5 fps (one frame every 200 ms).
class VideoAnalysisService {
  late final PoseDetector _detector;
  late final GaitAnalysisService _gaitService;
  late final FeedbackEngine _feedbackEngine;

  VideoAnalysisService() {
    // Use singleImage mode for non-sequential video frames (more accurate
    // than stream mode which assumes temporal continuity between frames).
    _detector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.single,
        model: PoseDetectionModel.accurate,
      ),
    );
    _feedbackEngine = FeedbackEngine();
    _gaitService = GaitAnalysisService(feedbackEngine: _feedbackEngine);
  }

  /// Processes [videoPath] frame-by-frame and returns [GaitMetrics].
  ///
  /// [repaintKey] must be attached to a [RepaintBoundary] that wraps a
  /// [VideoPlayer] widget rendered somewhere in the active widget tree.
  ///
  /// [onProgress] is called after each frame with a value in [0.0, 1.0].
  ///
  /// Throws an [Exception] when video duration is unreadable or fewer than
  /// 5 poses are successfully detected (too short / body not visible).
  Future<GaitMetrics> analyzeVideo({
    required String videoPath,
    required GlobalKey repaintKey,
    void Function(double progress)? onProgress,
  }) async {
    // ── Initialise video controller ────────────────────────────────────────
    final controller = VideoPlayerController.file(File(videoPath));
    await controller.initialize();
    await controller.setVolume(0); // silent — TTS from FeedbackEngine is enough
    await controller.setLooping(false);

    final total = controller.value.duration;
    if (total == Duration.zero) {
      await controller.dispose();
      throw Exception(
        'Could not read video duration. '
        'Ensure the file is a valid MP4/MOV/AVI video.',
      );
    }

    final frameCount = (total.inMilliseconds / 200).floor(); // 5 fps
    if (frameCount < 10) {
      await controller.dispose();
      throw Exception(
        'Video is too short (${total.inSeconds}s). '
        'Please use a video of at least 10 seconds of walking (side or front-on view).',
      );
    }

    // ── Process frames ─────────────────────────────────────────────────────
    _gaitService.startSession();
    int posesDetected = 0;

    for (int i = 0; i < frameCount; i++) {
      try {
        // Seek to target timestamp and let the widget render the frame.
        await controller.seekTo(Duration(milliseconds: i * 200));
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 100));
        await controller.pause();

        // Capture the rendered VideoPlayer widget as raw RGBA pixels.
        final boundary = repaintKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
        if (boundary == null) continue;

        final uiImage = await boundary.toImage(pixelRatio: 1.0);
        final int frameW = uiImage.width;
        final int frameH = uiImage.height;

        final byteData =
            await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
        uiImage.dispose(); // free GPU texture immediately

        if (byteData == null) continue;

        // Build InputImage. rawRgba gives RGBA bytes; we label as bgra8888
        // because pose detection is colour-agnostic and both formats are
        // accepted on the ML Kit software path.
        final inputImage = InputImage.fromBytes(
          bytes: byteData.buffer.asUint8List(),
          metadata: InputImageMetadata(
            size: Size(frameW.toDouble(), frameH.toDouble()),
            // Widget renders display-oriented frames — no additional rotation.
            rotation: InputImageRotation.rotation0deg,
            format: InputImageFormat.bgra8888,
            bytesPerRow: frameW * 4,
          ),
        );

        final poses = await _detector.processImage(inputImage);
        if (poses.isNotEmpty) {
          _gaitService.processFrame(poses.first);
          posesDetected++;
        }
      } catch (_) {
        // Skip this frame and continue — individual frame failures are normal
        // (e.g. seek not yet complete, boundary temporarily null).
      }

      onProgress?.call((i + 1) / frameCount);
    }

    await controller.dispose();

    if (posesDetected < 5) {
      throw Exception(
        'Insufficient pose data detected ($posesDetected/$frameCount frames). '
        'Ensure the full body is visible and well-lit throughout the video, '
        'and that the video is recorded from a side or front-on view.',
      );
    }

    return _gaitService.computeSessionMetrics();
  }

  /// Release ML Kit resources. Call from the owning widget's [dispose].
  void dispose() {
    _detector.close();
    _feedbackEngine.dispose();
  }
}
