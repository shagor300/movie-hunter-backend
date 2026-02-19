import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Centralized HTTP service for the MovieHub backend API.
class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://movie-hunter-backend.onrender.com',
  );

  static const Duration _timeout = Duration(seconds: 30);

  /// Search movies via the backend `/search` endpoint.
  Future<List<Map<String, dynamic>>> searchMovies(String query) async {
    final url = Uri.parse(
      '$baseUrl/search?query=${Uri.encodeComponent(query)}',
    );

    try {
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['results'] ?? []);
      }
      debugPrint('Search API error: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('Error searching movies: $e');
      return [];
    }
  }

  /// Fetch download + embed links via the backend `/links` endpoint.
  /// Returns the full response: { links: [...], embed_links: [...], ... }
  Future<Map<String, dynamic>> getLinks({
    required int tmdbId,
    required String title,
    String? year,
    String? hdhub4uUrl,
    String? source,
    String? skyMoviesHDUrl,
  }) async {
    final queryParams = {
      'tmdb_id': tmdbId.toString(),
      'title': title,
      'year': year,
      'hdhub4u_url': hdhub4uUrl,
      'source': source,
      'skymovieshd_url': skyMoviesHDUrl,
    }..removeWhere((_, v) => v == null);
    final url = Uri.parse(
      '$baseUrl/links',
    ).replace(queryParameters: queryParams);

    try {
      // Link generation can take longer due to scraping
      debugPrint('Fetching links from: $url');
      final response = await http.get(url).timeout(const Duration(seconds: 60));

      debugPrint('Links response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Return full response with both download and embed links
        return data as Map<String, dynamic>;
      }
      debugPrint('Links API error: ${response.statusCode}');
      return {};
    } catch (e) {
      debugPrint('Error getting links: $e');
      return {};
    }
  }

  /// Fetch latest movies from HDHub4u via the `/browse/latest` endpoint.
  Future<List<Map<String, dynamic>>> getLatestFromHDHub4u({
    int maxResults = 50,
  }) async {
    final url = Uri.parse('$baseUrl/browse/latest?max_results=$maxResults');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['movies'] ?? []);
      }
      debugPrint('Browse latest API error: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('Error fetching latest movies: $e');
      return [];
    }
  }

  /// Resolve an intermediate download link (HubDrive, GoFile, etc.)
  /// to a final direct file URL via the backend resolver.
  ///
  /// The backend automates: navigate → click download → wait for countdown
  /// → extract final URL. This can take 15–60 seconds.
  Future<Map<String, dynamic>> resolveDownloadLink({
    required String url,
    String quality = '1080p',
  }) async {
    final uri = Uri.parse('$baseUrl/api/resolve-download-link');

    try {
      debugPrint('🔗 Resolving download link: $url');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'url': url, 'quality': quality}),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          debugPrint('✅ Resolved to: ${data['direct_url']}');
          return {
            'success': true,
            'directUrl': data['direct_url'],
            'filename': data['filename'],
            'filesize': data['filesize'],
          };
        }
      }

      // Non-200 or non-success
      final errorBody = response.statusCode != 200
          ? jsonDecode(response.body)
          : {};
      final errorMsg = errorBody is Map
          ? (errorBody['detail'] is Map
                ? errorBody['detail']['error']
                : errorBody['detail'] ?? 'Resolution failed')
          : 'Resolution failed';
      return {'success': false, 'error': errorMsg.toString()};
    } catch (e) {
      debugPrint('❌ Resolution error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Fetch trending movies from the backend `/trending` endpoint.
  Future<List<Map<String, dynamic>>> getTrending() async {
    final url = Uri.parse('$baseUrl/trending');

    try {
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['results'] ?? []);
      }
      debugPrint('Trending API error: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('Error fetching trending: $e');
      return [];
    }
  }
}
