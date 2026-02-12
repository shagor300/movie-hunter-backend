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
      '$_baseUrl/search/movie?api_key=$_apiKey&query=${Uri.encodeComponent(query)}&include_adult=false',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((m) => Movie.fromJson(m)).toList();
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
    final url = Uri.parse('$_baseUrl/trending/movie/day?api_key=$_apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((m) => Movie.fromJson(m)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
