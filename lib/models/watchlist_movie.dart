import 'package:hive/hive.dart';

part 'watchlist_movie.g.dart';

@HiveType(typeId: 2)
class WatchlistMovie extends HiveObject {
  @HiveField(0)
  final int tmdbId;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? posterUrl;

  @HiveField(3)
  final double rating;

  @HiveField(4)
  final DateTime addedDate;

  @HiveField(5)
  WatchlistCategory category;

  @HiveField(6)
  int? userRating;

  @HiveField(7)
  String? notes;

  @HiveField(8)
  bool favorite;

  @HiveField(9)
  final String? releaseDate;

  @HiveField(10)
  final String? plot;

  WatchlistMovie({
    required this.tmdbId,
    required this.title,
    this.posterUrl,
    required this.rating,
    required this.addedDate,
    required this.category,
    this.userRating,
    this.notes,
    this.favorite = false,
    this.releaseDate,
    this.plot,
  });
}

@HiveType(typeId: 3)
enum WatchlistCategory {
  @HiveField(0)
  watchlist,

  @HiveField(1)
  watching,

  @HiveField(2)
  completed,

  @HiveField(3)
  favorites,
}
