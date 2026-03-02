import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Regex to pull S01E03 / E05 from a string.
final _episodeRe = RegExp(
  r'S(\d{1,2})\s*E(\d{1,3})|(?:Episode|Ep)\.?\s*(\d{1,3})|\bE(\d{1,3})\b',
  caseSensitive: false,
);

/// Try to extract episode label from text. Returns e.g. 'S01E03' or null.
String? _extractEpisode(String text) {
  final m = _episodeRe.firstMatch(text);
  if (m == null) return null;
  if (m.group(1) != null && m.group(2) != null) {
    final s = int.parse(m.group(1)!).toString().padLeft(2, '0');
    final e = int.parse(m.group(2)!).toString().padLeft(2, '0');
    return 'S${s}E$e';
  }
  final epNum = m.group(3) ?? m.group(4);
  if (epNum != null) {
    return 'E${int.parse(epNum).toString().padLeft(2, '0')}';
  }
  return null;
}

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
      final downloadLinks = rawLinks.map((l) {
        // Extract episode info: prefer backend field, fallback to regex on name/url
        String episode = (l['episode'] ?? '').toString();
        if (episode.isEmpty) {
          final nameStr = (l['name'] ?? '').toString();
          final urlStr = (l['url'] ?? '').toString();
          episode = _extractEpisode(nameStr) ?? _extractEpisode(urlStr) ?? '';
        }

        return <String, String>{
          'quality': (l['quality'] ?? 'Unknown').toString(),
          'url': (l['url'] ?? '').toString(),
          'name': (l['name'] ?? 'Download Link').toString(),
          'episode': episode,
        };
      }).toList();

      // Parse embed/streaming links
      final rawEmbeds = List<Map<String, dynamic>>.from(
        response['embed_links'] ?? [],
      );
      final embedLinks = rawEmbeds.map((l) {
        return <String, String>{
          'url': (l['url'] ?? '').toString(),
          'quality': (l['quality'] ?? 'HD').toString(),
          'player': (l['player'] ?? 'Player').toString(),
          'type': (l['type'] ?? 'embed').toString(),
        };
      }).toList();

      return {'downloadLinks': downloadLinks, 'embedLinks': embedLinks};
    } catch (e) {
      debugPrint('Error in ResolverService: $e');
      return {'downloadLinks': [], 'embedLinks': []};
    }
  }
}
