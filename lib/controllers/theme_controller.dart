import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:hive_flutter/hive_flutter.dart';
import '../models/theme_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class ThemeController extends GetxController {
  Box<ThemePreferences>? _box;
  var preferences = ThemePreferences().obs;
  var isReady = false.obs;

  static const List<Color> accentColors = [
    AppColors.primary, // Emerald (default)
    Color(0xFF1E94F6), // Blue
    Color(0xFFA855F7), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFFF59E0B), // Amber
  ];

  static const List<String> accentColorNames = [
    'Emerald',
    'Blue',
    'Purple',
    'Pink',
    'Amber',
  ];

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    try {
      _box = await Hive.openBox<ThemePreferences>('theme_prefs');
      final stored = _box!.get('prefs');
      if (stored != null) {
        preferences.value = stored;
      } else {
        // Default accent index 0 = Emerald
        preferences.value.accentColorIndex = 0;
        await _box!.put('prefs', preferences.value);
      }
      isReady.value = true;
      debugPrint('✅ ThemeController: Hive box ready');
    } catch (e) {
      debugPrint('❌ ThemeController init error: $e');
      // Still mark as ready so the app can render with defaults
      isReady.value = true;
    }
  }

  Future<void> _save() async {
    if (_box == null || !(_box?.isOpen ?? false)) return;
    await _box!.put('prefs', preferences.value);
    preferences.refresh(); // Force Obx to rebuild
  }

  Color get accentColor =>
      accentColors[preferences.value.accentColorIndex.clamp(
        0,
        accentColors.length - 1,
      )];

  ThemeData get currentTheme {
    switch (preferences.value.themeMode) {
      case AppThemeMode.light:
        return AppTheme.lightTheme;
      case AppThemeMode.amoled:
        return AppTheme.amoledTheme;
      default:
        return AppTheme.darkTheme;
    }
  }

  // Setters
  void setThemeMode(AppThemeMode mode) {
    preferences.value.themeMode = mode;
    _save();
  }

  void setAccentColor(int index) {
    preferences.value.accentColorIndex = index.clamp(
      0,
      accentColors.length - 1,
    );
    _save();
  }

  void setFontSize(double size) {
    preferences.value.fontSize = size.clamp(10.0, 20.0);
    _save();
  }

  void toggleGridLayout() {
    preferences.value.useGridLayout = !preferences.value.useGridLayout;
    _save();
  }

  void setGridColumnCount(int count) {
    preferences.value.gridColumnCount = count.clamp(2, 4);
    _save();
  }

  void toggleRoundedPosters() {
    preferences.value.roundedPosters = !preferences.value.roundedPosters;
    _save();
  }
}
