import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/movie.dart';
import '../models/watchlist_movie.dart';
import '../services/watchlist_service.dart';

class RecommendationService {
  static const String _apiKey = "7efd8424c17ff5b3e8dc9cebf4a33f73";
  static const String _baseUrl = "https://api.themoviedb.org/3";

  final WatchlistService _watchlistService = WatchlistService();

  /// Get movies similar to a given movie from TMDB
  Future<List<Movie>> getSimilarMovies(int tmdbId) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/movie/$tmdbId/similar?api_key=$_apiKey&page=1',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];
        return results.take(10).map((m) => Movie.fromJson(m)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('RecommendationService.getSimilarMovies error: $e');
      return [];
    }
  }

  /// Discover movies by genre IDs from TMDB
  Future<List<Movie>> discoverByGenre(int genreId, {int page = 1}) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/discover/movie?api_key=$_apiKey'
        '&with_genres=$genreId&sort_by=vote_average.desc'
        '&vote_count.gte=100&page=$page',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];
        return results.take(10).map((m) => Movie.fromJson(m)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('RecommendationService.discoverByGenre error: $e');
      return [];
    }
  }

  /// Discover movies with arbitrary TMDB discover params.
  /// Supports: with_original_language, with_cast, with_genres,
  /// primary_release_date, vote_average, vote_count, sort_by, etc.
  Future<List<Movie>> discoverMovies(Map<String, String> params) async {
    try {
      final queryParams = {'api_key': _apiKey, 'page': '1', ...params};
      // Ensure a sort_by default
      queryParams.putIfAbsent('sort_by', () => 'popularity.desc');

      final url = Uri.parse(
        '$_baseUrl/discover/movie',
      ).replace(queryParameters: queryParams);
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];
        return results.take(15).map((m) => Movie.fromJson(m)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('RecommendationService.discoverMovies error: $e');
      return [];
    }
  }

  /// Analyze user preferences from their completed/rated movies
  Map<String, dynamic> analyzeUserPreferences() {
    final completed = _watchlistService.getByCategory(
      WatchlistCategory.completed,
    );

    double totalRating = 0;
    int ratedCount = 0;

    for (var movie in completed) {
      if (movie.userRating != null) {
        totalRating += movie.userRating!;
        ratedCount++;
      }
    }

    return {
      'avgRating': ratedCount > 0 ? totalRating / ratedCount : 0.0,
      'totalWatched': completed.length,
    };
  }

  /// Get genre ID mapping for TMDB
  static const genreMap = {
    'Action': 28,
    'Adventure': 12,
    'Animation': 16,
    'Comedy': 35,
    'Crime': 80,
    'Documentary': 99,
    'Drama': 18,
    'Family': 10751,
    'Fantasy': 14,
    'History': 36,
    'Horror': 27,
    'Music': 10402,
    'Mystery': 9648,
    'Romance': 10749,
    'Science Fiction': 878,
    'Thriller': 53,
    'War': 10752,
    'Western': 37,
  };

  /// Get hidden gems — high rated but less popular movies
  Future<List<Movie>> getHiddenGems() async {
    try {
      final url = Uri.parse(
        '$_baseUrl/discover/movie?api_key=$_apiKey'
        '&sort_by=vote_average.desc'
        '&vote_count.gte=50&vote_count.lte=500'
        '&vote_average.gte=7.5&page=1',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];
        return results.take(10).map((m) => Movie.fromJson(m)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('RecommendationService.getHiddenGems error: $e');
      return [];
    }
  }
}
