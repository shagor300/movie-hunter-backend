// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_preferences.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppThemeModeAdapter extends TypeAdapter<AppThemeMode> {
  @override
  final int typeId = 6;

  @override
  AppThemeMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AppThemeMode.dark;
      case 1:
        return AppThemeMode.amoled;
      case 2:
        return AppThemeMode.light;
      default:
        return AppThemeMode.dark;
    }
  }

  @override
  void write(BinaryWriter writer, AppThemeMode obj) {
    switch (obj) {
      case AppThemeMode.dark:
        writer.writeByte(0);
        break;
      case AppThemeMode.amoled:
        writer.writeByte(1);
        break;
      case AppThemeMode.light:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppThemeModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ThemePreferencesAdapter extends TypeAdapter<ThemePreferences> {
  @override
  final int typeId = 5;

  @override
  ThemePreferences read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ThemePreferences(
      themeMode: fields[0] as AppThemeMode? ?? AppThemeMode.dark,
      accentColorIndex: fields[1] as int? ?? 1,
      fontSize: fields[2] as double? ?? 14.0,
      useGridLayout: fields[3] as bool? ?? true,
      gridColumnCount: fields[4] as int? ?? 2,
      roundedPosters: fields[5] as bool? ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, ThemePreferences obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.themeMode)
      ..writeByte(1)
      ..write(obj.accentColorIndex)
      ..writeByte(2)
      ..write(obj.fontSize)
      ..writeByte(3)
      ..write(obj.useGridLayout)
      ..writeByte(4)
      ..write(obj.gridColumnCount)
      ..writeByte(5)
      ..write(obj.roundedPosters);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemePreferencesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
