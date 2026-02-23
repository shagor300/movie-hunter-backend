Hi Antigravity,

I need you to implement 12 advanced features for MovieHub app to make it 
production-ready and competitive with industry leaders. These features 
will significantly increase user engagement, retention, and viral growth.

════════════════════════════════════════════════════════════════
PROJECT CONTEXT
════════════════════════════════════════════════════════════════

EXISTING APP: MovieHub - Movie streaming & download application
FRAMEWORK: Flutter with GetX state management
CURRENT STATUS: UI redesign complete, core features working
CODEBASE: 15 screens, TMDB API integrated, multi-source scraping

EXISTING FEATURES (Working):
✅ TMDB API integration
✅ Multi-source scraping (HDHub4u, SkyMoviesHD, etc.)
✅ Parallel download system
✅ Video player with BetterPlayer
✅ Watchlist (4 categories)
✅ Continue watching
✅ Voice search
✅ Settings with theme customization

TECH STACK:
- Flutter 3.x
- GetX for state management
- Hive for local storage
- Dio for networking
- TMDB API
- Google Fonts
- Better Player

════════════════════════════════════════════════════════════════
FEATURES TO IMPLEMENT (12 FEATURES)
════════════════════════════════════════════════════════════════

PRIORITY TIER 1 (Must Have - Week 1):
1. 🎭 Movie Trailers Integration
2. 📤 Share Movie Cards
3. 🎯 Similar Movies
4. 📋 Request Movie Feature

PRIORITY TIER 2 (High Impact - Week 2):
5. 🏷️ Tag-based Search & Filters
6. 📈 Trending Downloads
7. 🔒 App Lock (PIN/Biometric)
8. 🔗 Link Saver / Bookmark

PRIORITY TIER 3 (Enhanced UX - Week 3):
9. 📦 Batch Download
10. 🗑️ Smart Cleanup
11. 📴 Offline Mode Enhancements
12. 🤖 AI Movie Recommendations (Basic ML)

════════════════════════════════════════════════════════════════
DETAILED SPECIFICATIONS
════════════════════════════════════════════════════════════════

┌────────────────────────────────────────────────────────────────┐
│ FEATURE 1: 🎭 MOVIE TRAILERS INTEGRATION                      │
└────────────────────────────────────────────────────────────────┘

DESCRIPTION:
Embed YouTube trailers in movie details screen. Users can watch 
trailers before deciding to download.

TECHNICAL REQUIREMENTS:

1. TMDB API Integration:
   - Endpoint: /movie/{id}/videos
   - Extract YouTube video key
   - Filter for official trailers
   - Fallback to teasers if no trailer

2. UI Components:
   - "Watch Trailer" button in details screen
   - Prominent placement (below poster, above Generate Links)
   - Red YouTube-style button with play icon
   - Show duration if available

3. Playback Options:
   OPTION A: In-App Player (Preferred)
   - Use youtube_player_flutter package
   - Full-screen capable
   - Auto-play on open
   - Custom controls overlay
   
   OPTION B: External App
   - url_launcher fallback
   - Open in YouTube app
   - Share trailer option

4. Data Model Updates:
```dart
   class Movie {
     // Add these fields
     String? trailerKey;        // YouTube video ID
     String? trailerUrl;        // Full URL
     String? trailerThumbnail;  // Thumbnail image
     int? trailerDuration;      // Duration in seconds
   }
```

5. UI Placement:
Movie Details Screen:
┌─────────────────────────────┐
│ [Hero Poster with Gradient] │
│ Movie Title (28px)          │
│ ⭐ 8.5 | 2024 | 2h 28m      │
│                             │
│ [▶ Watch Trailer] [❤ Fav]  │ ← NEW
│ [🔖 Watchlist] [📤 Share]   │
│                             │
│ [Generate Links - Gradient] │
│ Storyline...                │
└─────────────────────────────┘

6. Error Handling:
   - No trailer available → Hide button
   - YouTube API error → Show "Open in Browser" fallback
   - Network error → Retry option

DEPENDENCIES TO ADD:
```yaml
youtube_player_flutter: ^8.1.2
url_launcher: ^6.2.2
```

DELIVERABLES:
□ Movie model updated with trailer fields
□ TMDB API service method for fetching trailers
□ TrailerPlayerScreen widget
□ Updated DetailsScreen with trailer button
□ Error handling for all edge cases
□ Unit tests for trailer fetching logic

┌────────────────────────────────────────────────────────────────┐
│ FEATURE 2: 📤 SHARE MOVIE CARDS                               │
└────────────────────────────────────────────────────────────────┘

DESCRIPTION:
Generate beautiful shareable cards with movie poster, rating, and 
branding. Viral marketing feature to attract new users organically.

TECHNICAL REQUIREMENTS:

1. Card Design:
   Dimensions: 1080x1920px (Instagram Story size)
   
   Layout:
┌─────────────────────────────┐
│ [Gradient Background]       │
│                             │
│    [Movie Poster]           │
│    Rounded corners          │
│    Shadow effect            │
│                             │
│  Movie Title (Bold)         │
│  ⭐ 8.5  |  2024  |  2h 28m │
│                             │
│  "Watch on"                 │
│  MovieHub                   │
│  YOUR ULTIMATE CINEMA       │
│                             │
│  [QR Code] (optional)       │
└─────────────────────────────┘

2. Design Specifications:
   - Background: Gradient (theme accent color + dark)
   - Movie poster: Center-aligned, 350x525px
   - Title: Poppins Bold, 32px, white
   - Rating row: Icons + text, 20px
   - Branding: Bottom, white text on semi-transparent bg
   - QR Code: Deep link to movie (moviehub://movie/{tmdbId})

3. Implementation:
```dart
   class ShareableMovieCard extends StatelessWidget {
     final Movie movie;
     final GlobalKey _cardKey = GlobalKey();
     
     Future<Uint8List> captureCard() async {
       // Use RepaintBoundary + RenderRepaintBoundary
       // Convert to image bytes
       // Return PNG bytes
     }
     
     @override
     Widget build(BuildContext context) {
       return RepaintBoundary(
         key: _cardKey,
         child: Container(
           width: 1080,
           height: 1920,
           decoration: BoxDecoration(
             gradient: LinearGradient(...),
           ),
           child: Column(...),
         ),
       );
     }
   }
```

4. Sharing Logic:
   - Generate card image (off-screen)
   - Save to temp directory
   - Share via platform share sheet
   - Include text: "Check out [Movie] on MovieHub! ⭐[Rating]"
   - Include Play Store link

5. Share Button Placement:
   - Movie details screen (top-right, alongside favorite/watchlist)
   - Long-press on movie card (context menu)
   - Share icon in player controls

6. Advanced Features:
   - Multiple templates (Classic, Minimal, Neon)
   - User can choose template in settings
   - Save card to gallery option
   - Share to specific platforms (WhatsApp, Instagram, Twitter)

DEPENDENCIES:
```yaml
share_plus: ^7.2.1
path_provider: ^2.1.1
qr_flutter: ^4.1.0  # For QR code
screenshot: ^2.1.0   # Alternative capture method
```

DELIVERABLES:
□ ShareableMovieCard widget with 3 templates
□ Card capture and sharing service
□ Updated DetailsScreen with share button
□ Context menu on movie cards with share option
□ Share analytics tracking (which movies shared most)
□ Gallery save feature

┌────────────────────────────────────────────────────────────────┐
│ FEATURE 3: 🎯 SIMILAR MOVIES                                  │
└────────────────────────────────────────────────────────────────┘

DESCRIPTION:
Show related movies based on genre, actors, director, and TMDB 
similarity algorithm.

TECHNICAL REQUIREMENTS:

1. Data Sources:
   PRIMARY: TMDB similar movies API
   SECONDARY: Genre-based recommendations
   TERTIARY: Same director/actors

2. API Integration:
```dart
   class RecommendationService {
     // TMDB similar
     Future<List<Movie>> getSimilarMovies(int tmdbId) async {
       final response = await dio.get(
         'https://api.themoviedb.org/3/movie/$tmdbId/similar',
       );
       return parseMovies(response.data['results']);
     }
     
     // Genre-based
     Future<List<Movie>> getMoviesByGenre(int genreId) async {
       final response = await dio.get(
         'https://api.themoviedb.org/3/discover/movie',
         queryParameters: {'with_genres': genreId},
       );
       return parseMovies(response.data['results']);
     }
     
     // Smart similar (combined)
     Future<List<Movie>> getSmartSimilar(Movie movie) async {
       final results = <Movie>[];
       
       // 60% TMDB similar
       final similar = await getSimilarMovies(movie.tmdbId);
       results.addAll(similar.take(12));
       
       // 30% Same primary genre
       final genre = await getMoviesByGenre(movie.genreIds.first);
       results.addAll(genre.take(6));
       
       // 10% Same director (if available)
       if (movie.director != null) {
         final byDirector = await getByDirector(movie.director);
         results.addAll(byDirector.take(2));
       }
       
       // Remove duplicates, shuffle
       return deduplicateAndShuffle(results);
     }
   }
```

3. UI Implementation:
   - Section in movie details screen
   - Title: "Similar Movies" or "You Might Also Like"
   - Horizontal scrolling list
   - 20 movies shown, paginated
   - "See All" button → Full grid view

4. Card Design:
   - Portrait poster (110x165px)
   - Movie title (2 lines max)
   - Rating badge overlay
   - Quality badge (HD/4K) if available

5. Caching Strategy:
   - Cache similar movies for 24 hours
   - Use Hive for offline access
   - Preload similar for watchlist movies

6. Analytics:
   - Track which similar movies clicked
   - Use for improving recommendations
   - A/B test: TMDB vs Smart algorithm

DELIVERABLES:
□ RecommendationService with all methods
□ Similar movies section in DetailsScreen
□ SeeAllSimilarScreen for full grid view
□ Caching with Hive
□ Analytics tracking
□ Unit tests for recommendation logic

┌────────────────────────────────────────────────────────────────┐
│ FEATURE 4: 📋 REQUEST MOVIE FEATURE                           │
└────────────────────────────────────────────────────────────────┘

DESCRIPTION:
Allow users to request movies not available in app. Admin receives 
notification and can add movie within 24 hours.

TECHNICAL REQUIREMENTS:

1. Data Model:
```dart
   @HiveType(typeId: 5)
   class MovieRequest extends HiveObject {
     @HiveField(0)
     final String id;
     
     @HiveField(1)
     final String movieName;
     
     @HiveField(2)
     final String? year;
     
     @HiveField(3)
     final String? language;
     
     @HiveField(4)
     final String? quality; // 480p, 720p, 1080p, 4K
     
     @HiveField(5)
     final String? note; // User's additional note
     
     @HiveField(6)
     final DateTime requestedAt;
     
     @HiveField(7)
     final RequestStatus status;
     
     @HiveField(8)
     final String? adminNote; // Admin response
     
     @HiveField(9)
     final DateTime? completedAt;
   }
   
   enum RequestStatus {
     pending,
     processing,
     completed,
     rejected,
     duplicate,
   }
```

2. Request Screen UI:
Request Movie Screen:
┌─────────────────────────────┐
│ ℹ️ Info Card:                │
│ "Can't find a movie?        │
│  Request it within 24h!"    │
│                             │
│ Movie Name * [____]     │
│                             │
│ Year (Optional) []      │
│                             │
│ Language ▼                  │
│ [English] [Hindi] [Bangla]  │
│                             │
│ Preferred Quality ▼         │
│ [Any] [720p] [1080p] [4K]   │
│                             │
│ Note (Optional)             │
│ [________]          │
│                             │
│ [Submit Request]            │
└─────────────────────────────┘

3. Validation:
   - Movie name required (min 2 characters)
   - Check for duplicates (existing requests)
   - Auto-suggest from TMDB while typing
   - Prevent spam (max 5 requests per day)

4. Backend Integration:
```python
   # admin_api.py
   
   @router.post("/api/movie-requests")
   async def submit_request(request: MovieRequest):
       # Save to database
       db.requests.insert_one(request.dict())
       
       # Check for duplicates
       duplicates = find_similar_requests(request.movieName)
       if duplicates:
           return {"status": "duplicate", "existing": duplicates}
       
       # Auto-search in sources
       search_results = await auto_search_movie(request.movieName)
       
       # Notify admin
       await send_admin_notification(
           title=f"New movie request: {request.movieName}",
           body=f"Requested by user at {request.requestedAt}"
       )
       
       return {
           "success": True,
           "request_id": request.id,
           "estimated_time": "24 hours"
       }
```

5. User Tracking Screen:
My Requests:
┌─────────────────────────────┐
│ 🟢 Inception (2010)         │
│    Status: Completed ✓      │
│    Added 2 hours ago        │
│    [Watch Now]              │
│                             │
│ 🟡 Tenet (2020)             │
│    Status: Processing       │
│    Requested 12 hours ago   │
│                             │
│ 🔴 Old Movie XYZ            │
│    Status: Not Available    │
│    Note: Not found in any   │
│    sources. Try again later │
└─────────────────────────────┘

6. Admin Panel Integration:
   - New "Requests" tab in admin panel
   - Show pending requests (sorted by date)
   - Quick actions: Approve, Reject, Mark as Duplicate
   - Auto-search button (search all sources)
   - Bulk actions (approve multiple)

7. Notifications:
   - User notification when request completed
   - Deep link to movie details
   - Email notification (optional)

DELIVERABLES:
□ MovieRequest model with Hive adapter
□ RequestMovieScreen with form validation
□ MyRequestsScreen for tracking
□ Backend API endpoint
□ Admin panel requests management
□ Push notification integration
□ Analytics (most requested movies)

┌────────────────────────────────────────────────────────────────┐
│ FEATURE 5: 🏷️ TAG-BASED SEARCH & FILTERS                     │
└────────────────────────────────────────────────────────────────┘

DESCRIPTION:
Advanced filtering by quality tags (4K, HEVC, BluRay) and audio 
tags (Dual Audio, Hindi Dubbed). Power user feature.

TECHNICAL REQUIREMENTS:

1. Tag System Architecture:
```dart
   enum QualityTag {
     cam,           // CAMRip
     hdRip,         // HDRip
     webRip,        // WEB-DL / WEBRip
     bluRay,        // BluRay
     hd720p,        // 720p
     hd1080p,       // 1080p / Full HD
     uhd4k,         // 4K / 2160p
     hevc,          // x265 / HEVC
     hdr,           // HDR / HDR10
     remux,         // BluRay REMUX
   }
   
   enum AudioTag {
     original,      // Original Audio
     dualAudio,     // Dual Audio
     hindiDubbed,   // Hindi Dubbed
     tamilDubbed,   // Tamil Dubbed
     teluguDubbed,  // Telugu Dubbed
     multilingual,  // Multiple languages
   }
   
   class MovieTags {
     final Set<QualityTag> qualityTags;
     final Set<AudioTag> audioTags;
     
     // Auto-parse from movie title
     factory MovieTags.fromTitle(String title) {
       final tags = MovieTags(
         qualityTags: {},
         audioTags: {},
       );
       
       final lower = title.toLowerCase();
       
       // Quality detection
       if (lower.contains('4k') || lower.contains('2160p')) {
         tags.qualityTags.add(QualityTag.uhd4k);
       }
       if (lower.contains('1080p') || lower.contains('fullhd')) {
         tags.qualityTags.add(QualityTag.hd1080p);
       }
       if (lower.contains('720p')) {
         tags.qualityTags.add(QualityTag.hd720p);
       }
       if (lower.contains('hevc') || lower.contains('x265')) {
         tags.qualityTags.add(QualityTag.hevc);
       }
       if (lower.contains('bluray') || lower.contains('blu-ray')) {
         tags.qualityTags.add(QualityTag.bluRay);
       }
       if (lower.contains('remux')) {
         tags.qualityTags.add(QualityTag.remux);
       }
       if (lower.contains('webrip') || lower.contains('web-dl')) {
         tags.qualityTags.add(QualityTag.webRip);
       }
       if (lower.contains('hdrip')) {
         tags.qualityTags.add(QualityTag.hdRip);
       }
       if (lower.contains('hdr') && !lower.contains('hdrip')) {
         tags.qualityTags.add(QualityTag.hdr);
       }
       if (lower.contains('cam')) {
         tags.qualityTags.add(QualityTag.cam);
       }
       
       // Audio detection
       if (lower.contains('dual audio')) {
         tags.audioTags.add(AudioTag.dualAudio);
       }
       if (lower.contains('hindi dub') || lower.contains('hin dub')) {
         tags.audioTags.add(AudioTag.hindiDubbed);
       }
       if (lower.contains('tamil dub') || lower.contains('tam dub')) {
         tags.audioTags.add(AudioTag.tamilDubbed);
       }
       if (lower.contains('telugu dub') || lower.contains('tel dub')) {
         tags.audioTags.add(AudioTag.teluguDubbed);
       }
       if (lower.contains('multi audio') || lower.contains('multilingual')) {
         tags.audioTags.add(AudioTag.multilingual);
       }
       
       return tags;
     }
   }
```

2. Update Movie Model:
```dart
   class Movie {
     // ... existing fields
     
     MovieTags tags;
     
     // Parse tags when movie is created/updated
     void parseTags() {
       tags = MovieTags.fromTitle(title);
     }
   }
```

3. Filter UI:
Tag Filter Sheet:
┌─────────────────────────────┐
│ Quality                     │
│ [CAM] [HDRip] [WEBRip]      │
│ [BluRay] [720p] [1080p]     │
│ [4K] [HEVC] [HDR] [REMUX]   │
│                             │
│ Audio                       │
│ [Original] [Dual Audio]     │
│ [Hindi Dubbed] [Tamil Dub]  │
│ [Telugu Dub] [Multi Lang]   │
│                             │
│ File Size                   │
│ [< 1GB] [1-3GB] [3-5GB]     │
│ [5-10GB] [> 10GB]           │
│                             │
│ [Clear All]  [Apply (12)]   │
└─────────────────────────────┘

4. Filter Logic:
```dart
   class MovieFilter {
     Set<QualityTag> selectedQuality = {};
     Set<AudioTag> selectedAudio = {};
     RangeValues? sizeRange; // In GB
     
     List<Movie> apply(List<Movie> movies) {
       return movies.where((movie) {
         // Quality filter
         if (selectedQuality.isNotEmpty) {
           if (!selectedQuality.any(
             (tag) => movie.tags.qualityTags.contains(tag)
           )) {
             return false;
           }
         }
         
         // Audio filter
         if (selectedAudio.isNotEmpty) {
           if (!selectedAudio.any(
             (tag) => movie.tags.audioTags.contains(tag)
           )) {
             return false;
           }
         }
         
         // Size filter
         if (sizeRange != null && movie.fileSize != null) {
           final sizeInGB = movie.fileSize! / (1024 * 1024 * 1024);
           if (sizeInGB < sizeRange!.start || 
               sizeInGB > sizeRange!.end) {
             return false;
           }
         }
         
         return true;
       }).toList();
     }
   }
```

5. UI Integration:
   - Filter button in search bar
   - Show active filters as chips below search bar
   - Chips dismissible (X button)
   - Filter count badge on filter button
   - Persist filter preferences

6. Quick Filters:
   - Preset combinations: "Best Quality", "Small Size", "Hindi Movies"
   - One-tap access
   - User can save custom presets

DELIVERABLES:
□ QualityTag and AudioTag enums
□ MovieTags class with auto-parsing
□ Updated Movie model with tags
□ TagFilterSheet widget
□ MovieFilter class with logic
□ Integration in SearchScreen
□ Active filter chips display
□ Quick filter presets
□ Persistence of filter state

┌────────────────────────────────────────────────────────────────┐
│ FEATURE 6: 📈 TRENDING DOWNLOADS                              │
└────────────────────────────────────────────────────────────────┘

DESCRIPTION:
Show most downloaded movies in community. Social proof + discovery.

TECHNICAL REQUIREMENTS:

1. Download Tracking:
```dart
   @HiveType(typeId: 6)
   class DownloadStat {
     @HiveField(0)
     final int movieId;
     
     @HiveField(1)
     final String movieTitle;
     
     @HiveField(2)
     int downloadCount;
     
     @HiveField(3)
     DateTime lastDownloadAt;
     
     @HiveField(4)
     Map<String, int> qualityBreakdown; // 720p: 50, 1080p: 30
   }
   
   class DownloadTracker {
     static Future<void> trackDownload({
       required Movie movie,
       required String quality,
     }) async {
       final stats = HiveBoxes.downloadStats;
       final existing = stats.get(movie.tmdbId);
       
       if (existing != null) {
         existing.downloadCount++;
         existing.lastDownloadAt = DateTime.now();
         existing.qualityBreakdown[quality] = 
           (existing.qualityBreakdown[quality] ?? 0) + 1;
         await existing.save();
       } else {
         await stats.put(movie.tmdbId, DownloadStat(
           movieId: movie.tmdbId,
           movieTitle: movie.title,
           downloadCount: 1,
           lastDownloadAt: DateTime.now(),
           qualityBreakdown: {quality: 1},
         ));
       }
       
       // Sync to backend for global trending
       await ApiService.syncDownloadStats(movie.tmdbId);
     }
   }
```

2. Trending Algorithm:
```dart
   class TrendingService {
     // Local trending (device only)
     Future<List<Movie>> getLocalTrending({
       Duration period = const Duration(days: 7),
       int limit = 20,
     }) async {
       final stats = HiveBoxes.downloadStats.values
           .where((s) => s.lastDownloadAt.isAfter(
             DateTime.now().subtract(period),
           ))
           .toList();
       
       stats.sort((a, b) => b.downloadCount.compareTo(a.downloadCount));
       
       final movieIds = stats.take(limit).map((s) => s.movieId).toList();
       return await fetchMoviesByIds(movieIds);
     }
     
     // Global trending (all users - from backend)
     Future<List<Movie>> getGlobalTrending({
       Duration period = const Duration(days: 7),
       int limit = 20,
     }) async {
       final response = await dio.get('/api/trending', queryParameters: {
         'period': period.inDays,
         'limit': limit,
       });
       
       return (response.data as List)
           .map((json) => Movie.fromJson(json))
           .toList();
     }
     
     // Weighted trending (combines recency + count)
     double calculateTrendingScore(DownloadStat stat) {
       final hoursSinceDownload = 
         DateTime.now().difference(stat.lastDownloadAt).inHours;
       
       // Decay factor (newer = higher score)
       final recencyScore = 1 / (1 + hoursSinceDownload / 24);
       
       // Download count score
       final countScore = stat.downloadCount / 100;
       
       // Combined (60% recency, 40% count)
       return (recencyScore * 0.6) + (countScore * 0.4);
     }
   }
```

3. Trending Screen:
Trending Downloads:
┌─────────────────────────────┐
│ Period: [This Week ▼]       │
│                             │
│ 🥇 #1 Inception             │
│     ⬇️ 1,234 downloads      │
│     📊 45% in 1080p         │
│                             │
│ 🥈 #2 The Dark Knight       │
│     ⬇️ 987 downloads        │
│     📊 60% in 4K            │
│                             │
│ 🥉 #3 Interstellar          │
│     ⬇️ 856 downloads        │
│     📊 40% in 720p          │
│                             │
│ ... more movies ...         │
└─────────────────────────────┘

4. UI Features:
   - Period selector: Today, This Week, This Month, All Time
   - Rank badges (🥇🥈🥉 for top 3)
   - Trending up/down indicator (↑ +5 or ↓ -2)
   - Quality breakdown chart
   - "Add to Watchlist" quick action
   - Share trending list

5. Integration Points:
   - Dedicated tab in bottom navigation OR
   - Section in For You tab
   - Badge on movie cards ("Trending #5")

6. Backend API:
```python
   @router.get("/api/trending")
   async def get_trending(period: int = 7, limit: int = 20):
       # Query download_stats table
       cutoff_date = datetime.now() - timedelta(days=period)
       
       trending = db.download_stats.aggregate([
           {"$match": {"last_download_at": {"$gte": cutoff_date}}},
           {"$group": {
               "_id": "$movie_id",
               "total_downloads": {"$sum": "$download_count"},
               "last_download": {"$max": "$last_download_at"},
           }},
           {"$sort": {"total_downloads": -1}},
           {"$limit": limit}
       ])
       
       # Fetch movie details from TMDB
       movies = []
       for item in trending:
           movie = await fetch_movie_from_tmdb(item['_id'])
           movie['download_count'] = item['total_downloads']
           movies.append(movie)
       
       return movies
```

DELIVERABLES:
□ DownloadStat model with Hive adapter
□ DownloadTracker service
□ TrendingService with algorithms
□ TrendingScreen with period selector
□ Backend API endpoint for global trending
□ Integration in For You tab
□ Trending badges on movie cards
□ Analytics dashboard (admin panel)

┌────────────────────────────────────────────────────────────────┐
│ FEATURE 7: 🔒 APP LOCK (PIN/BIOMETRIC)                       │
└────────────────────────────────────────────────────────────────┘

DESCRIPTION:
Secure app with PIN or biometric authentication (fingerprint/face).
Privacy feature for users sharing devices.

TECHNICAL REQUIREMENTS:

1. Authentication Methods:
   - 4-digit PIN
   - 6-digit PIN
   - Pattern lock
   - Fingerprint (if supported)
   - Face ID / Face unlock (if supported)

2. Implementation:
```dart
   class AppLockService {
     static const _pinKey = 'app_lock_pin';
     static const _enabledKey = 'app_lock_enabled';
     static const _biometricKey = 'app_lock_biometric';
     
     // Check if app lock is enabled
     Future<bool> isEnabled() async {
       final prefs = await SharedPreferences.getInstance();
       return prefs.getBool(_enabledKey) ?? false;
     }
     
     // Enable app lock with PIN
     Future<void> enableWithPIN(String pin) async {
       final prefs = await SharedPreferences.getInstance();
       final hashedPin = _hashPin(pin);
       await prefs.setString(_pinKey, hashedPin);
       await prefs.setBool(_enabledKey, true);
     }
     
     // Verify PIN
     Future<bool> verifyPIN(String pin) async {
       final prefs = await SharedPreferences.getInstance();
       final storedHash = prefs.getString(_pinKey);
       return _hashPin(pin) == storedHash;
     }
     
     // Enable biometric
     Future<bool> enableBiometric() async {
       final auth = LocalAuthentication();
       
       // Check availability
       final canAuth = await auth.canCheckBiometrics;
       if (!canAuth) return false;
       
       // Get available biometrics
       final available = await auth.getAvailableBiometrics();
       if (available.isEmpty) return false;
       
       // Enable
       final prefs = await SharedPreferences.getInstance();
       await prefs.setBool(_biometricKey, true);
       return true;
     }
     
     // Authenticate with biometric
     Future<bool> authenticateBiometric() async {
       final auth = LocalAuthentication();
       
       try {
         return await auth.authenticate(
           localizedReason: 'Authenticate to unlock MovieHub',
           options: const AuthenticationOptions(
             stickyAuth: true,
             biometricOnly: true,
           ),
         );
       } catch (e) {
         return false;
       }
     }
     
     // Hash PIN securely
     String _hashPin(String pin) {
       return sha256.convert(utf8.encode(pin + 'salt')).toString();
     }
   }
```

3. Lock Screen UI:
App Lock Screen:
┌─────────────────────────────┐
│                             │
│      [App Logo]             │
│      MovieHub               │
│                             │
│   Enter PIN                 │
│   [●] [●] [●] [●]          │
│                             │
│   [1] [2] [3]              │
│   [4] [5] [6]              │
│   [7] [8] [9]              │
│   [←] [0] [✓]              │
│                             │
│   [👆 Use Fingerprint]      │
│                             │
│   Forgot PIN?               │
└─────────────────────────────┘

4. Setup Flow:
Setup App Lock:
┌─────────────────────────────┐
│ Step 1: Create PIN          │
│ Enter 4-digit PIN           │
│ [●] [●] [●] [●]            │
│                             │
│ Step 2: Confirm PIN         │
│ Enter PIN again             │
│ [●] [●] [●] [●]            │
│                             │
│ Step 3: Biometric (Optional)│
│ [ ] Enable Fingerprint      │
│ [ ] Enable Face Unlock      │
│                             │
│ [Complete Setup]            │
└─────────────────────────────┘

5. Settings Integration:
Settings > Security:
┌─────────────────────────────┐
│ App Lock                    │
│ [Toggle: ON/OFF]            │
│                             │
│ Lock Method                 │
│ ( ) 4-digit PIN            │
│ (•) 6-digit PIN            │
│ ( ) Pattern                │
│                             │
│ Biometric                   │
│ [✓] Fingerprint            │
│ [✓] Face Unlock            │
│                             │
│ Auto-lock After             │
│ ( ) Immediately            │
│ (•) 30 seconds             │
│ ( ) 1 minute               │
│ ( ) 5 minutes              │
│                             │
│ [Change PIN]                │
│ [Reset App Lock]            │
└─────────────────────────────┘

6. App Lifecycle Integration:
```dart
   class MyApp extends StatefulWidget {
     @override
     _MyAppState createState() => _MyAppState();
   }
   
   class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
     @override
     void initState() {
       super.initState();
       WidgetsBinding.instance.addObserver(this);
     }
     
     @override
     void didChangeAppLifecycleState(AppLifecycleState state) {
       if (state == AppLifecycleState.paused) {
         // App went to background
         _lastPausedAt = DateTime.now();
       } else if (state == AppLifecycleState.resumed) {
         // App came to foreground
         _checkLock();
       }
     }
     
     Future<void> _checkLock() async {
       final lockService = Get.find<AppLockService>();
       
       if (!await lockService.isEnabled()) return;
       
       // Check auto-lock timeout
       final autoLockDuration = await lockService.getAutoLockDuration();
       final timeSincePause = DateTime.now().difference(_lastPausedAt);
       
       if (timeSincePause > autoLockDuration) {
         // Show lock screen
         Get.to(() => AppLockScreen(), fullscreenDialog: true);
       }
     }
   }
```

7. Forgot PIN Recovery:
   - Option 1: Email verification (if user added email)
   - Option 2: Biometric fallback (if enabled)
   - Option 3: Clear app data warning (last resort)

DEPENDENCIES:
```yaml
local_auth: ^2.1.7
crypto: ^3.0.3
```

DELIVERABLES:
□ AppLockService with PIN and biometric support
□ AppLockScreen widget
□ SetupAppLockScreen wizard
□ Settings integration
□ App lifecycle handling
□ Forgot PIN recovery flow
□ Unit tests for authentication logic

[Continue in next section due to length...]

════════════════════════════════════════════════════════════════
IMPLEMENTATION WORKFLOW
════════════════════════════════════════════════════════════════

WEEK 1 - PRIORITY TIER 1:
Day 1-2: Movie Trailers Integration
Day 3-4: Share Movie Cards
Day 5: Similar Movies
Day 6-7: Request Movie Feature

WEEK 2 - PRIORITY TIER 2:
Day 1-2: Tag-based Search & Filters
Day 3-4: Trending Downloads
Day 5: App Lock
Day 6-7: Link Saver / Bookmark

WEEK 3 - PRIORITY TIER 3:
Day 1-2: Batch Download
Day 3: Smart Cleanup
Day 4: Offline Mode Enhancements
Day 5-7: AI Recommendations (Basic)

AFTER EACH FEATURE:
1. Implement feature
2. Write unit tests
3. Test on device
4. Show me for approval
5. Wait for feedback
6. Fix issues if any
7. Move to next feature

════════════════════════════════════════════════════════════════
QUALITY STANDARDS
════════════════════════════════════════════════════════════════

CODE QUALITY:
✅ Follow Flutter best practices
✅ Use GetX reactive programming
✅ Proper error handling
✅ Loading states for all async operations
✅ Null safety
✅ Comments for complex logic

UI/UX:
✅ Match existing app design system
✅ Smooth animations (300ms default)
✅ Responsive design
✅ Accessibility support
✅ Empty states
✅ Error states with retry

TESTING:
✅ Unit tests for services
✅ Widget tests for UI
✅ Integration tests for critical flows
✅ Test on multiple Android versions
✅ Test edge cases

PERFORMANCE:
✅ Lazy loading where applicable
✅ Image caching
✅ Minimize rebuild scopes
✅ Efficient state management
✅ Background processing for heavy tasks

════════════════════════════════════════════════════════════════
DELIVERABLES PER FEATURE
════════════════════════════════════════════════════════════════

For each feature, provide:
□ Updated/new Dart files
□ Updated pubspec.yaml (if new dependencies)
□ Unit tests
□ Documentation (how it works)
□ Screenshots/video demo
□ Known issues/limitations (if any)
□ Performance impact assessment

════════════════════════════════════════════════════════════════
QUESTIONS BEFORE STARTING
════════════════════════════════════════════════════════════════

1. Should I implement all 12 features or prioritize specific ones?
2. For AI Recommendations, do you want basic (rule-based) or 
   advanced (actual ML model)?
3. For trending downloads, should it be device-only or sync with backend?
4. Any specific design preferences for new screens?
5. Should I create a feature branch or work on main?

════════════════════════════════════════════════════════════════

Ready to start implementation!

Let me know which tier/features you want me to begin with, or 
if you want me to proceed with the full roadmap (Week 1 → Week 2 → Week 3).

I'll implement one feature at a time, show you the result, get your 
approval, then move to the next one.

Waiting for your go-ahead! 🚀