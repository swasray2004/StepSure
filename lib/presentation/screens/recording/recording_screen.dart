// v4 - bug-fixed version
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../results/results_screen.dart';
import 'skeleton_painter.dart';

import 'package:gait_rehab/core/constants/app_colors.dart';

import '../../../data/pose_service.dart';
import '../../../data/supabase_service.dart';

import '../../../domain/gait_analysis_service.dart';
import '../../../domain/feedback_engine.dart';
import '../../../domain/score_calculator.dart';
import '../../../domain/report_generator.dart';

import '../../../domain/models/session_model.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  int _selectedCameraIndex = 0;
  String? _cameraError;

  Pose? _currentPose;

  Size? _rawImageSize;

  InputImageRotation _inputRotation = InputImageRotation.rotation0deg;
  int _sensorOrientation = 0;

  bool _isRecording = false;
  int _sessionSeconds = 0;
  DateTime _sessionStart = DateTime.now();

  late FeedbackEngine _feedbackEngine;
  late GaitAnalysisService _gaitService;
  late PoseService _poseService;

  final SupabaseService _supabase = SupabaseService();

  Timer? _timer;
  bool _processingFrame = false;

  final List<String> _errorLogs = [];

  String? _latestFeedback;
  Timer? _feedbackClearTimer;

  late AnimationController _feedbackAnim;
  late Animation<Offset> _feedbackSlide;
  late Animation<double> _feedbackFade;

  @override
  void initState() {
    super.initState();

    _feedbackEngine = FeedbackEngine();
    _gaitService = GaitAnalysisService(feedbackEngine: _feedbackEngine);
    _poseService = PoseService();

    _feedbackAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _feedbackSlide = Tween(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _feedbackAnim, curve: Curves.easeOutCubic),
    );

    _feedbackFade =
        CurvedAnimation(parent: _feedbackAnim, curve: Curves.easeOut);

    _initializeCamera();
  }

  // ───────────────── Camera ─────────────────

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      await _startCamera(_cameras!.first);
    } catch (e) {
      if (!mounted) return;
      setState(() => _cameraError = 'Camera error: $e');
    }
  }

  Future<void> _startCamera(CameraDescription desc) async {
    final controller = CameraController(
      desc,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await controller.initialize();

    _cameraController = controller;

    _sensorOrientation = controller.description.sensorOrientation;
    _inputRotation = _rotationIntToInputImageRotation(_sensorOrientation);

    if (mounted) setState(() {});
  }

  void _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    await _cameraController?.stopImageStream();
    await _cameraController?.dispose();

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;

    _currentPose = null;
    _rawImageSize = null;

    await _startCamera(_cameras![_selectedCameraIndex]);

    if (_isRecording) _startRecording();
  }

  InputImageRotation _rotationIntToInputImageRotation(int rotation) {
    switch (rotation) {
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

  InputImage? _inputImageFromCamera(CameraImage image) {
    try {
      if (Platform.isIOS) {
        return InputImage.fromBytes(
          bytes: image.planes.first.bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: _inputRotation,
            format: InputImageFormat.bgra8888,
            bytesPerRow: image.planes.first.bytesPerRow,
          ),
        );
      }

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
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  // ───────────────── Recording ─────────────────

  void _startRecording() async {
    _sessionStart = DateTime.now();
    _sessionSeconds = 0;

    _errorLogs.clear();

    setState(() => _isRecording = true);

    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isRecording) return;

      setState(() {
        _sessionSeconds =
            DateTime.now().difference(_sessionStart).inSeconds;
      });
    });

    try {
      await _cameraController?.startImageStream((CameraImage image) async {
        if (!_isRecording || _processingFrame) return;

        _processingFrame = true;

        try {
          final rawW = image.width.toDouble();
          final rawH = image.height.toDouble();

          final inputImage = _inputImageFromCamera(image);

          if (inputImage == null) {
            if (mounted) {
              setState(() => _errorLogs.add('Frame conversion failed'));
            }
            return;
          }

          final detectedPose = await _poseService.detectPose(inputImage);

          if (mounted) {
            setState(() {
              _rawImageSize = Size(rawW, rawH);
              _currentPose = detectedPose;
            });
          }

          if (detectedPose != null) {
            _gaitService.processFrame(detectedPose);
            _updateFeedback();
          }
        } catch (e) {
          if (mounted) {
            setState(() => _errorLogs.add(e.toString()));
          }
        } finally {
          _processingFrame = false;
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _errorLogs.add(e.toString()));
      }
    }
  }

  void _updateFeedback() {
    final msgs = _feedbackEngine.feedbackMessages;

    if (msgs.isEmpty) return;

    final latest = msgs.last;

    if (latest != _latestFeedback) {
      setState(() => _latestFeedback = latest);

      _feedbackAnim.forward(from: 0);

      _feedbackClearTimer?.cancel();

      _feedbackClearTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          _feedbackAnim.reverse();
        }
      });
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    await _cameraController?.stopImageStream();

    setState(() => _isRecording = false);

    final metrics = _gaitService.computeSessionMetrics();

    final score = ScoreCalculator.computeRecoveryScore(metrics);
    final fallRisk = ScoreCalculator.computeFallRisk(metrics);

    final userId = _supabase.currentUserId ?? '';

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
      videoUrl: null,
    );

    final sessionId = await _supabase.saveSession(session);

    final prev = await _supabase.getLastSession();

    final report =
        await ReportGenerator.generate(current: session, previous: prev);

    await _supabase.saveReport(
      sessionId: sessionId,
      report: report.toJson(),
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          session: session.copyWith(id: sessionId).toMap(),
          report: report.toJson(),
        ),
      ),
    );
  }

  // ───────────────── Dispose ─────────────────

  @override
  void dispose() {
    _timer?.cancel();
    _feedbackClearTimer?.cancel();
    _feedbackAnim.dispose();
    _cameraController?.dispose();
    _poseService.dispose();
    _feedbackEngine.dispose();
    super.dispose();
  }

  // ───────────────── UI ─────────────────

  @override
  Widget build(BuildContext context) {
    if (_cameraError != null) {
      return Scaffold(
        body: Center(child: Text(_cameraError!)),
      );
    }

    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isFront =
        _cameraController!.description.lensDirection ==
            CameraLensDirection.front;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController!),

          if (_currentPose != null && _rawImageSize != null)
            LayoutBuilder(
              builder: (context, constraints) {
                final screenSize =
                    Size(constraints.maxWidth, constraints.maxHeight);

                return CustomPaint(
                  size: screenSize,
                  painter: SkeletonPainter(
                    pose: _currentPose!,
                    imageSize: _rawImageSize!,
                    sensorOrientation: _sensorOrientation,
                    isFrontCamera: isFront,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}