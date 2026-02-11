import 'package:hive/hive.dart';

part 'theme_preferences.g.dart';

@HiveType(typeId: 6)
enum AppThemeMode {
  @HiveField(0)
  dark,

  @HiveField(1)
  amoled,

  @HiveField(2)
  light,
}

@HiveType(typeId: 5)
class ThemePreferences extends HiveObject {
  @HiveField(0)
  AppThemeMode themeMode;

  @HiveField(1)
  int accentColorIndex;

  @HiveField(2)
  double fontSize;

  @HiveField(3)
  bool useGridLayout;

  @HiveField(4)
  int gridColumnCount;

  @HiveField(5)
  bool roundedPosters;

  ThemePreferences({
    this.themeMode = AppThemeMode.dark,
    this.accentColorIndex = 1, // Blue default
    this.fontSize = 14.0,
    this.useGridLayout = true,
    this.gridColumnCount = 2,
    this.roundedPosters = true,
  });
}
