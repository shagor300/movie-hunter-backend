import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui' show IsolateNameServer;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import '../models/download_item.dart';
import '../services/storage_settings_service.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'package:http/http.dart' as http;

class DownloadController extends GetxController {
  final ApiService _apiService = ApiService();
  late StorageSettingsService _settings;

  // Observable state matching previous behavior
  final downloads = <String, DownloadItem>{}.obs; // Keyed by taskId
  var isInitialized = false.obs;

  final ReceivePort _port = ReceivePort();
  static const String _portName = 'downloader_send_port';

  @override
  void onInit() {
    super.onInit();
    _settings = Get.find<StorageSettingsService>();
    _init();
  }

  @override
  void onClose() {
    IsolateNameServer.removePortNameMapping(_portName);
    _port.close();
    super.onClose();
  }

  Future<void> _init() async {
    // 1. Load saved items from Hive
    await _loadSavedDownloads();

    // 2. Setup port mapping for background isolate communication
    IsolateNameServer.removePortNameMapping(_portName);
    IsolateNameServer.registerPortWithName(_port.sendPort, _portName);

    // 3. Listen to port events
    _port.listen((dynamic data) {
      if (data == null || data is! List) return;

      final taskId = data[0] as String;
      final statusValue = data[1] as int;
      final progress = data[2] as int;

      final DownloadTaskStatus status = DownloadTaskStatus.fromInt(statusValue);
      _handleDownloadUpdate(taskId, status, progress);
    });

    // 4. Register callback
    FlutterDownloader.registerCallback(downloadCallback);

    // 5. Sync state with native downloader to catch up on any background progress
    await _syncWithNativeDownloader();

    isInitialized.value = true;
  }

  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName(_portName);
    send?.send([id, status, progress]);
  }

  Future<void> _loadSavedDownloads() async {
    final box = await Hive.openBox<DownloadItem>('downloads_v2');
    for (final item in box.values) {
      downloads[item.id] = item;
    }
    debugPrint(
      '✅ DownloadController: loaded ${downloads.length} downloads from Hive',
    );
  }

  Future<void> _syncWithNativeDownloader() async {
    final tasks = await FlutterDownloader.loadTasks();
    if (tasks == null) return;

    for (final task in tasks) {
      final item = downloads[task.taskId];
      if (item != null) {
        _updateItemStatusFromTask(item, task.status, task.progress);
        await item.save();
      }
    }
    downloads.refresh();
  }

  void _handleDownloadUpdate(
    String taskId,
    DownloadTaskStatus status,
    int progress,
  ) {
    final item = downloads[taskId];
    if (item == null) return;

    _updateItemStatusFromTask(item, status, progress);

    // Refresh UI instantly for real-time progress
    downloads.refresh();

    // Save to Hive periodically (every ~5% or on specific status updates)
    // to avoid excessive disk I/O
    if (status == DownloadTaskStatus.complete ||
        status == DownloadTaskStatus.failed ||
        status == DownloadTaskStatus.canceled ||
        progress % 5 == 0) {
      item.save();
    }

    if (status == DownloadTaskStatus.complete) {
      _onDownloadComplete(item);
    } else if (status == DownloadTaskStatus.failed) {
      _onDownloadFailed(item);
    }
  }

  void _updateItemStatusFromTask(
    DownloadItem item,
    DownloadTaskStatus taskStatus,
    int progress,
  ) {
    if (taskStatus == DownloadTaskStatus.running) {
      item.status = 'downloading';
      // Estimate downloaded bytes based on progress percentage and total bytes
      if (item.totalBytes > 0 && progress > 0) {
        item.downloadedBytes = (item.totalBytes * (progress / 100)).round();
      } else if (progress > 0) {
        // Fallback for existing downloads where totalBytes is 0
        try {
          final file = File(item.filePath);
          if (file.existsSync()) {
            item.downloadedBytes = file.lengthSync();
            if (item.totalBytes == 0) {
              item.totalBytes = (item.downloadedBytes / (progress / 100))
                  .round();
            }
          }
        } catch (_) {}
      }
    } else if (taskStatus == DownloadTaskStatus.complete) {
      item.status = 'completed';
      try {
        final file = File(item.filePath);
        if (file.existsSync()) {
          item.totalBytes = file.lengthSync();
        }
      } catch (_) {}
      item.downloadedBytes = item.totalBytes;
      item.completedAt = DateTime.now();
    } else if (taskStatus == DownloadTaskStatus.failed) {
      item.status = 'failed';
    } else if (taskStatus == DownloadTaskStatus.canceled) {
      item.status = 'cancelled';
    } else if (taskStatus == DownloadTaskStatus.paused) {
      item.status = 'paused';
    } else if (taskStatus == DownloadTaskStatus.enqueued) {
      item.status = 'pending';
    }
  }

  void _onDownloadComplete(DownloadItem item) {
    try {
      NotificationService.instance.showDownloadComplete(
        item.movieTitle,
        item.quality,
        item.fileSizeText,
      );
    } catch (e) {
      debugPrint('⚠️ Completion notification error: $e');
    }

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
  }

  void _onDownloadFailed(DownloadItem item) {
    try {
      NotificationService.instance.showDownloadFailed(
        item.movieTitle,
        'Download failed. Tap to retry.',
      );
    } catch (e) {
      debugPrint('⚠️ Failed notification error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // PUBLIC API
  // ═══════════════════════════════════════════════════════════════════

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

  String _createProperFilename(String movieTitle, String? quality) {
    final sanitized = movieTitle
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
    final q = quality?.replaceAll(' ', '') ?? 'HD';
    return '${sanitized}_$q.mp4';
  }

  Future<void> startDownload({
    required String url,
    required String filename,
    int? tmdbId,
    String? quality,
    required String movieTitle,
    String? posterUrl,
  }) async {
    // 1. Check storage limits first
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
        posterUrl: posterUrl,
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
          posterUrl: posterUrl,
        );
        return;
      }

      final errorMsg =
          resolved['error']?.toString() ?? 'Could not resolve link';
      _showDownloadFailedDialog(
        errorMsg: errorMsg,
        url: url,
        movieTitle: movieTitle,
        tmdbId: tmdbId,
        quality: quality,
        filename: filename,
        posterUrl: posterUrl,
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
        posterUrl: posterUrl,
      );
    }
  }

  Future<void> _doDownload({
    required String url,
    required String movieTitle,
    int? tmdbId,
    String? quality,
    String? posterUrl,
  }) async {
    if (!await _requestPermission()) return;

    final properFilename = _createProperFilename(movieTitle, quality);
    final savedDir = await _buildSaveDirPath();

    // 1. Enqueue with flutter_downloader
    final taskId = await FlutterDownloader.enqueue(
      url: url,
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 13; SM-G998B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Mobile Safari/537.36',
      }, // optional: header send with url (auth token etc)
      savedDir: savedDir,
      fileName: properFilename,
      showNotification:
          true, // show download progress in status bar (for Android)
      openFileFromNotification:
          true, // click on notification to open downloaded file (for Android)
    );

    if (taskId == null) {
      Get.snackbar(
        'Error',
        'Could not enqueue download task',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.85),
        colorText: Colors.white,
      );
      return;
    }

    // Try to fetch exact file size before starting
    int resolvedTotalBytes = 0;
    try {
      final headResp = await http
          .head(
            Uri.parse(url),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Linux; Android 13; SM-G998B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Mobile Safari/537.36',
            },
          )
          .timeout(const Duration(seconds: 4));

      final cl = headResp.headers['content-length'];
      if (cl != null) {
        resolvedTotalBytes = int.tryParse(cl) ?? 0;
      }
    } catch (e) {
      debugPrint('⚠️ Could not fetch Content-Length: $e');
    }

    // Create download item
    final item = DownloadItem(
      id: taskId,
      movieTitle: movieTitle,
      quality: quality ?? 'HD',
      url: url,
      filePath: '$savedDir/$properFilename',
      fileName: properFilename,
      status: 'pending',
      createdAt: DateTime.now(),
      tmdbId: tmdbId ?? 0,
      posterUrl: posterUrl,
      totalBytes: resolvedTotalBytes,
      downloadedBytes: 0,
    );

    // 3. Save to Hive
    final box = await Hive.openBox<DownloadItem>('downloads_v2');
    await box.put(taskId, item);
    downloads[taskId] = item;
    downloads.refresh();

    Get.snackbar(
      '⬇️ Download Started',
      '$movieTitle${quality != null ? ' ($quality)' : ''}\nDownloading in background',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withValues(alpha: 0.85),
      colorText: Colors.white,
      margin: const EdgeInsets.all(20),
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.download_done, color: Colors.white),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // CONTROLS (compatible public API)
  // ═══════════════════════════════════════════════════════════════════

  Future<void> pauseDownload(dynamic download) async {
    final String id = _extractId(download);
    await FlutterDownloader.pause(taskId: id);
  }

  Future<void> resumeDownload(dynamic download) async {
    final String id = _extractId(download);
    final newTaskId = await FlutterDownloader.resume(taskId: id);

    // flutter_downloader generates a new taskId upon resuming.
    if (newTaskId != null && newTaskId != id) {
      await _migrateTask(oldId: id, newId: newTaskId);
    }
  }

  Future<void> cancelDownload(dynamic download) async {
    final String id = _extractId(download);
    await FlutterDownloader.cancel(taskId: id);
  }

  Future<void> retryDownload(dynamic download) async {
    final String id = _extractId(download);
    final newTaskId = await FlutterDownloader.retry(taskId: id);

    if (newTaskId != null && newTaskId != id) {
      await _migrateTask(oldId: id, newId: newTaskId);
    }
  }

  Future<void> deleteDownload(dynamic download) async {
    final String id = _extractId(download);

    // Remove task & delete file
    await FlutterDownloader.remove(taskId: id, shouldDeleteContent: true);

    final box = await Hive.openBox<DownloadItem>('downloads_v2');
    await box.delete(id);
    downloads.remove(id);
    downloads.refresh();
  }

  String _extractId(dynamic download) {
    if (download is DownloadItem) {
      return download.id;
    }
    return download.id?.toString() ?? '';
  }

  Future<void> _migrateTask({
    required String oldId,
    required String newId,
  }) async {
    final box = await Hive.openBox<DownloadItem>('downloads_v2');
    final item = downloads[oldId];
    if (item != null) {
      // Copy item with new ID
      final newItem = DownloadItem(
        id: newId,
        movieTitle: item.movieTitle,
        quality: item.quality,
        url: item.url,
        filePath: item.filePath,
        fileName: item.fileName,
        totalBytes: item.totalBytes,
        downloadedBytes: item.downloadedBytes,
        status: 'pending', // Reset status as it's queued again
        createdAt: item.createdAt, // keep original date
        completedAt: null,
        posterUrl: item.posterUrl,
        tmdbId: item.tmdbId,
      );

      await box.put(newId, newItem);
      await box.delete(oldId);

      downloads[newId] = newItem;
      downloads.remove(oldId);
      downloads.refresh();
    }
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

  Future<bool> _requestPermission() async {
    if (!Platform.isAndroid) return true;

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

  Future<String> _buildSaveDirPath() async {
    final dirPath = Platform.isAndroid
        ? '/storage/emulated/0/Download/FlixHub'
        : '${(await getApplicationDocumentsDirectory()).path}/FlixHub';

    await Directory(dirPath).create(recursive: true);
    return dirPath;
  }

  /// Get speed as a human-readable string (Not available easily with flutter_downloader standard api, using empty string to mock UI format without breaking)
  String getSpeedText(String? id) {
    return '';
  }

  /// Get ETA as a human-readable string (Not available easily with flutter_downloader standard api, using empty string to mock UI format without breaking)
  String getETAText(String? id) {
    return '';
  }

  void _showDownloadFailedDialog({
    required String errorMsg,
    required String url,
    required String movieTitle,
    int? tmdbId,
    String? quality,
    required String filename,
    String? posterUrl,
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
                posterUrl: posterUrl,
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
              // Try direct fallback
              _doDownload(
                url: url,
                movieTitle: movieTitle,
                tmdbId: tmdbId,
                quality: quality,
                posterUrl: posterUrl,
              );
            },
            child: const Text('Try Direct'),
          ),
        ],
      ),
    );
  }
}
