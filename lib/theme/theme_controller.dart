import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';
import 'app_colors.dart';
import 'app_theme.dart';
import 'theme_config.dart';

class ThemeController extends GetxController {
  // ══════════════════════════════════════════════════════════
  // OBSERVABLE STATE
  // ══════════════════════════════════════════════════════════

  final Rx<AppThemeMode> _themeMode = AppThemeMode.dark.obs;
  // Fallback to sky_blue if royal_purple not found to gracefully initialize
  final Rx<Color> _accentColor =
      (AppColors.accentColors['royal_purple']?.primary ??
              const Color(0xFF6C63FF))
          .obs;

  AppThemeMode get themeMode => _themeMode.value;
  Color get accentColor => _accentColor.value;

  // ══════════════════════════════════════════════════════════
  // LAYOUT STATE
  // ══════════════════════════════════════════════════════════
  final RxBool _useGridLayout = true.obs;
  final RxBool _roundedPosters = true.obs;
  final RxInt _gridColumnCount = 2.obs;
  final RxDouble _fontSize = 14.0.obs;

  bool get useGridLayout => _useGridLayout.value;
  bool get roundedPosters => _roundedPosters.value;
  int get gridColumnCount => _gridColumnCount.value;
  double get fontSize => _fontSize.value;

  // Backwards compatibility getter
  bool get isDarkMode => currentThemeConfig.brightness == Brightness.dark;

  // ══════════════════════════════════════════════════════════
  // COMPUTED PROPERTIES
  // ══════════════════════════════════════════════════════════

  ThemeData get themeData =>
      AppTheme.build(mode: _themeMode.value, accentColor: _accentColor.value);

  ThemeConfig get currentThemeConfig => ThemeConfig.configs[_themeMode.value]!;

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

      // Legacy support for older boolean theme implementation
      final isLegacyDarkMode = prefs.getBool('isDarkMode');
      if (isLegacyDarkMode != null) {
        _themeMode.value = isLegacyDarkMode
            ? AppThemeMode.dark
            : AppThemeMode.light;
        // Clear legacy key to avoid conflicts down the line
        await prefs.remove('isDarkMode');
      }

      // Load theme mode (new string-based)
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

      // Load Layout Properties
      _useGridLayout.value = prefs.getBool('use_grid') ?? true;
      _roundedPosters.value = prefs.getBool('rounded_posters') ?? true;
      _gridColumnCount.value = prefs.getInt('grid_columns') ?? 2;
      _fontSize.value = prefs.getDouble('font_size') ?? 14.0;

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
      backgroundColor: color.withValues(alpha: 0.8),
      colorText: Colors.white,
    );
  }

  Future<void> setAccentColorByKey(String key) async {
    final palette = AppColors.accentColors[key];
    if (palette != null) {
      await setAccentColor(palette.primary);
    }
  }

  // Backwards compatibility for toggle
  void toggleTheme() {
    setThemeMode(isDarkMode ? AppThemeMode.light : AppThemeMode.dark);
  }

  // ══════════════════════════════════════════════════════════
  // LAYOUT CHANGING METHODS
  // ══════════════════════════════════════════════════════════

  Future<void> toggleGridLayout() async {
    _useGridLayout.value = !_useGridLayout.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_grid', _useGridLayout.value);
  }

  Future<void> toggleRoundedPosters() async {
    _roundedPosters.value = !_roundedPosters.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rounded_posters', _roundedPosters.value);
  }

  Future<void> setGridColumnCount(int count) async {
    _gridColumnCount.value = count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('grid_columns', count);
  }

  Future<void> setFontSize(double size) async {
    _fontSize.value = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_size', size);
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
      await prefs.setInt('accent_color', _accentColor.value.toARGB32());
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
      colors: [_accentColor.value, _accentColor.value.withValues(alpha: 0.7)],
    );
  }
}
