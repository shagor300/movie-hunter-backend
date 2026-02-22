import 'package:flutter/material.dart';

/// Complete color system for MovieHub
class AppColors {
  // ══════════════════════════════════════════════════════════
  // ACCENT COLORS (User Selectable)
  // ══════════════════════════════════════════════════════════

  static const Map<String, AccentColorPalette> accentColors = {
    // Classic Colors
    'sky_blue': AccentColorPalette(
      name: 'Sky Blue',
      primary: Color(0xFF2196F3),
      light: Color(0xFF64B5F6),
      dark: Color(0xFF1976D2),
      category: 'Classic',
    ),
    'ocean_blue': AccentColorPalette(
      name: 'Ocean Blue',
      primary: Color(0xFF03A9F4),
      light: Color(0xFF4FC3F7),
      dark: Color(0xFF0288D1),
      category: 'Classic',
    ),
    'purple_haze': AccentColorPalette(
      name: 'Purple Haze',
      primary: Color(0xFF9C27B0),
      light: Color(0xFFBA68C8),
      dark: Color(0xFF7B1FA2),
      category: 'Classic',
    ),
    'pink_rose': AccentColorPalette(
      name: 'Pink Rose',
      primary: Color(0xFFE91E63),
      light: Color(0xFFF48FB1),
      dark: Color(0xFFC2185B),
      category: 'Classic',
    ),
    'amber_gold': AccentColorPalette(
      name: 'Amber Gold',
      primary: Color(0xFFFFC107),
      light: Color(0xFFFFD54F),
      dark: Color(0xFFFFA000),
      category: 'Classic',
    ),

    // Modern Colors
    'mint_green': AccentColorPalette(
      name: 'Mint Green',
      primary: Color(0xFF00D9A3),
      light: Color(0xFF4DFFCD),
      dark: Color(0xFF00A67C),
      category: 'Modern',
      icon: '🍃',
    ),
    'coral_red': AccentColorPalette(
      name: 'Coral Red',
      primary: Color(0xFFFF5370),
      light: Color(0xFFFF8BA0),
      dark: Color(0xFFE63950),
      category: 'Modern',
      icon: '🔥',
    ),
    'teal_cyan': AccentColorPalette(
      name: 'Teal Cyan',
      primary: Color(0xFF00BCD4),
      light: Color(0xFF4DD0E1),
      dark: Color(0xFF0097A7),
      category: 'Modern',
      icon: '💎',
    ),

    // Premium Colors
    'sunset_orange': AccentColorPalette(
      name: 'Sunset Orange',
      primary: Color(0xFFFF6B35),
      light: Color(0xFFFF9B6B),
      dark: Color(0xFFE65528),
      category: 'Premium',
      icon: '🌅',
    ),
    'royal_purple': AccentColorPalette(
      name: 'Royal Purple',
      primary: Color(0xFF6C63FF),
      light: Color(0xFF9B95FF),
      dark: Color(0xFF5448E6),
      category: 'Premium',
      icon: '👑',
    ),
    'electric_blue': AccentColorPalette(
      name: 'Electric Blue',
      primary: Color(0xFF536DFE),
      light: Color(0xFF8593FE),
      dark: Color(0xFF3D5AFE),
      category: 'Premium',
      icon: '⚡',
    ),

    // Sophisticated Colors
    'rose_gold': AccentColorPalette(
      name: 'Rose Gold',
      primary: Color(0xFFF4A261),
      light: Color(0xFFF7C590),
      dark: Color(0xFFE68A42),
      category: 'Sophisticated',
      icon: '✨',
    ),
    'emerald_green': AccentColorPalette(
      name: 'Emerald Green',
      primary: Color(0xFF10B981),
      light: Color(0xFF6EE7B7),
      dark: Color(0xFF059669),
      category: 'Sophisticated',
      icon: '💚',
    ),
    'neon_pink': AccentColorPalette(
      name: 'Neon Pink',
      primary: Color(0xFFFF0080),
      light: Color(0xFFFF4DA6),
      dark: Color(0xFFCC0066),
      category: 'Sophisticated',
      icon: '💗',
    ),
    'deep_indigo': AccentColorPalette(
      name: 'Deep Indigo',
      primary: Color(0xFF4F46E5),
      light: Color(0xFF8B83FF),
      dark: Color(0xFF3730A3),
      category: 'Sophisticated',
      icon: '🌌',
    ),

    // Cinema Colors
    'film_gold': AccentColorPalette(
      name: 'Film Reel Gold',
      primary: Color(0xFFD4AF37),
      light: Color(0xFFE8D174),
      dark: Color(0xFFB8941F),
      category: 'Cinema',
      icon: '🎬',
    ),
    'popcorn_yellow': AccentColorPalette(
      name: 'Popcorn Yellow',
      primary: Color(0xFFFFD700),
      light: Color(0xFFFFE44D),
      dark: Color(0xFFCCAA00),
      category: 'Cinema',
      icon: '🍿',
    ),
    'movie_red': AccentColorPalette(
      name: 'Movie Seat Red',
      primary: Color(0xFFDC143C),
      light: Color(0xFFE85C77),
      dark: Color(0xFFB00020),
      category: 'Cinema',
      icon: '🎥',
    ),
  };

  // ══════════════════════════════════════════════════════════
  // SEMANTIC COLORS (Fixed for all themes)
  // ══════════════════════════════════════════════════════════

  static const Color success = Color(0xFF00D9A3);
  static const Color warning = Color(0xFFFFB800);
  static const Color error = Color(0xFFFF5370);
  static const Color info = Color(0xFF2196F3);

  // Rating colors
  static const Color starGold = Color(0xFFFFC107);
  static const Color starRating = Color(0xFFFFC107);
  static const Color ratingGreen = Color(0xFF4CAF50);
  static const Color ratingYellow = Color(0xFFFFEB3B);
  static const Color ratingOrange = Color(0xFFFF9800);
  static const Color ratingRed = Color(0xFFF44336);

  // Quality badges
  static const Color qualityHD = Color(0xFF4CAF50);
  static const Color quality4K = Color(0xFF2196F3);
  static const Color qualityCAM = Color(0xFFFF9800);

  // Backward compatibility colors (to facilitate migration)
  static const Color primary = Color(0xFF00D9A3); // Legacy mint green
  static const Color primaryDark = Color(0xFF00A67C);
  static const Color secondary = Color(0xFF1F2937);
  static const Color background = Color(0xFF0F0F1E);
  static const Color backgroundDark = Color(0xFF0F0F1E);
  static const Color backgroundDarker = Color(0xFF0A0A0A);
  static const Color accentPurple = Color(0xFF6C63FF);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceLight = Color(0xFF2A2A40);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB4B4C8);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color divider = Color(0xFF2A2A40);
  static const Color glassBackground = Color(0x331A1A2E);
  static const Color glassBorder = Color(0x1AFFFFFF);

  // Download status
  static const Color downloadActive = Color(0xFF2196F3);
  static const Color downloadComplete = Color(0xFF4CAF50);
  static const Color downloadPaused = Color(0xFFFF9800);
  static const Color downloadFailed = Color(0xFFF44336);

  // Fallback Legacy Gradients for GradientButton
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00D9A3), Color(0xFF00A67C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient cinematicGradient = primaryGradient;
}

/// Accent color palette with light/dark variants
class AccentColorPalette {
  final String name;
  final Color primary;
  final Color light;
  final Color dark;
  final String category;
  final String? icon;

  const AccentColorPalette({
    required this.name,
    required this.primary,
    required this.light,
    required this.dark,
    required this.category,
    this.icon,
  });

  /// Create gradient from this color
  LinearGradient get gradient => LinearGradient(
    colors: [primary, dark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Create shimmer gradient
  LinearGradient get shimmerGradient => LinearGradient(
    colors: [
      primary.withValues(alpha: 0.1),
      primary.withValues(alpha: 0.3),
      primary.withValues(alpha: 0.1),
    ],
    stops: const [0.0, 0.5, 1.0],
  );
}
