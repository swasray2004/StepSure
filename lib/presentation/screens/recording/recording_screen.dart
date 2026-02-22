// v3 - fixed InputImage construction for Android ML Kit
import 'dart:async';
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

class _RecordingScreenState extends State<RecordingScreen>
    with TickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  String? _cameraError;
  Pose? _currentPose;

  /// Raw sensor frame size — set each time we get a CameraImage.
  /// This is the UNROTATED size (e.g. 1920×1080 on most Android phones).
  Size? _rawImageSize;

  InputImageRotation _inputRotation = InputImageRotation.rotation0deg;
  int _sensorOrientation = 0; // raw degrees, used by SkeletonPainter
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

  // Live feedback
  String? _latestFeedback;
  Timer? _feedbackClearTimer;

  // Animation for feedback bubble
  late AnimationController _feedbackAnim;
  late Animation<Offset> _feedbackSlide;
  late Animation<double> _feedbackFade;

  // ── Init ───────────────────────────────────────────────────────────────────
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
    _feedbackSlide = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _feedbackAnim, curve: Curves.easeOutCubic));
    _feedbackFade =
        CurvedAnimation(parent: _feedbackAnim, curve: Curves.easeOut);

    _initializeCamera();
  }

  // ── Camera ─────────────────────────────────────────────────────────────────
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      _selectedCameraIndex = 0;
      await _startCamera(_cameras![_selectedCameraIndex]);
    } catch (e) {
      setState(() => _cameraError = 'Camera error: $e');
    }
  }

  Future<void> _startCamera(CameraDescription desc) async {
    _cameraController = CameraController(
      desc,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await _cameraController!.initialize();
    _sensorOrientation = _cameraController!.description.sensorOrientation;
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

  // ── Coordinate helpers ─────────────────────────────────────────────────────
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
          bytes: image.planes[0].bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: _inputRotation,
            format: InputImageFormat.bgra8888,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );
      } else {
        // Android NV21: concatenate all planes
        final WriteBuffer buffer = WriteBuffer();
        for (final plane in image.planes) {
          buffer.putUint8List(plane.bytes);
        }
        return InputImage.fromBytes(
          bytes: buffer.done().buffer.asUint8List(),
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            // Pass the ACTUAL sensor rotation. ML Kit rotates the image
            // internally and returns landmarks in the rotated (portrait) space.
            // SkeletonPainter then just scales those coords to screen size.
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

  // ── Recording ──────────────────────────────────────────────────────────────
  void _startRecording() async {
    _sessionStart = DateTime.now();
    _sessionSeconds = 0;
    _errorLogs.clear();
    setState(() => _isRecording = true);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isRecording) return;
      setState(() =>
          _sessionSeconds = DateTime.now().difference(_sessionStart).inSeconds);
    });

    try {
      await _cameraController?.startImageStream((CameraImage image) async {
        if (!_isRecording || _processingFrame) return;
        _processingFrame = true;

        try {
          // Always capture the raw sensor frame size (width × height BEFORE rotation)
          final rawW = image.width.toDouble();
          final rawH = image.height.toDouble();

          final inputImage = _inputImageFromCamera(image);
          if (inputImage == null) {
            if (mounted)
              setState(() => _errorLogs.add('Frame conversion failed'));
            return;
          }

          final detectedPose = await _poseService.detectPose(inputImage);

          if (mounted) {
            setState(() {
              _rawImageSize = Size(rawW, rawH);
              _currentPose = detectedPose;
              // Only log first few "no pose" messages to avoid spam
              if (detectedPose == null && _errorLogs.length < 3) {
                _errorLogs.add('No pose detected');
              }
            });
          }

          if (detectedPose != null) {
            _gaitService.processFrame(detectedPose);
            _updateFeedback();
          }
        } catch (e, st) {
          debugPrint('Pose detection error: $e\n$st');
          if (mounted) setState(() => _errorLogs.add('Error: $e'));
        } finally {
          _processingFrame = false;
        }
      });
    } catch (e) {
      setState(() => _errorLogs.add('Image stream error: $e'));
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
    final report = ReportGenerator.generate(current: session, previous: prev);
    await _supabase.saveReport(sessionId: sessionId, report: report);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultsScreen(
            session: session.copyWith(id: sessionId).toMap(),
            report: report,
          ),
        ),
      );
    }
  }

  // ── Dispose ────────────────────────────────────────────────────────────────
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

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_cameraError != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off_rounded,
                  color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(_cameraError!,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00E5CC)),
        ),
      );
    }

    final isFront = _cameraController!.description.lensDirection ==
        CameraLensDirection.front;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Camera preview ───────────────────────────────────────────
          CameraPreview(_cameraController!),

          // ── Skeleton overlay ─────────────────────────────────────────
          // Only render when we have a pose AND the raw sensor frame size.
          if (_currentPose != null && _rawImageSize != null)
            LayoutBuilder(
              builder: (context, constraints) {
                final screenSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
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

          // ── Top HUD ──────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      // Back button
                      _GlassButton(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),

                      // Timer chip
                      _HudChip(
                        icon: Icons.timer_outlined,
                        label: _formatTime(_sessionSeconds),
                        color: Colors.white,
                      ),

                      const Spacer(),

                      // LIVE / READY indicator
                      _LiveChip(isLive: _isRecording),

                      const SizedBox(width: 10),

                      // Switch camera
                      if (_cameras != null && _cameras!.length > 1)
                        _GlassButton(
                          onTap: _switchCamera,
                          child: Icon(
                            isFront
                                ? Icons.camera_rear_rounded
                                : Icons.camera_front_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Feedback bubble ─────────────────────────────────
                if (_latestFeedback != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SlideTransition(
                      position: _feedbackSlide,
                      child: FadeTransition(
                        opacity: _feedbackFade,
                        child: _FeedbackBubble(message: _latestFeedback!),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Record / Stop button ──────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Guide text
                    AnimatedOpacity(
                      opacity: _isRecording ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Stand 2–3m away, full body visible',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    // Record button
                    GestureDetector(
                      onTap: _isRecording ? _stopRecording : _startRecording,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer ring
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _isRecording
                                    ? Colors.red.withOpacity(0.7)
                                    : Colors.white.withOpacity(0.7),
                                width: 3,
                              ),
                            ),
                          ),
                          // Inner button
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: _isRecording ? 34 : 66,
                            height: _isRecording ? 34 : 66,
                            decoration: BoxDecoration(
                              color: _isRecording ? Colors.red : Colors.white,
                              borderRadius:
                                  BorderRadius.circular(_isRecording ? 8 : 33),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    Text(
                      _isRecording ? 'Tap to stop' : 'Tap to record',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Debug error log (only shown in debug builds) ──────────────
          if (kDebugMode && _errorLogs.isNotEmpty)
            Positioned(
              bottom: 160,
              left: 16,
              right: 16,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 100),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.5)),
                ),
                child: ListView.builder(
                  itemCount: _errorLogs.length,
                  itemBuilder: (_, i) => Text(
                    _errorLogs[i],
                    style: const TextStyle(color: Colors.white60, fontSize: 10),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ─── HUD Widgets ──────────────────────────────────────────────────────────────

class _HudChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HudChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.50),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}

class _LiveChip extends StatefulWidget {
  final bool isLive;
  const _LiveChip({required this.isLive});

  @override
  State<_LiveChip> createState() => _LiveChipState();
}

class _LiveChipState extends State<_LiveChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulse = Tween(begin: 0.6, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: widget.isLive
            ? Colors.red.withOpacity(0.80)
            : Colors.black.withOpacity(0.50),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isLive
              ? Colors.red.withOpacity(0.5)
              : Colors.white.withOpacity(0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isLive)
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(_pulse.value),
                  shape: BoxShape.circle,
                ),
              ),
            )
          else
            const Icon(Icons.fiber_manual_record_rounded,
                color: Colors.white54, size: 8),
          const SizedBox(width: 6),
          Text(
            widget.isLive ? 'LIVE' : 'READY',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _GlassButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _FeedbackBubble extends StatelessWidget {
  final String message;
  const _FeedbackBubble({required this.message});

  IconData get _icon {
    final lower = message.toLowerCase();
    if (lower.contains('great') ||
        lower.contains('good') ||
        lower.contains('keep')) {
      return Icons.thumb_up_rounded;
    }
    if (lower.contains('faster') || lower.contains('cadence'))
      return Icons.speed_rounded;
    if (lower.contains('symmetr')) return Icons.balance_rounded;
    if (lower.contains('stride')) return Icons.straighten_rounded;
    if (lower.contains('posture') || lower.contains('upright')) {
      return Icons.accessibility_new_rounded;
    }
    return Icons.tips_and_updates_rounded;
  }

  Color get _color {
    final lower = message.toLowerCase();
    if (lower.contains('great') ||
        lower.contains('good') ||
        lower.contains('keep')) {
      return const Color(0xFF00C9AA);
    }
    if (lower.contains('try') ||
        lower.contains('faster') ||
        lower.contains('improve')) {
      return const Color(0xFFFFD166);
    }
    return const Color(0xFF64DFDF);
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.62),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.50), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.20),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(_icon, color: color, size: 15),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
