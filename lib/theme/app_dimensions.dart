import 'package:flutter/material.dart';

class AppDimensions {
  // Poster ratio
  static const double posterAspectRatio = 2 / 3;

  // Padding & margins
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  static const double spacingSm = 8.0; // Alias
  static const double spacingMd = 16.0; // Alias

  // Screen padding
  static const EdgeInsets screenPadding = EdgeInsets.all(md);

  // Border radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;

  static BorderRadius defaultRadius = BorderRadius.circular(radiusMd);
}
