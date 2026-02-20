import 'package:flutter/material.dart';
import 'package:gait_rehab/core/constants/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../instructions/primary_button.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _videoFile;
  bool _analyzing = false;
  final _picker = ImagePicker();

  Future<void> _pickVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _videoFile = File(picked.path));
    }
  }

  Future<void> _analyzeVideo() async {
    if (_videoFile == null) return;
    setState(() => _analyzing = true);

    // Simulate processing — in real implementation, pass video
    // frames through PoseService, same as RecordingScreen
    await Future.delayed(const Duration(seconds: 4));

    if (mounted) {
      setState(() => _analyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video analysis complete!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Upload Video')),
      body: SafeArea(
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
                          Text('Upload a walking video for full gait analysis',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Video picker area
              GestureDetector(
                onTap: _videoFile != null ? _analyzeVideo : _pickVideo,
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
                      style: _videoFile != null
                          ? BorderStyle.solid
                          : BorderStyle.solid,
                    ),
                  ),
                  child: _videoFile != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.videocam_rounded,
                                color: AppColors.primary, size: 44),
                            const SizedBox(height: 12),
                            Text(
                              _videoFile!.path.split('/').last,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            TextButton(
                              onPressed: _pickVideo,
                              child: const Text('Change Video',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        )
                      : Column(
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
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Requirements
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
                  'Recorded from side view, not front-on'
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
                        child:
                            Icon(item.$1, color: AppColors.primary, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(item.$2,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              PrimaryButton(
                label: _analyzing ? 'Analysing...' : 'Analyse Video',
                icon: _analyzing ? null : Icons.play_circle_outline_rounded,
                onTap: _videoFile != null ? _analyzeVideo : _pickVideo,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
