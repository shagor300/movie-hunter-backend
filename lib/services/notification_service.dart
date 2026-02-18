import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'package:get/get.dart';

import '../controllers/notification_controller.dart';
import '../screens/home_screen.dart';
import '../screens/downloads_screen.dart';
import '../screens/settings_screen.dart';

/// Core notification engine — channels, show, schedule, quiet hours.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── Channel IDs ──
  static const String chDownloads = 'downloads';
  static const String chUpdates = 'updates';
  static const String chContent = 'content';
  static const String chWatchlist = 'watchlist';
  static const String chPlayback = 'playback';
  static const String chSystem = 'system';

  // ── Frequency control ──
  final Map<String, DateTime> _lastNotifTime = {};
  int _contentCountToday = 0;
  DateTime _contentCountDate = DateTime.now();

  // ── Brand color ──
  static const Color _accentColor = Color(0xFF6C63FF);

  // ═══════════════════════════════════════════════════════════════════
  // INIT
  // ═══════════════════════════════════════════════════════════════════

  Future<void> init() async {
    if (_initialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();

    // Android init settings — use the white monochrome icon for status bar
    const androidSettings = AndroidInitializationSettings('ic_notification');

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create channels
    await _createChannels();
    _initialized = true;
    debugPrint('✅ NotificationService: initialized');
  }

  Future<void> _createChannels() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) return;

    final channels = [
      const AndroidNotificationChannel(
        chDownloads,
        'Downloads',
        description: 'Download progress and completion',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        chUpdates,
        'App Updates',
        description: 'App update notifications',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        chContent,
        'Content Updates',
        description: 'New movies and trending content',
        importance: Importance.defaultImportance,
      ),
      const AndroidNotificationChannel(
        chWatchlist,
        'Watchlist',
        description: 'Watchlist movie availability',
        importance: Importance.defaultImportance,
      ),
      const AndroidNotificationChannel(
        chPlayback,
        'Playback',
        description: 'Resume watching suggestions',
        importance: Importance.defaultImportance,
      ),
      const AndroidNotificationChannel(
        chSystem,
        'System',
        description: 'Background sync and cache operations',
        importance: Importance.low,
      ),
    ];

    for (final channel in channels) {
      await androidPlugin.createNotificationChannel(channel);
    }
    debugPrint('✅ NotificationService: 6 channels created');
  }

  // ═══════════════════════════════════════════════════════════════════
  // SHOW NOTIFICATION
  // ═══════════════════════════════════════════════════════════════════

  /// Show a notification respecting user preferences, quiet hours, and
  /// frequency limits.
  ///
  /// [category] — one of the NotificationSettings category keys.
  /// [channelId] — Android channel (chDownloads, chContent, etc.).
  /// [title], [body] — notification content.
  /// [payload] — optional data passed to tap handler.
  Future<void> show({
    required String category,
    required String channelId,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await init();

    // Check user preferences
    final nc = _getNotificationController();
    if (nc == null) return;
    final s = nc.settings.value;

    // Critical updates bypass all checks
    if (category != 'criticalUpdate') {
      if (!s.isEnabled(category)) {
        debugPrint('🔕 Notification blocked (disabled): $category');
        return;
      }

      if (s.isQuietTime) {
        debugPrint('🔕 Notification blocked (quiet hours): $category');
        return;
      }

      // Frequency control for content notifications
      if (category == 'newMoviesDaily' || category == 'weeklyTrending') {
        if (!_checkFrequency(category)) {
          debugPrint('🔕 Notification blocked (frequency): $category');
          return;
        }
      }
    }

    final id = _generateId();

    final androidDetails = AndroidNotificationDetails(
      channelId,
      _channelName(channelId),
      importance: _channelImportance(channelId),
      priority: _channelPriority(channelId),
      styleInformation: BigTextStyleInformation(body),
      icon: 'ic_notification',
      largeIcon: const DrawableResourceAndroidBitmap('launcher_icon'),
      color: _accentColor,
    );

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: payload,
    );

    _lastNotifTime[category] = DateTime.now();
    debugPrint('🔔 Notification shown: $title ($category)');
  }

  // ═══════════════════════════════════════════════════════════════════
  // CONVENIENCE METHODS (used by controllers)
  // ═══════════════════════════════════════════════════════════════════

  /// Download completed notification.
  Future<void> showDownloadComplete(
    String movieName,
    String quality,
    String size,
  ) async {
    await show(
      category: 'downloadComplete',
      channelId: chDownloads,
      title: '🎬 Download Complete',
      body: '$movieName ($quality) downloaded\n$size • Ready to watch',
      payload: 'download_complete',
    );
  }

  /// Download failed notification.
  Future<void> showDownloadFailed(String movieName, String reason) async {
    await show(
      category: 'downloadFailed',
      channelId: chDownloads,
      title: '❌ Download Failed',
      body: '$movieName\n$reason',
      payload: 'download_failed',
    );
  }

  /// Storage low warning.
  Future<void> showStorageLow(int freeMB, int requiredMB) async {
    await show(
      category: 'storageLow',
      channelId: chDownloads,
      title: '⚠️ Storage Space Low',
      body: 'Only $freeMB MB free. Need $requiredMB MB for download.',
      payload: 'storage_low',
    );
  }

  /// App update available.
  Future<void> showUpdateAvailable(String version, String changelog) async {
    await show(
      category: 'appUpdate',
      channelId: chUpdates,
      title: '🔄 Update Available — v$version',
      body: changelog,
      payload: 'app_update',
    );
  }

  /// Critical update (cannot be suppressed).
  Future<void> showCriticalUpdate(String version) async {
    await show(
      category: 'criticalUpdate',
      channelId: chUpdates,
      title: '🚨 Critical Update Required',
      body: 'Version $version fixes important security issues. Update now.',
      payload: 'critical_update',
    );
  }

  /// Resume watching suggestion.
  Future<void> showResumeWatching(String movieName, String timestamp) async {
    await show(
      category: 'resumeWatching',
      channelId: chPlayback,
      title: '▶️ Continue Watching',
      body: 'Resume $movieName from $timestamp',
      payload: 'resume_watching',
    );
  }

  /// New movies daily.
  Future<void> showNewMovies(int count, List<String> titles) async {
    final preview = titles.take(3).join(', ');
    await show(
      category: 'newMoviesDaily',
      channelId: chContent,
      title: '🎬 $count new movies added today',
      body: 'Including: $preview',
      payload: 'new_movies',
    );
  }

  /// Trending this week.
  Future<void> showWeeklyTrending(List<String> titles) async {
    final preview = titles.take(3).join(', ');
    await show(
      category: 'weeklyTrending',
      channelId: chContent,
      title: '🔥 Trending This Week',
      body: preview,
      payload: 'weekly_trending',
    );
  }

  /// Watchlist movie available.
  Future<void> showWatchlistAvailable(String movieName, String quality) async {
    await show(
      category: 'watchlistAvailable',
      channelId: chWatchlist,
      title: '🎬 Watchlist Update',
      body: '"$movieName" is now available in $quality',
      payload: 'watchlist_available',
    );
  }

  /// Quality upgrade available.
  Future<void> showQualityUpgraded(String movieName, String newQuality) async {
    await show(
      category: 'qualityUpgraded',
      channelId: chWatchlist,
      title: '⬆️ Quality Upgraded',
      body: '$movieName is now available in $newQuality',
      payload: 'quality_upgraded',
    );
  }

  /// Sync complete (silent).
  Future<void> showSyncComplete(int movieCount) async {
    await show(
      category: 'syncComplete',
      channelId: chSystem,
      title: '✅ Sync Complete',
      body: '$movieCount movies synced',
      payload: 'sync_complete',
    );
  }

  /// Cache cleared.
  Future<void> showCacheCleared(String freedSpace) async {
    await show(
      category: 'cacheCleared',
      channelId: chSystem,
      title: '🗑️ Cache Cleared',
      body: '$freedSpace freed',
      payload: 'cache_cleared',
    );
  }

  /// Preview notification for settings screen — shows a realistic sample
  /// for the given [category] so the user knows what to expect.
  Future<void> showPreview(String category) async {
    if (!_initialized) await init();

    final id = _generateId();
    String title;
    String body;
    String channelId;

    switch (category) {
      case 'downloadComplete':
        title = '🎬 Download Complete';
        body = 'Inception (1080p) downloaded\n2.5 GB • Ready to watch';
        channelId = chDownloads;
        break;
      case 'downloadFailed':
        title = '❌ Download Failed';
        body = 'The Batman\nConnection lost. Tap to retry.';
        channelId = chDownloads;
        break;
      case 'storageLow':
        title = '⚠️ Storage Space Low';
        body = 'Only 512 MB free. Need 1.8 GB for download.';
        channelId = chDownloads;
        break;
      case 'appUpdate':
        title = '🔄 Update Available — v2.1.0';
        body = 'Bug fixes, improved streaming, new UI features.';
        channelId = chUpdates;
        break;
      case 'newMoviesDaily':
        title = '🎬 5 new movies added today';
        body = 'Including: Oppenheimer, Barbie, The Batman';
        channelId = chContent;
        break;
      case 'weeklyTrending':
        title = '🔥 Trending This Week';
        body =
            'Oppenheimer, Barbie, Interstellar, Dune Part Two, Killers of the Flower Moon';
        channelId = chContent;
        break;
      case 'watchlistAvailable':
        title = '🎬 Watchlist Update';
        body = '"Avatar: The Way of Water" is now available in 1080p';
        channelId = chWatchlist;
        break;
      case 'qualityUpgraded':
        title = '⬆️ Quality Upgraded';
        body = 'The Dark Knight is now available in 4K';
        channelId = chWatchlist;
        break;
      case 'resumeWatching':
        title = '▶️ Continue Watching';
        body = 'Resume Interstellar from 1:23:45';
        channelId = chPlayback;
        break;
      case 'syncComplete':
        title = '✅ Sync Complete';
        body = '142 movies synced';
        channelId = chSystem;
        break;
      case 'cacheCleared':
        title = '🗑️ Cache Cleared';
        body = '1.2 GB freed';
        channelId = chSystem;
        break;
      default:
        title = '🎬 MovieHub';
        body = 'Notification preview for "$category"';
        channelId = chSystem;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      _channelName(channelId),
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(body),
      icon: 'ic_notification',
      largeIcon: const DrawableResourceAndroidBitmap('launcher_icon'),
      color: _accentColor,
    );

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
    debugPrint('🔔 Preview notification shown: $title ($category)');
  }

  // ═══════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════

  NotificationController? _getNotificationController() {
    try {
      return Get.find<NotificationController>();
    } catch (_) {
      return null;
    }
  }

  bool _checkFrequency(String category) {
    // Reset daily counter
    final today = DateTime.now();
    if (today.day != _contentCountDate.day) {
      _contentCountToday = 0;
      _contentCountDate = today;
    }

    // Max 3 content notifications per day
    if (_contentCountToday >= 3) return false;

    // Don't repeat within 24 hours
    final last = _lastNotifTime[category];
    if (last != null && today.difference(last).inHours < 24) return false;

    _contentCountToday++;
    return true;
  }

  int _generateId() => Random().nextInt(100000);

  String _channelName(String id) {
    switch (id) {
      case chDownloads:
        return 'Downloads';
      case chUpdates:
        return 'App Updates';
      case chContent:
        return 'Content Updates';
      case chWatchlist:
        return 'Watchlist';
      case chPlayback:
        return 'Playback';
      case chSystem:
        return 'System';
      default:
        return 'MovieHub';
    }
  }

  Importance _channelImportance(String id) {
    switch (id) {
      case chDownloads:
      case chUpdates:
        return Importance.high;
      case chContent:
      case chWatchlist:
      case chPlayback:
        return Importance.defaultImportance;
      case chSystem:
        return Importance.low;
      default:
        return Importance.defaultImportance;
    }
  }

  Priority _channelPriority(String id) {
    switch (id) {
      case chDownloads:
      case chUpdates:
        return Priority.high;
      case chSystem:
        return Priority.low;
      default:
        return Priority.defaultPriority;
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    debugPrint('🔔 Notification tapped: $payload');

    if (payload == null) return;

    switch (payload) {
      case 'download_complete':
      case 'download_failed':
      case 'storage_low':
        Get.to(() => const DownloadsScreen());
        break;
      case 'new_movies':
      case 'weekly_trending':
      case 'resume_watching':
        Get.to(() => const HomeScreen());
        break;
      case 'app_update':
      case 'critical_update':
        Get.to(() => const SettingsScreen());
        break;
      case 'watchlist_available':
      case 'quality_upgraded':
        Get.to(() => const HomeScreen());
        break;
      default:
        debugPrint('🔔 Unhandled notification payload: $payload');
    }
  }
}
