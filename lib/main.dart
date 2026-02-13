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
import 'screens/splash_screen.dart';

// ⚠️ CRITICAL: Must be top-level for background isolate
@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  final SendPort? send = IsolateNameServer.lookupPortByName(
    'downloader_send_port',
  );
  send?.send([id, status, progress]);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(DownloadStatusAdapter());
  Hive.registerAdapter(DownloadAdapter());
  Hive.registerAdapter(WatchlistCategoryAdapter());
  Hive.registerAdapter(WatchlistMovieAdapter());
  Hive.registerAdapter(PlaybackPositionAdapter());
  Hive.registerAdapter(AppThemeModeAdapter());
  Hive.registerAdapter(ThemePreferencesAdapter());
  Hive.registerAdapter(HomepageMovieAdapter());

  // Initialize Flutter Downloader (CRITICAL - must be before controllers)
  await FlutterDownloader.initialize(debug: true, ignoreSsl: true);
  FlutterDownloader.registerCallback(downloadCallback);

  // Register GetX controllers
  Get.put(WatchlistController(), permanent: true);
  Get.put(DownloadController(), permanent: true);
  Get.put(VideoPlayerGetxController(), permanent: true);
  Get.put(ThemeController(), permanent: true);

  runApp(const MovieHunterApp());
}

class MovieHunterApp extends StatelessWidget {
  const MovieHunterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(() {
      // Force rebuild when preferences change
      themeController.preferences.value;

      return GetMaterialApp(
        title: 'MovieHunter',
        debugShowCheckedModeBanner: false,
        theme: themeController.currentTheme,
        home: const SplashScreen(),
      );
    });
  }
}
