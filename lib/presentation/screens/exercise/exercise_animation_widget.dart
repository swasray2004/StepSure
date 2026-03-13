// ═══════════════════════════════════════════════════════════════════════════════
// EXERCISE ANIMATION WIDGET — 3D AVATAR REPLACEMENT
//
// This file REPLACES the old exercise_animation_widget.dart entirely.
// It exports ExerciseAnimationWidget as a drop-in compatible wrapper around
// the new SkeletalAvatar3D, so no changes are needed in exercise_mode_screen.dart
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:gait_rehab/domain/models/exercise_model.dart';
import 'skeletal_avatar_3d.dart';

export 'skeletal_avatar_3d.dart'
    show SkeletalAvatar3D, AvatarAnimationCard, AvatarPreviewWidget;

/// Drop-in replacement for the old ExerciseAnimationWidget.
/// Wraps SkeletalAvatar3D with the same constructor signature.
class ExerciseAnimationWidget extends StatelessWidget {
  final ExerciseModel exercise;
  final bool isActive;
  final double size;

  const ExerciseAnimationWidget({
    super.key,
    required this.exercise,
    this.isActive = true,
    this.size = 220,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletalAvatar3D(
      exerciseId: exercise.id,
      isActive: isActive,
      size: size,
      orbitCamera: true,
    );
  }
}
