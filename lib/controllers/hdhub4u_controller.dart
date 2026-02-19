import 'dart:async';
import 'package:get/get.dart';
import '../models/movie.dart';
import '../models/homepage_movie.dart';
import '../services/homepage_service.dart';

/// Manages HDHub4u homepage movies with offline‑first + incremental sync.
///
/// Flow:
///   1. `onInit` → load from Hive (instant) → show UI
///   2. Background `sync()` → fetch only new movies from backend
///   3. Merge new at top, update reactive list
class HDHub4uController extends GetxController {
  final HomepageService _homepageService = HomepageService();

  var movies = <Movie>[].obs;
  var isLoading = false.obs;
  var isSyncing = false.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    try {
      await _homepageService.init();

      // ① Show cached data instantly
      final cached = _homepageService.getLocal();
      if (cached.isNotEmpty) {
        movies.value = cached.map(_toMovie).toList();
      }

      // ② Sync in background
      await syncMovies();
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
    }
  }

  /// Sync with backend (incremental if we have cached data).
  Future<void> syncMovies() async {
    try {
      isSyncing.value = true;
      hasError.value = false;

      if (movies.isEmpty) {
        isLoading.value = true; // full-screen loader on first launch
      }

      final updated = await _homepageService.sync();
      movies.value = updated.map(_toMovie).toList();

      if (movies.isEmpty) {
        hasError.value = true;
        errorMessage.value =
            'No movies returned from server. The backend may still be deploying.';
      }
    } on TimeoutException {
      hasError.value = true;
      errorMessage.value =
          'Request timed out. The backend may be scraping new movies — try again in a moment.';
    } catch (e) {
      hasError.value = true;
      final msg = e.toString().toLowerCase();
      if (msg.contains('timeout') || msg.contains('timed out')) {
        errorMessage.value =
            'Request timed out. The backend may be scraping new movies — try again in a moment.';
      } else {
        errorMessage.value = e.toString();
      }
    } finally {
      isLoading.value = false;
      isSyncing.value = false;
    }
  }

  /// Pull-to-refresh / manual refresh.
  @override
  Future<void> refresh() async => syncMovies();

  /// Force full sync (clears cache first).
  Future<void> forceFullSync() async {
    await _homepageService.clearCache();
    movies.clear();
    await syncMovies();
  }

  // ── helper ──────────────────────────────────────────────────────────

  /// Convert a `HomepageMovie` (Hive) → `Movie` (used across the app).
  Movie _toMovie(HomepageMovie hm) {
    return Movie(
      tmdbId: hm.tmdbId,
      title: hm.title,
      plot: hm.overview,
      tmdbPoster: hm.posterUrl ?? '',
      releaseDate: hm.releaseDate ?? '',
      rating: hm.rating,
      sources: const [],
      hdhub4uUrl: hm.source == 'hdhub4u' ? hm.sourceUrl : null,
      skyMoviesHDUrl: hm.source == 'skymovieshd' ? hm.sourceUrl : null,
      sourceType: hm.source,
    );
  }
}
