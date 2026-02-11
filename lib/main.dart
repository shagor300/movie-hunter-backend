import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/download.dart';
import 'models/watchlist_movie.dart';
import 'models/playback_position.dart';
import 'models/theme_preferences.dart';
import 'controllers/download_controller.dart';
import 'controllers/watchlist_controller.dart';
import 'controllers/video_player_controller.dart';
import 'controllers/theme_controller.dart';
import 'screens/splash_screen.dart';

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
