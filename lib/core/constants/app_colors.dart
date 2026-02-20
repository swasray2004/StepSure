import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF2196F3);
  static const secondary = Color(0xFF00BCD4);
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9800);
  static const danger = Color(0xFFF44336);
  static const background = Color(0xFFF5F7FA);
  static const cardBg = Colors.white;
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B7280);

  // Hero / header gradient — teal to dark teal
  static const heroStart = Color(0xFF6ECECE);
  static const heroMid = Color(0xFF3AABAB);
  static const heroEnd = Color(0xFF1F7A7A);

  // Typography
  static const textDark = Color(0xFF183232);
  static const textMid = Color(0xFF3D5A5A);
  static const textLight = Color(0xFF7A9E9E);
  static const textHint = Color(0xFFABC8C8);

  // Surface & cards
  static const white = Color(0xFFFFFFFF);
  static const cardBorder = Color(0xFFE8F4F4);
  static const inputBg = Color(0xFFF5FAFA);
  static const inputBorder = Color(0xFFDCEEEE);

  static Color scoreColor(double score) {
    if (score >= 70) return success;
    if (score >= 40) return warning;
    return danger;
  }

  static Color riskColor(String risk) {
    switch (risk) {
      case 'low':
        return success;
      case 'moderate':
        return warning;
      case 'high':
        return danger;
      default:
        return Colors.grey;
    }
  }
}
