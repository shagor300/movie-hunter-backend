import 'package:flutter/foundation.dart';
import 'api_service.dart';

class ResolverService {
  final ApiService _apiService = ApiService();

  Future<List<Map<String, String>>> resolveLinks(
    String movieName, {
    String? targetUrl,
  }) async {
    try {
      if (targetUrl != null && targetUrl.isNotEmpty) {
        final links = await _apiService.getLinks(targetUrl);
        return links
            .map(
              (l) => {
                'quality': (l['quality'] ?? 'Unknown').toString(),
                'url': (l['url'] ?? '').toString(),
                'name': (l['name'] ?? 'Download Link').toString(),
              },
            )
            .toList();
      } else {
        // Fallback or automated search if no URL provided
        final searchResults = await _apiService.searchMovies(movieName);
        if (searchResults.isNotEmpty) {
          // Typically we'd let the user pick, but if we're "resolving"
          // we might take the first result or perform a secondary scan
          final firstUrl = searchResults.first['url'];
          if (firstUrl != null) {
            final links = await _apiService.getLinks(firstUrl);
            return links
                .map(
                  (l) => {
                    'quality': (l['quality'] ?? 'Unknown').toString(),
                    'url': (l['url'] ?? '').toString(),
                    'name': (l['name'] ?? 'Download Link').toString(),
                  },
                )
                .toList();
          }
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error in ResolverService: $e');
      return [];
    }
  }
}
