import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'app_colors.dart';
import '../controllers/theme_controller.dart';

class AppTextStyles {
  static double get _scale {
    try {
      final tc = Get.find<ThemeController>();
      // Default font size in settings is 14. Scale relative to that.
      return tc.preferences.value.fontSize / 14.0;
    } catch (_) {
      return 1.0;
    }
  }

  // Splash / Hero
  static TextStyle get displayLarge => GoogleFonts.plusJakartaSans(
    fontSize: 48 * _scale,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -1.5,
  );

  // Screen Titles
  static TextStyle get displayMedium => GoogleFonts.plusJakartaSans(
    fontSize: 32 * _scale,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -1.0,
  );

  // Section Headings
  static TextStyle get headingLarge => GoogleFonts.plusJakartaSans(
    fontSize: 18 * _scale,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  // Card Titles (Poppins)
  static TextStyle get titleMedium => GoogleFonts.poppins(
    fontSize: 14 * _scale,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Body Text
  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
    fontSize: 16 * _scale,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
    fontSize: 14 * _scale,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
    fontSize: 12 * _scale,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  // Labels / Overlines (Badges)
  static TextStyle get labelSmall => GoogleFonts.plusJakartaSans(
    fontSize: 10 * _scale,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 1.5,
  );
}
