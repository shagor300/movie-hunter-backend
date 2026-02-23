import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

/// Movie Collection — user-created groups of movies (e.g., "MCU", "Must Watch").
/// Each collection has a name, optional description, and a list of movies.
class MovieCollectionService {
  static const String _boxName = 'movie_collections';

  /// Create a new collection.
  static Future<String> createCollection({
    required String name,
    String? description,
    String? emoji,
  }) async {
    final box = await Hive.openBox<Map>(_boxName);
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    await box.put(id, {
      'id': id,
      'name': name,
      'description': description ?? '',
      'emoji': emoji ?? '🎬',
      'movies': <Map>[],
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    return id;
  }

  /// Get all collections.
  static Future<List<Map<String, dynamic>>> getCollections() async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      return box.values.map((e) => Map<String, dynamic>.from(e)).toList()..sort(
        (a, b) => (b['updatedAt'] ?? '').compareTo(a['updatedAt'] ?? ''),
      );
    } catch (e) {
      debugPrint('Collection getAll error: $e');
      return [];
    }
  }

  /// Add a movie to a collection.
  static Future<void> addToCollection({
    required String collectionId,
    required int tmdbId,
    required String title,
    required String posterUrl,
    double? rating,
  }) async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      final data = box.get(collectionId);
      if (data == null) return;

      final collection = Map<String, dynamic>.from(data);
      final movies = List<Map>.from(collection['movies'] ?? []);

      // Check duplicate
      if (movies.any((m) => m['tmdbId'] == tmdbId)) {
        debugPrint('Movie already in collection');
        return;
      }

      movies.add({
        'tmdbId': tmdbId,
        'title': title,
        'posterUrl': posterUrl,
        'rating': rating ?? 0.0,
        'addedAt': DateTime.now().toIso8601String(),
      });

      collection['movies'] = movies;
      collection['updatedAt'] = DateTime.now().toIso8601String();
      await box.put(collectionId, collection);
    } catch (e) {
      debugPrint('Collection add error: $e');
    }
  }

  /// Remove a movie from a collection.
  static Future<void> removeFromCollection({
    required String collectionId,
    required int tmdbId,
  }) async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      final data = box.get(collectionId);
      if (data == null) return;

      final collection = Map<String, dynamic>.from(data);
      final movies = List<Map>.from(collection['movies'] ?? []);
      movies.removeWhere((m) => m['tmdbId'] == tmdbId);
      collection['movies'] = movies;
      collection['updatedAt'] = DateTime.now().toIso8601String();
      await box.put(collectionId, collection);
    } catch (e) {
      debugPrint('Collection remove error: $e');
    }
  }

  /// Delete a collection.
  static Future<void> deleteCollection(String collectionId) async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      await box.delete(collectionId);
    } catch (e) {
      debugPrint('Collection delete error: $e');
    }
  }

  /// Get a specific collection.
  static Future<Map<String, dynamic>?> getCollection(
    String collectionId,
  ) async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      final data = box.get(collectionId);
      if (data != null) return Map<String, dynamic>.from(data);
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get collections that contain a specific movie.
  static Future<List<String>> getCollectionsForMovie(int tmdbId) async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      final result = <String>[];
      for (final entry in box.toMap().entries) {
        final movies = List<Map>.from(entry.value['movies'] ?? []);
        if (movies.any((m) => m['tmdbId'] == tmdbId)) {
          result.add(entry.key.toString());
        }
      }
      return result;
    } catch (e) {
      return [];
    }
  }
}
