import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/playback_position.dart';
import '../services/video_player_service.dart';

class VideoPlayerGetxController extends GetxController {
  final VideoPlayerService _service = VideoPlayerService();

  var continueWatching = <PlaybackPosition>[].obs;
  var isInitialized = false.obs;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    await _service.init();
    _load();
    _service.box.listenable().addListener(_load);
    isInitialized.value = true;
  }

  void _load() {
    continueWatching.assignAll(_service.getContinueWatching());
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
    await _service.savePosition(
      tmdbId: tmdbId,
      movieTitle: movieTitle,
      posterUrl: posterUrl,
      positionMs: positionMs,
      durationMs: durationMs,
      videoUrl: videoUrl,
      localFilePath: localFilePath,
    );
    _load();
  }

  PlaybackPosition? getPosition(int tmdbId) {
    return _service.getPosition(tmdbId);
  }

  Future<void> removePosition(int tmdbId) async {
    await _service.removePosition(tmdbId);
    _load();
  }

  @override
  void onClose() {
    _service.box.listenable().removeListener(_load);
    super.onClose();
  }
}
