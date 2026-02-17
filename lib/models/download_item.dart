import 'package:hive/hive.dart';

part 'download_item.g.dart';

@HiveType(typeId: 10)
class DownloadItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String movieTitle;

  @HiveField(2)
  String quality;

  @HiveField(3)
  String url;

  @HiveField(4)
  String filePath;

  @HiveField(5)
  String fileName;

  @HiveField(6)
  int totalBytes;

  @HiveField(7)
  int downloadedBytes;

  /// One of: pending, downloading, paused, completed, failed, cancelled
  @HiveField(8)
  String status;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime? completedAt;

  @HiveField(11)
  String? posterUrl;

  @HiveField(12)
  int tmdbId;

  DownloadItem({
    required this.id,
    required this.movieTitle,
    required this.quality,
    required this.url,
    required this.filePath,
    required this.fileName,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    this.status = 'pending',
    required this.createdAt,
    this.completedAt,
    this.posterUrl,
    this.tmdbId = 0,
  });

  double get progress => totalBytes > 0 ? downloadedBytes / totalBytes : 0;

  String get progressText => '${(progress * 100).toStringAsFixed(1)}%';

  String get fileSizeText => _formatBytes(totalBytes);

  String get downloadedText => _formatBytes(downloadedBytes);

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1 << 20) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1 << 30) {
      return '${(bytes / (1 << 20)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1 << 30)).toStringAsFixed(2)} GB';
  }
}
