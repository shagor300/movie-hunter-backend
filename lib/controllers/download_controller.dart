import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/download.dart';
import '../services/download_service.dart';
import '../services/api_service.dart';

class DownloadController extends GetxController {
  final DownloadService _service = DownloadService();
  final ApiService _apiService = ApiService();

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

  /// Start download with Stage 2 deep link resolution.
  ///
  /// Flow:
  /// 1. Show "Resolving…" dialog
  /// 2. POST to backend /api/resolve-download-link
  /// 3. Backend automates HubDrive steps (click, countdown, extract)
  /// 4. Enqueue the resolved direct URL with flutter_downloader
  Future<void> startDownload({
    required String url,
    required String filename,
    int? tmdbId,
    String? quality,
    required String movieTitle,
  }) async {
    // Show resolving dialog
    Get.dialog(
      PopScope(
        canPop: false,
        child: Center(
          child: Card(
            color: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.blueAccent),
                  const SizedBox(height: 20),
                  Text(
                    'Resolving download link…',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This may take up to 60 seconds',
                    style: TextStyle(fontSize: 12, color: Colors.white38),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      // Step 1: Resolve the intermediate URL
      final resolved = await _apiService.resolveDownloadLink(
        url: url,
        quality: quality ?? '1080p',
      );

      // Close loading dialog
      if (Get.isDialogOpen ?? false) Get.back();

      if (resolved['success'] != true) {
        Get.snackbar(
          'Resolution Failed',
          resolved['error']?.toString() ?? 'Could not extract download link',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(20),
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.error_outline, color: Colors.white),
        );
        return;
      }

      // Step 2: Use the resolved direct URL
      final directUrl = resolved['directUrl'] as String;
      final resolvedFilename = (resolved['filename'] as String?) ?? filename;

      debugPrint('✅ Resolved URL: $directUrl');
      debugPrint('📄 Filename: $resolvedFilename');

      await _service.startDownload(
        url: directUrl,
        filename: resolvedFilename,
        tmdbId: tmdbId,
        quality: quality,
        movieTitle: movieTitle,
      );
      _loadDownloads();

      Get.snackbar(
        'Download Started',
        '$movieTitle${quality != null ? ' - $quality' : ''}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.85),
        colorText: Colors.white,
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.download_done, color: Colors.white),
      );
    } catch (e) {
      // Close dialog if still open
      if (Get.isDialogOpen ?? false) Get.back();

      debugPrint('❌ Download error: $e');
      Get.snackbar(
        'Download Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      );
    }
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
