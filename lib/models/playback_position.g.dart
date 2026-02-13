// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playback_position.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlaybackPositionAdapter extends TypeAdapter<PlaybackPosition> {
  @override
  final int typeId = 4;

  @override
  PlaybackPosition read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlaybackPosition(
      tmdbId: fields[0] as int,
      movieTitle: fields[1] as String,
      posterUrl: fields[2] as String?,
      positionMs: fields[3] as int,
      durationMs: fields[4] as int,
      lastWatched: fields[5] as DateTime?,
      videoUrl: fields[6] as String?,
      localFilePath: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PlaybackPosition obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.tmdbId)
      ..writeByte(1)
      ..write(obj.movieTitle)
      ..writeByte(2)
      ..write(obj.posterUrl)
      ..writeByte(3)
      ..write(obj.positionMs)
      ..writeByte(4)
      ..write(obj.durationMs)
      ..writeByte(5)
      ..write(obj.lastWatched)
      ..writeByte(6)
      ..write(obj.videoUrl)
      ..writeByte(7)
      ..write(obj.localFilePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaybackPositionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
