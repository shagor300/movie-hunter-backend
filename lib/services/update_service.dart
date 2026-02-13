import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import '../models/app_update_info.dart';

/// Service responsible for checking remote update configuration.
class UpdateService {
  /// ── CONFIGURE THIS URL ──────────────────────────────────────────────
  /// Point this to your hosted JSON file (GitHub Gist raw URL, Firebase,
  /// or your own server endpoint).
  static const String _remoteConfigUrl =
      'https://raw.githubusercontent.com/shagor300/movie-hunter-backend/main/update_config.json';

  /// Fetch the remote update configuration.
  Future<AppUpdateInfo?> fetchUpdateInfo() async {
    try {
      final response = await http
          .get(Uri.parse(_remoteConfigUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return AppUpdateInfo.fromJson(json);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get the current app build number.
  Future<int> getCurrentBuildNumber() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform().timeout(
        const Duration(seconds: 5),
      );
      return int.tryParse(packageInfo.buildNumber) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Get the current app version name.
  Future<String> getCurrentVersionName() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform().timeout(
        const Duration(seconds: 5),
      );
      return packageInfo.version;
    } catch (_) {
      return 'Unknown';
    }
  }

  /// Check if an update is available.
  /// Returns [AppUpdateInfo] if update available, null otherwise.
  Future<AppUpdateInfo?> checkForUpdate() async {
    final remoteInfo = await fetchUpdateInfo();
    if (remoteInfo == null) return null;

    final localBuildNumber = await getCurrentBuildNumber();

    if (remoteInfo.latestVersionCode > localBuildNumber) {
      return remoteInfo;
    }
    return null;
  }
}
