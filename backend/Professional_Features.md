markdown

# 🚀 MovieHub - Professional Features Implementation Plan

**Complete Guide for Google Antigravity / AI Assistant**

---

## 📋 **FEATURES TO IMPLEMENT (8 Total)**

1. ✨ **Splash Screen Animation** - Animated app opening
2. 📭 **Empty State Screens** - Beautiful placeholder screens
3. 💀 **Skeleton Loading** - Shimmer loading effect
4. 🔄 **Pull-to-Refresh** - Refresh gesture
5. 🔍 **Search Suggestions** - Recent & trending searches
6. 📤 **Share Feature** - Share movies with beautiful cards
7. 👆 **Swipe Gestures** - Swipe to delete/add
8. 👋 **Onboarding Flow** - Welcome screens for new users

---

## 🎯 **IMPLEMENTATION ORDER & PRIORITY**

### **Phase 1: Foundation  - MUST HAVE**

#### **Feature 1: Empty State Screens** 📭
**Priority:** ⭐⭐⭐⭐⭐ (Highest)

**Impact:** High - Prevents blank screens

#### **Feature 2: Pull-to-Refresh** 🔄
**Priority:** ⭐⭐⭐⭐⭐

**Impact:** High - Expected by users

#### **Feature 3: Splash Screen Animation** ✨
**Priority:** ⭐⭐⭐⭐

**Impact:** High - First impression

### **Phase 2: User Experience  - SHOULD HAVE**

#### **Feature 4: Skeleton Loading** 💀
**Priority:** ⭐⭐⭐⭐⭐
 
**Impact:** Very High - Modern loading

#### **Feature 5: Search Suggestions** 🔍
**Priority:** ⭐⭐⭐⭐
 
**Impact:** Medium-High - Better search

### **Phase 3: Advanced  - NICE TO HAVE**

#### **Feature 6: Onboarding Flow** 👋
**Priority:** ⭐⭐⭐⭐
 
**Impact:** High - First-time user retention

#### **Feature 7: Swipe Gestures** 👆
**Priority:** ⭐⭐⭐
 
**Impact:** Medium - Modern interaction

#### **Feature 8: Share Feature** 📤
**Priority:** ⭐⭐⭐
 
**Impact:** Medium - Viral growth

---

## 📦 **DEPENDENCIES REQUIRED**

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Existing (keep these)
  get: ^4.6.6
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  http: ^1.1.0
  
  # NEW - Add these for features
  shimmer: ^3.0.0                      # Skeleton loading
  flutter_slidable: ^3.0.1            # Swipe gestures
  introduction_screen: ^3.1.12        # Onboarding
  share_plus: ^7.2.1                  # Share feature
  path_provider: ^2.1.1               # File operations
  screenshot: ^2.1.0                  # Generate share images
  lottie: ^3.0.0                      # Splash animations (optional)
  
  # Optional but recommended
  cached_network_image: ^3.3.0        # Better image caching
```

---

## 🔧 **FEATURE 1: EMPTY STATE SCREENS**

### **Overview:**
Replace blank screens with beautiful illustrations and helpful messages.

### **Where to Apply:**
- Search results (no results found)
- Watchlist (empty)
- Downloads (no downloads)
- Favorites (empty)
- Library (no content)

### **Implementation:**

**File:** `lib/widgets/empty_state.dart`

```dart
import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  
  const EmptyState({
    Key? key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with circular background
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 60,
                color: Theme.of(context).primaryColor,
              ),
            ),
            
            SizedBox(height: 32),
            
            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 12),
            
            // Message
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
            
            // Action button (optional)
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

### **Usage Examples:**

```dart
// Empty search results
EmptyState(
  icon: Icons.search_off,
  title: 'No Results Found',
  message: 'Try different keywords or browse our collection',
  actionLabel: 'Browse Movies',
  onAction: () => Get.toNamed('/browse'),
)

// Empty watchlist
EmptyState(
  icon: Icons.bookmark_border,
  title: 'Your Watchlist is Empty',
  message: 'Add movies to watch them later',
  actionLabel: 'Explore Movies',
  onAction: () => Get.toNamed('/home'),
)

// Empty downloads
EmptyState(
  icon: Icons.download_outlined,
  title: 'No Downloads Yet',
  message: 'Downloaded movies will appear here',
)

// Empty favorites
EmptyState(
  icon: Icons.favorite_border,
  title: 'No Favorites Yet',
  message: 'Mark movies as favorites to see them here',
  actionLabel: 'Discover Movies',
  onAction: () => Get.toNamed('/latest'),
)
```

---

## 🔧 **FEATURE 2: PULL-TO-REFRESH**

### **Overview:**
Add pull-down gesture to refresh content in scrollable screens.

### **Where to Apply:**
- Latest movies screen
- Search results
- Watchlist
- Downloads list

### **Implementation:**

```dart
// In your screen (e.g., LatestMoviesScreen)
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LatestMoviesScreen extends StatelessWidget {
  final controller = Get.find();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Call your refresh method
          await controller.syncMovies();
        },
        color: Theme.of(context).primaryColor,
        backgroundColor: Colors.black87,
        child: Obx(() {
          if (controller.movies.isEmpty) {
            return EmptyState(
              icon: Icons.movie_outlined,
              title: 'No Movies Yet',
              message: 'Pull down to load movies',
            );
          }
          
          return GridView.builder(
            // Your grid view
          );
        }),
      ),
    );
  }
}
```

### **Custom Pull-to-Refresh Style (Optional):**

```dart
RefreshIndicator(
  onRefresh: _refresh,
  color: Color(0xFF6200EE),
  backgroundColor: Colors.black87,
  displacement: 40, // Distance from top
  strokeWidth: 3,
  triggerMode: RefreshIndicatorTriggerMode.onEdge,
  child: YourScrollableWidget(),
)
```

---

## 🔧 **FEATURE 3: SKELETON LOADING**

### **Overview:**
Show shimmer loading placeholders instead of spinners while content loads.

### **Implementation:**

**File:** `lib/widgets/skeleton_loader.dart`

```dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoader extends StatelessWidget {
  final int itemCount;
  
  const SkeletonLoader({Key? key, this.itemCount = 6}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => SkeletonMovieCard(),
    );
  }
}

class SkeletonMovieCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[850]!,
      highlightColor: Colors.grey[700]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster skeleton
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
              ),
            ),
            
            // Title skeleton
            Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 6),
                  Container(
                    height: 12,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### **Usage:**

```dart
class LatestMoviesScreen extends StatelessWidget {
  final controller = Get.find();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        // Show skeleton while loading
        if (controller.isLoading.value && controller.movies.isEmpty) {
          return SkeletonLoader(itemCount: 6);
        }
        
        // Show content when loaded
        return GridView.builder(
          // Your actual content
        );
      }),
    );
  }
}
```

### **Skeleton Variations:**

**List View Skeleton:**
```dart
class SkeletonListItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[850]!,
      highlightColor: Colors.grey[700]!,
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          color: Colors.white,
        ),
        title: Container(
          height: 16,
          color: Colors.white,
        ),
        subtitle: Container(
          height: 12,
          width: 100,
          color: Colors.white,
        ),
      ),
    );
  }
}
```

---

## 🔧 **FEATURE 4: SPLASH SCREEN ANIMATION**

### **Overview:**
Animated splash screen with fade-in effects and loading indicator.

### **Implementation:**

**File:** `lib/screens/splash/animated_splash_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AnimatedSplashScreen extends StatefulWidget {
  @override
  _AnimatedSplashScreenState createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation _fadeAnimation;
  late Animation _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _controller = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    
    _scaleAnimation = Tween(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    // Start animation
    _controller.forward();
    
    // Navigate after animation + delay
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        _navigateToHome();
      }
    });
  }
  
  void _navigateToHome() {
    // Check if first launch (for onboarding)
    final prefs = Get.find();
    
    if (prefs.isFirstLaunch.value) {
      Get.offAll(() => OnboardingScreen());
    } else {
      Get.offAll(() => HomeScreen());
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated logo
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Color(0xFF6200EE).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.movie,
                        size: 80,
                        color: Color(0xFF6200EE),
                      ),
                    ),
                  ),
                );
              },
            ),
            
            SizedBox(height: 32),
            
            // App name with fade
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'MovieHub',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
            
            SizedBox(height: 8),
            
            // Tagline
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'Your Movie Universe',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                  letterSpacing: 1,
                ),
              ),
            ),
            
            SizedBox(height: 60),
            
            // Loading indicator
            FadeTransition(
              opacity: _fadeAnimation,
              child: SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(Color(0xFF6200EE)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### **Using Lottie Animation (Alternative):**

```dart
import 'package:lottie/lottie.dart';

// In your splash screen
Lottie.asset(
  'assets/animations/splash.json',
  width: 200,
  height: 200,
  fit: BoxFit.contain,
  repeat: false,
  onLoaded: (composition) {
    // Navigate after animation completes
    Future.delayed(composition.duration, _navigateToHome);
  },
)
```

---

## 🔧 **FEATURE 5: SEARCH SUGGESTIONS**

### **Overview:**
Show recent searches and trending movies while user types in search.

### **Implementation:**

**File:** `lib/models/search_suggestion.dart`

```dart
import 'package:hive/hive.dart';

part 'search_suggestion.g.dart';

@HiveType(typeId: 2)
class SearchSuggestion extends HiveObject {
  @HiveField(0)
  final String query;
  
  @HiveField(1)
  final DateTime timestamp;
  
  @HiveField(2)
  final int count; // How many times searched
  
  SearchSuggestion({
    required this.query,
    required this.timestamp,
    this.count = 1,
  });
}
```

**File:** `lib/services/search_suggestion_service.dart`

```dart
import 'package:hive/hive.dart';
import '../models/search_suggestion.dart';

class SearchSuggestionService {
  late Box _suggestionsBox;
  
  Future initialize() async {
    _suggestionsBox = await Hive.openBox('search_suggestions');
  }
  
  // Save search query
  Future saveSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    final existing = _suggestionsBox.values
        .where((s) => s.query.toLowerCase() == query.toLowerCase())
        .toList();
    
    if (existing.isNotEmpty) {
      // Update existing
      final suggestion = existing.first;
      suggestion.delete();
      await _suggestionsBox.add(SearchSuggestion(
        query: query,
        timestamp: DateTime.now(),
        count: suggestion.count + 1,
      ));
    } else {
      // Add new
      await _suggestionsBox.add(SearchSuggestion(
        query: query,
        timestamp: DateTime.now(),
      ));
    }
    
    // Keep only last 20
    if (_suggestionsBox.length > 20) {
      final oldest = _suggestionsBox.values.toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      await oldest.first.delete();
    }
  }
  
  // Get recent searches
  List getRecentSearches({int limit = 5}) {
    final suggestions = _suggestionsBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return suggestions.take(limit).toList();
  }
  
  // Get popular searches
  List getPopularSearches({int limit = 5}) {
    final suggestions = _suggestionsBox.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    
    return suggestions.take(limit).toList();
  }
  
  // Clear all
  Future clearAll() async {
    await _suggestionsBox.clear();
  }
  
  // Delete single
  Future deleteSearch(String query) async {
    final suggestion = _suggestionsBox.values
        .where((s) => s.query == query)
        .firstOrNull;
    
    if (suggestion != null) {
      await suggestion.delete();
    }
  }
}
```

**File:** `lib/screens/search/search_screen_with_suggestions.dart`

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SearchScreenWithSuggestions extends StatefulWidget {
  @override
  _SearchScreenWithSuggestionsState createState() => _SearchScreenWithSuggestionsState();
}

class _SearchScreenWithSuggestionsState extends State {
  final TextEditingController _searchController = TextEditingController();
  final suggestionService = Get.find();
  final searchController = Get.find();
  
  bool _showSuggestions = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search movies...',
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _showSuggestions = false);
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() {
              _showSuggestions = value.isNotEmpty;
            });
          },
          onSubmitted: (query) {
            _performSearch(query);
          },
        ),
      ),
      body: _showSuggestions
          ? _buildSuggestions()
          : _buildSearchResults(),
    );
  }
  
  Widget _buildSuggestions() {
    final recentSearches = suggestionService.getRecentSearches();
    
    return ListView(
      children: [
        // Recent searches
        if (recentSearches.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Searches',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    suggestionService.clearAll();
                    setState(() {});
                  },
                  child: Text('Clear All'),
                ),
              ],
            ),
          ),
          
          ...recentSearches.map((suggestion) {
            return ListTile(
              leading: Icon(Icons.history),
              title: Text(suggestion.query),
              trailing: IconButton(
                icon: Icon(Icons.close, size: 20),
                onPressed: () {
                  suggestionService.deleteSearch(suggestion.query);
                  setState(() {});
                },
              ),
              onTap: () {
                _searchController.text = suggestion.query;
                _performSearch(suggestion.query);
              },
            );
          }),
        ],
        
        // Divider
        if (recentSearches.isNotEmpty)
          Divider(height: 32),
        
        // Trending searches (could be from TMDB)
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Trending',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // Mock trending - replace with real data
        ...['Inception', 'Interstellar', 'The Dark Knight'].map((movie) {
          return ListTile(
            leading: Icon(Icons.trending_up),
            title: Text(movie),
            onTap: () {
              _searchController.text = movie;
              _performSearch(movie);
            },
          );
        }),
      ],
    );
  }
  
  Widget _buildSearchResults() {
    return Obx(() {
      if (searchController.isSearching.value) {
        return SkeletonLoader();
      }
      
      if (searchController.movies.isEmpty) {
        return EmptyState(
          icon: Icons.search_off,
          title: 'No Results Found',
          message: 'Try different keywords',
        );
      }
      
      return GridView.builder(
        // Your search results
      );
    });
  }
  
  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    
    // Save to history
    suggestionService.saveSearch(query);
    
    // Hide suggestions
    setState(() => _showSuggestions = false);
    
    // Perform search
    searchController.searchMovies(query);
  }
}
```

---

## 🔧 **FEATURE 6: SHARE FEATURE**

### **Overview:**
Generate beautiful movie cards and share via social media.

### **Implementation:**

**File:** `lib/services/share_service.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;

class ShareService {
  final ScreenshotController screenshotController = ScreenshotController();
  
  /// Share movie as text
  Future<void> shareMovieText({
    required String title,
    required double rating,
    required String year,
  }) async {
    final text = '''
🎬 $title ($year)
⭐ $rating/10

Watch on MovieHub - Your Movie Universe
Download: [Your Play Store Link]
''';
    
    await Share.share(
      text,
      subject: 'Check out this movie!',
    );
  }
  
  /// Share movie with generated card image
  Future<void> shareMovieCard({
    required BuildContext context,
    required String title,
    required String posterUrl,
    required double rating,
    required String year,
  }) async {
    try {
      // Generate card image
      final imageFile = await _generateMovieCard(
        context: context,
        title: title,
        posterUrl: posterUrl,
        rating: rating,
        year: year,
      );
      
      if (imageFile != null) {
        await Share.shareXFiles(
          [XFile(imageFile.path)],
          text: '🎬 $title ($year) - ⭐ $rating/10

Watch on MovieHub',
        );
      }
      
    } catch (e) {
      print('Share error: $e');
      // Fallback to text share
      await shareMovieText(title: title, rating: rating, year: year);
    }
  }
  
  Future<File?> _generateMovieCard({
    required BuildContext context,
    required String title,
    required String posterUrl,
    required double rating,
    required String year,
  }) async {
    try {
      // Create widget tree for card
      final cardWidget = MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            width: 400,
            height: 600,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
              ),
            ),
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                // Poster
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    posterUrl,
                    width: 200,
                    height: 300,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) {
                      return Container(
                        width: 200,
                        height: 300,
                        color: Colors.grey[800],
                        child: Icon(Icons.movie, size: 60),
                      );
                    },
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: 12),
                
                // Rating and Year
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 24),
                    SizedBox(width: 8),
                    Text(
                      '$rating/10',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      year,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[400],
                      ),
                    ),
Done 