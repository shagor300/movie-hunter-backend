import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/download.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  late Box<Download> _box;
  bool _initialized = false;

  final ReceivePort _port = ReceivePort();

  Future<void> init() async {
    if (_initialized) return;

    _box = await Hive.openBox<Download>('downloads');

    // Register port for background isolate communication
    // Remove existing mapping first to avoid conflicts
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    IsolateNameServer.registerPortWithName(
      _port.sendPort,
      'downloader_send_port',
    );

    _port.listen((dynamic data) {
      final taskId = data[0] as String;
      final status = data[1] as int;
      final progress = data[2] as int;

      _updateDownloadFromCallback(taskId, status, progress);
    });

    _initialized = true;
    debugPrint('✅ DownloadService initialized with port binding');

    // Sync Hive records with flutter_downloader's internal state on cold-start
    await _syncWithDownloader();
  }

  /// Reconcile Hive download records with flutter_downloader's SQLite state.
  /// This catches any status changes that happened while the app was closed.
  Future<void> _syncWithDownloader() async {
    try {
      final tasks = await FlutterDownloader.loadTasks() ?? [];
      final taskMap = {for (var t in tasks) t.taskId: t};

      for (final download in _box.values) {
        if (download.taskId == null) continue;

        final task = taskMap[download.taskId];
        if (task == null) continue;

        bool changed = false;

        // Sync progress
        if (task.progress != download.progress) {
          download.progress = task.progress;
          changed = true;
        }

        // Sync status
        DownloadStatus newStatus;
        switch (task.status.index) {
          case 0: // undefined
            newStatus = download.status; // keep current
            break;
          case 1: // enqueued
            newStatus = DownloadStatus.queued;
            break;
          case 2: // running
            newStatus = DownloadStatus.downloading;
            break;
          case 3: // complete
            newStatus = DownloadStatus.completed;
            break;
          case 4: // failed
            newStatus = DownloadStatus.failed;
            break;
          case 5: // canceled
            newStatus = DownloadStatus.canceled;
            break;
          case 6: // paused
            newStatus = DownloadStatus.paused;
            break;
          default:
            newStatus = download.status;
        }

        if (newStatus != download.status) {
          download.status = newStatus;
          changed = true;
        }

        // Update savedPath for completed downloads
        if (newStatus == DownloadStatus.completed) {
          final correctPath = '${task.savedDir}/${task.filename}';
          if (download.savedPath != correctPath) {
            download.savedPath = correctPath;
            changed = true;
          }
          if (download.progress != 100) {
            download.progress = 100;
            changed = true;
          }
        }

        if (changed) {
          await download.save();
        }
      }
      debugPrint('✅ Download sync complete: ${tasks.length} tasks reconciled');
    } catch (e) {
      debugPrint('⚠️ Error syncing downloads: $e');
    }
  }

  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send?.send([id, status, progress]);
  }

  Future<void> _updateDownloadFromCallback(
    String taskId,
    int status,
    int progress,
  ) async {
    try {
      final download = _box.values.cast<Download?>().firstWhere(
        (d) => d?.taskId == taskId,
        orElse: () => null,
      );

      if (download != null) {
        download.progress = progress;

        switch (status) {
          case 1: // pending
            download.status = DownloadStatus.queued;
            break;
          case 2: // running
            download.status = DownloadStatus.downloading;
            break;
          case 3: // complete
            download.status = DownloadStatus.completed;
            download.progress = 100;
            // Query flutter_downloader for the actual saved path
            try {
              final tasks = await FlutterDownloader.loadTasks() ?? [];
              final task = tasks.firstWhere(
                (t) => t.taskId == taskId,
                orElse: () => tasks.first, // fallback
              );
              if (task.taskId == taskId) {
                download.savedPath = '${task.savedDir}/${task.filename}';
              }
            } catch (_) {
              // Keep existing savedPath if query fails
            }
            break;
          case 4: // failed
            download.status = DownloadStatus.failed;
            break;
          case 5: // canceled
            download.status = DownloadStatus.canceled;
            break;
          case 6: // paused
            download.status = DownloadStatus.paused;
            break;
        }
        download.save();
      }
    } catch (e) {
      debugPrint('Error updating download: $e');
    }
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Request notification permission (Android 13+)
      final notification = await Permission.notification.request();

      // Request storage permission (pre-Android 13)
      final storage = await Permission.storage.request();

      // On Android 13+ storage.request() returns permanently denied
      // but downloads still work – so we only need notification or storage.
      return notification.isGranted || storage.isGranted;
    }
    return true;
  }

  Future<String> _getDownloadDirectory() async {
    final dir = Platform.isAndroid
        ? Directory('/storage/emulated/0/Download/MovieHub')
        : await getApplicationDocumentsDirectory();

    final downloadDir = Platform.isAndroid
        ? dir
        : Directory('${dir.path}/MovieHub');

    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir.path;
  }

  Future<Download?> startDownload({
    required String url,
    required String filename,
    int? tmdbId,
    String? quality,
    required String movieTitle,
  }) async {
    final hasPermission = await _requestPermissions();
    if (!hasPermission) {
      debugPrint('Storage permission denied');
      return null;
    }

    final savedDir = await _getDownloadDirectory();

    // Sanitize filename
    final sanitized = filename.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

    final taskId = await FlutterDownloader.enqueue(
      url: url,
      savedDir: savedDir,
      fileName: sanitized,
      showNotification: true,
      openFileFromNotification: true,
    );

    if (taskId == null) return null;

    final download = Download(
      url: url,
      filename: sanitized,
      movieTitle: movieTitle,
      tmdbId: tmdbId,
      quality: quality,
      taskId: taskId,
      savedPath: '$savedDir/$sanitized',
      status: DownloadStatus.downloading,
    );

    await _box.add(download);
    return download;
  }

  Future<void> pauseDownload(Download download) async {
    if (download.taskId != null) {
      await FlutterDownloader.pause(taskId: download.taskId!);
    }
  }

  Future<void> resumeDownload(Download download) async {
    if (download.taskId != null) {
      final newTaskId = await FlutterDownloader.resume(
        taskId: download.taskId!,
      );
      if (newTaskId != null) {
        download.taskId = newTaskId;
        await download.save();
      }
    }
  }

  Future<void> cancelDownload(Download download) async {
    if (download.taskId != null) {
      await FlutterDownloader.cancel(taskId: download.taskId!);
    }
  }

  Future<void> retryDownload(Download download) async {
    if (download.taskId != null) {
      final newTaskId = await FlutterDownloader.retry(taskId: download.taskId!);
      if (newTaskId != null) {
        download.taskId = newTaskId;
        download.status = DownloadStatus.downloading;
        download.progress = 0;
        await download.save();
      }
    }
  }

  Future<void> deleteDownload(Download download) async {
    if (download.taskId != null) {
      await FlutterDownloader.remove(
        taskId: download.taskId!,
        shouldDeleteContent: true,
      );
    }
    await download.delete();
  }

  List<Download> getAllDownloads() {
    return _box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Download> getActiveDownloads() {
    return _box.values
        .where(
          (d) =>
              d.status == DownloadStatus.downloading ||
              d.status == DownloadStatus.queued ||
              d.status == DownloadStatus.paused,
        )
        .toList();
  }

  List<Download> getCompletedDownloads() {
    return _box.values
        .where((d) => d.status == DownloadStatus.completed)
        .toList();
  }

  Box<Download> get box => _box;
}
