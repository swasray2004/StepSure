import 'dart:io';
import '../results/results_screen.dart';
import 'package:gait_rehab/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../../data/pose_service.dart';
import '../../../domain/gait_analysis_service.dart';
import '../../../domain/feedback_engine.dart';
import '../../../domain/score_calculator.dart';
import '../../../domain/report_generator.dart';
import '../../../data/supabase_service.dart';
import '../../../domain/models/session_model.dart';
import 'skeleton_painter.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  CameraController? _cameraController;
  String? _cameraError;
  late PoseService _poseService;
  late FeedbackEngine _feedbackEngine;
  late GaitAnalysisService _gaitService;
  final _supabase = SupabaseService();

  Pose? _currentPose;
  Size _imageSize = Size.zero;
  InputImageRotation _inputRotation = InputImageRotation.rotation0deg;
  bool _isRecording = false;
  int _sessionSeconds = 0;
  late DateTime _sessionStart;

  @override
  void initState() {
    super.initState();
    _poseService = PoseService();
    _feedbackEngine = FeedbackEngine();
    _gaitService = GaitAnalysisService(feedbackEngine: _feedbackEngine);
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      setState(() {
        _cameraError = 'No cameras found on this device.';
      });
      return;
    }
    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _cameraController!.initialize();
    _inputRotation = _rotationFromSensor(
      _cameraController!.description.sensorOrientation,
    );
    if (mounted) setState(() {});
  }

  InputImageRotation _rotationFromSensor(int sensorOrientation) {
    switch (sensorOrientation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  void _startRecording() {
    if (_isRecording) return;
    setState(() {
      _isRecording = true;
      _sessionStart = DateTime.now();
      _sessionSeconds = 0;
    });
    _gaitService.startSession();

    _cameraController?.startImageStream((CameraImage image) async {
      if (!_isRecording) return;

      final inputImage = _inputImageFromCamera(image);
      if (inputImage == null) {
        debugPrint('[ML] InputImage conversion failed');
        return;
      }

        debugPrint(
          '[ML] InputImage created: size=${inputImage.metadata?.size}, rotation=${inputImage.metadata?.rotation}, format=${inputImage.metadata?.format}');

      final pose = await _poseService.detectPose(inputImage);
      if (pose != null && mounted) {
        debugPrint('[ML] Pose detected: ${pose.landmarks.length} landmarks');
        setState(() {
          _currentPose = pose;
          _imageSize = Size(image.width.toDouble(), image.height.toDouble());
        });
        _gaitService.processFrame(pose);
      } else {
        debugPrint('[ML] No pose detected');
      }

      setState(() {
        _sessionSeconds = DateTime.now().difference(_sessionStart).inSeconds;
      });
    });
  }

  InputImage? _inputImageFromCamera(CameraImage image) {
    try {
      if (Platform.isIOS) {
        // iOS delivers a single BGRA8888 plane
        return InputImage.fromBytes(
          bytes: image.planes[0].bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: _inputRotation,
            format: InputImageFormat.bgra8888,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );
      } else {
        // Android: YUV_420_888 — concatenate all planes so ML Kit gets a
        // complete buffer (Y luma + U/V chroma). ML Kit tolerates the
        // I420-style plane ordering as NV21.
        final WriteBuffer buffer = WriteBuffer();
        for (final plane in image.planes) {
          buffer.putUint8List(plane.bytes);
        }
        return InputImage.fromBytes(
          bytes: buffer.done().buffer.asUint8List(),
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: _inputRotation,
            format: InputImageFormat.nv21,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );
      }
    } catch (_) {
      return null;
    }
  }

  Future<void> _stopRecording() async {
    await _cameraController?.stopImageStream();
    setState(() => _isRecording = false);

    final metrics = _gaitService.computeSessionMetrics();
    final score = ScoreCalculator.computeRecoveryScore(metrics);
    final fallRisk = ScoreCalculator.computeFallRisk(metrics);
    final userId = _supabase.currentUserId!;

    final session = SessionModel(
      userId: userId,
      sessionDate: _sessionStart,
      durationSeconds: _sessionSeconds,
      recoveryScore: score,
      fallRisk: fallRisk,
      strideLength: metrics.strideLength,
      cadence: metrics.cadence,
      symmetry: metrics.symmetry,
      strideConsistency: metrics.strideConsistency,
      jointDeviation: metrics.jointDeviation,
    );

    final sessionId = await _supabase.saveSession(session);
    final prev = await _supabase.getLastSession();
    final report = ReportGenerator.generate(
      current: session,
      previous: prev,
    );
    await _supabase.saveReport(sessionId: sessionId, report: report);

    if (mounted) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultsScreen(
              session: session.copyWith(id: sessionId).toMap(),
              report: report,
            ),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraError != null) {
      return Scaffold(body: Center(child: Text(_cameraError!)));
    }
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController!),

          // Skeleton overlay
          if (_currentPose != null)
            CustomPaint(
              painter: SkeletonPainter(
                pose: _currentPose!,
                imageSize: _imageSize,
                rotation: _inputRotation,
              ),
            ),

          // HUD overlay
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _hudChip(Icons.timer, '${_sessionSeconds}s'),
                _hudChip(
                    Icons.directions_walk, _isRecording ? 'LIVE' : 'READY'),
              ],
            ),
          ),

          // Controls
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _isRecording ? _stopRecording : _startRecording,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _isRecording ? Colors.red : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.fiber_manual_record,
                    color: _isRecording ? Colors.white : Colors.red,
                    size: 36,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hudChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseService.dispose();
    _feedbackEngine.dispose();
    super.dispose();
  }
}
