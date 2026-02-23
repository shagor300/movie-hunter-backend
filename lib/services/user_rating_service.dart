import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

/// User-submitted ratings for movies.
/// Separate from TMDB ratings — these are personal ratings.
class UserRatingService {
  static const String _boxName = 'user_ratings';

  /// Save or update a user rating for a movie.
  static Future<void> rateMovie({
    required int tmdbId,
    required double rating,
    String? title,
  }) async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      await box.put(tmdbId.toString(), {
        'tmdbId': tmdbId,
        'rating': rating,
        'title': title,
        'ratedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('UserRating error: $e');
    }
  }

  /// Get user rating for a specific movie. Returns null if not rated.
  static Future<double?> getRating(int tmdbId) async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      final data = box.get(tmdbId.toString());
      if (data != null) {
        return (data['rating'] as num?)?.toDouble();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get all user ratings.
  static Future<List<Map<String, dynamic>>> getAllRatings() async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      return box.values.map((e) => Map<String, dynamic>.from(e)).toList()
        ..sort((a, b) => (b['ratedAt'] ?? '').compareTo(a['ratedAt'] ?? ''));
    } catch (e) {
      return [];
    }
  }

  /// Remove a rating.
  static Future<void> removeRating(int tmdbId) async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      await box.delete(tmdbId.toString());
    } catch (e) {
      debugPrint('UserRating remove error: $e');
    }
  }
}
