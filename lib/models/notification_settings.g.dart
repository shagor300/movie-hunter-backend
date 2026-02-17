// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationSettingsAdapter extends TypeAdapter<NotificationSettings> {
  @override
  final int typeId = 8;

  @override
  NotificationSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationSettings(
      masterEnabled: fields[0] as bool,
      downloadComplete: fields[1] as bool,
      downloadFailed: fields[2] as bool,
      storageLow: fields[3] as bool,
      appUpdate: fields[4] as bool,
      criticalUpdate: fields[5] as bool,
      resumeWatching: fields[6] as bool,
      newMoviesDaily: fields[7] as bool,
      weeklyTrending: fields[8] as bool,
      watchlistAvailable: fields[9] as bool,
      qualityUpgraded: fields[10] as bool,
      cacheCleared: fields[11] as bool,
      syncComplete: fields[12] as bool,
      quietHoursEnabled: fields[13] as bool,
      quietStartHour: fields[14] as int,
      quietStartMinute: fields[15] as int,
      quietEndHour: fields[16] as int,
      quietEndMinute: fields[17] as int,
      dailyNotifHour: fields[18] as int,
      dailyNotifMinute: fields[19] as int,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationSettings obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.masterEnabled)
      ..writeByte(1)
      ..write(obj.downloadComplete)
      ..writeByte(2)
      ..write(obj.downloadFailed)
      ..writeByte(3)
      ..write(obj.storageLow)
      ..writeByte(4)
      ..write(obj.appUpdate)
      ..writeByte(5)
      ..write(obj.criticalUpdate)
      ..writeByte(6)
      ..write(obj.resumeWatching)
      ..writeByte(7)
      ..write(obj.newMoviesDaily)
      ..writeByte(8)
      ..write(obj.weeklyTrending)
      ..writeByte(9)
      ..write(obj.watchlistAvailable)
      ..writeByte(10)
      ..write(obj.qualityUpgraded)
      ..writeByte(11)
      ..write(obj.cacheCleared)
      ..writeByte(12)
      ..write(obj.syncComplete)
      ..writeByte(13)
      ..write(obj.quietHoursEnabled)
      ..writeByte(14)
      ..write(obj.quietStartHour)
      ..writeByte(15)
      ..write(obj.quietStartMinute)
      ..writeByte(16)
      ..write(obj.quietEndHour)
      ..writeByte(17)
      ..write(obj.quietEndMinute)
      ..writeByte(18)
      ..write(obj.dailyNotifHour)
      ..writeByte(19)
      ..write(obj.dailyNotifMinute);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
