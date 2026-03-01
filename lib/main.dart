import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/download_item.dart';
import 'models/watchlist_movie.dart';
import 'models/playback_position.dart';
import 'models/theme_preferences.dart';
import 'models/homepage_movie.dart';
import 'models/notification_settings.dart';
import 'models/movie_request.dart';
import 'controllers/download_controller.dart';
import 'controllers/watchlist_controller.dart';
import 'controllers/video_player_controller.dart';
import 'theme/theme_controller.dart';
import 'controllers/update_controller.dart';
import 'controllers/notification_controller.dart';
import 'services/storage_settings_service.dart';
import 'services/notification_service.dart';
import 'services/voice_search_service.dart';
import 'utils/notification_scheduler.dart';
import 'screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/analytics_service.dart';
import 'services/auth_service.dart';
import 'services/remote_config_service.dart';

void main() async {
  debugPrint('🚀 MAIN: Starting app');

  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('✅ MAIN: Flutter binding initialized');

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    debugPrint('✅ MAIN: Firebase initialized');

    // Auto guest sign-in (silent, no UI needed)
    await AuthService.instance.ensureSignedIn();

    // Setup FCM
    final messaging = FirebaseMessaging.instance;

    // Request notification permission (Android 13+)
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // Subscribe to 'all' topic for broadcast notifications
    await messaging.subscribeToTopic('all');
    debugPrint('✅ MAIN: Subscribed to FCM topic "all"');

    // Log FCM token for debugging
    final token = await messaging.getToken();
    debugPrint('📱 FCM Token: $token');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 FCM Foreground: ${message.notification?.title}');
    });
    // Log app open event
    AnalyticsService.instance.logCustomEvent('app_open');
    debugPrint('✅ MAIN: Firebase Analytics ready');

    // Initialize Remote Config for in-app updates
    await RemoteConfigService.instance.init();
    debugPrint('✅ MAIN: Remote Config ready');
  } catch (e) {
    debugPrint('❌ MAIN: Firebase/FCM init failed: $e');
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Global error handlers — prevent black screen on uncaught errors
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('❌ FLUTTER ERROR: ${details.exceptionAsString()}');
    debugPrint('   Stack: ${details.stack}');
    FlutterError.presentError(details);
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red.shade900,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Error: ${details.exceptionAsString()}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  };

  // Initialize Hive
  try {
    await Hive.initFlutter();
    Hive.registerAdapter(DownloadItemAdapter());
    Hive.registerAdapter(WatchlistCategoryAdapter());
    Hive.registerAdapter(WatchlistMovieAdapter());
    Hive.registerAdapter(PlaybackPositionAdapter());
    Hive.registerAdapter(AppThemeModeAdapter());
    Hive.registerAdapter(ThemePreferencesAdapter());
    Hive.registerAdapter(HomepageMovieAdapter());
    Hive.registerAdapter(NotificationSettingsAdapter());
    Hive.registerAdapter(MovieRequestAdapter());
    debugPrint('✅ MAIN: Hive initialized with all adapters');
  } catch (e) {
    debugPrint('❌ MAIN: Hive init error: $e');
  }

  // Register GetX controllers — each is wrapped individually so one failure
  // doesn't prevent the others (or runApp) from executing.
  try {
    Get.put(ThemeController(), permanent: true);
    debugPrint('✅ MAIN: ThemeController registered');
  } catch (e) {
    debugPrint('❌ MAIN: ThemeController failed: $e');
  }

  try {
    Get.put(WatchlistController(), permanent: true);
    debugPrint('✅ MAIN: WatchlistController registered');
  } catch (e) {
    debugPrint('❌ MAIN: WatchlistController failed: $e');
  }

  try {
    await Get.putAsync(() => StorageSettingsService().init(), permanent: true);
    debugPrint('✅ MAIN: StorageSettingsService registered');
  } catch (e) {
    debugPrint('❌ MAIN: StorageSettingsService failed: $e');
  }

  try {
    Get.put(DownloadController(), permanent: true);
    debugPrint('✅ MAIN: DownloadController registered');
  } catch (e) {
    debugPrint('❌ MAIN: DownloadController failed: $e');
  }

  try {
    Get.put(VideoPlayerGetxController(), permanent: true);
    debugPrint('✅ MAIN: VideoPlayerGetxController registered');
  } catch (e) {
    debugPrint('❌ MAIN: VideoPlayerGetxController failed: $e');
  }

  try {
    Get.put(UpdateController(), permanent: true);
    debugPrint('✅ MAIN: UpdateController registered');
  } catch (e) {
    debugPrint('❌ MAIN: UpdateController failed: $e');
  }

  // Initialize notification system
  try {
    Get.put(NotificationController(), permanent: true);
    await NotificationService.instance.init();
    await NotificationScheduler.init();
    debugPrint('✅ MAIN: Notification system initialized');
  } catch (e) {
    debugPrint('❌ MAIN: Notification init failed: $e');
  }

  // Initialize voice search service
  try {
    Get.put(VoiceSearchService(), permanent: true);
    debugPrint('✅ MAIN: VoiceSearchService registered');
  } catch (e) {
    debugPrint('❌ MAIN: VoiceSearchService failed: $e');
  }

  debugPrint('🏃 MAIN: Launching MovieHunterApp');
  runApp(const MovieHunterApp());
}

class MovieHunterApp extends StatelessWidget {
  const MovieHunterApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 MovieHunterApp: build() called');

    try {
      final themeController = Get.find<ThemeController>();

      return Obx(
        () => GetMaterialApp(
          title: 'MovieHunter',
          debugShowCheckedModeBanner: false,
          theme: themeController.themeData,
          home: const SplashScreen(),
          defaultTransition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 300),
          navigatorObservers: [AnalyticsService.instance.observer],
        ),
      );
    } catch (e) {
      debugPrint('❌ MovieHunterApp: build error: $e');
      // Emergency fallback — render something visible
      return MaterialApp(
        title: 'MovieHunter',
        theme: ThemeData.dark(),
        home: const SplashScreen(),
      );
    }
  }
}
