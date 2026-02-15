import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/download.dart';
import '../services/download_service.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

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
  final Map<String, DownloadStatus> _prevStatuses = {};

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
    final newList = _service.getAllDownloads();

    // Detect status transitions for notifications
    for (final d in newList) {
      if (d.taskId == null) continue;
      final prev = _prevStatuses[d.taskId!];
      if (prev != null && prev != d.status) {
        if (d.status == DownloadStatus.completed) {
          NotificationService.instance.showDownloadComplete(
            d.movieTitle,
            d.quality ?? 'HD',
            'Download complete',
          );
        } else if (d.status == DownloadStatus.failed) {
          NotificationService.instance.showDownloadFailed(
            d.movieTitle,
            'Download failed. Tap to retry.',
          );
        }
      }
      _prevStatuses[d.taskId!] = d.status;
    }

    downloads.assignAll(newList);
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

  /// Check if the URL points directly to a downloadable file.
  bool _isDirectUrl(String url) {
    final lower = url.toLowerCase();
    // Direct file extensions
    final directExtensions = ['.mp4', '.mkv', '.avi', '.mov', '.webm', '.m4v'];
    for (final ext in directExtensions) {
      if (lower.contains(ext)) return true;
    }
    // Known CDN / direct-download patterns
    final directPatterns = [
      'pixeldrain.com/api/file/',
      'cdn.',
      'download.',
      'dl.',
      'media.',
      'files.',
    ];
    for (final pattern in directPatterns) {
      if (lower.contains(pattern)) return true;
    }
    return false;
  }

  /// Directly enqueue a download URL without backend resolution.
  Future<void> _doDirectDownload({
    required String url,
    required String movieTitle,
    int? tmdbId,
    String? quality,
  }) async {
    final properFilename = _createProperFilename(movieTitle, quality);
    debugPrint('⬇️ Direct download: $url');
    debugPrint('📄 Filename: $properFilename');

    await _service.startDownload(
      url: url,
      filename: properFilename,
      tmdbId: tmdbId,
      quality: quality,
      movieTitle: movieTitle,
    );
    _loadDownloads();
    _ensureTimerRunning();

    Get.snackbar(
      '✅ Download Started',
      '$movieTitle${quality != null ? ' ($quality)' : ''}\n$properFilename',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withValues(alpha: 0.85),
      colorText: Colors.white,
      margin: const EdgeInsets.all(20),
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.download_done, color: Colors.white),
    );
  }

  /// Start download with smart strategy:
  /// 1. If URL looks direct → download immediately (skip resolver)
  /// 2. Otherwise → try backend resolution → fallback to direct download
  Future<void> startDownload({
    required String url,
    required String filename,
    int? tmdbId,
    String? quality,
    required String movieTitle,
  }) async {
    // ── Strategy 1: Direct URL → skip resolver entirely ──
    if (_isDirectUrl(url)) {
      debugPrint('🎯 URL looks direct, skipping resolver');
      await _doDirectDownload(
        url: url,
        movieTitle: movieTitle,
        tmdbId: tmdbId,
        quality: quality,
      );
      return;
    }

    // ── Strategy 2: Intermediate URL → try resolver ──
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
      final resolved = await _apiService.resolveDownloadLink(
        url: url,
        quality: quality ?? '1080p',
      );

      if (Get.isDialogOpen ?? false) Get.back();

      if (resolved['success'] == true) {
        final directUrl = resolved['directUrl'] as String;
        final properFilename = _createProperFilename(movieTitle, quality);
        debugPrint('✅ Resolved URL: $directUrl');
        debugPrint('📄 Filename: $properFilename');

        await _service.startDownload(
          url: directUrl,
          filename: properFilename,
          tmdbId: tmdbId,
          quality: quality,
          movieTitle: movieTitle,
        );
        _loadDownloads();
        _ensureTimerRunning();

        Get.snackbar(
          '✅ Download Started',
          '$movieTitle${quality != null ? ' ($quality)' : ''}\n$properFilename',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.85),
          colorText: Colors.white,
          margin: const EdgeInsets.all(20),
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.download_done, color: Colors.white),
        );
        return;
      }

      // ── Resolution failed → show options dialog ──
      final errorMsg =
          resolved['error']?.toString() ?? 'Could not resolve link';
      _showDownloadFailedDialog(
        errorMsg: errorMsg,
        url: url,
        movieTitle: movieTitle,
        tmdbId: tmdbId,
        quality: quality,
        filename: filename,
      );
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      debugPrint('❌ Download error: $e');

      _showDownloadFailedDialog(
        errorMsg: e.toString(),
        url: url,
        movieTitle: movieTitle,
        tmdbId: tmdbId,
        quality: quality,
        filename: filename,
      );
    }
  }

  /// Show a persistent dialog with retry and direct-download options.
  void _showDownloadFailedDialog({
    required String errorMsg,
    required String url,
    required String movieTitle,
    int? tmdbId,
    String? quality,
    required String filename,
  }) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Resolution Failed',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              errorMsg.length > 120
                  ? '${errorMsg.substring(0, 120)}…'
                  : errorMsg,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Text(
              'You can try downloading directly (may not work for all links) or retry resolution.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white38),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              startDownload(
                url: url,
                filename: filename,
                tmdbId: tmdbId,
                quality: quality,
                movieTitle: movieTitle,
              );
            },
            child: const Text(
              'Retry',
              style: TextStyle(color: Colors.orangeAccent),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Get.back();
              _doDirectDownload(
                url: url,
                movieTitle: movieTitle,
                tmdbId: tmdbId,
                quality: quality,
              );
            },
            child: const Text('Try Direct Download'),
          ),
        ],
      ),
    );
  }

  /// Create a clean filename: Movie_Title_Quality.mp4
  String _createProperFilename(String movieTitle, String? quality) {
    // Sanitize title: replace spaces/special chars with underscores
    final sanitized = movieTitle
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();

    final q = quality?.replaceAll(' ', '') ?? 'HD';
    return '${sanitized}_$q.mp4';
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

  /// Failed + canceled downloads for the history section.
  List<Download> get historyDownloads => downloads
      .where(
        (d) =>
            d.status == DownloadStatus.failed ||
            d.status == DownloadStatus.canceled,
      )
      .toList();

  @override
  void onClose() {
    _refreshTimer?.cancel();
    _service.box.listenable().removeListener(_loadDownloads);
    super.onClose();
  }
}
