import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  /// Font family names
  static String get englishFontFamily => GoogleFonts.inter().fontFamily ?? 'sans-serif';
  static String get urduFontFamily => GoogleFonts.notoSansArabic().fontFamily ?? 'sans-serif';
  static String get arabicFontFamily => GoogleFonts.amiri().fontFamily ?? 'serif';

  /// Dynamically builds a responsive TextTheme tailored for English vs. Urdu
  static TextTheme buildTextTheme(bool isUrdu) {
    final baseFamily = isUrdu ? urduFontFamily : englishFontFamily;
    final double heightScale = isUrdu ? 1.55 : 1.35;

    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: baseFamily,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: isUrdu ? 1.4 : 1.2,
      ),
      headlineMedium: TextStyle(
        fontFamily: baseFamily,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: isUrdu ? 1.45 : 1.25,
      ),
      titleLarge: TextStyle(
        fontFamily: baseFamily,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: isUrdu ? 1.5 : 1.3,
      ),
      titleMedium: TextStyle(
        fontFamily: baseFamily,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: heightScale,
      ),
      titleSmall: TextStyle(
        fontFamily: baseFamily,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        height: heightScale,
      ),
      bodyLarge: TextStyle(
        fontFamily: baseFamily,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: isUrdu ? 1.7 : 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: baseFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: isUrdu ? 1.65 : 1.5,
      ),
      bodySmall: TextStyle(
        fontFamily: baseFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
        height: isUrdu ? 1.55 : 1.4,
      ),
      labelLarge: TextStyle(
        fontFamily: baseFamily,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      labelMedium: TextStyle(
        fontFamily: baseFamily,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: TextStyle(
        fontFamily: baseFamily,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      ),
    );
  }

  // ── Static Styles with Fallbacks ──────────────────────────────

  static const TextStyle displayLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.8,
    height: 1.2,
  );

  static const TextStyle headingLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.4,
    height: 1.25,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.1,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    letterSpacing: 0.3,
  );

  static const TextStyle labelUppercase = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
    letterSpacing: 1.2,
  );

  static TextStyle get arabicText => GoogleFonts.amiri(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryEmerald,
        height: 1.8,
      );

  static TextStyle get arabicSmall => GoogleFonts.amiri(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.accentGold,
        height: 1.6,
      );

  static const TextStyle statValue = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle statLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    letterSpacing: 0.3,
  );
}
