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

  Movie({
    this.tmdbId,
    required this.title,
    required this.plot,
    required this.tmdbPoster,
    required this.releaseDate,
    required this.rating,
    required this.sources,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    var sourceList = json['sources'] as List? ?? [];
    List<MovieSource> parsedSources = sourceList
        .map((s) => MovieSource.fromJson(s))
        .toList();

    // Map fields from either Enriched Backend or Raw TMDB
    return Movie(
      tmdbId: json['tmdb_id'] ?? json['id'],
      title: json['title'] ?? 'Unknown',
      plot: json['plot'] ?? json['overview'] ?? '',
      tmdbPoster:
          json['tmdb_poster'] ??
          (json['poster_path'] != null
              ? 'https://image.tmdb.org/t/p/w500${json['poster_path']}'
              : ''),
      releaseDate: json['release_date'] ?? 'N/A',
      rating: (json['rating'] ?? json['vote_average'] ?? 0.0).toDouble(),
      sources: parsedSources,
    );
  }

  String get year => releaseDate.isNotEmpty ? releaseDate.split('-')[0] : 'N/A';

  // For backward compatibility if needed, or just use tmdbPoster directly
  String get fullPosterPath => tmdbPoster;
}
