import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Fetches movie trailers from TMDB API.
class TrailerService {
  static const String _apiKey = "7efd8424c17ff5b3e8dc9cebf4a33f73";
  static const String _baseUrl = "https://api.themoviedb.org/3";

  /// Fetches the best YouTube trailer key for a movie.
  /// Returns null if no trailer is found.
  /// Priority: Official Trailer → Trailer → Teaser → any YouTube video.
  static Future<String?> getTrailerKey(int tmdbId) async {
    final url = Uri.parse(
      '$_baseUrl/movie/$tmdbId/videos?api_key=$_apiKey&language=en-US',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];

        if (results.isEmpty) return null;

        // Filter for YouTube videos only
        final youtubeVideos = results
            .where((v) => v['site'] == 'YouTube' && v['key'] != null)
            .toList();

        if (youtubeVideos.isEmpty) return null;

        // Priority 1: Official Trailer
        final officialTrailer = youtubeVideos.firstWhere(
          (v) =>
              v['type'] == 'Trailer' &&
              (v['official'] == true ||
                  v['name']?.toString().toLowerCase().contains('official') ==
                      true),
          orElse: () => null,
        );
        if (officialTrailer != null) return officialTrailer['key'];

        // Priority 2: Any Trailer
        final anyTrailer = youtubeVideos.firstWhere(
          (v) => v['type'] == 'Trailer',
          orElse: () => null,
        );
        if (anyTrailer != null) return anyTrailer['key'];

        // Priority 3: Teaser
        final teaser = youtubeVideos.firstWhere(
          (v) => v['type'] == 'Teaser',
          orElse: () => null,
        );
        if (teaser != null) return teaser['key'];

        // Priority 4: Any YouTube video
        return youtubeVideos.first['key'];
      }

      debugPrint('TMDB Videos API error: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error fetching trailer: $e');
      return null;
    }
  }

  /// Returns the full YouTube URL for a video key.
  static String getYouTubeUrl(String key) {
    return 'https://www.youtube.com/watch?v=$key';
  }

  /// Returns the YouTube thumbnail URL for a video key.
  static String getThumbnailUrl(String key) {
    return 'https://img.youtube.com/vi/$key/hqdefault.jpg';
  }

  /// Fetches similar movies from TMDB API.
  static Future<List<Map<String, dynamic>>> getSimilarMovies(int tmdbId) async {
    final url = Uri.parse(
      '$_baseUrl/movie/$tmdbId/similar?api_key=$_apiKey&language=en-US&page=1',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['results'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching similar movies: $e');
      return [];
    }
  }

  /// Fetches recommended movies from TMDB API.
  static Future<List<Map<String, dynamic>>> getRecommendations(
    int tmdbId,
  ) async {
    final url = Uri.parse(
      '$_baseUrl/movie/$tmdbId/recommendations?api_key=$_apiKey&language=en-US&page=1',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['results'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching recommendations: $e');
      return [];
    }
  }
}
