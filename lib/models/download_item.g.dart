// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DownloadItemAdapter extends TypeAdapter<DownloadItem> {
  @override
  final int typeId = 10;

  @override
  DownloadItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DownloadItem(
      id: fields[0] as String,
      movieTitle: fields[1] as String,
      quality: fields[2] as String,
      url: fields[3] as String,
      filePath: fields[4] as String,
      fileName: fields[5] as String,
      totalBytes: fields[6] as int,
      downloadedBytes: fields[7] as int,
      status: fields[8] as String,
      createdAt: fields[9] as DateTime,
      completedAt: fields[10] as DateTime?,
      posterUrl: fields[11] as String?,
      tmdbId: fields[12] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DownloadItem obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.movieTitle)
      ..writeByte(2)
      ..write(obj.quality)
      ..writeByte(3)
      ..write(obj.url)
      ..writeByte(4)
      ..write(obj.filePath)
      ..writeByte(5)
      ..write(obj.fileName)
      ..writeByte(6)
      ..write(obj.totalBytes)
      ..writeByte(7)
      ..write(obj.downloadedBytes)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.completedAt)
      ..writeByte(11)
      ..write(obj.posterUrl)
      ..writeByte(12)
      ..write(obj.tmdbId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
