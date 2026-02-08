import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';

class TmdbService {
  static const String _apiKey = "05e5e579c17f5d2539dc6e19fbeac60f";
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
