import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/theme_controller.dart';

/// Adaptive glass blur levels — adjusts blur intensity based on context.
enum GlassLevel {
  /// Heavy blur (20σ) — nav bars, persistent headers
  heavy,

  /// Medium blur (12σ) — bottom sheets, dialogs, overlays
  medium,

  /// Subtle blur (6σ) — cards, badges, inline elements
  subtle,

  /// No blur — just tinted background, for performance
  none,
}

/// A premium glassmorphism container that adapts its blur
/// based on [GlassLevel] and accent color.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final GlassLevel level;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? tintColor;
  final double borderOpacity;
  final bool showBorder;
  final List<BoxShadow>? boxShadow;

  const GlassContainer({
    super.key,
    required this.child,
    this.level = GlassLevel.medium,
    this.borderRadius,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.tintColor,
    this.borderOpacity = 0.08,
    this.showBorder = true,
    this.boxShadow,
  });

  double get _sigma => switch (level) {
    GlassLevel.heavy => 20.0,
    GlassLevel.medium => 12.0,
    GlassLevel.subtle => 6.0,
    GlassLevel.none => 0.0,
  };

  double get _tintOpacity => switch (level) {
    GlassLevel.heavy => 0.75,
    GlassLevel.medium => 0.6,
    GlassLevel.subtle => 0.4,
    GlassLevel.none => 0.85,
  };

  @override
  Widget build(BuildContext context) {
    final tc = Get.find<ThemeController>();
    final radius = borderRadius ?? BorderRadius.circular(16);
    final bg = tintColor ?? tc.currentThemeConfig.surfaceColor;

    final decoration = BoxDecoration(
      color: bg.withValues(alpha: _tintOpacity),
      borderRadius: radius,
      border: showBorder
          ? Border.all(
              color: Colors.white.withValues(alpha: borderOpacity),
              width: 1,
            )
          : null,
      boxShadow: boxShadow,
    );

    // If no blur needed, skip costly BackdropFilter
    if (level == GlassLevel.none) {
      return Container(
        width: width,
        height: height,
        margin: margin,
        padding: padding,
        decoration: decoration,
        child: child,
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: _sigma, sigmaY: _sigma),
          child: Container(
            padding: padding,
            decoration: decoration,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A small glass badge — for ratings, quality labels, counts.
class GlassBadge extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  const GlassBadge({super.key, required this.child, this.color, this.padding});

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? Colors.white;
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.2),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
