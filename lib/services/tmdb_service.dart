import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';

class TmdbService {
  static const String _apiKey = "7efd8424c17ff5b3e8dc9cebf4a33f73";
  static const String _baseUrl = "https://api.themoviedb.org/3";

  Future<List<Movie>> searchMovies(String query) async {
    if (query.isEmpty) return [];

    final url = Uri.parse(
      '$_baseUrl/search/multi?api_key=$_apiKey&query=${Uri.encodeComponent(query)}&include_adult=false',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results
            .where((m) => m['media_type'] != 'person')
            .map((m) => Movie.fromJson(m))
            .toList();
      } else {
        debugPrint('TMDB Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('TMDB Exception: $e');
      return [];
    }
  }

  Future<List<Movie>> getTrendingMovies() async {
    final url = Uri.parse('$_baseUrl/trending/all/day?api_key=$_apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results
            .where((m) => m['media_type'] != 'person')
            .map((m) => Movie.fromJson(m))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Discover movies by genre, sorted by popularity.
  /// Returns 20 results per page from TMDB discover API.
  Future<List<Movie>> discoverByGenre(int genreId, {int page = 1}) async {
    final url = Uri.parse(
      '$_baseUrl/discover/movie?api_key=$_apiKey'
      '&with_genres=$genreId'
      '&sort_by=popularity.desc'
      '&include_adult=false'
      '&page=$page',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        // discover/movie doesn't include media_type, so we add it
        return results.map((m) {
          m['media_type'] = 'movie';
          return Movie.fromJson(m);
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('TMDB Discover Genre Error: $e');
      return [];
    }
  }

  /// Discover popular movies only (no TV), sorted by popularity.
  Future<List<Movie>> discoverMovies({int page = 1}) async {
    final url = Uri.parse(
      '$_baseUrl/discover/movie?api_key=$_apiKey'
      '&sort_by=popularity.desc'
      '&include_adult=false'
      '&page=$page',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((m) {
          m['media_type'] = 'movie';
          return Movie.fromJson(m);
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('TMDB Discover Movies Error: $e');
      return [];
    }
  }

  /// Discover popular TV shows only, sorted by popularity.
  Future<List<Movie>> discoverTvShows({int page = 1}) async {
    final url = Uri.parse(
      '$_baseUrl/discover/tv?api_key=$_apiKey'
      '&sort_by=popularity.desc'
      '&include_adult=false'
      '&page=$page',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((m) {
          m['media_type'] = 'tv';
          return Movie.fromJson(m);
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('TMDB Discover TV Error: $e');
      return [];
    }
  }
}
