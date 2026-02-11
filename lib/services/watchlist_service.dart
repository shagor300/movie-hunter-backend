import 'package:hive/hive.dart';
import '../models/watchlist_movie.dart';
import '../models/movie.dart';

class WatchlistService {
  static final WatchlistService _instance = WatchlistService._internal();
  factory WatchlistService() => _instance;
  WatchlistService._internal();

  late Box<WatchlistMovie> _box;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _box = await Hive.openBox<WatchlistMovie>('watchlist_v2');
    _initialized = true;
  }

  Future<void> addToWatchlist(
    Movie movie, {
    WatchlistCategory category = WatchlistCategory.watchlist,
  }) async {
    if (movie.tmdbId == null || movie.tmdbId! <= 0) return;

    final watchlistMovie = WatchlistMovie(
      tmdbId: movie.tmdbId!,
      title: movie.title,
      posterUrl: movie.tmdbPoster,
      rating: movie.rating,
      addedDate: DateTime.now(),
      category: category,
      releaseDate: movie.releaseDate,
      plot: movie.plot,
    );

    await _box.put(movie.tmdbId, watchlistMovie);
  }

  Future<void> removeFromWatchlist(int tmdbId) async {
    await _box.delete(tmdbId);
  }

  bool isInWatchlist(int tmdbId) {
    return _box.containsKey(tmdbId);
  }

  WatchlistMovie? getMovie(int tmdbId) {
    return _box.get(tmdbId);
  }

  List<WatchlistMovie> getAll() {
    return _box.values.toList()
      ..sort((a, b) => b.addedDate.compareTo(a.addedDate));
  }

  List<WatchlistMovie> getByCategory(WatchlistCategory category) {
    return _box.values.where((m) => m.category == category).toList()
      ..sort((a, b) => b.addedDate.compareTo(a.addedDate));
  }

  List<WatchlistMovie> getFavorites() {
    return _box.values.where((m) => m.favorite).toList()
      ..sort((a, b) => b.addedDate.compareTo(a.addedDate));
  }

  Future<void> updateCategory(int tmdbId, WatchlistCategory category) async {
    final movie = _box.get(tmdbId);
    if (movie != null) {
      movie.category = category;
      await movie.save();
    }
  }

  Future<void> toggleFavorite(int tmdbId) async {
    final movie = _box.get(tmdbId);
    if (movie != null) {
      movie.favorite = !movie.favorite;
      await movie.save();
    }
  }

  Future<void> addRating(int tmdbId, int rating, {String? notes}) async {
    final movie = _box.get(tmdbId);
    if (movie != null) {
      movie.userRating = rating;
      if (notes != null) movie.notes = notes;
      await movie.save();
    }
  }

  Box<WatchlistMovie> get box => _box;
}
