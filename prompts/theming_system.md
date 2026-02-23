 Premium Advanced Theming System - Complete Guide
Global Theme Implementation for MovieHub

📋 TABLE OF CONTENTS:

Theme Architecture Overview
Color System Setup
Theme Configuration
State Management
Widget Integration
Screen-by-Screen Implementation
Theme Persistence
Testing Checklist


🏗️ PART 1: THEME ARCHITECTURE
File Structure:
lib/
├── theme/
│   ├── app_colors.dart           # Color definitions
│   ├── app_text_styles.dart      # Typography
│   ├── app_dimensions.dart       # Spacing, sizes
│   ├── app_theme.dart            # ThemeData builder
│   ├── theme_controller.dart     # State management
│   └── theme_config.dart         # Theme mode definitions
├── main.dart                      # Theme setup
└── screens/
    └── settings/
        └── appearance_settings.dart  # Theme picker UI

🎨 PART 2: COLOR SYSTEM SETUP
File: lib/theme/app_colors.dart
dartimport 'package:flutter/material.dart';

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
  static const Color ratingGreen = Color(0xFF4CAF50);
  static const Color ratingYellow = Color(0xFFFFEB3B);
  static const Color ratingOrange = Color(0xFFFF9800);
  static const Color ratingRed = Color(0xFFF44336);
  
  // Quality badges
  static const Color qualityHD = Color(0xFF4CAF50);
  static const Color quality4K = Color(0xFF2196F3);
  static const Color qualityCAM = Color(0xFFFF9800);
  
  // Download status
  static const Color downloadActive = Color(0xFF2196F3);
  static const Color downloadComplete = Color(0xFF4CAF50);
  static const Color downloadPaused = Color(0xFFFF9800);
  static const Color downloadFailed = Color(0xFFF44336);
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
      primary.withOpacity(0.1),
      primary.withOpacity(0.3),
      primary.withOpacity(0.1),
    ],
    stops: const [0.0, 0.5, 1.0],
  );
}

🎭 PART 3: THEME MODE CONFIGURATION
File: lib/theme/theme_config.dart
dartimport 'package:flutter/material.dart';

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

🔧 PART 4: THEME DATA BUILDER
File: lib/theme/app_theme.dart
dartimport 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'theme_config.dart';

class AppTheme {
  /// Build complete ThemeData for app
  static ThemeData build({
    required AppThemeMode mode,
    required Color accentColor,
  }) {
    final config = ThemeConfig.configs[mode]!;
    final isDark = config.brightness == Brightness.dark;
    
    // Text colors based on brightness
    final textPrimary = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final textSecondary = isDark ? const Color(0xFFB4B4C8) : const Color(0xFF6B7280);
    final textTertiary = isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
    
    return ThemeData(
      // ══════════════════════════════════════════════════════
      // BRIGHTNESS & COLORS
      // ══════════════════════════════════════════════════════
      brightness: config.brightness,
      primaryColor: accentColor,
      scaffoldBackgroundColor: config.backgroundColor,
      cardColor: config.cardColor,
      
      colorScheme: ColorScheme(
        brightness: config.brightness,
        primary: accentColor,
        onPrimary: Colors.white,
        secondary: accentColor,
        onSecondary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        background: config.backgroundColor,
        onBackground: textPrimary,
        surface: config.surfaceColor,
        onSurface: textPrimary,
      ),
      
      // ══════════════════════════════════════════════════════
      // TYPOGRAPHY
      // ══════════════════════════════════════════════════════
      textTheme: GoogleFonts.interTextTheme().copyWith(
        // Display (largest)
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        
        // Headlines
        headlineLarge: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        
        // Titles
        titleLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleSmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        
        // Body
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textTertiary,
        ),
        
        // Labels
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textTertiary,
        ),
      ),
      
      // ══════════════════════════════════════════════════════
      // COMPONENT THEMES
      // ══════════════════════════════════════════════════════
      
      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: config.surfaceColor,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      
      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: config.surfaceColor,
        selectedItemColor: accentColor,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),
      
      // Cards
      cardTheme: CardTheme(
        color: config.cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          side: BorderSide(color: accentColor, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark 
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white24 : Colors.black26,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white24 : Colors.black26,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: textTertiary),
      ),
      
      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: config.cardColor,
        selectedColor: accentColor,
        labelStyle: GoogleFonts.inter(fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      // Divider
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white12 : Colors.black12,
        thickness: 1,
        space: 1,
      ),
      
      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return Colors.white;
          return textTertiary;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return accentColor;
          return isDark ? Colors.white24 : Colors.black26;
        }),
      ),
      
      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: accentColor,
        inactiveTrackColor: isDark ? Colors.white24 : Colors.black26,
        thumbColor: accentColor,
        overlayColor: accentColor.withOpacity(0.2),
      ),
      
      // Progress indicators
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accentColor,
      ),
      
      // Dialogs
      dialogTheme: DialogTheme(
        backgroundColor: config.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      
      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: config.surfaceColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: config.cardColor,
        contentTextStyle: GoogleFonts.inter(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

🎮 PART 5: THEME CONTROLLER (State Management)
File: lib/theme/theme_controller.dart
dartimport 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';
import 'app_theme.dart';
import 'theme_config.dart';

class ThemeController extends GetxController {
  // ══════════════════════════════════════════════════════════
  // OBSERVABLE STATE
  // ══════════════════════════════════════════════════════════
  
  final Rx<AppThemeMode> _themeMode = AppThemeMode.dark.obs;
  final Rx<Color> _accentColor = AppColors.accentColors['royal_purple']!.primary.obs;
  
  AppThemeMode get themeMode => _themeMode.value;
  Color get accentColor => _accentColor.value;
  
  // ══════════════════════════════════════════════════════════
  // COMPUTED PROPERTIES
  // ══════════════════════════════════════════════════════════
  
  ThemeData get themeData => AppTheme.build(
    mode: _themeMode.value,
    accentColor: _accentColor.value,
  );
  
  ThemeConfig get currentThemeConfig => ThemeConfig.configs[_themeMode.value]!;
  
  bool get isDarkMode => currentThemeConfig.brightness == Brightness.dark;
  
  AccentColorPalette? get currentAccentPalette {
    return AppColors.accentColors.values.firstWhereOrNull(
      (palette) => palette.primary == _accentColor.value,
    );
  }
  
  // ══════════════════════════════════════════════════════════
  // INITIALIZATION
  // ══════════════════════════════════════════════════════════
  
  @override
  void onInit() {
    super.onInit();
    _loadPreferences();
  }
  
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load theme mode
      final themeModeString = prefs.getString('theme_mode');
      if (themeModeString != null) {
        _themeMode.value = AppThemeMode.values.firstWhere(
          (mode) => mode.name == themeModeString,
          orElse: () => AppThemeMode.dark,
        );
      }
      
      // Load accent color
      final accentColorValue = prefs.getInt('accent_color');
      if (accentColorValue != null) {
        _accentColor.value = Color(accentColorValue);
      } else {
        // Use default accent for current theme if available
        final defaultAccent = currentThemeConfig.defaultAccent;
        if (defaultAccent != null) {
          _accentColor.value = defaultAccent;
        }
      }
      
      // Apply theme immediately
      Get.changeTheme(themeData);
      
    } catch (e) {
      debugPrint('Error loading theme preferences: $e');
    }
  }
  
  // ══════════════════════════════════════════════════════════
  // THEME CHANGING METHODS
  // ══════════════════════════════════════════════════════════
  
  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode.value = mode;
    
    // If theme has default accent, optionally switch to it
    final defaultAccent = ThemeConfig.configs[mode]!.defaultAccent;
    if (defaultAccent != null && _shouldUseDefaultAccent(mode)) {
      _accentColor.value = defaultAccent;
      await _saveAccentColor();
    }
    
    // Apply new theme
    Get.changeTheme(themeData);
    
    // Save preference
    await _saveThemeMode();
    
    // Show feedback
    Get.snackbar(
      'Theme Changed',
      'Switched to ${ThemeConfig.configs[mode]!.name} theme',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }
  
  Future<void> setAccentColor(Color color) async {
    _accentColor.value = color;
    
    // Apply new theme with updated accent
    Get.changeTheme(themeData);
    
    // Save preference
    await _saveAccentColor();
    
    // Show feedback
    final palette = AppColors.accentColors.values.firstWhereOrNull(
      (p) => p.primary == color,
    );
    Get.snackbar(
      'Accent Color Changed',
      palette != null ? palette.name : 'Custom color',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      backgroundColor: color.withOpacity(0.8),
      colorText: Colors.white,
    );
  }
  
  Future<void> setAccentColorByKey(String key) async {
    final palette = AppColors.accentColors[key];
    if (palette != null) {
      await setAccentColor(palette.primary);
    }
  }
  
  // ══════════════════════════════════════════════════════════
  // PERSISTENCE
  // ══════════════════════════════════════════════════════════
  
  Future<void> _saveThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_mode', _themeMode.value.name);
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }
  
  Future<void> _saveAccentColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('accent_color', _accentColor.value.value);
    } catch (e) {
      debugPrint('Error saving accent color: $e');
    }
  }
  
  // ══════════════════════════════════════════════════════════
  // HELPER METHODS
  // ══════════════════════════════════════════════════════════
  
  bool _shouldUseDefaultAccent(AppThemeMode mode) {
    // Only auto-switch accent for themes with strong identity
    return mode == AppThemeMode.netflixRed || 
           mode == AppThemeMode.sepiaVintage ||
           mode == AppThemeMode.midnightBlue;
  }
  
  /// Get all accent colors grouped by category
  Map<String, List<AccentColorPalette>> get accentColorsByCategory {
    final Map<String, List<AccentColorPalette>> grouped = {};
    
    for (final palette in AppColors.accentColors.values) {
      grouped.putIfAbsent(palette.category, () => []).add(palette);
    }
    
    return grouped;
  }
  
  /// Get gradient for current accent color
  LinearGradient get accentGradient {
    final palette = currentAccentPalette;
    if (palette != null) {
      return palette.gradient;
    }
    // Fallback gradient
    return LinearGradient(
      colors: [_accentColor.value, _accentColor.value.withOpacity(0.7)],
    );
  }
}

🚀 PART 6: MAIN.DART SETUP
File: lib/main.dart
dartimport 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'theme/theme_controller.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );
  
  // Initialize theme controller
  Get.put(ThemeController());
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    
    return Obx(() => GetMaterialApp(
      title: 'MovieHub',
      debugShowCheckedModeBanner: false,
      
      // ═══════════════════════════════════════════════════
      // THEME CONFIGURATION (Updates reactively)
      // ═══════════════════════════════════════════════════
      theme: themeController.themeData,
      themeMode: ThemeMode.dark, // Always use theme from controller
      
      // Initial route
      home: const SplashScreen(),
      
      // Default transitions
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
    ));
  }
}

🎨 PART 7: SETTINGS UI
File: lib/screens/settings/appearance_settings.dart
dartimport 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/theme_controller.dart';
import '../../theme/theme_config.dart';
import '../../theme/app_colors.dart';

class AppearanceSettings extends StatelessWidget {
  const AppearanceSettings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Mode Section
            _buildSectionHeader('🎨 THEME MODE'),
            const SizedBox(height: 16),
            _buildThemeModeSelector(themeController),
            
            const SizedBox(height: 32),
            
            // Accent Color Section
            _buildSectionHeader('🌈 ACCENT COLOR'),
            const SizedBox(height: 16),
            _buildAccentColorSelector(themeController),
            
            const SizedBox(height: 32),
            
            // Preview Section
            _buildSectionHeader('👁️ PREVIEW'),
            const SizedBox(height: 16),
            _buildPreviewCards(themeController),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: Colors.grey,
      ),
    );
  }
  
  Widget _buildThemeModeSelector(ThemeController controller) {
    return Obx(() => Wrap(
      spacing: 12,
      runSpacing: 12,
      children: ThemeConfig.configs.entries.map((entry) {
        final mode = entry.key;
        final config = entry.value;
        final isSelected = controller.themeMode == mode;
        
        return GestureDetector(
          onTap: () => controller.setThemeMode(mode),
          child: Container(
            width: (Get.width - 56) / 2, // 2 columns
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected 
                ? controller.accentColor.withOpacity(0.2)
                : Theme.of(Get.context!).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                  ? controller.accentColor
                  : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  config.icon,
                  size: 32,
                  color: isSelected 
                    ? controller.accentColor
                    : Colors.grey,
                ),
                const SizedBox(height: 8),
                Text(
                  config.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected 
                      ? controller.accentColor
                      : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  config.description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ));
  }
  
  Widget _buildAccentColorSelector(ThemeController controller) {
    final colorsByCategory = controller.accentColorsByCategory;
    
    return Column(
      children: colorsByCategory.entries.map((entry) {
        final category = entry.key;
        final colors = entry.value;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                category,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ),
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: colors.length,
                itemBuilder: (context, index) {
                  final palette = colors[index];
                  return Obx(() {
                    final isSelected = controller.accentColor == palette.primary;
                    
                    return GestureDetector(
                      onTap: () => controller.setAccentColor(palette.primary),
                      child: Container(
                        width: 70,
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: palette.gradient,
                                shape: BoxShape.circle,
                                border: isSelected
                                  ? Border.all(color: Colors.white, width: 3)
                                  : null,
                                boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: palette.primary.withOpacity(0.5),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                              ),
                              child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 28)
                                : palette.icon != null
                                  ? Center(
                                      child: Text(
                                        palette.icon!,
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      }).toList(),
    );
  }
  
  Widget _buildPreviewCards(ThemeController controller) {
    return Obx(() => Column(
      children: [
        // Button previews
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Primary Button'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                child: const Text('Outlined'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Card preview
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: controller.accentGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preview Card',
                        style: Theme.of(Get.context!).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This is how cards will look',
                        style: Theme.of(Get.context!).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.star, size: 16, color: controller.accentColor),
                          const SizedBox(width: 4),
                          Text('8.5', style: TextStyle(color: controller.accentColor)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ));
  }
}

🎬 PART 8: USING THEME IN SCREENS
Example 1: Movie Card Widget
dartimport 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/theme_controller.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  
  const MovieCard({Key? key, required this.movie}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    
    return Card(
      // Card automatically uses theme colors
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster with accent color overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  movie.posterUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              
              // Quality badge with accent color
              Positioned(
                top: 8,
                right: 8,
                child: Obx(() => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: themeController.accentColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'HD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )),
              ),
            ],
          ),
          
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title (uses theme textTheme)
                Text(
                  movie.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 4),
                
                // Rating with accent color
                Obx(() => Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: themeController.accentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${movie.rating}',
                      style: TextStyle(
                        color: themeController.accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
Example 2: Search Bar
dartclass CustomSearchBar extends StatelessWidget {
  final Function(String) onChanged;
  
  const CustomSearchBar({Key? key, required this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    
    return Obx(() => Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: TextField(
        onChanged: onChanged,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: 'Search movies...',
          hintStyle: Theme.of(context).textTheme.bodyMedium,
          prefixIcon: Icon(
            Icons.search,
            color: themeController.accentColor,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
        ),
      ),
    ));
  }
}
Example 3: Bottom Navigation
dartclass HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    
    return Scaffold(
      body: Obx(() => IndexedStack(
        index: controller.currentIndex.value,
        children: const [
          SearchScreen(),
          ForYouScreen(),
          LatestScreen(),
          LibraryScreen(),
          DownloadsScreen(),
        ],
      )),
      
      // Bottom navigation automatically uses theme
      bottomNavigationBar: Obx(() => BottomNavigationBar(
        currentIndex: controller.currentIndex.value,
        onTap: controller.changePage,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'For You',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.new_releases),
            label: 'Latest',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmarks),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.download),
            label: 'Downloads',
          ),
        ],
      )),
    );
  }
}
```

---

## ✅ **PART 9: TESTING CHECKLIST**

### **Visual Verification:**
```
□ Change theme mode in Settings
  → All screens update immediately
  → Background colors change
  → Text colors change
  → Card colors change
  
□ Change accent color in Settings
  → Bottom nav selected icon changes
  → Buttons change color
  → Progress bars change color
  → Ratings stars change color
  → Quality badges change color
  → Links change color
  
□ Test each theme mode:
  □ Dark Mode
  □ AMOLED Mode
  □ Light Mode
  □ Cinema Black
  □ Midnight Blue
  □ Charcoal Gray
  □ Netflix Red
  □ Sepia Vintage
  
□ Test each accent color:
  □ All 17 colors work
  □ Gradient buttons render correctly
  □ No color contrast issues
  
□ Test on all screens:
  □ Splash Screen
  □ Onboarding
  □ Search Tab
  □ For You Tab
  □ Latest Tab
  □ Library Tab
  □ Downloads Tab
  □ Movie Details
  □ Video Player
  □ Settings
  
□ Test transitions:
  □ Theme change is immediate
  □ No flickering
  □ No white flash
  
□ Test persistence:
  □ Close app
  □ Reopen app
  □ Theme persists
  □ Accent color persists
```

---

## 🚀 **IMPLEMENTATION STEPS:**

###   Foundation**
```
 : Create all theme files (colors, config, theme builder)
  Create theme controller with persistence
  Setup main.dart and test basic theme switching
```

###   UI Integration**
```
  Update all reusable widgets (MovieCard, buttons, etc.)
  Update all screens to use theme
  Create appearance settings UI
```

###   Polish & Test**
```
 Test all theme modes
  Test all accent colors
  Fix any issues, polish animations
```

---

## 📊 **EXPECTED RESULT:**

**After Implementation:**
```
✅ User changes theme in Settings
✅ Entire app updates instantly (all tabs, all screens)
✅ Theme persists after app restart
✅ Accent color applies to:
   - Bottom navigation
   - Buttons
   - Links
   - Progress bars
   - Ratings
   - Badges
   - Highlights
✅ All 9 theme modes work
✅ All 17 accent colors work
✅ Smooth transitions
✅ No performance impact
