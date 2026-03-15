import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
// EXACT COLORS FROM REFERENCE IMAGE
// ═══════════════════════════════════════════════════════════════
class AppColors {
  // Background — light sky blue gradient
  static const bgLight = Color(0xFFDFF2F7);
  static const bgMid = Color(0xFFC2E5EF);
  static const bgDark = Color(0xFFA8D8E8);

  // Hero / header gradient — teal to dark teal
  static const heroStart = Color(0xFF6ECECE);
  static const heroMid = Color(0xFF3AABAB);
  static const heroEnd = Color(0xFF1F7A7A);

  // Teal accent (buttons, active states, dots)
  static const teal = Color(0xFF3AABAB);
  static const tealLight = Color(0xFF7DD4D4);
  static const tealDark = Color(0xFF1F7A7A);
  static const tealPale = Color(0xFFE0F5F5);
  static const tealPill = Color(0xFFD0EFEF);

  // Surface & cards
  static const white = Color(0xFFFFFFFF);
  static const cardBg = Color(0xFFFFFFFF);
  static const cardBorder = Color(0xFFE8F4F4);
  static const inputBg = Color(0xFFF5FAFA);
  static const inputBorder = Color(0xFFDCEEEE);

  // Typography
  static const textDark = Color(0xFF183232);
  static const textMid = Color(0xFF3D5A5A);
  static const textLight = Color(0xFF7A9E9E);
  static const textHint = Color(0xFFABC8C8);

  // Semantic
  static const success = Color(0xFF3AABAB); // teal is success here
  static const warning = Color(0xFFF5A623);
  static const danger = Color(0xFFE05454);
  static const info = Color(0xFF4AADCD);

  // Score colors
  static Color scoreColor(double score) {
    if (score >= 70) return teal;
    if (score >= 40) return warning;
    return danger;
  }

  static Color riskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'low':
        return teal;
      case 'moderate':
        return warning;
      case 'high':
        return danger;
      default:
        return textLight;
    }
  }

  // Gradients
  static const heroGradient = LinearGradient(
    colors: [heroStart, heroMid, heroEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const bgGradient = LinearGradient(
    colors: [
      Color(0xFFF4FAFF), // very light blue
      Color(0xFFEAF6FF), // soft blue
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const tealGradient = LinearGradient(
    colors: [tealLight, teal, tealDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ═══════════════════════════════════════════════════════════════
// TYPOGRAPHY
// ═══════════════════════════════════════════════════════════════
class AppText {
  static const String fontFamily = 'Nunito'; // clean, friendly medical font

  static const h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
    letterSpacing: -0.3,
  );

  static const h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static const h4 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static const body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textMid,
    height: 1.55,
  );

  static const bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textLight,
    height: 1.4,
  );

  static const label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textLight,
    letterSpacing: 0.3,
  );

  static const button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    letterSpacing: 0.2,
  );

  static const heroTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.white,
    letterSpacing: -0.4,
    height: 1.25,
  );

  static const heroSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Color(0xCCFFFFFF),
  );
}

// ═══════════════════════════════════════════════════════════════
// THEME
// ═══════════════════════════════════════════════════════════════
class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        fontFamily: AppText.fontFamily,
        scaffoldBackgroundColor: AppColors.bgLight,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.teal,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: AppColors.textDark),
          titleTextStyle: TextStyle(
            fontFamily: AppText.fontFamily,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.teal,
            foregroundColor: AppColors.white,
            elevation: 0,
            shadowColor: AppColors.teal.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: AppText.button,
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.teal, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.danger),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: const TextStyle(
            fontFamily: AppText.fontFamily,
            color: AppColors.textLight,
            fontSize: 14,
          ),
          prefixIconColor: AppColors.teal,
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.teal,
          unselectedItemColor: AppColors.textHint,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: TextStyle(
            fontFamily: AppText.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: AppText.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
// CARD SHADOW — from the reference (very soft, layered)
// ═══════════════════════════════════════════════════════════════
List<BoxShadow> get cardShadow => [
      BoxShadow(
        color: AppColors.tealDark.withValues(alpha: 0.07),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: AppColors.tealDark.withValues(alpha: 0.04),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ];
