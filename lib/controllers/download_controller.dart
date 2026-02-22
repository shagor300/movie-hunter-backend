import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../models/download_item.dart';
import '../services/storage_settings_service.dart';
import '../services/parallel_download_engine.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class DownloadController extends GetxController {
  final ApiService _apiService = ApiService();

  // Active download engines
  final Map<String, ParallelDownloadEngine> _engines = {};

  // Observable state
  final downloads = <String, DownloadItem>{}.obs;
  final speeds = <String, double>{}.obs;
  final etas = <String, int>{}.obs;

  var isInitialized = false.obs;

  // Notification throttle (avoid updating notifications too frequently)
  final Map<String, DateTime> _lastNotifUpdate = {};

  late StorageSettingsService _settings;

  @override
  void onInit() {
    super.onInit();
    _settings = Get.find<StorageSettingsService>();
    _init();
  }

  Future<void> _init() async {
    await _loadSavedDownloads();
    isInitialized.value = true;
  }

  Future<void> _loadSavedDownloads() async {
    final box = await Hive.openBox<DownloadItem>('downloads_v2');
    for (final item in box.values) {
      // Reset "downloading" to "paused" on restart (app was killed mid-download)
      if (item.status == 'downloading') {
        item.status = 'paused';
        await item.save();
      }
      downloads[item.id] = item;
    }
    debugPrint('✅ DownloadController: loaded ${downloads.length} downloads');
  }

  // ═══════════════════════════════════════════════════════════════════
  // PUBLIC API
  // ═══════════════════════════════════════════════════════════════════

  /// Check if the URL points directly to a downloadable file.
  bool _isDirectUrl(String url) {
    final lower = url.toLowerCase();
    final directExtensions = ['.mp4', '.mkv', '.avi', '.mov', '.webm', '.m4v'];
    for (final ext in directExtensions) {
      if (lower.contains(ext)) return true;
    }
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

  /// Clean filename: Movie_Title_Quality.mp4
  String _createProperFilename(String movieTitle, String? quality) {
    final sanitized = movieTitle
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
    final q = quality?.replaceAll(' ', '') ?? 'HD';
    return '${sanitized}_$q.mp4';
  }

  /// Start download with smart strategy:
  /// 1. Direct URL → download immediately
  /// 2. Otherwise → try backend resolution → fallback
  Future<void> startDownload({
    required String url,
    required String filename,
    int? tmdbId,
    String? quality,
    required String movieTitle,
  }) async {
    // Check storage limits first
    final double maxStorageGb = _settings.storageLimit.value;
    double currentUsedGb = 0;
    for (var d in allDownloads) {
      if (d.status == 'completed' || d.status == 'downloading') {
        final sStr = d.fileSizeText
            .toUpperCase()
            .replaceAll(' GB', '')
            .replaceAll(' MB', '');
        final val = double.tryParse(sStr) ?? 0.0;
        if (d.fileSizeText.toUpperCase().contains('MB')) {
          currentUsedGb += (val / 1024);
        } else {
          currentUsedGb += val;
        }
      }
    }

    // 64.0 is treated as "Max" (unlimited practically)
    if (currentUsedGb >= maxStorageGb && maxStorageGb < 64.0) {
      Get.snackbar(
        'Storage Limit Reached',
        'You have reached your set download limit of ${maxStorageGb.toInt()}GB. Please manage your storage in the Downloads settings.',
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
        icon: const Icon(Icons.storage, color: Colors.white),
      );
      return;
    }

    // Strategy 1: Direct URL
    if (_isDirectUrl(url)) {
      debugPrint('🎯 URL looks direct, skipping resolver');
      await _doDownload(
        url: url,
        movieTitle: movieTitle,
        tmdbId: tmdbId,
        quality: quality,
      );
      return;
    }

    // Strategy 2: Try resolver
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
        debugPrint('✅ Resolved URL: $directUrl');
        await _doDownload(
          url: directUrl,
          movieTitle: movieTitle,
          tmdbId: tmdbId,
          quality: quality,
        );
        return;
      }

      // Resolution failed
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

  /// Core download action using the parallel engine.
  Future<void> _doDownload({
    required String url,
    required String movieTitle,
    int? tmdbId,
    String? quality,
  }) async {
    if (!await _requestPermission()) return;

    final id = 'dl_${DateTime.now().millisecondsSinceEpoch}';
    final properFilename = _createProperFilename(movieTitle, quality);
    final savePath = await _buildSavePath(properFilename);

    // Create download item
    final item = DownloadItem(
      id: id,
      movieTitle: movieTitle,
      quality: quality ?? 'HD',
      url: url,
      filePath: savePath,
      fileName: properFilename,
      status: 'downloading',
      createdAt: DateTime.now(),
      tmdbId: tmdbId ?? 0,
    );

    // Save to Hive
    final box = await Hive.openBox<DownloadItem>('downloads_v2');
    await box.put(id, item);
    downloads[id] = item;

    // Show start notification
    try {
      NotificationService.instance.showDownloadProgress(
        notifId: id.hashCode.abs() % 100000,
        movieTitle: movieTitle,
        progress: 0,
        speed: 'Starting...',
        eta: '--',
      );
    } catch (_) {}

    // Start engine
    _startEngine(id, url, savePath, {});

    Get.snackbar(
      '⬇️ Download Started',
      '$movieTitle${quality != null ? ' ($quality)' : ''}\n$properFilename',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withValues(alpha: 0.85),
      colorText: Colors.white,
      margin: const EdgeInsets.all(20),
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.download_done, color: Colors.white),
    );
  }

  void _startEngine(
    String id,
    String url,
    String savePath,
    Map<String, String> headers,
  ) {
    final engine = ParallelDownloadEngine(
      id: id,
      url: url,
      savePath: savePath,
      headers: headers,
      maxChunks: 4,
      onProgress: (downloaded, total, speed, eta) {
        final item = downloads[id];
        if (item == null) return;

        item.downloadedBytes = downloaded;
        item.totalBytes = total;
        speeds[id] = speed;
        etas[id] = eta;
        downloads.refresh();

        // Save progress to Hive periodically (every 5%)
        if (total > 0 && (downloaded / total * 100).round() % 5 == 0) {
          item.save();
        }

        // Update notification (throttle: every 2 seconds)
        final now = DateTime.now();
        final lastUpdate = _lastNotifUpdate[id];
        if (lastUpdate == null || now.difference(lastUpdate).inSeconds >= 2) {
          _lastNotifUpdate[id] = now;
          try {
            NotificationService.instance.showDownloadProgress(
              notifId: id.hashCode.abs() % 100000,
              movieTitle: item.movieTitle,
              progress: total > 0 ? (downloaded / total * 100).round() : 0,
              speed: _fmtSpeed(speed),
              eta: _fmtEta(eta),
            );
          } catch (_) {}
        }
      },
      onComplete: (filePath) async {
        final item = downloads[id];
        if (item == null) return;

        // Verify file
        final file = File(filePath);
        final exists = await file.exists();
        final size = exists ? await file.length() : 0;

        if (!exists || size == 0) {
          await _setFailed(id, 'File not saved correctly');
          return;
        }

        // ✅ SUCCESS
        item.status = 'completed';
        item.downloadedBytes = size;
        item.totalBytes = size;
        item.completedAt = DateTime.now();
        await item.save();
        downloads.refresh();
        _engines.remove(id);

        // Cancel progress notification
        try {
          await NotificationService.instance.cancelNotification(
            id.hashCode.abs() % 100000,
          );
        } catch (_) {}

        // Show completion notification
        try {
          NotificationService.instance.showDownloadComplete(
            item.movieTitle,
            item.quality,
            item.fileSizeText,
          );
        } catch (_) {}

        Get.snackbar(
          '✅ Download Complete!',
          '${item.movieTitle} (${item.quality}) · ${item.fileSizeText}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(20),
          duration: const Duration(seconds: 5),
          icon: const Icon(Icons.check_circle, color: Colors.white),
        );
      },
      onError: (error) async {
        await _setFailed(id, error);
      },
    );

    _engines[id] = engine;
    engine.start();
  }

  // ═══════════════════════════════════════════════════════════════════
  // CONTROLS (compatible public API)
  // ═══════════════════════════════════════════════════════════════════

  Future<void> pauseDownload(dynamic download) async {
    final String id;
    if (download is DownloadItem) {
      id = download.id;
    } else {
      // Legacy support: check for .taskId or .id
      id = download.id?.toString() ?? '';
    }
    _engines[id]?.pause();
    final item = downloads[id];
    if (item == null) return;
    item.status = 'paused';
    await item.save();
    downloads.refresh();
    try {
      await NotificationService.instance.cancelNotification(
        id.hashCode.abs() % 100000,
      );
    } catch (_) {}
  }

  Future<void> resumeDownload(dynamic download) async {
    final String id;
    if (download is DownloadItem) {
      id = download.id;
    } else {
      id = download.id?.toString() ?? '';
    }
    final item = downloads[id];
    if (item == null) return;
    item.status = 'downloading';
    await item.save();
    downloads.refresh();
    _startEngine(id, item.url, item.filePath, {});
  }

  Future<void> cancelDownload(dynamic download) async {
    final String id;
    if (download is DownloadItem) {
      id = download.id;
    } else {
      id = download.id?.toString() ?? '';
    }
    _engines[id]?.cancel();
    _engines.remove(id);
    final item = downloads[id];
    if (item == null) return;
    item.status = 'cancelled';
    await item.save();
    downloads.refresh();
    try {
      await NotificationService.instance.cancelNotification(
        id.hashCode.abs() % 100000,
      );
    } catch (_) {}
  }

  Future<void> retryDownload(dynamic download) async {
    final String id;
    if (download is DownloadItem) {
      id = download.id;
    } else {
      id = download.id?.toString() ?? '';
    }
    final item = downloads[id];
    if (item == null) return;
    item.status = 'downloading';
    item.downloadedBytes = 0;
    await item.save();
    downloads.refresh();
    _startEngine(id, item.url, item.filePath, {});
  }

  Future<void> deleteDownload(dynamic download) async {
    final String id;
    if (download is DownloadItem) {
      id = download.id;
    } else {
      id = download.id?.toString() ?? '';
    }
    // Cancel if active
    _engines[id]?.cancel();
    _engines.remove(id);

    final item = downloads[id];
    if (item != null) {
      // Try to delete the file
      try {
        final f = File(item.filePath);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }

    final box = await Hive.openBox<DownloadItem>('downloads_v2');
    await box.delete(id);
    downloads.remove(id);
    speeds.remove(id);
    etas.remove(id);
  }

  // ═══════════════════════════════════════════════════════════════════
  // COMPUTED LISTS (for UI compatibility)
  // ═══════════════════════════════════════════════════════════════════

  List<DownloadItem> get allDownloads =>
      downloads.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<DownloadItem> get activeDownloads => allDownloads
      .where(
        (d) =>
            d.status == 'downloading' ||
            d.status == 'pending' ||
            d.status == 'paused',
      )
      .toList();

  List<DownloadItem> get completedDownloads =>
      allDownloads.where((d) => d.status == 'completed').toList();

  List<DownloadItem> get historyDownloads => allDownloads
      .where((d) => d.status == 'failed' || d.status == 'cancelled')
      .toList();

  // ═══════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _setFailed(String id, String error) async {
    final item = downloads[id];
    if (item == null) return;

    item.status = 'failed';
    await item.save();
    downloads.refresh();
    _engines.remove(id);

    try {
      await NotificationService.instance.cancelNotification(
        id.hashCode.abs() % 100000,
      );
    } catch (_) {}

    try {
      NotificationService.instance.showDownloadFailed(
        item.movieTitle,
        'Download failed. Tap to retry.',
      );
    } catch (_) {}

    debugPrint('❌ Download failed [$id]: $error');
  }

  Future<bool> _requestPermission() async {
    if (!Platform.isAndroid) return true;

    // Android 13+ → notification permission (storage not needed for
    // app-private directories)
    final notifStatus = await Permission.notification.request();
    final storageStatus = await Permission.storage.request();

    if (!notifStatus.isGranted && !storageStatus.isGranted) {
      Get.snackbar(
        'Permission Required',
        'Allow storage/notification to download movies',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    return true;
  }

  Future<String> _buildSavePath(String fileName) async {
    final dir = Platform.isAndroid
        ? '/storage/emulated/0/Download/MovieHub'
        : '${(await getApplicationDocumentsDirectory()).path}/MovieHub';

    await Directory(dir).create(recursive: true);
    return '$dir/$fileName';
  }

  /// Get speed as a human-readable string
  String getSpeedText(String? id) {
    if (id == null) return '--';
    return _fmtSpeed(speeds[id] ?? 0);
  }

  /// Get ETA as a human-readable string
  String getETAText(String? id) {
    if (id == null) return '--';
    return _fmtEta(etas[id] ?? 0);
  }

  String _fmtSpeed(double bps) {
    if (bps <= 0) return '--';
    if (bps < 1024) return '${bps.toStringAsFixed(0)} B/s';
    if (bps < 1024 * 1024) {
      return '${(bps / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${(bps / (1024 * 1024)).toStringAsFixed(2)} MB/s';
  }

  String _fmtEta(int seconds) {
    if (seconds <= 0) return '--';
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${seconds ~/ 60}m ${seconds % 60}s';
    return '${seconds ~/ 3600}h ${(seconds % 3600) ~/ 60}m';
  }

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
              'You can try downloading directly (may not work for all links)'
              ' or retry resolution.',
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
              _doDownload(
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

  @override
  void onClose() {
    // Cancel all active downloads when controller is disposed
    for (final engine in _engines.values) {
      engine.cancel();
    }
    super.onClose();
  }
}
