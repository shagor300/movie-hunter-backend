import 'package:hive/hive.dart';

part 'playback_position.g.dart';

@HiveType(typeId: 4)
class PlaybackPosition extends HiveObject {
  @HiveField(0)
  final int tmdbId;

  @HiveField(1)
  final String movieTitle;

  @HiveField(2)
  final String? posterUrl;

  @HiveField(3)
  int positionMs;

  @HiveField(4)
  int durationMs;

  @HiveField(5)
  DateTime lastWatched;

  @HiveField(6)
  String? videoUrl;

  @HiveField(7)
  String? localFilePath;

  PlaybackPosition({
    required this.tmdbId,
    required this.movieTitle,
    this.posterUrl,
    this.positionMs = 0,
    this.durationMs = 0,
    DateTime? lastWatched,
    this.videoUrl,
    this.localFilePath,
  }) : lastWatched = lastWatched ?? DateTime.now();

  double get progress =>
      durationMs > 0 ? (positionMs / durationMs).clamp(0.0, 1.0) : 0.0;

  String get remainingTime {
    final remaining = durationMs - positionMs;
    final minutes = (remaining / 60000).floor();
    return '${minutes}m left';
  }
}
