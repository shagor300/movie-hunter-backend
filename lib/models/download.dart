import 'package:hive/hive.dart';

part 'download.g.dart';

@HiveType(typeId: 0)
enum DownloadStatus {
  @HiveField(0)
  queued,

  @HiveField(1)
  downloading,

  @HiveField(2)
  paused,

  @HiveField(3)
  completed,

  @HiveField(4)
  failed,

  @HiveField(5)
  canceled,
}

@HiveType(typeId: 1)
class Download extends HiveObject {
  @HiveField(0)
  final String url;

  @HiveField(1)
  final String filename;

  @HiveField(2)
  DownloadStatus status;

  @HiveField(3)
  int progress;

  @HiveField(4)
  final int? tmdbId;

  @HiveField(5)
  final String? quality;

  @HiveField(6)
  final String movieTitle;

  @HiveField(7)
  String? taskId;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  String? savedPath;

  Download({
    required this.url,
    required this.filename,
    this.status = DownloadStatus.queued,
    this.progress = 0,
    this.tmdbId,
    this.quality,
    required this.movieTitle,
    this.taskId,
    DateTime? createdAt,
    this.savedPath,
  }) : createdAt = createdAt ?? DateTime.now();
}
