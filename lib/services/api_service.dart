import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://movie-hunter-backend.onrender.com';

  Future<List<Map<String, dynamic>>> searchMovies(String query) async {
    final url = Uri.parse(
      '$baseUrl/search?query=${Uri.encodeComponent(query)}',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['results']);
      }
      return [];
    } catch (e) {
      debugPrint('Error searching movies: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getLinks(String movieUrl) async {
    final url = Uri.parse(
      '$baseUrl/links?url=${Uri.encodeComponent(movieUrl)}',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['links']);
      }
      return [];
    } catch (e) {
      debugPrint('Error getting links: $e');
      return [];
    }
  }
}
