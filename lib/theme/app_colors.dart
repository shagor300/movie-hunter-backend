import 'package:flutter/material.dart';

class AppColors {
  // Primary & Accents
  static const Color primary = Color(0xFF1E94F6); // Main Stitch Blue
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color accentPurple = Color(0xFF8B5CF6);

  // Backgrounds
  static const Color background = Color(
    0xFF0F0F1E,
  ); // Standard Stitch background
  static const Color backgroundLight = Color(0xFFF5F7F8);
  static const Color backgroundDark = Color(
    0xFF0A0A0A,
  ); // Deep dark from Onboarding
  static const Color backgroundDarker = Color(0xFF101A22); // From Splash/Search

  // Surfaces & Cards
  static const Color surface = Color(0xFF1E293B); // slate-800
  static const Color surfaceLight = Color(0xFF334155); // slate-700

  // Glassmorphism
  static const Color glassBackground = Color(
    0x08FFFFFF,
  ); // rgba(255,255,255,0.03) -> 0x08 is approx 3%
  static const Color glassBorder = Color(
    0x14FFFFFF,
  ); // rgba(255,255,255,0.08) -> 0x14 is approx 8%

  // Text Colors
  static const Color textPrimary = Color(0xFFF1F5F9); // slate-100
  static const Color textSecondary = Color(0xFF94A3B8); // slate-400
  static const Color textMuted = Color(0xFF64748B); // slate-500

  // Status Colors
  static const Color success = Color(0xFF10B981); // emerald-500
  static const Color warning = Color(0xFFF59E0B); // amber-500
  static const Color error = Color(0xFFEF4444); // red-500
  static const Color starRating = Color(0xFFFACC15); // yellow-400

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, accentPurple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cinematicGradient = LinearGradient(
    colors: [Color(0xFF0F0F1E), Color(0xFF2C2C54)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
