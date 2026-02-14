import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/download.dart';
import 'models/watchlist_movie.dart';
import 'models/playback_position.dart';
import 'models/theme_preferences.dart';
import 'models/homepage_movie.dart';
import 'controllers/download_controller.dart';
import 'controllers/watchlist_controller.dart';
import 'controllers/video_player_controller.dart';
import 'controllers/theme_controller.dart';
import 'controllers/update_controller.dart';
import 'screens/splash_screen.dart';

// ⚠️ CRITICAL: Must be top-level for background isolate
@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  final SendPort? send = IsolateNameServer.lookupPortByName(
    'downloader_send_port',
  );
  send?.send([id, status, progress]);

  // Also forward to update downloader port
  final SendPort? updateSend = IsolateNameServer.lookupPortByName(
    'update_downloader_port',
  );
  updateSend?.send([id, status, progress]);
}

void main() async {
  print('🚀 MAIN: Starting app');

  WidgetsFlutterBinding.ensureInitialized();
  print('✅ MAIN: Flutter binding initialized');

  // Global error handlers — prevent black screen on uncaught errors
  FlutterError.onError = (FlutterErrorDetails details) {
    print('❌ FLUTTER ERROR: ${details.exceptionAsString()}');
    print('   Stack: ${details.stack}');
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
    Hive.registerAdapter(DownloadStatusAdapter());
    Hive.registerAdapter(DownloadAdapter());
    Hive.registerAdapter(WatchlistCategoryAdapter());
    Hive.registerAdapter(WatchlistMovieAdapter());
    Hive.registerAdapter(PlaybackPositionAdapter());
    Hive.registerAdapter(AppThemeModeAdapter());
    Hive.registerAdapter(ThemePreferencesAdapter());
    Hive.registerAdapter(HomepageMovieAdapter());
    print('✅ MAIN: Hive initialized with all adapters');
  } catch (e) {
    print('❌ MAIN: Hive init error: $e');
  }

  // Initialize Flutter Downloader (CRITICAL - must be before controllers)
  try {
    await FlutterDownloader.initialize(debug: true, ignoreSsl: true);
    FlutterDownloader.registerCallback(downloadCallback);
    print('✅ MAIN: FlutterDownloader initialized');
  } catch (e) {
    print('❌ MAIN: FlutterDownloader init error: $e');
  }

  // Register GetX controllers — each is wrapped individually so one failure
  // doesn't prevent the others (or runApp) from executing.
  try {
    Get.put(ThemeController(), permanent: true);
    print('✅ MAIN: ThemeController registered');
  } catch (e) {
    print('❌ MAIN: ThemeController failed: $e');
  }

  try {
    Get.put(WatchlistController(), permanent: true);
    print('✅ MAIN: WatchlistController registered');
  } catch (e) {
    print('❌ MAIN: WatchlistController failed: $e');
  }

  try {
    Get.put(DownloadController(), permanent: true);
    print('✅ MAIN: DownloadController registered');
  } catch (e) {
    print('❌ MAIN: DownloadController failed: $e');
  }

  try {
    Get.put(VideoPlayerGetxController(), permanent: true);
    print('✅ MAIN: VideoPlayerGetxController registered');
  } catch (e) {
    print('❌ MAIN: VideoPlayerGetxController failed: $e');
  }

  try {
    Get.put(UpdateController(), permanent: true);
    print('✅ MAIN: UpdateController registered');
  } catch (e) {
    print('❌ MAIN: UpdateController failed: $e');
  }

  print('🏃 MAIN: Launching MovieHunterApp');
  runApp(const MovieHunterApp());
}

class MovieHunterApp extends StatelessWidget {
  const MovieHunterApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('🎨 MovieHunterApp: build() called');

    try {
      final themeController = Get.find<ThemeController>();

      return Obx(() {
        // Force rebuild when preferences change
        themeController.preferences.value;

        print(
          '🎨 MovieHunterApp: Obx rebuilding, isReady=${themeController.isReady.value}',
        );

        return GetMaterialApp(
          title: 'MovieHunter',
          debugShowCheckedModeBanner: false,
          theme: themeController.currentTheme,
          home: const SplashScreen(),
        );
      });
    } catch (e) {
      print('❌ MovieHunterApp: build error: $e');
      // Emergency fallback — render something visible
      return MaterialApp(
        title: 'MovieHunter',
        theme: ThemeData.dark(),
        home: const SplashScreen(),
      );
    }
  }
}
