import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/download.dart';
import '../services/download_service.dart';

class DownloadController extends GetxController {
  final DownloadService _service = DownloadService();

  var downloads = <Download>[].obs;
  var isInitialized = false.obs;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    await _service.init();
    _loadDownloads();

    // Listen for Hive box changes to keep UI reactive
    _service.box.listenable().addListener(_loadDownloads);
    isInitialized.value = true;
  }

  void _loadDownloads() {
    downloads.assignAll(_service.getAllDownloads());
  }

  Future<void> startDownload({
    required String url,
    required String filename,
    int? tmdbId,
    String? quality,
    required String movieTitle,
  }) async {
    await _service.startDownload(
      url: url,
      filename: filename,
      tmdbId: tmdbId,
      quality: quality,
      movieTitle: movieTitle,
    );
    _loadDownloads();
  }

  Future<void> pauseDownload(Download download) async {
    await _service.pauseDownload(download);
    _loadDownloads();
  }

  Future<void> resumeDownload(Download download) async {
    await _service.resumeDownload(download);
    _loadDownloads();
  }

  Future<void> cancelDownload(Download download) async {
    await _service.cancelDownload(download);
    _loadDownloads();
  }

  Future<void> retryDownload(Download download) async {
    await _service.retryDownload(download);
    _loadDownloads();
  }

  Future<void> deleteDownload(Download download) async {
    await _service.deleteDownload(download);
    _loadDownloads();
  }

  List<Download> get activeDownloads => downloads
      .where(
        (d) =>
            d.status == DownloadStatus.downloading ||
            d.status == DownloadStatus.queued ||
            d.status == DownloadStatus.paused,
      )
      .toList();

  List<Download> get completedDownloads =>
      downloads.where((d) => d.status == DownloadStatus.completed).toList();

  @override
  void onClose() {
    _service.box.listenable().removeListener(_loadDownloads);
    super.onClose();
  }
}
