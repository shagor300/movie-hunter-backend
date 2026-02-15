import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/homepage_movie.dart';
import 'api_service.dart';

/// Offline-first homepage service: Hive cache + incremental backend sync.
class HomepageService {
  static const String _boxName = 'homepage_movies';
  Box<HomepageMovie>? _box;

  // ── initialisation ────────────────────────────────────────────────────

  Future<void> init() async {
    try {
      _box = await Hive.openBox<HomepageMovie>(_boxName);
    } catch (e) {
      // Box corrupted (e.g. typeId migration) — delete and recreate
      debugPrint('⚠️ HomepageService: box corrupted, resetting — $e');
      await Hive.deleteBoxFromDisk(_boxName);
      _box = await Hive.openBox<HomepageMovie>(_boxName);
    }
    debugPrint('✅ HomepageService: ${_box!.length} cached movies');
  }

  // ── local reads (instant) ─────────────────────────────────────────────

  /// All locally-cached movies, newest first.
  List<HomepageMovie> getLocal() {
    if (_box == null || _box!.isEmpty) return [];
    return _box!.values.toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
  }

  bool get isEmpty => _box == null || _box!.isEmpty;

  // ── sync with backend ─────────────────────────────────────────────────

  /// Fetch from backend with smart incremental mode.
  ///
  /// * First launch (empty cache) → full sync.
  /// * Subsequent launches → incremental (only new movies).
  ///
  /// Returns the complete local movie list (old + new merged).
  Future<List<HomepageMovie>> sync() async {
    final incremental = !isEmpty;
    debugPrint(
      '🔄 HomepageService.sync (incremental=$incremental, cached=${_box?.length ?? 0})',
    );

    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/browse/latest?incremental=$incremental&max_results=50',
      );

      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final movies = (data['movies'] as List? ?? [])
            .map((j) => HomepageMovie.fromJson(j as Map<String, dynamic>))
            .toList();

        debugPrint(
          '📥 Received ${movies.length} movies (mode=${data['sync_mode']})',
        );

        if (movies.isNotEmpty) {
          await _merge(movies);
        }
      } else {
        debugPrint('⚠️ Browse latest returned ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Sync error: $e');
      // If we have cached data, don't propagate — user can still see movies
      if (isEmpty) rethrow;
    }

    return getLocal();
  }

  // ── internal helpers ──────────────────────────────────────────────────

  Future<void> _merge(List<HomepageMovie> incoming) async {
    if (_box == null) return;

    // Build index of existing tmdbIds for O(1) lookup
    final existingIds = <int, dynamic>{};
    for (final key in _box!.keys) {
      final movie = _box!.get(key);
      if (movie != null) existingIds[movie.tmdbId] = key;
    }

    int added = 0;
    for (final movie in incoming) {
      if (existingIds.containsKey(movie.tmdbId)) {
        // Update existing entry
        await _box!.put(existingIds[movie.tmdbId], movie);
      } else {
        // New movie
        await _box!.add(movie);
        added++;
      }
    }

    debugPrint('💾 Merged: $added new, ${incoming.length - added} updated');
  }

  /// Clear the local cache (forces full sync on next call).
  Future<void> clearCache() async {
    await _box?.clear();
    debugPrint('🗑️ Homepage cache cleared');
  }
}
