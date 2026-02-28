import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/app_update_info.dart';

/// Firebase Remote Config service — fetches app update configuration
/// controlled from the Admin Panel.
///
/// Remote Config keys:
///   - `current_version`  → String, e.g. "1.2.0+5"
///   - `update_url`       → String, APK download URL
///   - `is_force_update`  → Boolean, non-dismissible dialog
///   - `whats_new`        → String, comma-separated changelog items
class RemoteConfigService {
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();

  late final FirebaseRemoteConfig _remoteConfig;
  bool _initialized = false;

  /// Initialize Remote Config with defaults and fetch settings.
  Future<void> init() async {
    if (_initialized) return;

    _remoteConfig = FirebaseRemoteConfig.instance;

    // Set fetch interval to 0 for testing (instant updates)
    // Change to 3600 (1 hour) for production
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: Duration.zero, // 0 for testing
      ),
    );

    // Set default values (used before first successful fetch)
    await _remoteConfig.setDefaults({
      'current_version': '1.0.0+1',
      'update_url': '',
      'is_force_update': false,
      'whats_new': '',
    });

    _initialized = true;
    debugPrint('✅ RemoteConfig: initialized');
  }

  /// Fetch and activate latest config from Firebase.
  Future<bool> fetchAndActivate() async {
    try {
      final updated = await _remoteConfig.fetchAndActivate();
      debugPrint('✅ RemoteConfig: fetched (changed=$updated)');
      return updated;
    } catch (e) {
      debugPrint('❌ RemoteConfig: fetch failed: $e');
      return false;
    }
  }

  // ── Getters ──

  String get currentVersion => _remoteConfig.getString('current_version');
  String get updateUrl => _remoteConfig.getString('update_url');
  bool get isForceUpdate => _remoteConfig.getBool('is_force_update');
  String get whatsNewRaw => _remoteConfig.getString('whats_new');

  List<String> get whatsNew {
    final raw = whatsNewRaw.trim();
    if (raw.isEmpty) return [];
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  // ── Version Comparison ──

  /// Parse version string like "1.2.0+5" into build number (5)
  /// and version name ("1.2.0").
  static (String versionName, int buildNumber) parseVersion(String version) {
    final parts = version.split('+');
    final versionName = parts[0].trim();
    final buildNumber = parts.length > 1
        ? int.tryParse(parts[1].trim()) ?? 0
        : 0;
    return (versionName, buildNumber);
  }

  /// Check if update is available by comparing build numbers.
  /// Returns [AppUpdateInfo] if update needed, null otherwise.
  Future<AppUpdateInfo?> checkForUpdate() async {
    await fetchAndActivate();

    final remoteVersion = currentVersion;
    final (remoteVersionName, remoteBuildNumber) = parseVersion(remoteVersion);

    if (remoteBuildNumber <= 0 || updateUrl.isEmpty) return null;

    // Get installed version
    try {
      final packageInfo = await PackageInfo.fromPlatform().timeout(
        const Duration(seconds: 5),
      );
      final localBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      debugPrint(
        '📦 RemoteConfig: remote=$remoteVersion (build $remoteBuildNumber) '
        'vs local=${packageInfo.version}+${packageInfo.buildNumber} (build $localBuildNumber)',
      );

      if (remoteBuildNumber > localBuildNumber) {
        return AppUpdateInfo(
          latestVersionCode: remoteBuildNumber,
          latestVersionName: remoteVersionName,
          updateUrl: updateUrl,
          isForceUpdate: isForceUpdate,
          whatsNew: whatsNew,
        );
      }
    } catch (e) {
      debugPrint('❌ RemoteConfig: version check failed: $e');
    }

    return null;
  }
}
