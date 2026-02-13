import 'dart:async';
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

  // ── Real-time speed / ETA tracking ──
  Timer? _refreshTimer;
  final Map<String, int> _lastProgress = {};
  final Map<String, DateTime> _lastUpdateTime = {};
  final Map<String, double> _speeds = {}; // bytes per second
  final Map<String, String> _etas = {};

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

    // Start periodic refresh for active downloads
    _startRefreshTimer();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _loadDownloads();
      _updateSpeedAndETA();
      // Stop timer if no active downloads
      if (activeDownloads.isEmpty) {
        _refreshTimer?.cancel();
        _refreshTimer = null;
      }
    });
  }

  void _ensureTimerRunning() {
    if (_refreshTimer == null || !_refreshTimer!.isActive) {
      _startRefreshTimer();
    }
  }

  void _loadDownloads() {
    downloads.assignAll(_service.getAllDownloads());
  }

  void _updateSpeedAndETA() {
    final now = DateTime.now();
    for (final d in downloads) {
      if (d.taskId == null) continue;
      if (d.status != DownloadStatus.downloading) continue;

      final taskId = d.taskId!;
      final prevProgress = _lastProgress[taskId];
      final prevTime = _lastUpdateTime[taskId];

      if (prevProgress != null &&
          prevTime != null &&
          d.progress > prevProgress) {
        final elapsed = now.difference(prevTime).inMilliseconds / 1000.0;
        if (elapsed > 0) {
          // Estimate: assume ~500 MB average file size if unknown
          const estimatedTotalBytes = 500 * 1024 * 1024;
          final progressDelta = (d.progress - prevProgress) / 100.0;
          final bytesDownloaded = progressDelta * estimatedTotalBytes;
          final speed = bytesDownloaded / elapsed;

          // Smooth the speed with exponential moving average
          final oldSpeed = _speeds[taskId] ?? speed;
          _speeds[taskId] = oldSpeed * 0.3 + speed * 0.7;

          // Calculate ETA
          final remaining = (100 - d.progress) / 100.0 * estimatedTotalBytes;
          final etaSeconds = _speeds[taskId]! > 0
              ? remaining / _speeds[taskId]!
              : 0;
          _etas[taskId] = _formatETA(etaSeconds.round());
        }
      }

      _lastProgress[taskId] = d.progress;
      _lastUpdateTime[taskId] = now;
    }
  }

  String _formatETA(int seconds) {
    if (seconds <= 0) return '--';
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${(seconds / 60).round()}m ${seconds % 60}s';
    return '${(seconds / 3600).round()}h ${((seconds % 3600) / 60).round()}m';
  }

  /// Get download speed as a human-readable string
  String getSpeedText(String? taskId) {
    if (taskId == null) return '--';
    final speed = _speeds[taskId];
    if (speed == null || speed <= 0) return '--';
    if (speed >= 1024 * 1024) {
      return '${(speed / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    } else if (speed >= 1024) {
      return '${(speed / 1024).toStringAsFixed(0)} KB/s';
    }
    return '${speed.toStringAsFixed(0)} B/s';
  }

  /// Get ETA as a human-readable string
  String getETAText(String? taskId) {
    if (taskId == null) return '--';
    return _etas[taskId] ?? '--';
  }

  /// Start download with Stage 2 deep link resolution.
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
      _ensureTimerRunning();

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
    _ensureTimerRunning();
  }

  Future<void> cancelDownload(Download download) async {
    await _service.cancelDownload(download);
    // Clean up tracking for this task
    if (download.taskId != null) {
      _lastProgress.remove(download.taskId);
      _lastUpdateTime.remove(download.taskId);
      _speeds.remove(download.taskId);
      _etas.remove(download.taskId);
    }
    _loadDownloads();
  }

  Future<void> retryDownload(Download download) async {
    await _service.retryDownload(download);
    _loadDownloads();
    _ensureTimerRunning();
  }

  Future<void> deleteDownload(Download download) async {
    if (download.taskId != null) {
      _lastProgress.remove(download.taskId);
      _lastUpdateTime.remove(download.taskId);
      _speeds.remove(download.taskId);
      _etas.remove(download.taskId);
    }
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
    _refreshTimer?.cancel();
    _service.box.listenable().removeListener(_loadDownloads);
    super.onClose();
  }
}
