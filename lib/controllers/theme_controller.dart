import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/theme_preferences.dart';
import '../utils/stitch_design_system.dart';

class ThemeController extends GetxController {
  Box<ThemePreferences>? _box;
  var preferences = ThemePreferences().obs;
  var isReady = false.obs;

  /// Accent colors from Stitch design system
  static const accentColors = StitchColors.accentPalette;
  static const accentColorNames = StitchColors.accentNames;

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
    final prefs = preferences.value;
    final accent = accentColor;

    switch (prefs.themeMode) {
      case AppThemeMode.dark:
        return _buildTheme(
          scaffoldBg: StitchColors.bgDark, // #0F0F1E
          surfaceBg: StitchColors.bgAlt, // #101A22
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
          scaffoldBg: const Color(0xFFF5F7F8), // Stitch light BG
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
    final textColor = isDark ? StitchColors.textPrimary : Colors.black87;

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: brightness,
        surface: surfaceBg,
        primary: accent,
      ),
      // Plus Jakarta Sans — Stitch primary font
      textTheme:
          GoogleFonts.plusJakartaSansTextTheme(
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
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 22 * (fontSize / 14.0),
          color: textColor,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceBg,
        selectedItemColor: accent,
        unselectedItemColor: isDark
            ? StitchColors.textTertiary
            : Colors.black38,
      ),
      // Stitch-style elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: StitchColors.bgDark,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      // Stitch-style switches
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? accent
              : Colors.white.withValues(alpha: 0.1),
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
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
