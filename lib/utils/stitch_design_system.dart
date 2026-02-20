import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

// ─────────────────────────────────────────────────────────────
//  Stitch Design System — Extracted from Google Stitch designs
// ─────────────────────────────────────────────────────────────

/// All Stitch color constants
class StitchColors {
  StitchColors._();

  // Primary
  static const Color emerald = Color(0xFF13ECC8);
  static const Color emeraldDark = Color(0xFF06B6D4);

  // Backgrounds
  static const Color bgDark = Color(0xFF0F0F1E);
  static const Color bgAlt = Color(0xFF101A22);
  static const Color surfaceDark = Color(0xFF1A1A2E);

  // Splash
  static const Color splashTop = Color(0xFF0F0F1E);
  static const Color splashBottom = Color(0xFF2C2C54);

  // Glass
  static const Color glassBackground = Color(0x0DFFFFFF); // 5%
  static const Color glassBorder = Color(0x1AFFFFFF); // 10%
  static const Color glassHeader = Color(0xCC101A22); // 80%
  static const Color glassNav = Color(0xCC0F0F1E); // 80%

  // Text
  static const Color textPrimary = Color(0xFFF1F5F9); // slate-100
  static const Color textSecondary = Color(0xFF94A3B8); // slate-400
  static const Color textTertiary = Color(0xFF64748B); // slate-500

  // Misc
  static const Color slateChip = Color(0xFF1E293B); // slate-800
  static const Color slateChipBorder = Color(0xFF334155); // slate-700
  static const Color yellowStar = Color(0xFFFACC15);
  static const Color redDanger = Color(0xFFEF4444);
  static const Color greenComplete = Color(0xFF34D399); // emerald-400

  // Accent palette (for Settings accent picker)
  static const List<Color> accentPalette = [
    emerald, // Emerald (default)
    Color(0xFF1E94F6), // Blue
    Color(0xFFA855F7), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFFF59E0B), // Amber
  ];

  static const List<String> accentNames = [
    'Emerald',
    'Blue',
    'Purple',
    'Pink',
    'Amber',
  ];
}

/// Gradient definitions
class StitchGradients {
  StitchGradients._();

  static const LinearGradient accent = LinearGradient(
    colors: [StitchColors.emerald, StitchColors.emeraldDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splash = LinearGradient(
    colors: [StitchColors.splashTop, StitchColors.splashBottom],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient progressBar = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF1E94F6)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient splashProgress = LinearGradient(
    colors: [StitchColors.emerald, Color(0xFF8B5CF6)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static LinearGradient heroFade = LinearGradient(
    colors: [
      StitchColors.bgAlt,
      StitchColors.bgAlt.withValues(alpha: 0.4),
      Colors.transparent,
    ],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  static LinearGradient posterFade = LinearGradient(
    colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );
}

/// Typography helpers
class StitchText {
  StitchText._();

  static TextStyle display({
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.w700,
    Color color = StitchColors.textPrimary,
    double letterSpacing = -0.5,
  }) => GoogleFonts.plusJakartaSans(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
  );

  static TextStyle heading({
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w700,
    Color color = StitchColors.textPrimary,
  }) => GoogleFonts.plusJakartaSans(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: -0.3,
  );

  static TextStyle body({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Color color = StitchColors.textPrimary,
  }) => GoogleFonts.plusJakartaSans(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
  );

  static TextStyle caption({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w500,
    Color color = StitchColors.textSecondary,
  }) => GoogleFonts.plusJakartaSans(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
  );

  static TextStyle sectionLabel({Color color = StitchColors.textSecondary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 1.5,
      );

  /// Movie titles use Poppins per Stitch
  static TextStyle movieTitle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w600,
    Color color = StitchColors.textPrimary,
  }) => GoogleFonts.poppins(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
  );
}

// ─────────────────────────────────────────────────────
//  Reusable Widgets
// ─────────────────────────────────────────────────────

/// Glassmorphism card container
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? backgroundColor;
  final double blurAmount;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.backgroundColor,
    this.blurAmount = 12,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor ?? StitchColors.glassBackground,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: StitchColors.glassBorder, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Stitch-style filter chip
class StitchChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const StitchChip({
    super.key,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? StitchColors.emerald : StitchColors.slateChip,
          borderRadius: BorderRadius.circular(9999),
          border: isActive
              ? null
              : Border.all(color: StitchColors.slateChipBorder, width: 1),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? Colors.white : StitchColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Gradient progress bar
class StitchProgressBar extends StatelessWidget {
  final double progress; // 0.0 - 1.0
  final double height;
  final Gradient? gradient;
  final bool showGlow;

  const StitchProgressBar({
    super.key,
    required this.progress,
    this.height = 4,
    this.gradient,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: StitchColors.slateChip,
        borderRadius: BorderRadius.circular(height),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient ?? StitchGradients.progressBar,
            borderRadius: BorderRadius.circular(height),
            boxShadow: showGlow
                ? [
                    BoxShadow(
                      color: StitchColors.emerald.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 0),
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}

/// Skeleton loader with shimmer
class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: StitchColors.slateChip,
      highlightColor: StitchColors.slateChipBorder,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: StitchColors.slateChip,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Skeleton for a poster card (2:3 ratio)
class PosterSkeleton extends StatelessWidget {
  final double width;

  const PosterSkeleton({super.key, this.width = 140});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(width: width, height: width * 1.5, borderRadius: 12),
          const SizedBox(height: 8),
          SkeletonLoader(width: width * 0.8, height: 14),
          const SizedBox(height: 4),
          SkeletonLoader(width: width * 0.5, height: 12),
        ],
      ),
    );
  }
}

/// Rating badge (star + number)
class RatingBadge extends StatelessWidget {
  final double rating;
  final double fontSize;

  const RatingBadge({super.key, required this.rating, this.fontSize = 10});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            color: StitchColors.yellowStar,
            size: fontSize + 2,
          ),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: GoogleFonts.plusJakartaSans(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quality tag badge (4K, HD, etc.)
class QualityBadge extends StatelessWidget {
  final String label;
  final bool isPrimary;

  const QualityBadge({super.key, required this.label, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isPrimary
            ? StitchColors.emerald
            : Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
