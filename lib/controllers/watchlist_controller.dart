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
    return _service.isInWatchlist(tmdbId);
  }

  List<WatchlistMovie> getByCategory(WatchlistCategory category) {
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

  Future<void> addRating(int tmdbId, int rating, {String? notes}) async {
    await _service.addRating(tmdbId, rating, notes: notes);
    _loadAll();
  }

  Future<void> toggleWatchlist(Movie movie) async {
    if (isInWatchlist(movie.tmdbId)) {
      await removeFromWatchlist(movie.tmdbId!);
    } else {
      await addToWatchlist(movie);
    }
  }

  @override
  void onClose() {
    _service.box.listenable().removeListener(_loadAll);
    super.onClose();
  }
}
