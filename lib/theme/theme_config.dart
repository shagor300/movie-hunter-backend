import 'package:flutter/material.dart';

/// Theme mode options
enum AppThemeMode {
  dark,
  amoled,
  light,
  cinemaBlack,
  midnightBlue,
  charcoalGray,
  netflixRed,
  dimLight,
  sepiaVintage,
}

/// Theme configuration for each mode
class ThemeConfig {
  final String name;
  final String description;
  final IconData icon;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color cardColor;
  final Brightness brightness;
  final Color? defaultAccent; // Optional default accent for this theme

  const ThemeConfig({
    required this.name,
    required this.description,
    required this.icon,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.cardColor,
    required this.brightness,
    this.defaultAccent,
  });

  static const Map<AppThemeMode, ThemeConfig> configs = {
    AppThemeMode.dark: ThemeConfig(
      name: 'Dark',
      description: 'Standard dark theme',
      icon: Icons.dark_mode,
      backgroundColor: Color(0xFF0F0F1E),
      surfaceColor: Color(0xFF1A1A2E),
      cardColor: Color(0xFF16213E),
      brightness: Brightness.dark,
    ),

    AppThemeMode.amoled: ThemeConfig(
      name: 'AMOLED',
      description: 'Pure black for OLED displays',
      icon: Icons.brightness_2,
      backgroundColor: Color(0xFF000000),
      surfaceColor: Color(0xFF0A0A0A),
      cardColor: Color(0xFF121212),
      brightness: Brightness.dark,
    ),

    AppThemeMode.light: ThemeConfig(
      name: 'Light',
      description: 'Bright and clean',
      icon: Icons.light_mode,
      backgroundColor: Color(0xFFF5F5F5),
      surfaceColor: Color(0xFFFFFFFF),
      cardColor: Color(0xFFFFFFFF),
      brightness: Brightness.light,
    ),

    AppThemeMode.cinemaBlack: ThemeConfig(
      name: 'Cinema Black',
      description: 'Theater-inspired darkness',
      icon: Icons.theaters,
      backgroundColor: Color(0xFF0A0A0F),
      surfaceColor: Color(0xFF15151F),
      cardColor: Color(0xFF1A1A23),
      brightness: Brightness.dark,
    ),

    AppThemeMode.midnightBlue: ThemeConfig(
      name: 'Midnight Blue',
      description: 'Deep blue for eye comfort',
      icon: Icons.nightlight,
      backgroundColor: Color(0xFF0F1419),
      surfaceColor: Color(0xFF192734),
      cardColor: Color(0xFF1E2D3C),
      brightness: Brightness.dark,
      defaultAccent: Color(0xFF536DFE), // Electric Blue
    ),

    AppThemeMode.charcoalGray: ThemeConfig(
      name: 'Charcoal Gray',
      description: 'Professional balanced contrast',
      icon: Icons.gradient,
      backgroundColor: Color(0xFF1E1E1E),
      surfaceColor: Color(0xFF2D2D2D),
      cardColor: Color(0xFF3C3C3C),
      brightness: Brightness.dark,
    ),

    AppThemeMode.netflixRed: ThemeConfig(
      name: 'Netflix Red',
      description: 'Familiar streaming vibe',
      icon: Icons.movie,
      backgroundColor: Color(0xFF141414),
      surfaceColor: Color(0xFF1F1F1F),
      cardColor: Color(0xFF232323),
      brightness: Brightness.dark,
      defaultAccent: Color(0xFFE50914), // Netflix red
    ),

    AppThemeMode.dimLight: ThemeConfig(
      name: 'Dim Light',
      description: 'Gentle light mode',
      icon: Icons.wb_sunny_outlined,
      backgroundColor: Color(0xFFF0F0F0),
      surfaceColor: Color(0xFFFAFAFA),
      cardColor: Color(0xFFFFFFFF),
      brightness: Brightness.light,
    ),

    AppThemeMode.sepiaVintage: ThemeConfig(
      name: 'Sepia Vintage',
      description: 'Classic film-inspired',
      icon: Icons.camera_roll,
      backgroundColor: Color(0xFF2B2520),
      surfaceColor: Color(0xFF3D342E),
      cardColor: Color(0xFF4A3F38),
      brightness: Brightness.dark,
      defaultAccent: Color(0xFFD4A574), // Sepia gold
    ),
  };
}
