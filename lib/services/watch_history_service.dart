import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

/// Tracks what movies the user has watched/viewed.
/// Stores view history with timestamps for "Continue Watching" and stats.
class WatchHistoryService {
  static const String _boxName = 'watch_history';

  /// Record that user viewed a movie's details page.
  static Future<void> recordView({
    required int tmdbId,
    required String title,
    required String posterUrl,
    double? rating,
  }) async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      final key = tmdbId.toString();

      await box.put(key, {
        'tmdbId': tmdbId,
        'title': title,
        'posterUrl': posterUrl,
        'rating': rating ?? 0.0,
        'viewCount': ((box.get(key)?['viewCount'] as int?) ?? 0) + 1,
        'lastViewed': DateTime.now().toIso8601String(),
        'firstViewed':
            box.get(key)?['firstViewed'] ?? DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('WatchHistory recordView error: $e');
    }
  }

  /// Get recent watch history (most recent first).
  static Future<List<Map<String, dynamic>>> getHistory({int limit = 30}) async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      final entries =
          box.values.map((e) => Map<String, dynamic>.from(e)).toList()..sort(
            (a, b) => (b['lastViewed'] ?? '').compareTo(a['lastViewed'] ?? ''),
          );
      return entries.take(limit).toList();
    } catch (e) {
      debugPrint('WatchHistory getHistory error: $e');
      return [];
    }
  }

  /// Get frequently viewed movies (for recommendations).
  static Future<List<Map<String, dynamic>>> getFrequent({
    int limit = 10,
  }) async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      final entries =
          box.values.map((e) => Map<String, dynamic>.from(e)).toList()..sort(
            (a, b) => (b['viewCount'] as int? ?? 0).compareTo(
              a['viewCount'] as int? ?? 0,
            ),
          );
      return entries.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  /// Clear all history
  static Future<void> clearHistory() async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      await box.clear();
    } catch (e) {
      debugPrint('WatchHistory clearHistory error: $e');
    }
  }

  /// Get stats
  static Future<Map<String, dynamic>> getStats() async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      int totalViews = 0;
      for (final entry in box.values) {
        totalViews += (entry['viewCount'] as int?) ?? 0;
      }
      return {'uniqueMovies': box.length, 'totalViews': totalViews};
    } catch (e) {
      return {'uniqueMovies': 0, 'totalViews': 0};
    }
  }
}
