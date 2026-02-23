import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Smart download queue that manages download priority,
/// prevents duplicates, and tracks queue state.
/// Integrates with the existing DownloadController.
class SmartDownloadQueue {
  static const String _boxName = 'smart_download_queue';

  /// Add a movie's download to the queue.
  /// Priority: 0 = high, 1 = normal, 2 = low
  static Future<bool> enqueue({
    required int tmdbId,
    required String title,
    required String url,
    required String fileName,
    String? quality,
    int priority = 1,
  }) async {
    try {
      final box = await Hive.openBox<Map>(_boxName);

      // Check for duplicate
      for (final entry in box.values) {
        if (entry['url'] == url) {
          debugPrint('SmartQueue: Duplicate detected, skipping: $fileName');
          return false;
        }
      }

      final id = DateTime.now().millisecondsSinceEpoch.toString();
      await box.put(id, {
        'id': id,
        'tmdbId': tmdbId,
        'title': title,
        'url': url,
        'fileName': fileName,
        'quality': quality,
        'priority': priority,
        'status': 'queued', // queued, downloading, completed, failed
        'addedAt': DateTime.now().toIso8601String(),
        'progress': 0.0,
      });

      debugPrint('SmartQueue: Enqueued $fileName (priority: $priority)');
      return true;
    } catch (e) {
      debugPrint('SmartQueue error: $e');
      return false;
    }
  }

  /// Get all queued items sorted by priority (high first) then by time (oldest first).
  static Future<List<Map<String, dynamic>>> getQueue() async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      final entries = box.values
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      entries.sort((a, b) {
        final priorityCompare = (a['priority'] as int? ?? 1).compareTo(
          b['priority'] as int? ?? 1,
        );
        if (priorityCompare != 0) return priorityCompare;
        return (a['addedAt'] ?? '').compareTo(b['addedAt'] ?? '');
      });

      return entries;
    } catch (e) {
      return [];
    }
  }

  /// Get next item to download (highest priority, oldest in queue).
  static Future<Map<String, dynamic>?> getNext() async {
    final queue = await getQueue();
    final pending = queue.where((e) => e['status'] == 'queued');
    return pending.isEmpty ? null : pending.first;
  }

  /// Update status of a queue item.
  static Future<void> updateStatus(
    String id,
    String status, {
    double? progress,
  }) async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      final existing = box.get(id);
      if (existing != null) {
        final data = Map<String, dynamic>.from(existing);
        data['status'] = status;
        if (progress != null) data['progress'] = progress;
        await box.put(id, data);
      }
    } catch (e) {
      debugPrint('SmartQueue updateStatus error: $e');
    }
  }

  /// Remove completed/failed items from queue.
  static Future<void> cleanup() async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      final keysToRemove = <dynamic>[];
      for (final entry in box.toMap().entries) {
        final status = entry.value['status'];
        if (status == 'completed' || status == 'failed') {
          keysToRemove.add(entry.key);
        }
      }
      await box.deleteAll(keysToRemove);
    } catch (e) {
      debugPrint('SmartQueue cleanup error: $e');
    }
  }

  /// Get queue statistics.
  static Future<Map<String, int>> getStats() async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      int queued = 0, downloading = 0, completed = 0, failed = 0;
      for (final entry in box.values) {
        switch (entry['status']) {
          case 'queued':
            queued++;
          case 'downloading':
            downloading++;
          case 'completed':
            completed++;
          case 'failed':
            failed++;
        }
      }
      return {
        'queued': queued,
        'downloading': downloading,
        'completed': completed,
        'failed': failed,
        'total': box.length,
      };
    } catch (e) {
      return {
        'queued': 0,
        'downloading': 0,
        'completed': 0,
        'failed': 0,
        'total': 0,
      };
    }
  }
}
