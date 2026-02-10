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

  /// Fetch download links for a given movie URL via the backend `/links` endpoint.
  Future<List<Map<String, dynamic>>> getLinks(String movieUrl) async {
    final url = Uri.parse(
      '$baseUrl/links?url=${Uri.encodeComponent(movieUrl)}',
    );

    try {
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['links'] ?? []);
      }
      debugPrint('Links API error: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('Error getting links: $e');
      return [];
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
