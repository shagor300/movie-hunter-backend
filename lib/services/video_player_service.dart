import 'package:hive/hive.dart';
import '../models/playback_position.dart';

class VideoPlayerService {
  static final VideoPlayerService _instance = VideoPlayerService._internal();
  factory VideoPlayerService() => _instance;
  VideoPlayerService._internal();

  late Box<PlaybackPosition> _box;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _box = await Hive.openBox<PlaybackPosition>('playback_positions');
    _initialized = true;
  }

  Future<void> savePosition({
    required int tmdbId,
    required String movieTitle,
    String? posterUrl,
    required int positionMs,
    required int durationMs,
    String? videoUrl,
    String? localFilePath,
  }) async {
    // Don't save if near the end (>95% complete)
    if (durationMs > 0 && positionMs / durationMs > 0.95) {
      // Mark as completed — remove from continue watching
      await _box.delete(tmdbId);
      return;
    }

    // Don't save if less than 30 seconds watched
    if (positionMs < 30000) return;

    final existing = _box.get(tmdbId);
    if (existing != null) {
      existing.positionMs = positionMs;
      existing.durationMs = durationMs;
      existing.lastWatched = DateTime.now();
      existing.videoUrl = videoUrl ?? existing.videoUrl;
      existing.localFilePath = localFilePath ?? existing.localFilePath;
      await existing.save();
    } else {
      final position = PlaybackPosition(
        tmdbId: tmdbId,
        movieTitle: movieTitle,
        posterUrl: posterUrl,
        positionMs: positionMs,
        durationMs: durationMs,
        videoUrl: videoUrl,
        localFilePath: localFilePath,
      );
      await _box.put(tmdbId, position);
    }
  }

  PlaybackPosition? getPosition(int tmdbId) {
    return _box.get(tmdbId);
  }

  List<PlaybackPosition> getContinueWatching() {
    return _box.values.toList()
      ..sort((a, b) => b.lastWatched.compareTo(a.lastWatched));
  }

  Future<void> removePosition(int tmdbId) async {
    await _box.delete(tmdbId);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }

  Box<PlaybackPosition> get box => _box;
}
