import 'package:hive/hive.dart';

part 'homepage_movie.g.dart';

/// A movie scraped from the homepage (HDHub4u / SkyMoviesHD),
/// persisted locally via Hive for offline‑first + incremental sync.
@HiveType(typeId: 5)
class HomepageMovie extends HiveObject {
  @HiveField(0)
  final int tmdbId;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? posterUrl;

  @HiveField(3)
  final String? backdropUrl;

  @HiveField(4)
  final double rating;

  @HiveField(5)
  final String overview;

  @HiveField(6)
  final String? releaseDate;

  @HiveField(7)
  final String? year;

  @HiveField(8)
  final String sourceUrl; // HDHub4u / SkyMoviesHD page URL

  @HiveField(9)
  final String source; // 'hdhub4u' | 'skymovieshd'

  @HiveField(10)
  final DateTime addedAt;

  HomepageMovie({
    required this.tmdbId,
    required this.title,
    this.posterUrl,
    this.backdropUrl,
    required this.rating,
    required this.overview,
    this.releaseDate,
    this.year,
    required this.sourceUrl,
    required this.source,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  /// Parse from the backend JSON returned by `/browse/latest`.
  factory HomepageMovie.fromJson(Map<String, dynamic> json) {
    return HomepageMovie(
      tmdbId: json['tmdb_id'] ?? json['id'] ?? 0,
      title: json['title'] ?? 'Unknown',
      posterUrl: json['poster_url'],
      backdropUrl: json['backdrop_url'],
      rating: (json['rating'] ?? json['vote_average'] ?? 0).toDouble(),
      overview: json['overview'] ?? '',
      releaseDate: json['release_date'],
      year: json['year'],
      sourceUrl: json['hdhub4u_url'] ?? json['url'] ?? '',
      source: json['source'] ?? 'hdhub4u',
    );
  }
}
