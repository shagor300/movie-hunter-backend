import 'package:flutter/foundation.dart';
import 'api_service.dart';

class ResolverService {
  final ApiService _apiService = ApiService();

  /// Resolve both download and embed links from the backend.
  /// Returns a map with 'downloadLinks' and 'embedLinks' lists.
  Future<Map<String, List<Map<String, String>>>> resolveLinks({
    required int tmdbId,
    required String title,
    String? year,
    String? hdhub4uUrl,
    String? source,
    String? skyMoviesHDUrl,
  }) async {
    try {
      final response = await _apiService.getLinks(
        tmdbId: tmdbId,
        title: title,
        year: year,
        hdhub4uUrl: hdhub4uUrl,
        source: source,
        skyMoviesHDUrl: skyMoviesHDUrl,
      );

      // Parse download links
      final rawLinks = List<Map<String, dynamic>>.from(response['links'] ?? []);
      final downloadLinks = rawLinks
          .map(
            (l) => {
              'quality': (l['quality'] ?? 'Unknown').toString(),
              'url': (l['url'] ?? '').toString(),
              'name': (l['name'] ?? 'Download Link').toString(),
            },
          )
          .toList();

      // Parse embed/streaming links
      final rawEmbeds = List<Map<String, dynamic>>.from(
        response['embed_links'] ?? [],
      );
      final embedLinks = rawEmbeds
          .map(
            (l) => {
              'url': (l['url'] ?? '').toString(),
              'quality': (l['quality'] ?? 'HD').toString(),
              'player': (l['player'] ?? 'Player').toString(),
              'type': (l['type'] ?? 'embed').toString(),
            },
          )
          .toList();

      return {'downloadLinks': downloadLinks, 'embedLinks': embedLinks};
    } catch (e) {
      debugPrint('Error in ResolverService: $e');
      return {'downloadLinks': [], 'embedLinks': []};
    }
  }
}
