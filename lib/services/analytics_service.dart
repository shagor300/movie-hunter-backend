import 'package:firebase_analytics/firebase_analytics.dart';

/// Centralized analytics service — log events to Firebase Analytics.
///
/// Usage:
///   AnalyticsService.instance.logMovieView('Inception', 'tt1375666');
///   AnalyticsService.instance.logSearch('Batman');
///   AnalyticsService.instance.logDownloadStart('Inception', '1080p');
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Navigator observer for automatic screen tracking.
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ── Screen Tracking ──

  /// Log when user views a screen.
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // ── Movie Events ──

  /// User viewed a movie's details page.
  Future<void> logMovieView(String title, String movieId) async {
    await _analytics.logEvent(
      name: 'movie_view',
      parameters: {'movie_title': title, 'movie_id': movieId},
    );
  }

  /// User searched for something.
  Future<void> logSearch(String query) async {
    await _analytics.logSearch(searchTerm: query);
  }

  /// User started a download.
  Future<void> logDownloadStart(String title, String quality) async {
    await _analytics.logEvent(
      name: 'download_start',
      parameters: {'movie_title': title, 'quality': quality},
    );
  }

  /// Download completed.
  Future<void> logDownloadComplete(String title, String quality) async {
    await _analytics.logEvent(
      name: 'download_complete',
      parameters: {'movie_title': title, 'quality': quality},
    );
  }

  /// User started watching a movie.
  Future<void> logWatchStart(String title, String source) async {
    await _analytics.logEvent(
      name: 'watch_start',
      parameters: {'movie_title': title, 'source': source},
    );
  }

  /// User added a movie to watchlist.
  Future<void> logAddToWatchlist(String title, String category) async {
    await _analytics.logEvent(
      name: 'add_to_watchlist',
      parameters: {'movie_title': title, 'category': category},
    );
  }

  /// User removed a movie from watchlist.
  Future<void> logRemoveFromWatchlist(String title) async {
    await _analytics.logEvent(
      name: 'remove_from_watchlist',
      parameters: {'movie_title': title},
    );
  }

  /// User shared a movie.
  Future<void> logShare(String title, String method) async {
    await _analytics.logShare(
      contentType: 'movie',
      itemId: title,
      method: method,
    );
  }

  // ── App Events ──

  /// User used voice search.
  Future<void> logVoiceSearch(String query) async {
    await _analytics.logEvent(
      name: 'voice_search',
      parameters: {'query': query},
    );
  }

  /// User changed theme.
  Future<void> logThemeChange(String theme) async {
    await _analytics.logEvent(
      name: 'theme_change',
      parameters: {'theme': theme},
    );
  }

  /// User enabled/disabled app lock.
  Future<void> logAppLockToggle(bool enabled) async {
    await _analytics.logEvent(
      name: 'app_lock_toggle',
      parameters: {'enabled': enabled.toString()},
    );
  }

  /// Generic custom event.
  Future<void> logCustomEvent(
    String name, [
    Map<String, Object>? params,
  ]) async {
    await _analytics.logEvent(name: name, parameters: params);
  }

  // ── User Properties ──

  /// Set user property (e.g. preferred quality, theme).
  Future<void> setUserProperty(String name, String value) async {
    await _analytics.setUserProperty(name: name, value: value);
  }
}
