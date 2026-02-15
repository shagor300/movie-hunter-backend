import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:workmanager/workmanager.dart';

import '../services/api_service.dart';
import '../services/notification_service.dart';

/// Background scheduling via WorkManager.
class NotificationScheduler {
  static const String dailyTask = 'daily_new_movies';
  static const String weeklyTask = 'weekly_trending';

  /// Register background tasks. Call once from main().
  static Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );

    // Daily task — runs every 24h
    await Workmanager().registerPeriodicTask(
      dailyTask,
      dailyTask,
      frequency: const Duration(hours: 24),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );

    // Weekly task — runs every 7 days
    await Workmanager().registerPeriodicTask(
      weeklyTask,
      weeklyTask,
      frequency: const Duration(hours: 168), // 7 days
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );

    debugPrint('✅ NotificationScheduler: background tasks registered');
  }

  /// Cancel all scheduled tasks.
  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
  }
}

/// Top-level callback for WorkManager — must be a top-level function.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    debugPrint('📋 Background task: $taskName');

    try {
      final notifService = NotificationService.instance;
      await notifService.init();

      switch (taskName) {
        case NotificationScheduler.dailyTask:
          await _handleDailyNewMovies(notifService);
          break;
        case NotificationScheduler.weeklyTask:
          await _handleWeeklyTrending(notifService);
          break;
      }
    } catch (e) {
      debugPrint('❌ Background task error: $e');
    }

    return true;
  });
}

Future<void> _handleDailyNewMovies(NotificationService service) async {
  try {
    final url = Uri.parse('${ApiService.baseUrl}/browse/latest?max_results=10');
    final response = await http.get(url).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final movies = data['movies'] as List? ?? [];

      if (movies.isNotEmpty) {
        final titles = movies
            .take(5)
            .map((m) => (m as Map)['title']?.toString() ?? '')
            .where((t) => t.isNotEmpty)
            .toList();

        await service.showNewMovies(movies.length, titles);
      }
    }
  } catch (e) {
    debugPrint('❌ Daily new movies error: $e');
  }
}

Future<void> _handleWeeklyTrending(NotificationService service) async {
  try {
    final url = Uri.parse('${ApiService.baseUrl}/trending');
    final response = await http.get(url).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final movies = data['movies'] as List? ?? [];

      if (movies.isNotEmpty) {
        final titles = movies
            .take(5)
            .map((m) => (m as Map)['title']?.toString() ?? '')
            .where((t) => t.isNotEmpty)
            .toList();

        await service.showWeeklyTrending(titles);
      }
    }
  } catch (e) {
    debugPrint('❌ Weekly trending error: $e');
  }
}
