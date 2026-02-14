import 'package:flutter/foundation.dart';

class MovieSource {
  final String site;
  final String url;

  MovieSource({required this.site, required this.url});

  factory MovieSource.fromJson(Map<String, dynamic> json) {
    return MovieSource(site: json['site'] ?? 'Unknown', url: json['url'] ?? '');
  }
}

class Movie {
  final int? tmdbId;
  final String title;
  final String plot;
  final String tmdbPoster;
  final String releaseDate;
  final double rating;
  final List<MovieSource> sources;
  final String? hdhub4uUrl;
  final String? hdhub4uTitle;
  final String? skyMoviesHDUrl;
  final String? skyMoviesHDTitle;
  final String sourceType; // 'hdhub4u' or 'skymovieshd'
  final List<int> genreIds;
  final String? originalLanguage;

  Movie({
    this.tmdbId,
    required this.title,
    required this.plot,
    required this.tmdbPoster,
    required this.releaseDate,
    required this.rating,
    required this.sources,
    this.hdhub4uUrl,
    this.hdhub4uTitle,
    this.skyMoviesHDUrl,
    this.skyMoviesHDTitle,
    this.sourceType = 'hdhub4u',
    this.genreIds = const [],
    this.originalLanguage,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    // Robust ID parsing
    int parseId(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    final id = parseId(json['tmdb_id']) != 0
        ? parseId(json['tmdb_id'])
        : parseId(json['id']);

    if (id <= 0) {
      debugPrint('WARNING: Invalid TMDB ID in JSON: $json');
    }

    var sourceList = json['sources'] as List? ?? [];
    List<MovieSource> parsedSources = sourceList
        .map((s) => MovieSource.fromJson(s))
        .toList();

    return Movie(
      tmdbId: id != 0 ? id : null,
      title: json['title'] ?? 'Unknown',
      plot: json['plot'] ?? json['overview'] ?? '',
      tmdbPoster:
          json['tmdb_poster'] ??
          json['poster_url'] ??
          (json['poster_path'] != null
              ? 'https://image.tmdb.org/t/p/w500${json['poster_path']}'
              : ''),
      releaseDate: json['release_date'] ?? 'N/A',
      rating: (json['rating'] ?? json['vote_average'] ?? 0.0).toDouble(),
      sources: parsedSources,
      hdhub4uUrl: json['hdhub4u_url'],
      hdhub4uTitle: json['hdhub4u_title'],
      skyMoviesHDUrl: json['skymovieshd_url'] ?? json['url'],
      skyMoviesHDTitle: json['skymovieshd_title'] ?? json['original_title'],
      sourceType: json['source_type'] ?? 'hdhub4u',
      genreIds:
          (json['genre_ids'] as List?)
              ?.map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
              .toList() ??
          [],
      originalLanguage: json['original_language'],
    );
  }

  String get year => releaseDate.isNotEmpty ? releaseDate.split('-')[0] : 'N/A';

  /// Returns the full poster URL, handling relative TMDB paths and empty values.
  String get fullPosterPath {
    if (tmdbPoster.isEmpty) return '';
    if (tmdbPoster.startsWith('http')) return tmdbPoster;
    // Relative TMDB path like "/abc123.jpg"
    return 'https://image.tmdb.org/t/p/w500$tmdbPoster';
  }
}
