import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

/// Tracks download activity across the app.
/// Stores download counts per movie for trending calculation.
class DownloadTracker {
  static const String _boxName = 'download_tracker';

  /// Record a download for a movie.
  static Future<void> trackDownload({
    required int tmdbId,
    required String title,
    required String posterUrl,
    String? quality,
  }) async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      final key = tmdbId.toString();

      final existing = box.get(key);
      if (existing != null) {
        final data = Map<String, dynamic>.from(existing);
        data['count'] = (data['count'] as int? ?? 0) + 1;
        data['lastDownloaded'] = DateTime.now().toIso8601String();
        data['lastQuality'] = quality;
        await box.put(key, data);
      } else {
        await box.put(key, {
          'tmdbId': tmdbId,
          'title': title,
          'posterUrl': posterUrl,
          'count': 1,
          'firstDownloaded': DateTime.now().toIso8601String(),
          'lastDownloaded': DateTime.now().toIso8601String(),
          'lastQuality': quality,
        });
      }
    } catch (e) {
      debugPrint('DownloadTracker error: $e');
    }
  }

  /// Get the top N trending (most downloaded) movies.
  static Future<List<Map<String, dynamic>>> getTrending({
    int limit = 20,
  }) async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      final entries = box.values.toList();

      // Sort by count (descending), then by recency
      final typed = entries.map((e) => Map<String, dynamic>.from(e)).toList();
      typed.sort((a, b) {
        final countCompare = (b['count'] as int? ?? 0).compareTo(
          a['count'] as int? ?? 0,
        );
        if (countCompare != 0) return countCompare;
        return (b['lastDownloaded'] ?? '').compareTo(a['lastDownloaded'] ?? '');
      });

      return typed.take(limit).toList();
    } catch (e) {
      debugPrint('DownloadTracker getTrending error: $e');
      return [];
    }
  }

  /// Get total download count
  static Future<int> getTotalDownloads() async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      int total = 0;
      for (final entry in box.values) {
        total += (entry['count'] as int? ?? 0);
      }
      return total;
    } catch (e) {
      return 0;
    }
  }
}
