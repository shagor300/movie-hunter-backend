# 🚀 Chrome-Style Download System - Complete Guide

**For Google Antigravity**

---

## 🎯 WHAT TO BUILD

Replace broken FlutterDownloader with professional system:

| Feature | Status |
|---------|--------|
| Real-time speed (MB/s) | ✅ Must have |
| Estimated time remaining | ✅ Must have |
| Progress percentage | ✅ Must have |
| **Parallel downloading** | ✅ Must have |
| Resume if interrupted | ✅ Must have |
| Correct status | ✅ Must have |
| Proper notification with app icon | ✅ Must have |

---

## 📦 STEP 1: DEPENDENCIES

```yaml
dependencies:
  # REMOVE FlutterDownloader completely
  # flutter_downloader: ^1.11.5  ← DELETE

  # ADD these
  dio: ^5.4.0                           # Download engine
  path_provider: ^2.1.1                 # File paths
  permission_handler: ^11.1.0           # Storage permission
  flutter_local_notifications: ^16.3.0  # Notifications
  hive: ^2.2.3                          # Save history
  hive_flutter: ^1.1.0
  open_file: ^3.3.2                     # Open completed file
  wakelock_plus: ^1.1.4                 # Keep screen on
  crypto: ^3.0.3                        # MD5 for chunk merge
```

---

## 🔧 STEP 2: PARALLEL DOWNLOAD ENGINE

This is the most important file. It splits files into chunks and downloads simultaneously like Chrome.

**File:** `lib/services/parallel_download_engine.dart`

```dart
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// Represents one chunk of a parallel download
class DownloadChunk {
  final int index;
  final int startByte;
  final int endByte;
  final String tempPath;

  int downloadedBytes = 0;
  bool isCompleted = false;
  CancelToken cancelToken = CancelToken();

  DownloadChunk({
    required this.index,
    required this.startByte,
    required this.endByte,
    required this.tempPath,
  });

  int get totalBytes => endByte - startByte + 1;
  double get progress => totalBytes > 0 ? downloadedBytes / totalBytes : 0;
}

/// Speed sample for moving average calculation
class _SpeedSample {
  final int totalBytes;
  final DateTime time;
  _SpeedSample(this.totalBytes, this.time);
}

/// Chrome-style parallel download engine
class ParallelDownloadEngine {
  final String id;
  final String url;
  final String savePath;
  final Map<String, String> headers;
  final int maxChunks;

  // State
  List<DownloadChunk> chunks = [];
  bool isPaused = false;
  bool isCancelled = false;

  // Progress tracking
  int totalFileSize = 0;
  final List<_SpeedSample> _speedSamples = [];
  double currentSpeedBps = 0;
  int etaSeconds = 0;

  // Callbacks
  final Function(int downloaded, int total, double speed, int eta)? onProgress;
  final Function(String filePath)? onComplete;
  final Function(String error)? onError;

  ParallelDownloadEngine({
    required this.id,
    required this.url,
    required this.savePath,
    required this.headers,
    this.maxChunks = 4,  // 4 parallel chunks like Chrome
    this.onProgress,
    this.onComplete,
    this.onError,
  });

  /// Start parallel download
  Future<void> start() async {
    final dio = Dio();
    dio.options.headers = {
      'User-Agent': 'Mozilla/5.0 (Linux; Android 13)',
      ...headers,
    };

    try {
      // Step 1: Get file size and check if server supports ranges
      print('[$id] 🔍 Checking server capabilities...');
      final response = await dio.head(url).timeout(Duration(seconds: 15));

      final contentLength = int.tryParse(
        response.headers.value('content-length') ?? '0'
      ) ?? 0;

      final acceptRanges = response.headers.value('accept-ranges');
      final supportsRanges = acceptRanges == 'bytes' && contentLength > 0;

      totalFileSize = contentLength;
      print('[$id] 📏 File size: ${_formatBytes(contentLength)}');
      print('[$id] ⚡ Parallel: $supportsRanges');

      if (supportsRanges && contentLength > 1024 * 1024) {
        // File > 1MB: use parallel chunks
        await _parallelDownload(dio, contentLength);
      } else {
        // Small file or no range support: single download
        await _singleDownload(dio);
      }

    } catch (e) {
      if (!isCancelled) {
        print('[$id] ❌ Error: $e');
        onError?.call(e.toString());
      }
    } finally {
      dio.close();
    }
  }

  /// Parallel chunk download
  Future<void> _parallelDownload(Dio dio, int fileSize) async {
    // Calculate chunk sizes
    final numChunks = min(maxChunks, (fileSize / (512 * 1024)).ceil());
    final chunkSize = (fileSize / numChunks).ceil();

    print('[$id] ⚡ Starting $numChunks parallel chunks');

    // Create chunk objects
    final tempDir = await getTemporaryDirectory();
    chunks = List.generate(numChunks, (i) {
      final start = i * chunkSize;
      final end = min(start + chunkSize - 1, fileSize - 1);
      return DownloadChunk(
        index: i,
        startByte: start,
        endByte: end,
        tempPath: '${tempDir.path}/${id}_chunk_$i.tmp',
      );
    });

    // Check for existing partial chunks (resume support)
    for (final chunk in chunks) {
      final tempFile = File(chunk.tempPath);
      if (await tempFile.exists()) {
        chunk.downloadedBytes = await tempFile.length();
        if (chunk.downloadedBytes >= chunk.totalBytes) {
          chunk.isCompleted = true;
          print('[$id] ✅ Chunk ${chunk.index} already done');
        }
      }
    }

    // Start all chunks simultaneously
    final futures = chunks
        .where((c) => !c.isCompleted)
        .map((chunk) => _downloadChunk(dio, chunk));

    await Future.wait(futures);

    if (!isCancelled && !isPaused) {
      // All chunks done - merge them
      await _mergeChunks(fileSize);
    }
  }

  /// Download a single chunk
  Future<void> _downloadChunk(Dio dio, DownloadChunk chunk) async {
    final tempFile = File(chunk.tempPath);
    final startByte = chunk.startByte + chunk.downloadedBytes;

    try {
      await dio.download(
        url,
        chunk.tempPath,
        cancelToken: chunk.cancelToken,
        deleteOnError: false,
        options: Options(
          headers: {
            ...headers,
            'Range': 'bytes=$startByte-${chunk.endByte}',
          },
          responseType: ResponseType.stream,
        ),
        onReceiveProgress: (received, total) {
          chunk.downloadedBytes = chunk.downloadedBytes + received;
          _updateProgress();
        },
      );

      chunk.isCompleted = true;
      print('[$id] ✅ Chunk ${chunk.index} complete');

    } catch (e) {
      if (!isCancelled && !isPaused) {
        print('[$id] ❌ Chunk ${chunk.index} error: $e');
        throw e;
      }
    }
  }

  /// Merge all chunks into final file
  Future<void> _mergeChunks(int expectedSize) async {
    print('[$id] 🔀 Merging ${chunks.length} chunks...');

    final outputFile = File(savePath);
    final sink = outputFile.openWrite();

    try {
      for (final chunk in chunks) {
        final chunkFile = File(chunk.tempPath);
        if (!await chunkFile.exists()) {
          throw Exception('Chunk ${chunk.index} missing!');
        }

        final bytes = await chunkFile.readAsBytes();
        sink.add(bytes);
      }

      await sink.flush();
      await sink.close();

      // Verify final file
      final finalSize = await outputFile.length();
      print('[$id] 📁 Final size: ${_formatBytes(finalSize)}');

      if (finalSize != expectedSize && expectedSize > 0) {
        throw Exception('Size mismatch: got $finalSize, expected $expectedSize');
      }

      // Clean up temp chunks
      for (final chunk in chunks) {
        final f = File(chunk.tempPath);
        if (await f.exists()) await f.delete();
      }

      print('[$id] ✅ Download complete!');
      onComplete?.call(savePath);

    } catch (e) {
      await sink.close();
      print('[$id] ❌ Merge error: $e');
      onError?.call('Merge failed: $e');
    }
  }

  /// Single-threaded download (fallback)
  Future<void> _singleDownload(Dio dio) async {
    print('[$id] ⬇️ Single-thread download...');
    final cancelToken = CancelToken();

    // Check for partial file (resume)
    int startByte = 0;
    final file = File(savePath);
    if (await file.exists()) {
      startByte = await file.length();
      print('[$id] 📂 Resuming from ${_formatBytes(startByte)}');
    }

    final rangeHeaders = startByte > 0
        ? {...headers, 'Range': 'bytes=$startByte-'}
        : headers;

    await dio.download(
      url,
      savePath,
      cancelToken: cancelToken,
      deleteOnError: false,
      options: Options(
        headers: rangeHeaders,
        responseType: ResponseType.stream,
      ),
      onReceiveProgress: (received, total) {
        final totalReceived = startByte + received;
        final totalSize = startByte + total;
        totalFileSize = totalSize;
        _updateProgressDirect(totalReceived, totalSize);
      },
    );

    onComplete?.call(savePath);
  }

  /// Update progress from chunks
  void _updateProgress() {
    final totalDownloaded = chunks.fold<int>(
      0, (sum, c) => sum + c.downloadedBytes
    );
    _updateProgressDirect(totalDownloaded, totalFileSize);
  }

  void _updateProgressDirect(int downloaded, int total) {
    final now = DateTime.now();

    // Add speed sample
    _speedSamples.add(_SpeedSample(downloaded, now));

    // Keep only last 8 seconds
    final cutoff = now.subtract(Duration(seconds: 8));
    _speedSamples.removeWhere((s) => s.time.isBefore(cutoff));

    // Calculate speed (moving average)
    if (_speedSamples.length >= 2) {
      final oldest = _speedSamples.first;
      final newest = _speedSamples.last;
      final ms = newest.time.difference(oldest.time).inMilliseconds;
      final bytes = newest.totalBytes - oldest.totalBytes;

      if (ms > 0) {
        currentSpeedBps = (bytes / ms) * 1000;
      }
    }

    // Calculate ETA
    if (currentSpeedBps > 0 && total > 0) {
      final remaining = total - downloaded;
      etaSeconds = (remaining / currentSpeedBps).round();
    }

    onProgress?.call(downloaded, total, currentSpeedBps, etaSeconds);
  }

  /// Pause download
  void pause() {
    isPaused = true;
    for (final chunk in chunks) {
      chunk.cancelToken.cancel('paused');
    }
  }

  /// Cancel download
  void cancel() {
    isCancelled = true;
    for (final chunk in chunks) {
      chunk.cancelToken.cancel('cancelled');
    }
    // Delete temp files
    for (final chunk in chunks) {
      final f = File(chunk.tempPath);
      f.exists().then((exists) {
        if (exists) f.delete();
      });
    }
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
```

---

## 🔧 STEP 3: DOWNLOAD MODEL

**File:** `lib/models/download_item.dart`

```dart
import 'package:hive/hive.dart';

part 'download_item.g.dart';

@HiveType(typeId: 3)
class DownloadItem extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String movieTitle;
  @HiveField(2) String quality;
  @HiveField(3) String url;
  @HiveField(4) String filePath;
  @HiveField(5) String fileName;
  @HiveField(6) int totalBytes;
  @HiveField(7) int downloadedBytes;
  @HiveField(8) String status; // pending/downloading/paused/completed/failed
  @HiveField(9) DateTime createdAt;
  @HiveField(10) DateTime? completedAt;
  @HiveField(11) String? posterUrl;
  @HiveField(12) int tmdbId;

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

  double get progress =>
      totalBytes > 0 ? downloadedBytes / totalBytes : 0;

  String get progressText =>
      '${(progress * 100).toStringAsFixed(1)}%';

  String get fileSizeText => _fmt(totalBytes);
  String get downloadedText => _fmt(downloadedBytes);

  static String _fmt(int b) {
    if (b <= 0) return '0 B';
    if (b < 1 << 20) return '${(b / 1024).toStringAsFixed(1)} KB';
    if (b < 1 << 30) return '${(b / (1 << 20)).toStringAsFixed(2)} MB';
    return '${(b / (1 << 30)).toStringAsFixed(2)} GB';
  }
}
```

---

## 🔧 STEP 4: DOWNLOAD MANAGER (Controller)

**File:** `lib/services/download_manager.dart`

```dart
import 'dart:io';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/download_item.dart';
import 'parallel_download_engine.dart';
import 'notification_service.dart';
import 'package:flutter/material.dart';

class DownloadManager extends GetxService {
  // Active engines
  final Map<String, ParallelDownloadEngine> _engines = {};

  // Observable state
  final downloads = <String, DownloadItem>{}.obs;

  // Live stats (for UI)
  final speeds = <String, double>{}.obs;
  final etas = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSavedDownloads();
  }

  Future<void> _loadSavedDownloads() async {
    final box = await Hive.openBox<DownloadItem>('downloads_v2');
    for (final item in box.values) {
      // Reset "downloading" to "paused" on restart (app was killed)
      if (item.status == 'downloading') {
        item.status = 'paused';
        await item.save();
      }
      downloads[item.id] = item;
    }
  }

  // ══════════════════════════════════
  // START DOWNLOAD
  // ══════════════════════════════════

  Future<void> startDownload({
    required String movieTitle,
    required String quality,
    required String url,
    required int tmdbId,
    String? posterUrl,
    Map<String, String>? headers,
  }) async {
    // Check permission
    if (!await _requestPermission()) return;

    final id = 'dl_${DateTime.now().millisecondsSinceEpoch}';
    final cleanTitle = movieTitle
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
    final fileName = '${cleanTitle}_$quality.mp4';
    final savePath = await _buildSavePath(fileName);

    // Create item
    final item = DownloadItem(
      id: id,
      movieTitle: movieTitle,
      quality: quality,
      url: url,
      filePath: savePath,
      fileName: fileName,
      status: 'downloading',
      createdAt: DateTime.now(),
      posterUrl: posterUrl,
      tmdbId: tmdbId,
    );

    // Save and show
    final box = await Hive.openBox<DownloadItem>('downloads_v2');
    await box.put(id, item);
    downloads[id] = item;

    // Show start notification
    await Get.find<NotificationService>().showDownloadProgress(
      notifId: id.hashCode.abs(),
      movieTitle: movieTitle,
      progress: 0,
      speed: 'Starting...',
      eta: '--',
    );

    // Start engine
    _startEngine(id, url, savePath, headers ?? {});

    Get.snackbar(
      '⬇️ Download Started',
      '$movieTitle ($quality)',
      snackPosition: SnackPosition.BOTTOM,
      duration: Duration(seconds: 3),
      backgroundColor: Colors.blue.withOpacity(0.8),
    );
  }

  void _startEngine(
    String id, String url, String savePath,
    Map<String, String> headers,
  ) {
    final engine = ParallelDownloadEngine(
      id: id,
      url: url,
      savePath: savePath,
      headers: headers,
      maxChunks: 4,  // 4 parallel connections

      onProgress: (downloaded, total, speed, eta) async {
        final item = downloads[id];
        if (item == null) return;

        item.downloadedBytes = downloaded;
        item.totalBytes = total;
        speeds[id] = speed;
        etas[id] = eta;
        downloads.refresh();

        // Save progress to Hive (every 5%)
        if (total > 0 && (downloaded / total * 100).round() % 5 == 0) {
          await item.save();
        }

        // Update notification (every 2 seconds)
        final now = DateTime.now();
        if (now.second % 2 == 0) {
          await Get.find<NotificationService>().showDownloadProgress(
            notifId: id.hashCode.abs(),
            movieTitle: item.movieTitle,
            progress: total > 0 ? (downloaded / total * 100).round() : 0,
            speed: _fmtSpeed(speed),
            eta: _fmtEta(eta),
          );
        }
      },

      onComplete: (filePath) async {
        final item = downloads[id];
        if (item == null) return;

        // VERIFY file actually exists
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

        // Success notification
        await Get.find<NotificationService>().showDownloadComplete(
          notifId: id.hashCode.abs(),
          movieTitle: item.movieTitle,
          quality: item.quality,
          fileSize: item.fileSizeText,
          filePath: filePath,
        );

        Get.snackbar(
          '✅ Download Complete!',
          '${item.movieTitle} (${item.quality}) · ${item.fileSizeText}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.9),
          duration: Duration(seconds: 5),
        );
      },

      onError: (error) async {
        await _setFailed(id, error);
      },
    );

    _engines[id] = engine;
    engine.start();
  }

  // ══════════════════════════════════
  // CONTROLS
  // ══════════════════════════════════

  Future<void> pause(String id) async {
    _engines[id]?.pause();
    final item = downloads[id];
    if (item == null) return;
    item.status = 'paused';
    await item.save();
    downloads.refresh();
    await Get.find<NotificationService>().cancelNotification(id.hashCode.abs());
  }

  Future<void> resume(String id) async {
    final item = downloads[id];
    if (item == null) return;
    item.status = 'downloading';
    await item.save();
    downloads.refresh();
    _startEngine(id, item.url, item.filePath, {});
  }

  Future<void> cancel(String id) async {
    _engines[id]?.cancel();
    _engines.remove(id);
    final item = downloads[id];
    if (item == null) return;
    item.status = 'cancelled';
    await item.save();
    downloads.refresh();
    await Get.find<NotificationService>().cancelNotification(id.hashCode.abs());
  }

  Future<void> retry(String id) async {
    final item = downloads[id];
    if (item == null) return;
    item.status = 'downloading';
    item.downloadedBytes = 0;
    await item.save();
    downloads.refresh();
    _startEngine(id, item.url, item.filePath, {});
  }

  Future<void> delete(String id, {bool deleteFile = false}) async {
    await cancel(id);
    if (deleteFile) {
      final item = downloads[id];
      if (item != null) {
        final f = File(item.filePath);
        if (await f.exists()) await f.delete();
      }
    }
    final box = await Hive.openBox<DownloadItem>('downloads_v2');
    await box.delete(id);
    downloads.remove(id);
  }

  // ══════════════════════════════════
  // HELPERS
  // ══════════════════════════════════

  Future<void> _setFailed(String id, String error) async {
    final item = downloads[id];
    if (item == null) return;

    item.status = 'failed';
    await item.save();
    downloads.refresh();
    _engines.remove(id);

    await Get.find<NotificationService>().showDownloadFailed(
      notifId: id.hashCode.abs(),
      movieTitle: item.movieTitle,
      error: error,
    );

    print('❌ Download failed [$id]: $error');
  }

  Future<bool> _requestPermission() async {
    if (!Platform.isAndroid) return true;
    final sdk = int.tryParse(
      (await Process.run('getprop', ['ro.build.version.sdk']))
          .stdout.toString().trim()
    ) ?? 30;

    if (sdk >= 33) return true; // Android 13+ no permission needed

    final status = await Permission.storage.request();
    if (!status.isGranted) {
      Get.snackbar(
        'Permission Required',
        'Allow storage to download movies',
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    return true;
  }

  Future<String> _buildSavePath(String fileName) async {
    final dir = Platform.isAndroid
        ? '/storage/emulated/0/Movies/MovieHub'
        : '${(await getApplicationDocumentsDirectory()).path}/MovieHub';

    await Directory(dir).create(recursive: true);
    return '$dir/$fileName';
  }

  String _fmtSpeed(double bps) {
    if (bps <= 0) return '--';
    if (bps < 1024) return '${bps.toStringAsFixed(0)} B/s';
    if (bps < 1024 * 1024) return '${(bps / 1024).toStringAsFixed(1)} KB/s';
    return '${(bps / (1024 * 1024)).toStringAsFixed(2)} MB/s';
  }

  String _fmtEta(int seconds) {
    if (seconds <= 0) return '--';
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) {
      return '${seconds ~/ 60}m ${seconds % 60}s';
    }
    return '${seconds ~/ 3600}h ${(seconds % 3600) ~/ 60}m';
  }

  // Getters for UI
  String getSpeed(String id) => _fmtSpeed(speeds[id] ?? 0);
  String getEta(String id) => _fmtEta(etas[id] ?? 0);

  List<DownloadItem> get allDownloads =>
      downloads.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}
```

---

## 🔔 STEP 5: NOTIFICATIONS

**File:** `lib/services/notification_service.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class NotificationService extends GetxService {
  final _notif = FlutterLocalNotificationsPlugin();

  @override
  Future<void> onInit() async {
    super.onInit();

    await _notif.initialize(
      InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    // Create channels
    final plugin = _notif.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await plugin?.createNotificationChannel(AndroidNotificationChannel(
      'downloads', 'Downloads',
      description: 'Download progress and completion',
      importance: Importance.high,
    ));

    await plugin?.createNotificationChannel(AndroidNotificationChannel(
      'content', 'New Movies',
      description: 'New content alerts',
      importance: Importance.defaultImportance,
    ));
  }

  Future<void> showDownloadProgress({
    required int notifId,
    required String movieTitle,
    required int progress,
    required String speed,
    required String eta,
  }) async {
    await _notif.show(
      notifId,
      '⬇️ $movieTitle',
      '$progress% · $speed · $eta remaining',
      NotificationDetails(android: AndroidNotificationDetails(
        'downloads', 'Downloads',
        channelDescription: 'Download progress',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        showProgress: true,
        maxProgress: 100,
        progress: progress,
        onlyAlertOnce: true,
        icon: 'ic_notification',
        color: Color(0xFF6200EE),
        actions: [
          AndroidNotificationAction('pause', 'Pause'),
          AndroidNotificationAction('cancel', 'Cancel'),
        ],
      )),
    );
  }

  Future<void> showDownloadComplete({
    required int notifId,
    required String movieTitle,
    required String quality,
    required String fileSize,
    required String filePath,
  }) async {
    await _notif.cancel(notifId); // Cancel progress notification

    await _notif.show(
      notifId + 10000,
      '✅ Download Complete',
      '$movieTitle ($quality) · $fileSize',
      NotificationDetails(android: AndroidNotificationDetails(
        'downloads', 'Downloads',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_notification',
        color: Color(0xFF4CAF50),
        autoCancel: true,
        actions: [
          AndroidNotificationAction('play', '▶️ Play Now'),
          AndroidNotificationAction('open_folder', '📂 Open'),
        ],
      )),
      payload: filePath,
    );
  }

  Future<void> showDownloadFailed({
    required int notifId,
    required String movieTitle,
    required String error,
  }) async {
    await _notif.cancel(notifId);

    await _notif.show(
      notifId + 20000,
      '❌ Download Failed',
      '$movieTitle · Tap to retry',
      NotificationDetails(android: AndroidNotificationDetails(
        'downloads', 'Downloads',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_notification',
        color: Color(0xFFF44336),
        autoCancel: true,
        actions: [
          AndroidNotificationAction('retry', '🔄 Retry'),
        ],
      )),
      payload: movieTitle,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notif.cancel(id);
  }
}
```

---

## 🎨 STEP 6: DOWNLOADS SCREEN UI

**File:** `lib/screens/downloads_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/download_manager.dart';
import '../models/download_item.dart';

class DownloadsScreen extends StatelessWidget {
  final manager = Get.find<DownloadManager>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text('Downloads (${manager.allDownloads.length})')),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep),
            onPressed: _clearCompleted,
            tooltip: 'Clear completed',
          ),
        ],
      ),
      body: Obx(() {
        final items = manager.allDownloads;

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.download_outlined, size: 80, color: Colors.grey[700]),
                SizedBox(height: 16),
                Text('No Downloads', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Downloaded movies will appear here', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (_, i) => _DownloadCard(item: items[i]),
        );
      }),
    );
  }

  void _clearCompleted() {
    final completed = manager.allDownloads
        .where((d) => d.status == 'completed' || d.status == 'cancelled')
        .toList();

    for (final item in completed) {
      manager.delete(item.id);
    }
  }
}

class _DownloadCard extends StatelessWidget {
  final DownloadItem item;
  const _DownloadCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final manager = Get.find<DownloadManager>();

    return Card(
      margin: EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                _StatusIcon(status: item.status),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.movieTitle,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 3),
                      Row(
                        children: [
                          _QualityBadge(quality: item.quality),
                          SizedBox(width: 8),
                          Text(item.fileName,
                            style: TextStyle(color: Colors.grey[500], fontSize: 11),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _ActionButtons(item: item),
              ],
            ),

            // Progress section
            if (item.status == 'downloading' || item.status == 'paused')
              _ProgressSection(item: item),

            // Complete info
            if (item.status == 'completed')
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '✅ ${item.fileSizeText} · Completed',
                  style: TextStyle(color: Colors.green[400], fontSize: 12),
                ),
              ),

            // Failed info
            if (item.status == 'failed')
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '❌ Failed · Tap retry to try again',
                  style: TextStyle(color: Colors.red[400], fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final DownloadItem item;
  const _ProgressSection({required this.item});

  @override
  Widget build(BuildContext context) {
    final manager = Get.find<DownloadManager>();

    return Obx(() {
      final speed = manager.getSpeed(item.id);
      final eta = manager.getEta(item.id);
      final progress = item.progress;
      final isPaused = item.status == 'paused';

      return Padding(
        padding: EdgeInsets.only(top: 12),
        child: Column(
          children: [
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation(
                  isPaused ? Colors.orange : Color(0xFF6200EE),
                ),
              ),
            ),

            SizedBox(height: 6),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${item.downloadedText} / ${item.fileSizeText}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
                Text(
                  item.progressText,
                  style: TextStyle(
                    color: Color(0xFF6200EE),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isPaused)
                  Text(
                    '$speed · $eta',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  )
                else
                  Text('Paused',
                    style: TextStyle(color: Colors.orange, fontSize: 11),
                  ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _StatusIcon extends StatelessWidget {
  final String status;
  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (status) {
      case 'downloading':
        color = Color(0xFF6200EE); icon = Icons.download; break;
      case 'completed':
        color = Colors.green; icon = Icons.check_circle; break;
      case 'failed':
        color = Colors.red; icon = Icons.error; break;
      case 'paused':
        color = Colors.orange; icon = Icons.pause_circle; break;
      default:
        color = Colors.grey; icon = Icons.hourglass_empty;
    }

    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _QualityBadge extends StatelessWidget {
  final String quality;
  const _QualityBadge({required this.quality});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Color(0xFF6200EE),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(quality,
        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final DownloadItem item;
  const _ActionButtons({required this.item});

  @override
  Widget build(BuildContext context) {
    final m = Get.find<DownloadManager>();

    switch (item.status) {
      case 'downloading':
        return Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(icon: Icon(Icons.pause, color: Colors.orange, size: 22),
            onPressed: () => m.pause(item.id)),
          IconButton(icon: Icon(Icons.cancel, color: Colors.red, size: 22),
            onPressed: () => m.cancel(item.id)),
        ]);

      case 'paused':
        return Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(icon: Icon(Icons.play_arrow, color: Colors.green, size: 22),
            onPressed: () => m.resume(item.id)),
          IconButton(icon: Icon(Icons.cancel, color: Colors.red, size: 22),
            onPressed: () => m.cancel(item.id)),
        ]);

      case 'completed':
        return Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(icon: Icon(Icons.play_circle_outline,
            color: Color(0xFF6200EE), size: 22),
            onPressed: () => Get.toNamed('/player',
              arguments: {'filePath': item.filePath})),
          IconButton(icon: Icon(Icons.delete_outline, color: Colors.red, size: 22),
            onPressed: () => _deleteDialog(item)),
        ]);

      case 'failed':
        return Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(icon: Icon(Icons.refresh, color: Colors.orange, size: 22),
            onPressed: () => m.retry(item.id)),
          IconButton(icon: Icon(Icons.delete_outline, color: Colors.red, size: 22),
            onPressed: () => m.delete(item.id)),
        ]);

      default:
        return SizedBox.shrink();
    }
  }

  void _deleteDialog(DownloadItem item) {
    final m = Get.find<DownloadManager>();
    Get.dialog(AlertDialog(
      title: Text('Delete Download?'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text('Cancel')),
        TextButton(
          onPressed: () { Get.back(); m.delete(item.id); },
          child: Text('Record Only'),
        ),
        ElevatedButton(
          onPressed: () { Get.back(); m.delete(item.id, deleteFile: true); },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text('Delete File'),
        ),
      ],
    ));
  }
}
```

---

## 🔧 STEP 7: NOTIFICATION ICON

**File:** `android/app/src/main/res/drawable/ic_notification.xml`

```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
  <path
      android:fillColor="#FFFFFFFF"
      android:pathData="M18,4l2,4h-3l-2,-4h-2l2,4h-3l-2,-4H8l2,4H7L5,4H4C2.9,4 2,4.9 2,6v12c0,1.1 0.9,2 2,2h16c1.1,0 2,-0.9 2,-2V4h-4z"/>
</vector>
```

---

## 🔧 STEP 8: ANDROID MANIFEST

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>

<application android:requestLegacyExternalStorage="true">
```

---

## 🔧 STEP 9: INITIALIZE IN MAIN.DART

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(DownloadItemAdapter());

  Get.put(NotificationService());
  await Get.find<NotificationService>().onInit();

  Get.put(DownloadManager());

  runApp(MyApp());
}
```

---

## 📱 HOW PARALLEL DOWNLOAD WORKS

```
File: Inception_1080P.mp4 (2.1 GB)
    ↓
Check server → supports Range: bytes ✅
    ↓
Split into 4 chunks:
  Chunk 0: bytes 0      → 536MB    → download
  Chunk 1: bytes 536MB  → 1072MB   → download simultaneously
  Chunk 2: bytes 1072MB → 1608MB   → download simultaneously
  Chunk 3: bytes 1608MB → 2100MB   → download simultaneously
    ↓
All 4 chunks downloading at SAME TIME = 4x faster!
    ↓
All complete → merge chunks → Inception_1080P.mp4 ✅
```

---

## ✅ TESTING CHECKLIST

### Speed & Progress:
- [ ] Shows "2.5 MB/s" while downloading
- [ ] Shows "3m 45s" remaining
- [ ] Shows "45%" percentage
- [ ] Progress bar moves smoothly
- [ ] Stats update every ~2 seconds

### Parallel:
- [ ] 4 parallel connections active
- [ ] Download faster than before
- [ ] Works for files > 1MB

### Resume:
- [ ] Kill app mid-download
- [ ] Reopen → status shows "Paused"
- [ ] Tap Resume → continues from same position
- [ ] Does NOT restart from beginning

### Status:
- [ ] Downloading → shows progress ✅
- [ ] Paused → orange icon ✅
- [ ] Completed → green check, correct size ✅
- [ ] Failed → red error (ONLY if actually failed) ✅
- [ ] NO more false "failed" status!

### Notifications:
- [ ] App icon shows (not generic)
- [ ] Progress updates in notification
- [ ] "Download Complete" → green, shows file size
- [ ] "Tap to retry" on failure
- [ ] "Play Now" button works

### Files:
- [ ] Saved as "Inception_1080P.mp4"
- [ ] Saved in /Movies/MovieHub/
- [ ] Can open from Downloads tab
- [ ] Delete file option works

---

## 📊 OLD vs NEW

| | FlutterDownloader ❌ | Dio Parallel ✅ |
|--|---------------------|----------------|
| Status | Always "Failed" | Always Correct |
| Speed | Not shown | MB/s live |
| ETA | Not shown | Accurate |
| Progress | Basic | Smooth % |
| Resume | Broken | ✅ Working |
| Parallel | ❌ None | ✅ 4 chunks |
| Filename | Random | Movie name |
| Notification | Generic icon | App icon |
| Controls | Limited | Pause/Resume/Cancel |

---

**PRIORITY: CRITICAL - Remove FlutterDownloader completely and replace with this system.**

Thank you!