# MovieHunter Frontend - Complete Implementation Guide

## 📱 **Phase 1: Essential Features** (Week 1-2)

### ✅ **Download Manager** (Already provided above)

**Integration Steps:**

1. **Add to pubspec.yaml:**
```yaml
dependencies:
  flutter_downloader: ^1.11.5
  path_provider: ^2.1.1
  permission_handler: ^11.1.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  provider: ^6.1.1
```

2. **Initialize in main.dart:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(DownloadAdapter());
  Hive.registerAdapter(DownloadStatusAdapter());
  
  // Initialize DownloadService
  await DownloadService().init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DownloadProvider()),
        // Other providers...
      ],
      child: MyApp(),
    ),
  );
}
```

3. **Android Permissions (AndroidManifest.xml):**
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<application>
    <provider
        android:name="androidx.core.content.FileProvider"
        android:authorities="${applicationId}.provider"
        android:exported="false"
        android:grantUriPermissions="true">
        <meta-data
            android:name="android.support.FILE_PROVIDER_PATHS"
            android:resource="@xml/provider_paths"/>
    </provider>
</application>
```

4. **Usage in Movie Detail Screen:**
```dart
ElevatedButton(
  onPressed: () async {
    final link = selectedDownloadLink; // User selected link
    
    await DownloadService().startDownload(
      url: link.url,
      filename: '${movie.title}_${link.quality}.mp4',
      tmdbId: movie.tmdbId,
      quality: link.quality,
      movieTitle: movie.title,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Download started')),
    );
  },
  child: Text('Download'),
)
```

---

### ✅ **Watchlist/Library System**

**1. Watchlist Model:**
```dart
// lib/models/watchlist_movie.dart

@HiveType(typeId: 2)
class WatchlistMovie extends HiveObject {
  @HiveField(0)
  final int tmdbId;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String? posterUrl;
  
  @HiveField(3)
  final double rating;
  
  @HiveField(4)
  final DateTime addedDate;
  
  @HiveField(5)
  WatchlistCategory category; // watching, completed, etc.
  
  @HiveField(6)
  int? userRating; // 1-10
  
  @HiveField(7)
  String? notes;
  
  @HiveField(8)
  bool favorite;

  WatchlistMovie({
    required this.tmdbId,
    required this.title,
    this.posterUrl,
    required this.rating,
    required this.addedDate,
    required this.category,
    this.userRating,
    this.notes,
    this.favorite = false,
  });
}

@HiveType(typeId: 3)
enum WatchlistCategory {
  @HiveField(0)
  watchlist,
  
  @HiveField(1)
  watching,
  
  @HiveField(2)
  completed,
  
  @HiveField(3)
  favorites,
}
```

**2. Watchlist Service:**
```dart
// lib/services/watchlist_service.dart

class WatchlistService {
  late Box<WatchlistMovie> _box;
  
  Future<void> init() async {
    _box = await Hive.openBox<WatchlistMovie>('watchlist');
  }
  
  // Add to watchlist
  Future<void> addToWatchlist(Movie movie, {WatchlistCategory category = WatchlistCategory.watchlist}) async {
    final watchlistMovie = WatchlistMovie(
      tmdbId: movie.tmdbId,
      title: movie.title,
      posterUrl: movie.posterUrl,
      rating: movie.rating,
      addedDate: DateTime.now(),
      category: category,
    );
    
    await _box.put(movie.tmdbId, watchlistMovie);
  }
  
  // Remove from watchlist
  Future<void> removeFromWatchlist(int tmdbId) async {
    await _box.delete(tmdbId);
  }
  
  // Check if in watchlist
  bool isInWatchlist(int tmdbId) {
    return _box.containsKey(tmdbId);
  }
  
  // Get by category
  List<WatchlistMovie> getByCategory(WatchlistCategory category) {
    return _box.values
        .where((m) => m.category == category)
        .toList()
        ..sort((a, b) => b.addedDate.compareTo(a.addedDate));
  }
  
  // Update category
  Future<void> updateCategory(int tmdbId, WatchlistCategory category) async {
    final movie = _box.get(tmdbId);
    if (movie != null) {
      movie.category = category;
      await movie.save();
    }
  }
  
  // Toggle favorite
  Future<void> toggleFavorite(int tmdbId) async {
    final movie = _box.get(tmdbId);
    if (movie != null) {
      movie.favorite = !movie.favorite;
      await movie.save();
    }
  }
  
  // Add rating
  Future<void> addRating(int tmdbId, int rating, {String? notes}) async {
    final movie = _box.get(tmdbId);
    if (movie != null) {
      movie.userRating = rating;
      movie.notes = notes;
      await movie.save();
    }
  }
}
```

**3. Library Screen:**
```dart
// lib/screens/library/library_screen.dart

class LibraryScreen extends StatefulWidget {
  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final categories = [
    WatchlistCategory.watchlist,
    WatchlistCategory.watching,
    WatchlistCategory.completed,
    WatchlistCategory.favorites,
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Library'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'Watchlist'),
            Tab(text: 'Watching'),
            Tab(text: 'Completed'),
            Tab(text: 'Favorites'),
          ],
        ),
      ),
      body: Consumer<WatchlistProvider>(
        builder: (context, provider, child) {
          return TabBarView(
            controller: _tabController,
            children: categories.map((category) {
              final movies = provider.getByCategory(category);
              
              if (movies.isEmpty) {
                return _buildEmptyState(category);
              }
              
              return GridView.builder(
                padding: EdgeInsets.all(8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: movies.length,
                itemBuilder: (context, index) {
                  return WatchlistMovieCard(movie: movies[index]);
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
  
  Widget _buildEmptyState(WatchlistCategory category) {
    String message;
    IconData icon;
    
    switch (category) {
      case WatchlistCategory.watchlist:
        message = 'No movies in your watchlist';
        icon = Icons.bookmark_border;
        break;
      case WatchlistCategory.watching:
        message = 'Not watching anything right now';
        icon = Icons.play_circle_outline;
        break;
      case WatchlistCategory.completed:
        message = 'No completed movies yet';
        icon = Icons.check_circle_outline;
        break;
      case WatchlistCategory.favorites:
        message = 'No favorites yet';
        icon = Icons.favorite_border;
        break;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}
```

**4. Quick Add Button (Movie Detail Screen):**
```dart
// Add to watchlist button
IconButton(
  icon: Icon(
    watchlistProvider.isInWatchlist(movie.tmdbId)
        ? Icons.bookmark
        : Icons.bookmark_border,
  ),
  onPressed: () {
    if (watchlistProvider.isInWatchlist(movie.tmdbId)) {
      watchlistProvider.removeFromWatchlist(movie.tmdbId);
    } else {
      watchlistProvider.addToWatchlist(movie);
    }
  },
)
```

---

### ✅ **Advanced Search & Filters**

**1. Search Screen with Filters:**
```dart
// lib/screens/search/search_screen.dart

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<String> recentSearches = [];
  
  // Filters
  List<String> selectedGenres = [];
  String? selectedYear;
  double minRating = 0;
  String? selectedLanguage;
  
  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search movies...',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: Icon(Icons.mic),
              onPressed: _startVoiceSearch,
            ),
          ),
          onSubmitted: (query) => _performSearch(query),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Active filters chips
          if (selectedGenres.isNotEmpty || selectedYear != null || minRating > 0)
            _buildActiveFilters(),
          
          // Search results or recent searches
          Expanded(
            child: _searchController.text.isEmpty
                ? _buildRecentSearches()
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActiveFilters() {
    return Container(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 8),
        children: [
          // Genre chips
          ...selectedGenres.map((genre) => Padding(
            padding: EdgeInsets.only(right: 8),
            child: Chip(
              label: Text(genre),
              onDeleted: () {
                setState(() => selectedGenres.remove(genre));
                _performSearch(_searchController.text);
              },
            ),
          )),
          
          // Year chip
          if (selectedYear != null)
            Padding(
              padding: EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(selectedYear!),
                onDeleted: () {
                  setState(() => selectedYear = null);
                  _performSearch(_searchController.text);
                },
              ),
            ),
          
          // Rating chip
          if (minRating > 0)
            Chip(
              label: Text('${minRating.toInt()}+ ⭐'),
              onDeleted: () {
                setState(() => minRating = 0);
                _performSearch(_searchController.text);
              },
            ),
        ],
      ),
    );
  }
  
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        builder: (context, scrollController) {
          return FilterSheet(
            selectedGenres: selectedGenres,
            selectedYear: selectedYear,
            minRating: minRating,
            onApply: (genres, year, rating, language) {
              setState(() {
                selectedGenres = genres;
                selectedYear = year;
                minRating = rating;
                selectedLanguage = language;
              });
              _performSearch(_searchController.text);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
  
  void _performSearch(String query) {
    if (query.isEmpty) return;
    
    // Save to recent searches
    _saveRecentSearch(query);
    
    // Search with filters
    context.read<MovieProvider>().search(
      query: query,
      genres: selectedGenres,
      year: selectedYear,
      minRating: minRating,
      language: selectedLanguage,
    );
  }
  
  void _startVoiceSearch() async {
    // Implement voice search
    // Use speech_to_text package
  }
}
```

**2. Filter Sheet Widget:**
```dart
class FilterSheet extends StatefulWidget {
  final List<String> selectedGenres;
  final String? selectedYear;
  final double minRating;
  final Function(List<String>, String?, double, String?) onApply;
  
  FilterSheet({
    required this.selectedGenres,
    this.selectedYear,
    required this.minRating,
    required this.onApply,
  });
  
  @override
  _FilterSheetState createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late List<String> _selectedGenres;
  late String? _selectedYear;
  late double _minRating;
  String? _selectedLanguage;
  
  final genres = [
    'Action', 'Adventure', 'Animation', 'Comedy', 'Crime',
    'Documentary', 'Drama', 'Family', 'Fantasy', 'History',
    'Horror', 'Music', 'Mystery', 'Romance', 'Sci-Fi',
    'Thriller', 'War', 'Western'
  ];
  
  final years = List.generate(50, (i) => (DateTime.now().year - i).toString());
  
  @override
  void initState() {
    super.initState();
    _selectedGenres = List.from(widget.selectedGenres);
    _selectedYear = widget.selectedYear;
    _minRating = widget.minRating;
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filters', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: _resetFilters,
                child: Text('Reset'),
              ),
            ],
          ),
          
          Divider(),
          
          Expanded(
            child: ListView(
              children: [
                // Genre selection
                _buildSectionTitle('Genres'),
                Wrap(
                  spacing: 8,
                  children: genres.map((genre) {
                    final selected = _selectedGenres.contains(genre);
                    return FilterChip(
                      label: Text(genre),
                      selected: selected,
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            _selectedGenres.add(genre);
                          } else {
                            _selectedGenres.remove(genre);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                
                SizedBox(height: 24),
                
                // Year selection
                _buildSectionTitle('Release Year'),
                DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedYear,
                  hint: Text('Select year'),
                  items: years.map((year) {
                    return DropdownMenuItem(
                      value: year,
                      child: Text(year),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedYear = value),
                ),
                
                SizedBox(height: 24),
                
                // Rating slider
                _buildSectionTitle('Minimum Rating: ${_minRating.toInt()}+'),
                Slider(
                  value: _minRating,
                  min: 0,
                  max: 10,
                  divisions: 10,
                  label: _minRating.toInt().toString(),
                  onChanged: (value) => setState(() => _minRating = value),
                ),
                
                SizedBox(height: 24),
                
                // Language
                _buildSectionTitle('Language'),
                Wrap(
                  spacing: 8,
                  children: ['Hindi', 'English', 'Dual Audio'].map((lang) {
                    return ChoiceChip(
                      label: Text(lang),
                      selected: _selectedLanguage == lang,
                      onSelected: (selected) {
                        setState(() => _selectedLanguage = selected ? lang : null);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onApply(
                _selectedGenres,
                _selectedYear,
                _minRating,
                _selectedLanguage,
              ),
              child: Text('Apply Filters'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  void _resetFilters() {
    setState(() {
      _selectedGenres.clear();
      _selectedYear = null;
      _minRating = 0;
      _selectedLanguage = null;
    });
  }
}
```

---

## 📋 **Implementation Checklist**

### Week 1:
- [ ] Setup project dependencies
- [ ] Implement Download Manager
- [ ] Create Download Service
- [ ] Build Downloads Screen UI
- [ ] Test download/pause/resume/cancel

### Week 2:
- [ ] Implement Watchlist System
- [ ] Create Library Screen
- [ ] Add watchlist buttons to movie cards
- [ ] Test add/remove/category changes

### Week 3:
- [ ] Build Advanced Search
- [ ] Implement Filter System
- [ ] Add voice search
- [ ] Create filter sheet UI

---

## 🚀 **Next Phases Coming:**
- Phase 2: Video Player, Themes, Recommendations
- Phase 3: Multi-language, Statistics, Notifications
- Phase 4: Gamification, Social Features

**Want me to continue with Phase 2?** 🎯