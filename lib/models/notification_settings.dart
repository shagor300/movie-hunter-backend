import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'notification_settings.g.dart';

/// Persisted notification preferences.
@HiveType(typeId: 8)
class NotificationSettings extends HiveObject {
  @HiveField(0)
  bool masterEnabled;

  // ── Downloads ──
  @HiveField(1)
  bool downloadComplete;

  @HiveField(2)
  bool downloadFailed;

  @HiveField(3)
  bool storageLow;

  // ── Updates ──
  @HiveField(4)
  bool appUpdate;

  @HiveField(5)
  bool criticalUpdate; // always true, cannot disable

  // ── Playback ──
  @HiveField(6)
  bool resumeWatching;

  // ── Content ──
  @HiveField(7)
  bool newMoviesDaily;

  @HiveField(8)
  bool weeklyTrending;

  // ── Watchlist ──
  @HiveField(9)
  bool watchlistAvailable;

  @HiveField(10)
  bool qualityUpgraded;

  // ── System ──
  @HiveField(11)
  bool cacheCleared;

  @HiveField(12)
  bool syncComplete;

  // ── Quiet Hours ──
  @HiveField(13)
  bool quietHoursEnabled;

  @HiveField(14)
  int quietStartHour; // 0-23

  @HiveField(15)
  int quietStartMinute;

  @HiveField(16)
  int quietEndHour;

  @HiveField(17)
  int quietEndMinute;

  // ── Daily notification time ──
  @HiveField(18)
  int dailyNotifHour;

  @HiveField(19)
  int dailyNotifMinute;

  NotificationSettings({
    this.masterEnabled = true,
    this.downloadComplete = true,
    this.downloadFailed = true,
    this.storageLow = true,
    this.appUpdate = true,
    this.criticalUpdate = true,
    this.resumeWatching = true,
    this.newMoviesDaily = true,
    this.weeklyTrending = true,
    this.watchlistAvailable = true,
    this.qualityUpgraded = true,
    this.cacheCleared = true,
    this.syncComplete = true,
    this.quietHoursEnabled = false,
    this.quietStartHour = 23,
    this.quietStartMinute = 0,
    this.quietEndHour = 7,
    this.quietEndMinute = 0,
    this.dailyNotifHour = 9,
    this.dailyNotifMinute = 0,
  });

  /// Check if current time is within quiet hours.
  bool get isQuietTime {
    if (!quietHoursEnabled) return false;
    final now = TimeOfDay.now();
    final nowMin = now.hour * 60 + now.minute;
    final startMin = quietStartHour * 60 + quietStartMinute;
    final endMin = quietEndHour * 60 + quietEndMinute;

    if (startMin <= endMin) {
      return nowMin >= startMin && nowMin < endMin;
    } else {
      // Wraps midnight (e.g. 23:00 → 07:00)
      return nowMin >= startMin || nowMin < endMin;
    }
  }

  /// Whether a specific category is enabled (master + category toggle).
  bool isEnabled(String category) {
    if (!masterEnabled) return false;
    switch (category) {
      case 'downloadComplete':
        return downloadComplete;
      case 'downloadFailed':
        return downloadFailed;
      case 'storageLow':
        return storageLow;
      case 'appUpdate':
        return appUpdate;
      case 'criticalUpdate':
        return true; // always enabled
      case 'resumeWatching':
        return resumeWatching;
      case 'newMoviesDaily':
        return newMoviesDaily;
      case 'weeklyTrending':
        return weeklyTrending;
      case 'watchlistAvailable':
        return watchlistAvailable;
      case 'qualityUpgraded':
        return qualityUpgraded;
      case 'cacheCleared':
        return cacheCleared;
      case 'syncComplete':
        return syncComplete;
      default:
        return true;
    }
  }
}
