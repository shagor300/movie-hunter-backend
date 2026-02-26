import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/watchlist_movie.dart';
import '../models/movie.dart';
import '../services/watchlist_service.dart';

class WatchlistController extends GetxController {
  final WatchlistService _service = WatchlistService();

  var allMovies = <WatchlistMovie>[].obs;
  var isInitialized = false.obs;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    await _service.init();
    _loadAll();

    _service.box.listenable().addListener(_loadAll);
    isInitialized.value = true;
  }

  void _loadAll() {
    allMovies.assignAll(_service.getAll());
  }

  Future<void> addToWatchlist(
    Movie movie, {
    WatchlistCategory category = WatchlistCategory.watchlist,
  }) async {
    await _service.addToWatchlist(movie, category: category);
    _loadAll();
  }

  Future<void> removeFromWatchlist(int tmdbId) async {
    await _service.removeFromWatchlist(tmdbId);
    _loadAll();
  }

  bool isInWatchlist(int? tmdbId) {
    if (tmdbId == null || tmdbId <= 0) return false;
    final movie = allMovies.firstWhereOrNull((m) => m.tmdbId == tmdbId);
    if (movie == null) return false;
    return movie.category == WatchlistCategory.watchlist;
  }

  bool isFavorite(int? tmdbId) {
    if (tmdbId == null || tmdbId <= 0) return false;
    final movie = allMovies.firstWhereOrNull((m) => m.tmdbId == tmdbId);
    return movie?.favorite ?? false;
  }

  List<WatchlistMovie> getByCategory(WatchlistCategory category) {
    if (category == WatchlistCategory.favorites) {
      return allMovies.where((m) => m.favorite).toList();
    }
    return allMovies.where((m) => m.category == category).toList();
  }

  List<WatchlistMovie> get favorites =>
      allMovies.where((m) => m.favorite).toList();

  Future<void> updateCategory(int tmdbId, WatchlistCategory category) async {
    await _service.updateCategory(tmdbId, category);
    _loadAll();
  }

  Future<void> toggleFavorite(int tmdbId) async {
    await _service.toggleFavorite(tmdbId);
    _loadAll();
  }

  /// Toggle favorite independently — does NOT require or affect watchlist.
  /// If the movie isn't in the Hive box yet, adds it with favorite=true.
  /// If it is, just flips the favorite flag without touching the watchlist category.
  Future<void> toggleFavoriteIndependent(Movie movie) async {
    final tmdbId = movie.tmdbId;
    if (tmdbId == null || tmdbId <= 0) return;

    final existing = _service.getMovie(tmdbId);
    if (existing == null) {
      // Not in box at all — add with favorite=true, category stays default
      await _service.addToWatchlist(
        movie,
        category: WatchlistCategory.favorites,
      );
      // Set favorite flag
      final added = _service.getMovie(tmdbId);
      if (added != null) {
        added.favorite = true;
        await added.save();
      }
    } else {
      // Already exists — just toggle the favorite flag
      existing.favorite = !existing.favorite;
      await existing.save();
    }
    _loadAll();
  }

  Future<void> addRating(int tmdbId, int rating, {String? notes}) async {
    await _service.addRating(tmdbId, rating, notes: notes);
    _loadAll();
  }

  /// Toggle watchlist independently — does NOT affect favorite status.
  Future<void> toggleWatchlist(Movie movie) async {
    final tmdbId = movie.tmdbId;
    if (tmdbId == null || tmdbId <= 0) return;

    final existing = _service.getMovie(tmdbId);
    if (existing == null) {
      // Not in box — add as watchlist
      await addToWatchlist(movie, category: WatchlistCategory.watchlist);
    } else if (existing.category == WatchlistCategory.watchlist) {
      // Already in watchlist — check if it's also favorited
      if (existing.favorite) {
        // Keep in box but change category to favorites only
        existing.category = WatchlistCategory.favorites;
        await existing.save();
        _loadAll();
      } else {
        // Not favorited either — safe to remove entirely
        await removeFromWatchlist(tmdbId);
      }
    } else {
      // Exists but not in watchlist (e.g. only favorited) — add to watchlist
      existing.category = WatchlistCategory.watchlist;
      await existing.save();
      _loadAll();
    }
  }

  @override
  void onClose() {
    _service.box.listenable().removeListener(_loadAll);
    super.onClose();
  }
}
