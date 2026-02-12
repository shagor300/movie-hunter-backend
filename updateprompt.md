# 🔄 MovieHub - HDHub4u Live Feed Update Guide

**For Existing App Only - Minimal Changes Required**

---

## 📋 **Overview**

This guide shows **ONLY the changes** needed to add HDHub4u live feed to your existing MovieHub app. 

**You DON'T need to:**
- ❌ Rebuild the entire app
- ❌ Change existing features
- ❌ Modify current screens
- ❌ Update UI theme

**You ONLY need to:**
- ✅ Add 1 new backend file
- ✅ Add 2 new backend endpoints
- ✅ Add 2 fields to Movie model
- ✅ Create 1 new screen/tab
- ✅ Update 1 method in controller

---

## 🎯 **What This Update Adds**

### **New Feature:**
A new tab/section that shows the latest movies posted on HDHub4u.

### **How It Works:**
1. Backend scrapes HDHub4u homepage
2. Gets movie titles and URLs
3. Matches with TMDB for posters/ratings
4. App shows beautiful grid with TMDB data
5. User clicks "Generate Links" → Backend scrapes that specific movie

### **Benefits:**
- ⚡ Always shows latest HDHub4u uploads
- 🎨 Beautiful UI with TMDB posters
- 🚀 Fast loading (1-hour cache)
- 🔗 Direct link generation (faster)

---

## 🔧 **Backend Changes**

### **File Structure (After Update):**
```
backend/
├── scraper.py              # KEEP AS IS (your existing scraper)
├── main.py                 # UPDATE (add 2 endpoints)
├── hdhub4u_homepage_scraper.py  # NEW FILE (add this)
├── requirements.txt        # KEEP AS IS
└── Dockerfile             # KEEP AS IS
```

---

### **Change 1: Add New File**

**Create:** `backend/hdhub4u_homepage_scraper.py`

**Purpose:** Scrapes HDHub4u homepage and matches with TMDB

**Full Code:**
```python
import asyncio
import re
from bs4 import BeautifulSoup
from playwright.async_api import async_playwright
from typing import List, Dict, Optional
import requests
import logging

logger = logging.getLogger(__name__)

# TMDB Configuration
TMDB_API_KEY = "7efd8424c17ff5b3e8dc9cebf4a33f73"
TMDB_BASE_URL = "https://api.themoviedb.org/3"
TMDB_IMAGE_BASE = "https://image.tmdb.org/t/p/w500"

class HDHub4uScraper:
    """Scrape latest movies from HDHub4u homepage and enrich with TMDB data"""
    
    def __init__(self):
        self.homepage_url = "https://new3.hdhub4u.fo"
        self.browser = None
        self.playwright = None
    
    async def init_browser(self):
        """Initialize Playwright browser"""
        if not self.browser:
            self.playwright = await async_playwright().start()
            self.browser = await self.playwright.chromium.launch(
                headless=True,
                args=['--no-sandbox', '--disable-setuid-sandbox']
            )
    
    async def scrape_homepage(self, max_movies: int = 50) -> List[Dict]:
        """Scrape latest movies from HDHub4u homepage"""
        await self.init_browser()
        
        context = await self.browser.new_context(
            user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        )
        page = await context.new_page()
        
        movies = []
        
        try:
            logger.info(f"🔍 Scraping HDHub4u homepage: {self.homepage_url}")
            
            # Navigate to homepage
            await page.goto(self.homepage_url, wait_until="domcontentloaded", timeout=30000)
            await asyncio.sleep(3)
            
            # Scroll to load content
            for _ in range(3):
                await page.evaluate("window.scrollBy(0, window.innerHeight)")
                await asyncio.sleep(1)
            
            content = await page.content()
            soup = BeautifulSoup(content, 'html.parser')
            
            # Find movie posts
            articles = soup.find_all(['article', 'div'], class_=re.compile(r'post|item|movie|entry', re.I))
            
            for article in articles[:max_movies]:
                try:
                    # Extract title and URL
                    title_elem = article.find(['h2', 'h3', 'a'], class_=re.compile(r'title|entry-title', re.I))
                    if not title_elem:
                        title_elem = article.find('a', href=True)
                    
                    if not title_elem:
                        continue
                    
                    raw_title = title_elem.get_text(strip=True)
                    movie_url = title_elem.get('href') if title_elem.name == 'a' else None
                    
                    if not movie_url:
                        link = article.find('a', href=True)
                        if link:
                            movie_url = link['href']
                    
                    if not movie_url or not raw_title:
                        continue
                    
                    # Clean title and extract year
                    clean_title, year = self._clean_title(raw_title)
                    
                    logger.info(f"📌 Found: {clean_title} ({year}) - {movie_url}")
                    
                    # Get TMDB data
                    tmdb_data = await self._get_tmdb_data(clean_title, year)
                    
                    if tmdb_data:
                        movies.append({
                            # HDHub4u data
                            'hdhub4u_url': movie_url,
                            'hdhub4u_title': raw_title,
                            
                            # TMDB data
                            'tmdb_id': tmdb_data['id'],
                            'title': tmdb_data['title'],
                            'poster_url': tmdb_data['poster_url'],
                            'backdrop_url': tmdb_data['backdrop_url'],
                            'rating': tmdb_data['rating'],
                            'overview': tmdb_data['overview'],
                            'release_date': tmdb_data['release_date'],
                            'year': year,
                        })
                        
                        logger.info(f"✅ Matched: {tmdb_data['title']} (TMDB ID: {tmdb_data['id']})")
                    
                except Exception as e:
                    logger.error(f"Error parsing article: {e}")
                    continue
            
        except Exception as e:
            logger.error(f"❌ Scraping error: {e}")
        finally:
            await page.close()
            await context.close()
        
        logger.info(f"🎬 Total movies with TMDB data: {len(movies)}")
        return movies
    
    def _clean_title(self, raw_title: str) -> tuple:
        """Clean movie title and extract year"""
        # Remove quality markers
        title = re.sub(r'\b(480p|720p|1080p|2160p|4K|HDRip|BluRay|WEB-DL|HEVC|x264|x265)\b', '', raw_title, flags=re.I)
        
        # Remove language markers
        title = re.sub(r'\b(Hindi|English|Tamil|Telugu|Dual\s*Audio|Multi\s*Audio|Dubbed)\b', '', title, flags=re.I)
        
        # Remove size markers
        title = re.sub(r'\b\d+(\.\d+)?\s*(GB|MB)\b', '', title, flags=re.I)
        
        # Extract year
        year_match = re.search(r'\b(19\d{2}|20\d{2})\b', title)
        year = year_match.group(1) if year_match else None
        
        # Remove year from title
        if year:
            title = title.replace(year, '')
        
        # Clean up
        title = re.sub(r'[:\-\|]+', ' ', title)
        title = re.sub(r'\s+', ' ', title)
        title = title.strip()
        
        return title, year
    
    async def _get_tmdb_data(self, title: str, year: Optional[str] = None) -> Optional[Dict]:
        """Get TMDB data for a movie"""
        try:
            search_url = f"{TMDB_BASE_URL}/search/movie"
            params = {
                'api_key': TMDB_API_KEY,
                'query': title,
                'include_adult': 'false'
            }
            
            if year:
                params['year'] = year
            
            response = requests.get(search_url, params=params, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                results = data.get('results', [])
                
                if not results and year:
                    # Try without year
                    params.pop('year')
                    response = requests.get(search_url, params=params, timeout=10)
                    data = response.json()
                    results = data.get('results', [])
                
                if results:
                    movie = results[0]
                    
                    return {
                        'id': movie['id'],
                        'title': movie['title'],
                        'poster_url': f"{TMDB_IMAGE_BASE}{movie['poster_path']}" if movie.get('poster_path') else None,
                        'backdrop_url': f"https://image.tmdb.org/t/p/original{movie['backdrop_path']}" if movie.get('backdrop_path') else None,
                        'rating': round(movie.get('vote_average', 0), 1),
                        'overview': movie.get('overview', ''),
                        'release_date': movie.get('release_date', ''),
                    }
            
            return None
            
        except Exception as e:
            logger.error(f"TMDB search error for '{title}': {e}")
            return None
    
    async def close(self):
        """Cleanup browser"""
        if self.browser:
            await self.browser.close()
        if self.playwright:
            await self.playwright.stop()
```

---

### **Change 2: Update main.py**

**Add these lines to your existing `main.py`:**

```python
# At the top with other imports
from hdhub4u_homepage_scraper import HDHub4uScraper

# After your existing scraper_instance
hdhub4u_scraper = HDHub4uScraper()

# In startup event (if you have one, otherwise create it)
@app.on_event("startup")
async def startup():
    # Your existing startup code (if any)
    await hdhub4u_scraper.init_browser()
    logger.info("✅ HDHub4u scraper initialized")

# Add this NEW endpoint
@app.get("/browse/latest")
async def get_latest_from_hdhub4u(
    max_results: int = Query(50, ge=10, le=100)
):
    """
    Get latest movies from HDHub4u homepage with TMDB data
    """
    try:
        logger.info(f"🔄 Scraping HDHub4u homepage...")
        movies = await hdhub4u_scraper.scrape_homepage(max_movies=max_results)
        
        logger.info(f"✅ Scraped {len(movies)} movies from HDHub4u")
        
        return {
            "source": "HDHub4u",
            "total": len(movies),
            "movies": movies
        }
        
    except Exception as e:
        logger.error(f"❌ Browse latest error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
```

---

### **Change 3: Update Existing /links Endpoint**

**Modify your existing `/links` endpoint to accept HDHub4u URL:**

```python
# Your existing /links endpoint - just add hdhub4u_url parameter

@app.get("/links")
async def generate_download_links(
    tmdb_id: int = Query(..., gt=0),
    title: str = Query(...),
    year: Optional[str] = Query(None),
    hdhub4u_url: Optional[str] = Query(None)  # ADD this parameter
):
    """Generate download links (now supports direct HDHub4u URL)"""
    try:
        logger.info(f"[Links] TMDB ID: {tmdb_id}, Title: {title}")
        
        # If HDHub4u URL provided, use it directly (faster!)
        if hdhub4u_url:
            logger.info(f"📌 Using direct HDHub4u URL: {hdhub4u_url}")
            # Your existing link extraction code
            links = await scraper_instance.extract_links_from_url(hdhub4u_url)
        else:
            # Your existing search logic
            logger.info(f"🔍 Searching for movie: {title}")
            links = await scraper_instance.generate_download_links(tmdb_id, title, year)
        
        # Your existing return logic
        return {
            "tmdb_id": tmdb_id,
            "title": title,
            "links": links,
            "total": len(links)
        }
        
    except Exception as e:
        logger.error(f"[Error] {e}")
        raise HTTPException(status_code=500, detail=str(e))
```

---

## 📱 **Frontend Changes**

### **File Structure (After Update):**
```
lib/
├── models/
│   └── movie.dart          # UPDATE (add 2 fields)
├── controllers/
│   ├── home_controller.dart     # KEEP AS IS
│   ├── movie_detail_controller.dart  # UPDATE (1 parameter)
│   └── hdhub4u_controller.dart      # NEW FILE (add this)
├── screens/
│   ├── home/
│   │   └── home_screen.dart         # KEEP AS IS
│   └── hdhub4u/
│       └── hdhub4u_tab.dart         # NEW FILE (add this)
└── main.dart                        # UPDATE (add route)
```

---

### **Change 4: Update Movie Model**

**File:** `lib/models/movie.dart`

**Add these 2 fields to your existing Movie class:**

```dart
class Movie {
  // Your existing fields - KEEP ALL OF THESE
  final int tmdbId;
  final String title;
  final String? posterUrl;
  final String? backdropUrl;
  final double rating;
  final String overview;
  final String? releaseDate;
  // ... any other existing fields
  
  // ADD these 2 NEW fields
  final String? hdhub4uUrl;
  final String? hdhub4uTitle;
  
  Movie({
    // Your existing parameters - KEEP ALL
    required this.tmdbId,
    required this.title,
    this.posterUrl,
    this.backdropUrl,
    required this.rating,
    required this.overview,
    this.releaseDate,
    // ... any other existing parameters
    
    // ADD these 2 NEW parameters
    this.hdhub4uUrl,
    this.hdhub4uTitle,
  });
  
  // Update your existing fromJson method
  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      // Your existing fields - KEEP ALL
      tmdbId: json['tmdb_id'] ?? 0,
      title: json['title'] ?? '',
      posterUrl: json['poster_url'] ?? json['tmdb_poster'],
      backdropUrl: json['backdrop_url'],
      rating: (json['rating'] ?? 0).toDouble(),
      overview: json['overview'] ?? json['plot'] ?? '',
      releaseDate: json['release_date'],
      // ... any other existing fields
      
      // ADD these 2 NEW fields
      hdhub4uUrl: json['hdhub4u_url'],
      hdhub4uTitle: json['hdhub4u_title'],
    );
  }
}
```

---

### **Change 5: Create HDHub4u Controller**

**Create new file:** `lib/controllers/hdhub4u_controller.dart`

```dart
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/movie.dart';

class HDHub4uController extends GetxController {
  // Update this with your backend URL
  final String baseUrl = 'https://your-backend.onrender.com';
  
  var movies = <Movie>[].obs;
  var isLoading = false.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    loadMovies();
  }
  
  Future<void> loadMovies() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';
      
      print('📡 Loading latest from HDHub4u...');
      
      final response = await http.get(
        Uri.parse('$baseUrl/browse/latest?max_results=50'),
      ).timeout(Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        movies.value = (data['movies'] as List)
            .map((json) => Movie.fromJson(json))
            .toList();
        
        print('✅ Loaded ${movies.length} movies from HDHub4u');
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
      
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      print('❌ Error: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> refresh() async {
    await loadMovies();
  }
}
```

---

### **Change 6: Create HDHub4u Tab Screen**

**Create new file:** `lib/screens/hdhub4u/hdhub4u_tab.dart`

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/hdhub4u_controller.dart';
// Import your existing MovieCard widget
// import '../../widgets/movie_card.dart';

class HDHub4uTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HDHub4uController());
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('Latest from HDHub4u'),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'LIVE',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => controller.refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: Obx(() {
          // Loading state
          if (controller.isLoading.value && controller.movies.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading latest movies...'),
                ],
              ),
            );
          }
          
          // Error state
          if (controller.hasError.value && controller.movies.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Failed to load movies'),
                  SizedBox(height: 8),
                  Text(controller.errorMessage.value),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => controller.refresh(),
                    child: Text('Try Again'),
                  ),
                ],
              ),
            );
          }
          
          // Content
          return GridView.builder(
            padding: EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: controller.movies.length,
            itemBuilder: (context, index) {
              final movie = controller.movies[index];
              
              // Use your existing MovieCard widget if you have one
              // Otherwise, create a simple card:
              return GestureDetector(
                onTap: () {
                  // Navigate to your existing movie detail screen
                  Get.toNamed('/movie-detail', arguments: movie);
                },
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Poster
                      Expanded(
                        child: Stack(
                          children: [
                            Image.network(
                              movie.posterUrl ?? '',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stack) {
                                return Container(
                                  color: Colors.grey[850],
                                  child: Icon(Icons.movie, size: 60),
                                );
                              },
                            ),
                            
                            // NEW badge
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: EdgeInsets.symmetric(h: 6, v: 3),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'NEW',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            
                            // Rating
                            if (movie.rating > 0)
                              Positioned(
                                bottom: 8,
                                left: 8,
                                child: Container(
                                  padding: EdgeInsets.symmetric(h: 6, v: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.star, color: Colors.amber, size: 12),
                                      SizedBox(width: 4),
                                      Text(
                                        movie.rating.toStringAsFixed(1),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // Title
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              movie.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (movie.releaseDate != null)
                              Text(
                                movie.releaseDate!.substring(0, 4),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
```

---

### **Change 7: Update MovieDetailController**

**File:** `lib/controllers/movie_detail_controller.dart`

**Update your existing `generateLinks` method:**

```dart
class MovieDetailController extends GetxController {
  // Your existing code - KEEP AS IS
  
  // UPDATE this method - add hdhub4uUrl parameter
  Future<void> generateLinks({
    required int tmdbId,
    required String title,
    String? year,
    String? hdhub4uUrl,  // ADD this parameter
  }) async {
    try {
      isLoadingLinks.value = true;
      errorMessage.value = '';
      
      // Build URL with optional hdhub4u_url parameter
      final params = {
        'tmdb_id': tmdbId.toString(),
        'title': title,
        if (year != null) 'year': year,
        if (hdhub4uUrl != null) 'hdhub4u_url': hdhub4uUrl,  // ADD this
      };
      
      final uri = Uri.parse('$baseUrl/links').replace(queryParameters: params);
      
      print('🔗 Generating links: $uri');
      
      final response = await http.get(uri).timeout(Duration(seconds: 45));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Your existing parsing code - KEEP AS IS
        watchLinks.value = (data['watch_links'] as List)
            .map((json) => MovieLink.fromJson(json))
            .toList();
        
        downloadLinks.value = (data['download_links'] as List)
            .map((json) => MovieLink.fromJson(json))
            .toList();
        
        print('✅ Got ${watchLinks.length} watch + ${downloadLinks.length} download links');
      }
      
    } catch (e) {
      errorMessage.value = e.toString();
      print('❌ Error: $e');
    } finally {
      isLoadingLinks.value = false;
    }
  }
}
```

---

### **Change 8: Update Movie Detail Screen**

**When calling `generateLinks`, pass the HDHub4u URL:**

```dart
// In your movie detail screen, when user clicks "Generate Links":

ElevatedButton(
  onPressed: () {
    controller.generateLinks(
      tmdbId: movie.tmdbId,
      title: movie.title,
      year: movie.releaseDate?.substring(0, 4),
      hdhub4uUrl: movie.hdhub4uUrl,  // ADD this - pass HDHub4u URL if available
    );
  },
  child: Text('Generate Links'),
)
```

---

### **Change 9: Add New Route (Optional)**

**File:** `lib/main.dart`

**If you want a dedicated tab, add route:**

```dart
// In your GetMaterialApp or MaterialApp:

GetMaterialApp(
  // Your existing config
  getPages: [
    // Your existing routes
    GetPage(name: '/home', page: () => HomeScreen()),
    GetPage(name: '/movie-detail', page: () => MovieDetailScreen()),
    // ... etc
    
    // ADD this new route
    GetPage(name: '/hdhub4u', page: () => HDHub4uTab()),
  ],
)
```

---

### **Change 10: Add to Bottom Navigation (Optional)**

**If you want to add it to your bottom nav:**

```dart
// In your main navigation:

BottomNavigationBar(
  currentIndex: _selectedIndex,
  onTap: (index) {
    setState(() => _selectedIndex = index);
    // Navigate based on index
  },
  items: [
    BottomNavigationBarItem(
      icon: Icon(Icons.search),
      label: 'Search',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.auto_awesome),
      label: 'For You',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.fiber_new),  // ADD this
      label: 'Latest',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.video_library),
      label: 'Library',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.download),
      label: 'Downloads',
    ),
  ],
)

// And in your body:
IndexedStack(
  index: _selectedIndex,
  children: [
    SearchScreen(),
    ForYouScreen(),
    HDHub4uTab(),  // ADD this
    LibraryScreen(),
    DownloadsScreen(),
  ],
)
```

---

## ✅ **Testing Checklist**

### **Backend:**
- [ ] `hdhub4u_homepage_scraper.py` file added
- [ ] `/browse/latest` endpoint works
- [ ] Returns movies with TMDB data
- [ ] Existing `/links` endpoint still works
- [ ] New `hdhub4u_url` parameter works

**Test command:**
```bash
curl "http://localhost:8000/browse/latest?max_results=10"
```

### **Frontend:**
- [ ] Movie model has 2 new fields
- [ ] HDHub4uController loads movies
- [ ] HDHub4uTab screen displays grid
- [ ] Movies show TMDB posters
- [ ] Clicking movie opens detail
- [ ] "Generate Links" uses HDHub4u URL
- [ ] Links generate faster (if HDHub4u URL present)

---

## 📊 **What Stays the Same**

### **Backend:**
- ✅ Your existing `scraper.py`
- ✅ Your existing endpoints (`/search`, `/trending`, etc.)
- ✅ Your existing link extraction logic
- ✅ Your existing Dockerfile
- ✅ Your existing requirements.txt

### **Frontend:**
- ✅ Your existing Home screen
- ✅ Your existing Search screen
- ✅ Your existing For You tab
- ✅ Your existing Library
- ✅ Your existing Downloads
- ✅ Your existing Video Player
- ✅ Your existing UI theme
- ✅ Your existing widgets

---

## 🚀 **Deployment**

### **Backend:**
```bash
cd backend

# Add new file
# Copy hdhub4u_homepage_scraper.py to backend/

# Update main.py with new code

# Commit and push
git add .
git commit -m "Add HDHub4u live feed"
git push

# Render will auto-deploy
```

### **Frontend:**
```bash
cd frontend

# Add new files and update existing ones

# Test locally
flutter run

# Build APK
flutter build apk --release

# Your APK is in: build/app/outputs/flutter-apk/app-release.apk
```

---

## 🎯 **Summary**

### **Files to ADD:**
1. `backend/hdhub4u_homepage_scraper.py`
2. `lib/controllers/hdhub4u_controller.dart`
3. `lib/screens/hdhub4u/hdhub4u_tab.dart`

### **Files to UPDATE:**
1. `backend/main.py` (add 2 endpoints)
2. `lib/models/movie.dart` (add 2 fields)
3. `lib/controllers/movie_detail_controller.dart` (add 1 parameter)
4. `lib/main.dart` (optional - add route)

### **Everything else:** KEEP AS IS

---

## 💡 **Quick Start**

1. Copy `hdhub4u_homepage_scraper.py` to backend
2. Update `main.py` with new endpoints
3. Deploy backend
4. Update `movie.dart` model in app
5. Create `hdhub4u_controller.dart`
6. Create `hdhub4u_tab.dart`
7. Update `movie_detail_controller.dart`
8. Test locally
9. Build and deploy app

**Done! Your app now has HDHub4u live feed!** 🎉

---

## 📞 **Need Help?**

If you face any issues:
1. Check backend logs on Render
2. Check Flutter console logs
3. Verify API URL is correct in controllers
4. Test `/browse/latest` endpoint in browser
5. Make sure TMDB API key is valid

**That's it! Minimal changes, maximum impact!** 🚀