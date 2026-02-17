import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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

  String? _savedFilePath;
  CancelToken? _cancelToken;

  // ── Check for update ──────────────────────────────────────────────

  Future<void> checkForUpdate() async {
    if (isChecking.value) return;
    isChecking.value = true;
    try {
      // Add overall safety timeout
      final info = await _updateService.checkForUpdate().timeout(
        const Duration(seconds: 8),
        onTimeout: () => null,
      );

      if (info != null) {
        updateInfo.value = info;
      }
    } catch (e) {
      debugPrint('Update check error: $e');
      // Silently fail — update check shouldn't block app usage
    } finally {
      isChecking.value = false;
    }
  }

  // ── Download APK using Dio ────────────────────────────────────────

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
      _cancelToken = CancelToken();

      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(minutes: 10);

      await dio.download(
        info.updateUrl,
        _savedFilePath!,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            downloadProgress.value = (received / total * 100).round();
          }
        },
      );

      // Download complete
      isDownloading.value = false;
      downloadProgress.value = 100;
      _installApk();
    } catch (e) {
      isDownloading.value = false;
      if (e is DioException && e.type == DioExceptionType.cancel) {
        debugPrint('Update download cancelled');
        return;
      }
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

  @override
  void onClose() {
    _cancelToken?.cancel('Controller disposed');
    super.onClose();
  }
}
