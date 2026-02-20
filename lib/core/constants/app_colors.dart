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
