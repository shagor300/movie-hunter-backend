import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../models/notification_settings.dart';

/// Reactive GetX controller for notification preferences.
class NotificationController extends GetxController {
  static const String _boxName = 'notification_settings';

  final settings = NotificationSettings().obs;
  Box<NotificationSettings>? _box;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    try {
      _box = await Hive.openBox<NotificationSettings>(_boxName);
      if (_box!.isNotEmpty) {
        settings.value = _box!.getAt(0)!;
      } else {
        final defaults = NotificationSettings();
        await _box!.add(defaults);
        settings.value = defaults;
      }
      debugPrint('✅ NotificationController: settings loaded');
    } catch (e) {
      debugPrint('❌ NotificationController: $e — resetting');
      await Hive.deleteBoxFromDisk(_boxName);
      _box = await Hive.openBox<NotificationSettings>(_boxName);
      final defaults = NotificationSettings();
      await _box!.add(defaults);
      settings.value = defaults;
    }
  }

  Future<void> _save() async {
    if (_box == null || _box!.isEmpty) return;
    await _box!.putAt(0, settings.value);
    settings.refresh();
  }

  // ── Master ──

  void toggleMaster(bool val) {
    settings.value.masterEnabled = val;
    _save();
  }

  // ── Category toggles ──

  void toggle(String category, bool val) {
    final s = settings.value;
    switch (category) {
      case 'downloadComplete':
        s.downloadComplete = val;
        break;
      case 'downloadFailed':
        s.downloadFailed = val;
        break;
      case 'storageLow':
        s.storageLow = val;
        break;
      case 'appUpdate':
        s.appUpdate = val;
        break;
      case 'criticalUpdate':
        return; // cannot disable
      case 'resumeWatching':
        s.resumeWatching = val;
        break;
      case 'newMoviesDaily':
        s.newMoviesDaily = val;
        break;
      case 'weeklyTrending':
        s.weeklyTrending = val;
        break;
      case 'watchlistAvailable':
        s.watchlistAvailable = val;
        break;
      case 'qualityUpgraded':
        s.qualityUpgraded = val;
        break;
      case 'cacheCleared':
        s.cacheCleared = val;
        break;
      case 'syncComplete':
        s.syncComplete = val;
        break;
    }
    _save();
  }

  // ── Quiet Hours ──

  void toggleQuietHours(bool val) {
    settings.value.quietHoursEnabled = val;
    _save();
  }

  void setQuietStart(TimeOfDay t) {
    settings.value.quietStartHour = t.hour;
    settings.value.quietStartMinute = t.minute;
    _save();
  }

  void setQuietEnd(TimeOfDay t) {
    settings.value.quietEndHour = t.hour;
    settings.value.quietEndMinute = t.minute;
    _save();
  }

  // ── Daily Notification Time ──

  void setDailyTime(TimeOfDay t) {
    settings.value.dailyNotifHour = t.hour;
    settings.value.dailyNotifMinute = t.minute;
    _save();
  }

  // ── Reset ──

  Future<void> resetToDefaults() async {
    settings.value = NotificationSettings();
    await _save();
  }
}
