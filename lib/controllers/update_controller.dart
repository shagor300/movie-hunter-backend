import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import '../models/app_update_info.dart';
import '../services/update_service.dart';

class UpdateController extends GetxController {
  final UpdateService _updateService = UpdateService();

  var isChecking = false.obs;
  var isDownloading = false.obs;
  var downloadProgress = 0.obs;
  var updateInfo = Rxn<AppUpdateInfo>();

  final ReceivePort _port = ReceivePort();
  String? _taskId;
  String? _savedFilePath;

  @override
  void onInit() {
    super.onInit();
    _bindDownloadPort();
  }

  @override
  void onClose() {
    _unbindDownloadPort();
    super.onClose();
  }

  // ── Download port handling ─────────────────────────────────────────

  void _bindDownloadPort() {
    IsolateNameServer.registerPortWithName(
      _port.sendPort,
      'update_downloader_port',
    );

    _port.listen((dynamic data) {
      final List<dynamic> args = data;
      final String id = args[0];
      final int status = args[1];
      final int progress = args[2];

      if (id == _taskId) {
        downloadProgress.value = progress;

        if (status == 3) {
          // DownloadTaskStatus.complete
          isDownloading.value = false;
          downloadProgress.value = 100;
          _installApk();
        } else if (status == 4) {
          // DownloadTaskStatus.failed
          isDownloading.value = false;
          Get.snackbar(
            'Download Failed',
            'Could not download the update. Please try again.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.redAccent.withValues(alpha: 0.85),
            colorText: Colors.white,
            margin: const EdgeInsets.all(20),
          );
        }
      }
    });
  }

  void _unbindDownloadPort() {
    IsolateNameServer.removePortNameMapping('update_downloader_port');
  }

  // ── Check for update ──────────────────────────────────────────────

  Future<void> checkForUpdate() async {
    isChecking.value = true;
    try {
      final info = await _updateService.checkForUpdate();
      if (info != null) {
        updateInfo.value = info;
      }
    } catch (_) {
      // Silently fail — update check shouldn't block app usage
    } finally {
      isChecking.value = false;
    }
  }

  // ── Download APK ──────────────────────────────────────────────────

  Future<void> downloadUpdate() async {
    final info = updateInfo.value;
    if (info == null) return;

    isDownloading.value = true;
    downloadProgress.value = 0;

    try {
      final dir = await getExternalStorageDirectory();
      if (dir == null) {
        isDownloading.value = false;
        return;
      }

      final savePath = dir.path;
      final fileName = 'MovieHub_v${info.latestVersionName}.apk';

      // Remove old APK if exists
      final oldFile = File('$savePath/$fileName');
      if (await oldFile.exists()) {
        await oldFile.delete();
      }

      _savedFilePath = '$savePath/$fileName';

      _taskId = await FlutterDownloader.enqueue(
        url: info.updateUrl,
        savedDir: savePath,
        fileName: fileName,
        showNotification: true,
        openFileFromNotification: true,
      );
    } catch (e) {
      isDownloading.value = false;
      Get.snackbar(
        'Error',
        'Failed to start download: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.85),
        colorText: Colors.white,
        margin: const EdgeInsets.all(20),
      );
    }
  }

  // ── Install APK ───────────────────────────────────────────────────

  Future<void> _installApk() async {
    if (_savedFilePath == null) return;

    try {
      await OpenFilex.open(
        _savedFilePath!,
        type: 'application/vnd.android.package-archive',
      );
    } catch (e) {
      Get.snackbar(
        'Install Error',
        'Could not open the APK. Please install manually from: $_savedFilePath',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orangeAccent.withValues(alpha: 0.85),
        colorText: Colors.black,
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 5),
      );
    }
  }

  /// Dismiss non-forced updates
  void dismissUpdate() {
    updateInfo.value = null;
  }
}
