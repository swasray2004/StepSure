// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gait_rehab/core/constants/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../../data/video_analysis_service.dart';
import '../../../data/supabase_service.dart';
import '../../../domain/score_calculator.dart';
import '../../../domain/report_generator.dart';
import '../../../domain/models/session_model.dart';
import '../instructions/primary_button.dart';
import '../results/results_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _videoFile;
  bool _analyzing = false;
  double _progress = 0.0;
  String? _errorMessage;

  final _picker = ImagePicker();
  // Key for the hidden RepaintBoundary that VideoAnalysisService reads frames from.
  final _repaintKey = GlobalKey();
  final _supabase = SupabaseService();
  late final VideoAnalysisService _analysisService;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _analysisService = VideoAnalysisService();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _analysisService.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return;

    // Dispose old controller before creating a new one.
    await _videoController?.dispose();
    final controller = VideoPlayerController.file(File(picked.path));
    await controller.initialize();

    setState(() {
      _videoFile = File(picked.path);
      _videoController = controller;
      _errorMessage = null;
      _progress = 0.0;
    });
  }

  Future<void> _analyzeVideo() async {
    if (_videoFile == null || _videoController == null || _analyzing) return;

    setState(() {
      _analyzing = true;
      _progress = 0.0;
      _errorMessage = null;
    });

    try {
      final metrics = await _analysisService.analyzeVideo(
        videoPath: _videoFile!.path,
        repaintKey: _repaintKey,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );

      final score = ScoreCalculator.computeRecoveryScore(metrics);
      final fallRisk = ScoreCalculator.computeFallRisk(metrics);
      final userId = _supabase.currentUserId!;

      final session = SessionModel(
        userId: userId,
        sessionDate: DateTime.now(),
        durationSeconds: _videoController!.value.duration.inSeconds,
        recoveryScore: score,
        fallRisk: fallRisk,
        strideLength: metrics.strideLength,
        cadence: metrics.cadence,
        symmetry: metrics.symmetry,
        strideConsistency: metrics.strideConsistency,
        jointDeviation: metrics.jointDeviation,
      );

      final sessionId = await _supabase.saveSession(session);
      final videoUrl = await _supabase.uploadVideo(_videoFile!.path, sessionId);
      if (videoUrl != null) {
        await _supabase.updateSessionVideoUrl(sessionId, videoUrl);
      }
      final sessionWithVideo =
          session.copyWith(id: sessionId, videoUrl: videoUrl);

      final prev = await _supabase.getLastSession();
      final report = ReportGenerator.generate(
        current: sessionWithVideo,
        previous: prev,
      );
      await _supabase.saveReport(sessionId: sessionId, report: report);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultsScreen(
              session: sessionWithVideo.toMap(),
              report: report,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _analyzing = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Upload Video')),
      body: Stack(
        children: [
          // ── Hidden VideoPlayer ─────────────────────────────────────────
          // Positioned far off-screen so it's never visible, but Flutter
          // still lays it out and paints it, allowing RepaintBoundary.toImage()
          // to capture frames during analysis.
          if (_videoController != null)
            Positioned(
              left: -4000,
              top: 0,
              width: 320,
              height: 240,
              child: RepaintBoundary(
                key: _repaintKey,
                child: VideoPlayer(_videoController!),
              ),
            ),

          // ── Main UI ────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00A890), Color(0xFF00D4AA)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.upload_file_rounded,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Analyse Existing Video',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16)),
                              SizedBox(height: 4),
                              Text(
                                  'Upload a walking video for full gait analysis',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Video picker / progress area
                  GestureDetector(
                    onTap: _analyzing
                        ? null
                        : (_videoFile != null ? null : _pickVideo),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _videoFile != null
                            ? AppColors.primary.withOpacity(0.08)
                            : AppColors.cardBg,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: _videoFile != null
                              ? AppColors.primary
                              : AppColors.primary.withOpacity(0.15),
                          width: _videoFile != null ? 2 : 1,
                        ),
                      ),
                      child: _analyzing
                          ? _buildAnalyzingView()
                          : _videoFile != null
                              ? _buildVideoSelectedView()
                              : _buildEmptyView(),
                    ),
                  ),

                  // Error message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.danger.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.danger, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.danger),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Requirements list
                  const Text('Requirements',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          fontSize: 15)),
                  const SizedBox(height: 12),
                  ...[
                    (
                      Icons.directions_walk_rounded,
                      'Full body visible throughout the video'
                    ),
                    (
                      Icons.wb_sunny_outlined,
                      'Good lighting, avoid dark/blurry videos'
                    ),
                    (
                      Icons.phone_android_rounded,
                      'Side view or front-on view supported'
                    ),
                    (
                      Icons.straighten_rounded,
                      'At least 10 seconds of walking footage'
                    ),
                  ].map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(item.$1,
                                color: AppColors.primary, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(item.$2,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  PrimaryButton(
                    label: _analyzing
                        ? 'Analysing... ${(_progress * 100).toStringAsFixed(0)}%'
                        : (_videoFile != null
                            ? 'Analyse Video'
                            : 'Select Video'),
                    icon: _analyzing ? null : Icons.play_circle_outline_rounded,
                    onTap: _analyzing
                        ? () {}
                        : (_videoFile != null ? _analyzeVideo : _pickVideo),
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            value: _progress > 0 ? _progress : null,
            strokeWidth: 4,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Detecting pose landmarks...',
          style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontSize: 14),
        ),
        const SizedBox(height: 6),
        Text(
          '${(_progress * 100).toStringAsFixed(0)}% of frames processed',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildVideoSelectedView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.videocam_rounded, color: AppColors.primary, size: 44),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _videoFile!.path.split('/').last,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: _pickVideo,
          child: const Text('Change Video',
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildEmptyView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.video_library_outlined,
              color: AppColors.primary, size: 36),
        ),
        const SizedBox(height: 16),
        const Text('Tap to select video',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 16)),
        const SizedBox(height: 6),
        const Text('MP4, MOV, AVI supported',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
