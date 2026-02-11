// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DownloadAdapter extends TypeAdapter<Download> {
  @override
  final int typeId = 1;

  @override
  Download read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return Download(
      url: fields[0] as String,
      filename: fields[1] as String,
      status: fields[2] as DownloadStatus,
      progress: fields[3] as int,
      tmdbId: fields[4] as int?,
      quality: fields[5] as String?,
      movieTitle: fields[6] as String,
      taskId: fields[7] as String?,
      createdAt: fields[8] as DateTime,
      savedPath: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Download obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.url)
      ..writeByte(1)
      ..write(obj.filename)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.progress)
      ..writeByte(4)
      ..write(obj.tmdbId)
      ..writeByte(5)
      ..write(obj.quality)
      ..writeByte(6)
      ..write(obj.movieTitle)
      ..writeByte(7)
      ..write(obj.taskId)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.savedPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DownloadStatusAdapter extends TypeAdapter<DownloadStatus> {
  @override
  final int typeId = 0;

  @override
  DownloadStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DownloadStatus.queued;
      case 1:
        return DownloadStatus.downloading;
      case 2:
        return DownloadStatus.paused;
      case 3:
        return DownloadStatus.completed;
      case 4:
        return DownloadStatus.failed;
      case 5:
        return DownloadStatus.canceled;
      default:
        return DownloadStatus.queued;
    }
  }

  @override
  void write(BinaryWriter writer, DownloadStatus obj) {
    switch (obj) {
      case DownloadStatus.queued:
        writer.writeByte(0);
        break;
      case DownloadStatus.downloading:
        writer.writeByte(1);
        break;
      case DownloadStatus.paused:
        writer.writeByte(2);
        break;
      case DownloadStatus.completed:
        writer.writeByte(3);
        break;
      case DownloadStatus.failed:
        writer.writeByte(4);
        break;
      case DownloadStatus.canceled:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
