# 🎬 Phase 2: Enhanced Experience - Complete Guide

## ✅ **What's Included**

### 1. **Video Player** 🎥
- BetterPlayer integration with all controls
- Subtitle support (.srt files)
- Playback speed control (0.5x - 2x)
- Picture-in-Picture mode
- Resume playback from saved position
- Continue Watching section
- Network & local file support

### 2. **Themes & Customization** 🎨
- Dark theme (default)
- AMOLED theme (pure black)
- Light theme
- 5 accent colors (Red, Blue, Purple, Green, Orange)
- Font size adjustment (10-20pt)
- Grid/List layout toggle
- Grid column count (2-4 columns)
- Rounded/square posters

---

## 📦 **Installation**

### **pubspec.yaml additions:**

```yaml
dependencies:
  # Video Player
  better_player: ^0.0.83
  video_player: ^2.8.1
  
  # Already have these:
  hive: ^2.2.3
  provider: ^6.1.1
```

### **Initialize in main.dart:**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register all adapters
  Hive.registerAdapter(DownloadAdapter());
  Hive.registerAdapter(DownloadStatusAdapter());
  Hive.registerAdapter(WatchlistMovieAdapter());
  Hive.registerAdapter(WatchlistCategoryAdapter());
  Hive.registerAdapter(PlaybackPositionAdapter());
  Hive.registerAdapter(UserThemePreferencesAdapter());
  Hive.registerAdapter(AppThemeModeAdapter());
  
  // Initialize services
  await DownloadService().init();
  await VideoPlayerService().init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => DownloadProvider()),
        ChangeNotifierProvider(create: (_) => WatchlistProvider()),
        ChangeNotifierProvider(create: (_) => MovieProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'MovieHunter',
          theme: themeProvider.currentTheme, // Dynamic theme
          debugShowCheckedModeBanner: false,
          home: MainScreen(),
          routes: {
            '/player': (context) => VideoPlayerScreen(
              videoUrl: '',
            ),
            '/customization': (context) => CustomizationScreen(),
          },
        );
      },
    );
  }
}
```

---

## 🎥 **Video Player Usage**

### **1. Play from URL:**

```dart
// In Movie Detail Screen
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(
          videoUrl: 'https://hubdrive.space/file/12345',
          movie: movie, // Pass movie object for tracking
          isNetworkSource: true,
        ),
      ),
    );
  },
  child: Text('Watch Online'),
)
```

### **2. Play Downloaded File:**

```dart
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(
          videoUrl: '',
          movie: movie,
          localFilePath: '/storage/emulated/0/Download/MovieHunter/movie.mp4',
          isNetworkSource: false,
        ),
      ),
    );
  },
  child: Text('Play Downloaded'),
)
```

### **3. Add Continue Watching to Home:**

```dart
// In HomeScreen
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // Featured carousel
        FeaturedMoviesCarousel(),
        
        // Continue Watching section
        ContinueWatchingSection(),
        
        // Trending
        TrendingMoviesSection(),
        
        // Categories...
      ],
    );
  }
}
```

---

## 🎨 **Themes & Customization**

### **1. Add Settings Button:**

```dart
// In AppBar or Settings Screen
IconButton(
  icon: Icon(Icons.palette),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomizationScreen(),
      ),
    );
  },
)
```

### **2. Use Theme Preferences in Movie Grid:**

```dart
class MovieGrid extends StatelessWidget {
  final List<Movie> movies;
  
  @override
  Widget build(BuildContext context) {
    final themePrefs = context.watch<ThemeProvider>().preferences;
    
    if (!themePrefs.useGridLayout) {
      // Show as list
      return ListView.builder(
        itemCount: movies.length,
        itemBuilder: (context, index) => MovieListTile(movies[index]),
      );
    }
    
    // Show as grid
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: themePrefs.gridColumnCount,
        childAspectRatio: 0.7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        return MovieCard(
          movie: movies[index],
          rounded: themePrefs.roundedPosters,
        );
      },
    );
  }
}
```

---

## 🎯 **3. Recommendations System**

### **Recommendation Engine:**

```dart
// lib/services/recommendation_service.dart

class RecommendationService {
  // Analyze user preferences
  Map<String, dynamic> analyzeUserPreferences() {
    final watchlist = WatchlistService().getByCategory(WatchlistCategory.completed);
    
    // Count genres
    Map<String, int> genreCount = {};
    double totalRating = 0;
    int ratedCount = 0;
    
    for (var movie in watchlist) {
      // Count genres (would need genre data from TMDB)
      if (movie.userRating != null) {
        totalRating += movie.userRating!;
        ratedCount++;
      }
    }
    
    return {
      'topGenre': genreCount.entries.isEmpty ? null 
          : genreCount.entries.reduce((a, b) => a.value > b.value ? a : b).key,
      'avgRating': ratedCount > 0 ? totalRating / ratedCount : 0,
      'totalWatched': watchlist.length,
    };
  }
  
  // Get similar movies (based on last watched)
  Future<List<Movie>> getSimilarMovies(Movie movie) async {
    // Call TMDB API for similar movies
    final response = await http.get(
      Uri.parse(
        'https://api.themoviedb.org/3/movie/${movie.tmdbId}/similar?api_key=YOUR_KEY'
      ),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List)
          .map((json) => Movie.fromJson(json))
          .toList();
    }
    
    return [];
  }
  
  // Get recommendations by genre
  Future<List<Movie>> getByGenre(String genre) async {
    // Call TMDB discover API
    final response = await http.get(
      Uri.parse(
        'https://api.themoviedb.org/3/discover/movie?'
        'api_key=YOUR_KEY&with_genres=${_getGenreId(genre)}&sort_by=vote_average.desc'
      ),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List)
          .map((json) => Movie.fromJson(json))
          .toList();
    }
    
    return [];
  }
  
  int _getGenreId(String genre) {
    final genreMap = {
      'Action': 28,
      'Comedy': 35,
      'Drama': 18,
      'Horror': 27,
      'Sci-Fi': 878,
      // Add more...
    };
    return genreMap[genre] ?? 28;
  }
}
```

### **Recommendations Screen:**

```dart
// lib/screens/recommendations/recommendations_screen.dart

class RecommendationsScreen extends StatefulWidget {
  @override
  _RecommendationsScreenState createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final _recommendationService = RecommendationService();
  late Future<List<RecommendationSection>> _recommendations;
  
  @override
  void initState() {
    super.initState();
    _recommendations = _loadRecommendations();
  }
  
  Future<List<RecommendationSection>> _loadRecommendations() async {
    final prefs = _recommendationService.analyzeUserPreferences();
    List<RecommendationSection> sections = [];
    
    // Based on last watched
    final lastWatched = VideoPlayerService().getContinueWatching().first;
    if (lastWatched != null) {
      final similar = await _recommendationService.getSimilarMovies(
        // Get movie from TMDB ID
      );
      
      sections.add(RecommendationSection(
        title: 'Because you watched ${lastWatched.movieTitle}',
        movies: similar,
      ));
    }
    
    // Based on favorite genre
    if (prefs['topGenre'] != null) {
      final genreMovies = await _recommendationService.getByGenre(prefs['topGenre']);
      
      sections.add(RecommendationSection(
        title: 'Top ${prefs['topGenre']} Movies',
        movies: genreMovies,
      ));
    }
    
    // Hidden Gems (high rated, low popularity)
    sections.add(RecommendationSection(
      title: 'Hidden Gems',
      movies: [], // Implement discovery logic
    ));
    
    return sections;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recommended for You'),
      ),
      body: FutureBuilder<List<RecommendationSection>>(
        future: _recommendations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }
          
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final section = snapshot.data![index];
              return _buildRecommendationSection(section);
            },
          );
        },
      ),
    );
  }
  
  Widget _buildRecommendationSection(RecommendationSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            section.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        Container(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: section.movies.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(right: 12),
                child: MovieCard(
                  movie: section.movies[index],
                  width: 150,
                ),
              );
            },
          ),
        ),
        
        SizedBox(height: 16),
      ],
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.movie_outlined, size: 100, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text('Watch some movies first!'),
          SizedBox(height: 8),
          Text(
            'We\'ll recommend movies based on your taste',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class RecommendationSection {
  final String title;
  final List<Movie> movies;
  
  RecommendationSection({
    required this.title,
    required this.movies,
  });
}
```

---

## ✅ **Phase 2 Checklist**

### **Video Player:**
- [ ] Add better_player dependency
- [ ] Create VideoPlayerService
- [ ] Implement playback position tracking
- [ ] Build VideoPlayerScreen
- [ ] Add Continue Watching widget to Home
- [ ] Test online streaming
- [ ] Test local file playback
- [ ] Test resume functionality

### **Themes:**
- [ ] Create theme_config.dart
- [ ] Implement ThemeProvider
- [ ] Build CustomizationScreen
- [ ] Add theme mode selector
- [ ] Add accent color picker
- [ ] Add font size slider
- [ ] Add layout toggles
- [ ] Test theme switching

### **Recommendations:**
- [ ] Create RecommendationService
- [ ] Analyze user preferences
- [ ] Integrate TMDB similar movies API
- [ ] Build RecommendationsScreen
- [ ] Add to navigation
- [ ] Test recommendations

---

## 🎯 **Next Steps**

After completing Phase 2, you'll have:
- ✅ Professional video player
- ✅ Beautiful customizable themes
- ✅ Personalized recommendations
- ✅ Continue watching feature
- ✅ Enhanced user experience

**Ready for Phase 3 (Multi-language, Statistics, Notifications)?** 🚀