import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/theme_preferences.dart';

class ThemeController extends GetxController {
  late Box<ThemePreferences> _box;
  var preferences = ThemePreferences().obs;

  static const accentColors = [
    Colors.redAccent,
    Colors.blueAccent,
    Colors.purpleAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
  ];

  static const accentColorNames = ['Red', 'Blue', 'Purple', 'Green', 'Orange'];

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox<ThemePreferences>('theme_prefs');
    final stored = _box.get('prefs');
    if (stored != null) {
      preferences.value = stored;
    } else {
      await _box.put('prefs', preferences.value);
    }
  }

  Future<void> _save() async {
    await _box.put('prefs', preferences.value);
    preferences.refresh(); // Force Obx to rebuild
  }

  Color get accentColor =>
      accentColors[preferences.value.accentColorIndex.clamp(
        0,
        accentColors.length - 1,
      )];

  ThemeData get currentTheme {
    final prefs = preferences.value;
    final accent = accentColor;

    switch (prefs.themeMode) {
      case AppThemeMode.dark:
        return _buildTheme(
          scaffoldBg: const Color(0xFF0F0F1E),
          surfaceBg: const Color(0xFF1A1A2E),
          brightness: Brightness.dark,
          accent: accent,
          fontSize: prefs.fontSize,
        );
      case AppThemeMode.amoled:
        return _buildTheme(
          scaffoldBg: Colors.black,
          surfaceBg: const Color(0xFF0A0A0A),
          brightness: Brightness.dark,
          accent: accent,
          fontSize: prefs.fontSize,
        );
      case AppThemeMode.light:
        return _buildTheme(
          scaffoldBg: const Color(0xFFF5F5F5),
          surfaceBg: Colors.white,
          brightness: Brightness.light,
          accent: accent,
          fontSize: prefs.fontSize,
        );
    }
  }

  ThemeData _buildTheme({
    required Color scaffoldBg,
    required Color surfaceBg,
    required Brightness brightness,
    required Color accent,
    required double fontSize,
  }) {
    final isDark = brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: brightness,
        surface: surfaceBg,
      ),
      textTheme:
          GoogleFonts.poppinsTextTheme(
            (isDark ? ThemeData.dark() : ThemeData.light()).textTheme,
          ).apply(
            bodyColor: textColor,
            displayColor: textColor,
            fontSizeFactor: fontSize / 14.0,
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          fontSize: 22 * (fontSize / 14.0),
          color: textColor,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceBg,
        selectedItemColor: accent,
        unselectedItemColor: isDark ? Colors.white30 : Colors.black38,
      ),
    );
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
