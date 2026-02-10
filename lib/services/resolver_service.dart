import 'package:flutter/foundation.dart';
import 'api_service.dart';

class ResolverService {
  final ApiService _apiService = ApiService();

  Future<List<Map<String, String>>> resolveLinks({
    required int tmdbId,
    required String title,
    String? year,
  }) async {
    try {
      final links = await _apiService.getLinks(
        tmdbId: tmdbId,
        title: title,
        year: year,
      );
      return links
          .map(
            (l) => {
              'quality': (l['quality'] ?? 'Unknown').toString(),
              'url': (l['url'] ?? '').toString(),
              'name': (l['name'] ?? 'Download Link').toString(),
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Error in ResolverService: $e');
      return [];
    }
  }
}
