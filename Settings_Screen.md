Hi Antigravity,

Settings screen has UI but NOTHING works. 
Every single setting is non-functional.
Please fix ALL settings to be 100% working.

CURRENT STATE:
- Settings UI exists ✅
- But NO setting actually changes anything ❌
- Changes don't persist after app restart ❌
- No visual feedback when settings change ❌

════════════════════════════════════════
FIX 1: FONT SIZE - Make it work globally
════════════════════════════════════════

CURRENT: Slider moves but text size never changes anywhere

REQUIRED:
- Slider value (8-24) must change text size GLOBALLY
- Every screen must respect font size setting
- Must persist after app restart
- Live preview in settings screen

IMPLEMENTATION:
```dart
// lib/controllers/settings_controller.dart

class SettingsController extends GetxController {
  final _box = Hive.box('settings');
  
  // Font Size
  var fontSize = 14.0.obs;
  
  @override
  void onInit() {
    super.onInit();
    fontSize.value = _box.get('fontSize', defaultValue: 14.0);
  }
  
  void setFontSize(double size) {
    fontSize.value = size;
    _box.put('fontSize', size);
    // This triggers rebuild of entire app
    Get.forceAppUpdate();
  }
}

// lib/main.dart - Apply font size globally
class MyApp extends StatelessWidget {
  final settings = Get.find<SettingsController>();
  
  @override
  Widget build(BuildContext context) {
    return Obx(() => GetMaterialApp(
      theme: ThemeData.dark().copyWith(
        textTheme: ThemeData.dark().textTheme.apply(
          fontSizeFactor: settings.fontSize.value / 14.0,
        ),
      ),
      home: HomeScreen(),
    ));
  }
}
```

════════════════════════════════════════
FIX 2: LAYOUT - Full working control
════════════════════════════════════════

CURRENT: 
- Grid Layout toggle → does nothing
- Rounded Posters toggle → does nothing  
- Grid Columns (2/3/4) → does nothing

REQUIRED:
All layout changes must immediately update the movie grid
on Latest, Search, Library screens.
```dart
// In SettingsController
var gridLayout = true.obs;      // grid vs list
var roundedPosters = true.obs;  // rounded corners
var gridColumns = 2.obs;        // 2, 3, or 4 columns

void setGridLayout(bool value) {
  gridLayout.value = value;
  _box.put('gridLayout', value);
}

void setRoundedPosters(bool value) {
  roundedPosters.value = value;
  _box.put('roundedPosters', value);
}

void setGridColumns(int columns) {
  gridColumns.value = columns;
  _box.put('gridColumns', columns);
}

// Load saved values in onInit:
gridLayout.value = _box.get('gridLayout', defaultValue: true);
roundedPosters.value = _box.get('roundedPosters', defaultValue: true);
gridColumns.value = _box.get('gridColumns', defaultValue: 2);

// In every screen that shows movies (Latest, Search, etc):
Obx(() {
  final settings = Get.find<SettingsController>();
  
  if (!settings.gridLayout.value) {
    // LIST VIEW
    return ListView.builder(
      itemCount: movies.length,
      itemBuilder: (context, index) {
        return MovieListItem(
          movie: movies[index],
          rounded: settings.roundedPosters.value,
        );
      },
    );
  }
  
  // GRID VIEW
  return GridView.builder(
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: settings.gridColumns.value, // 2, 3, or 4
      childAspectRatio: 0.65,
    ),
    itemBuilder: (context, index) {
      return MovieCard(
        movie: movies[index],
        rounded: settings.roundedPosters.value,
      );
    },
  );
})

// In MovieCard - apply rounded corners:
ClipRRect(
  borderRadius: BorderRadius.circular(
    settings.roundedPosters.value ? 8.0 : 0.0
  ),
  child: Image.network(posterUrl),
)
```

ALSO ADD these layout settings:
```dart
// Poster Size (Small/Medium/Large)
var posterSize = 'medium'.obs;

// Show movie title below poster
var showMovieTitle = true.obs;

// Show rating badge on poster
var showRatingBadge = true.obs;

// Show year below title
var showMovieYear = true.obs;
```

════════════════════════════════════════
FIX 3: DATA & CACHE - Make all work
════════════════════════════════════════

CURRENT: Tapping any option does nothing

REQUIRED - Each button must work with confirmation dialog:
```dart
// 1. Clear Movie Cache
void clearMovieCache() async {
  // Show confirmation
  final confirmed = await _showConfirmDialog(
    title: 'Clear Movie Cache?',
    message: 'This will remove cached movie data. '
             'Movies will reload from server.',
  );
  
  if (!confirmed) return;
  
  // Actually clear cache
  final movieBox = Hive.box('homepage_movies');
  await movieBox.clear();
  
  final searchBox = Hive.box('search_cache');
  await searchBox.clear();
  
  // Clear image cache
  PaintingBinding.instance.imageCache.clear();
  PaintingBinding.instance.imageCache.clearLiveImages();
  
  // Show success
  Get.snackbar(
    'Cache Cleared',
    'Movie cache has been cleared successfully',
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: Colors.green,
    duration: Duration(seconds: 3),
  );
}

// 2. Clear Watchlist
void clearWatchlist() async {
  final confirmed = await _showConfirmDialog(
    title: 'Clear Watchlist?',
    message: 'This will remove ALL movies from your watchlist. '
             'This cannot be undone.',
    destructive: true,
  );
  
  if (!confirmed) return;
  
  final watchlistBox = Hive.box('watchlist');
  await watchlistBox.clear();
  
  // Update watchlist controller
  Get.find<WatchlistController>().movies.clear();
  
  Get.snackbar(
    'Watchlist Cleared',
    'All movies removed from watchlist',
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: Colors.orange,
  );
}

// 3. Clear Download History
void clearDownloadHistory() async {
  final confirmed = await _showConfirmDialog(
    title: 'Clear Download History?',
    message: 'Download records will be removed but '
             'actual files will remain on your device.',
  );
  
  if (!confirmed) return;
  
  final downloadBox = Hive.box('download_history');
  await downloadBox.clear();
  
  // Update downloads controller
  Get.find<DownloadController>().history.clear();
  
  Get.snackbar(
    'History Cleared',
    'Download history cleared. Files are still on device.',
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: Colors.blue,
  );
}

// 4. Reset All Settings
void resetAllSettings() async {
  final confirmed = await _showConfirmDialog(
    title: 'Reset All Settings?',
    message: 'ALL settings will be reset to default values. '
             'This includes theme, layout, notifications, etc.',
    destructive: true,
  );
  
  if (!confirmed) return;
  
  // Reset all to defaults
  await _box.clear();
  
  // Re-apply defaults
  fontSize.value = 14.0;
  gridLayout.value = true;
  roundedPosters.value = true;
  gridColumns.value = 2;
  
  // Force app update
  Get.forceAppUpdate();
  
  Get.snackbar(
    'Settings Reset',
    'All settings restored to default',
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: Colors.purple,
  );
}

// HELPER: Confirmation dialog
Future<bool> _showConfirmDialog({
  required String title,
  required String message,
  bool destructive = false,
}) async {
  final result = await Get.dialog<bool>(
    AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Get.back(result: true),
          style: ElevatedButton.styleFrom(
            backgroundColor: destructive ? Colors.red : Colors.blue,
          ),
          child: Text('Confirm'),
        ),
      ],
    ),
  );
  return result ?? false;
}
```

ALSO ADD cache size display:
```dart
// Show how much cache is being used
Widget _buildCacheSize() {
  return FutureBuilder<String>(
    future: _calculateCacheSize(),
    builder: (context, snapshot) {
      return Text(
        'Cache: ${snapshot.data ?? "Calculating..."}',
        style: TextStyle(color: Colors.grey),
      );
    },
  );
}

Future<String> _calculateCacheSize() async {
  // Calculate Hive boxes size
  int totalBytes = 0;
  
  for (String boxName in ['homepage_movies', 'search_cache', 'watchlist']) {
    try {
      final box = Hive.box(boxName);
      totalBytes += box.length * 1024; // Approximate
    } catch (e) {}
  }
  
  if (totalBytes < 1024 * 1024) {
    return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
```

════════════════════════════════════════
FIX 4: ABOUT SECTION - Make all work
════════════════════════════════════════

CURRENT: Tapping MovieHub, Source Code, Developer → Nothing

REQUIRED:
```dart
// 1. MovieHub version tap → Show changelog dialog
void showChangelog() {
  Get.dialog(
    AlertDialog(
      title: Row(
        children: [
          Icon(Icons.movie, color: Color(0xFF6200EE)),
          SizedBox(width: 8),
          Text('MovieHub v1.0.0'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "What's New:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ...changelogItems.map((item) => Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• '),
                  Expanded(child: Text(item)),
                ],
              ),
            )),
            
            SizedBox(height: 16),
            
            // Check for updates button
            ElevatedButton.icon(
              onPressed: () {
                Get.back();
                Get.find<UpdateController>().checkForUpdates(
                  showNoUpdateDialog: true,
                );
              },
              icon: Icon(Icons.system_update),
              label: Text('Check for Updates'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('Close'),
        ),
      ],
    ),
  );
}

// 2. Source Code tap → Open GitHub in browser
void openSourceCode() async {
  final url = Uri.parse('https://github.com/yourusername/moviehub');
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

// 3. Developer tap → Show developer info
void showDeveloperInfo() {
  Get.dialog(
    AlertDialog(
      title: Text('Developer'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFF6200EE),
            child: Text(
              'S',
              style: TextStyle(fontSize: 32, color: Colors.white),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Shagor',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'App Developer',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.email),
                onPressed: () => launchUrl(
                  Uri.parse('mailto:your@email.com')
                ),
              ),
              IconButton(
                icon: Icon(Icons.code),
                onPressed: () => launchUrl(
                  Uri.parse('https://github.com/yourusername')
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('Close'),
        ),
      ],
    ),
  );
}
```

════════════════════════════════════════
ALSO ADD TO SETTINGS (Missing features):
════════════════════════════════════════

1. Download Quality Default:
```dart
var defaultQuality = '1080p'.obs;
// Options: 480p, 720p, 1080p, 4K
// Use this when download button tapped
```

2. Download over WiFi only:
```dart
var wifiOnly = false.obs;
// Before download: check if on WiFi
// If wifiOnly=true and on mobile data: show warning
```

3. Auto-clear cache:
```dart
var autoClearCache = 'never'.obs;
// Options: never, weekly, monthly
// Run cleanup based on last_cleared date
```

4. App Language:
```dart
var appLanguage = 'English'.obs;
// Options: English, বাংলা, हिंदी
```

════════════════════════════════════════
PERSISTENCE - CRITICAL:
════════════════════════════════════════

ALL settings MUST be saved to Hive and 
loaded on app start:
```dart
@override
void onInit() {
  super.onInit();
  
  final box = Hive.box('settings');
  
  // Load all saved settings
  fontSize.value = box.get('fontSize', defaultValue: 14.0);
  gridLayout.value = box.get('gridLayout', defaultValue: true);
  roundedPosters.value = box.get('roundedPosters', defaultValue: true);
  gridColumns.value = box.get('gridColumns', defaultValue: 2);
  defaultQuality.value = box.get('defaultQuality', defaultValue: '1080p');
  wifiOnly.value = box.get('wifiOnly', defaultValue: false);
  autoClearCache.value = box.get('autoClearCache', defaultValue: 'never');
}
```

════════════════════════════════════════
TESTING CHECKLIST:
════════════════════════════════════════

Font Size:
[ ] Drag slider → text changes immediately everywhere
[ ] Restart app → font size still same
[ ] Small (8) → very small text
[ ] Large (24) → very large text

Layout:
[ ] Grid toggle OFF → switches to list view
[ ] Grid toggle ON → switches to grid
[ ] Rounded OFF → square corners on posters
[ ] Rounded ON → rounded corners on posters
[ ] Columns 2 → 2 columns grid
[ ] Columns 3 → 3 columns grid
[ ] Columns 4 → 4 columns grid
[ ] Restart app → layout setting preserved

Data & Cache:
[ ] Clear Cache → confirmation → clears → snackbar ✅
[ ] Clear Watchlist → confirmation → clears → snackbar ✅
[ ] Clear Downloads → confirmation → clears → snackbar ✅
[ ] Reset Settings → confirmation → resets → snackbar ✅
[ ] Cancel dialogs → nothing changes ✅
[ ] Cache size shows actual size

About:
[ ] Tap MovieHub → changelog dialog opens ✅
[ ] Tap Source Code → GitHub opens in browser ✅
[ ] Tap Developer → developer info shows ✅
[ ] Check for Updates button works ✅

PRIORITY: CRITICAL
All settings must work 100%.
Currently settings are completely non-functional
which makes the settings screen useless.

Thank you!