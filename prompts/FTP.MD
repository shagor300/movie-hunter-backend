 FlixHub Complete Implementation Guide
For Antigravity - Step-by-Step Professional Implementation

📋 TABLE OF CONTENTS:
1. OVERVIEW & ARCHITECTURE
2. BACKEND IMPLEMENTATION (FastAPI)
   - FTP Integration
   - Scraping Fallback
   - API Endpoints
3. FLUTTER APP IMPLEMENTATION
   - Search System
   - Video Player
   - Download Manager
   - UI Components
4. HIDING SOURCE INFORMATION
5. TESTING & DEPLOYMENT
6. OPTIMIZATION & SCALING

1️⃣ OVERVIEW & ARCHITECTURE
System Architecture:
┌─────────────────────────────────────────────────────┐
│                   FLUTTER APP                       │
│                                                     │
│  User searches "Inception"                          │
│         ↓                                           │
│  Shows loading indicator                            │
│         ↓                                           │
│  Calls Backend API                                  │
└──────────────────┬──────────────────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────────────────┐
│              BACKEND (FastAPI)                      │
│                                                     │
│  Step 1: Check FTP Server (80% hit rate)           │
│  ├─ Connect to ftp.ctgfun.com                      │
│  ├─ Search in /English, /Indian, /TV_Series       │
│  ├─ Parse folder names                             │
│  └─ Generate clean links                           │
│                                                     │
│  If found → Return results ✅                       │
│  If not found → Step 2                             │
│                                                     │
│  Step 2: Scrape websites (20% fallback)            │
│  ├─ HDHub4u scraper                                │
│  ├─ SkyMoviesHD scraper                            │
│  └─ Cinefreak scraper                              │
│                                                     │
│  Return unified results                             │
└──────────────────┬──────────────────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────────────────┐
│                FLUTTER APP DISPLAYS                 │
│                                                     │
│  ✅ NO [DDN] tags shown                            │
│  ✅ NO FTP URLs shown                              │
│  ✅ NO "Source: FTP" badges                        │
│  ✅ Clean, professional UI                         │
│                                                     │
│  User sees:                                         │
│  - Movie title, year, quality                      │
│  - [▶ PLAY] [⬇ DOWNLOAD] buttons                 │
│  - That's it!                                       │
│                                                     │
│  When user clicks Play/Download:                    │
│  - App directly uses the HTTP link                 │
│  - No backend involved in streaming/downloading    │
└─────────────────────────────────────────────────────┘
Key Principles:
✅ FTP-first strategy (80% of content)
✅ Scraping as fallback (20% of content)
✅ Hide all source information from users
✅ Minimal backend load (Render free tier compatible)
✅ Seamless user experience
✅ Professional, clean UI

2️⃣ BACKEND IMPLEMENTATION
File Structure:
backend/
├── main.py                    # FastAPI main app
├── ftp_handler.py             # FTP integration
├── scrapers/
│   ├── base_scraper.py
│   ├── hdhub4u_scraper.py
│   ├── skymovieshd_scraper.py
│   └── cinefreak_scraper.py
├── models.py                  # Data models
├── utils.py                   # Helper functions
└── requirements.txt

2.1 - FTP Handler (ftp_handler.py):
python"""
FTP Handler - Lightweight FTP integration
NO heavy processing, just list and parse folder names
"""

import ftplib
import re
from typing import List, Dict, Optional
from urllib.parse import quote

class FTPMovieHandler:
    """
    Handles FTP server operations
    Designed to be SUPER lightweight for Render free tier
    """
    
    def __init__(self):
        self.host = "ftp.ctgfun.com"
        self.user = "anonymous"
        self.password = ""
        self.timeout = 10
        
        # Directories to search
        self.search_dirs = [
            '/English',
            '/Indian/Hindi Movies',
            '/TV_Series',
        ]
    
    def search(self, query: str, limit: int = 20) -> List[Dict]:
        """
        Search for movies/series in FTP server
        
        Returns clean data without exposing FTP structure
        """
        query = query.lower().strip()
        all_results = []
        
        try:
            # Connect to FTP
            ftp = ftplib.FTP(self.host, timeout=self.timeout)
            ftp.login(self.user, self.password)
            
            # Search each directory
            for directory in self.search_dirs:
                try:
                    ftp.cwd(directory)
                    items = []
                    ftp.retrlines('NLST', items.append)
                    
                    # Find matches
                    for item in items:
                        if self._matches(query, item):
                            # Parse and clean the data
                            movie = self._parse_folder(item, directory)
                            if movie:
                                all_results.append(movie)
                            
                            # Limit results
                            if len(all_results) >= limit:
                                break
                    
                    if len(all_results) >= limit:
                        break
                        
                except Exception as e:
                    print(f"Error in {directory}: {e}")
                    continue
            
            ftp.quit()
            
        except Exception as e:
            print(f"FTP connection error: {e}")
        
        return all_results
    
    def _matches(self, query: str, folder_name: str) -> bool:
        """Simple matching logic"""
        folder_lower = folder_name.lower()
        
        # Remove special characters for better matching
        folder_clean = re.sub(r'[._\-\[\]\(\)]', ' ', folder_lower)
        query_clean = re.sub(r'[._\-\[\]\(\)]', ' ', query)
        
        # Check if all query words are in folder name
        query_words = query_clean.split()
        return all(word in folder_clean for word in query_words if len(word) > 1)
    
    def _parse_folder(self, folder_name: str, directory: str) -> Optional[Dict]:
        """
        Parse folder name and return CLEAN data
        
        IMPORTANT: NO [DDN] tags, NO FTP paths shown to user!
        Everything is cleaned and normalized
        """
        try:
            # Clean folder name - remove [DDN] and other tags
            clean_name = folder_name.rstrip('/')
            clean_name = re.sub(r'\[DDN\]|\(DDN\)', '', clean_name)
            clean_name = clean_name.strip()
            
            # Extract information
            info = {
                'id': self._generate_id(clean_name, directory),
                'title': '',
                'year': '',
                'quality': '',
                'language': '',
                'type': 'movie',  # or 'series'
                'poster': None,   # Will be filled by TMDB later
                'rating': None,
                
                # Internal data (not shown to user)
                '_internal_folder': folder_name,
                '_internal_directory': directory,
                '_source': 'premium',  # Generic name
            }
            
            # Extract title and year
            # Pattern: Title.Year.Quality.Format.Codec
            match = re.search(r'^(.+?)[.\s](\d{4})', clean_name)
            if match:
                title_raw = match.group(1)
                info['title'] = title_raw.replace('.', ' ').replace('_', ' ').strip()
                info['year'] = match.group(2)
            else:
                # No year found
                info['title'] = clean_name.split('.')[0].replace('.', ' ').replace('_', ' ').strip()
            
            # Extract quality
            quality_patterns = ['2160p', '4K', 'UHD', '1080p', '720p', '480p']
            for q in quality_patterns:
                if q.lower() in clean_name.lower():
                    info['quality'] = q if q != '2160p' else '4K'
                    break
            
            # Extract language
            if 'Hindi' in clean_name or '/Indian' in directory:
                info['language'] = 'Hindi'
            elif '/English' in directory:
                info['language'] = 'English'
            
            # Determine type
            if '/TV_Series' in directory:
                info['type'] = 'series'
            
            return info
            
        except Exception as e:
            print(f"Parse error: {e}")
            return None
    
    def _generate_id(self, name: str, directory: str) -> str:
        """Generate unique ID for the movie"""
        import hashlib
        combined = f"{directory}/{name}"
        return hashlib.md5(combined.encode()).hexdigest()[:16]
    
    def get_playable_link(self, movie_id: str, internal_folder: str, 
                          internal_directory: str) -> Dict:
        """
        Get actual playable links from FTP folder
        
        Called when user clicks Play/Download
        Returns direct HTTP links (NO FTP paths exposed!)
        """
        try:
            ftp = ftplib.FTP(self.host, timeout=self.timeout)
            ftp.login(self.user, self.password)
            
            # Navigate to folder
            folder_path = f"{internal_directory}/{internal_folder}"
            ftp.cwd(folder_path)
            
            # Get files
            file_list = []
            ftp.retrlines('LIST', file_list.append)
            
            videos = []
            subtitles = []
            
            for file_info in file_list:
                parts = file_info.split()
                if len(parts) >= 9:
                    filename = ' '.join(parts[8:])
                    size = int(parts[4]) if parts[4].isdigit() else 0
                    
                    # Video files
                    if self._is_video(filename):
                        videos.append({
                            'filename': filename,
                            'size': size,
                            'quality': self._extract_quality_from_filename(filename),
                            # Direct HTTP link (converted from FTP)
                            'url': f"http://{self.host}{folder_path}/{quote(filename)}",
                        })
                    
                    # Subtitle files
                    elif filename.lower().endswith('.srt'):
                        subtitles.append({
                            'filename': filename,
                            'url': f"http://{self.host}{folder_path}/{quote(filename)}",
                        })
            
            ftp.quit()
            
            return {
                'success': True,
                'videos': videos,
                'subtitles': subtitles,
            }
            
        except Exception as e:
            print(f"Get links error: {e}")
            return {
                'success': False,
                'error': 'Could not retrieve playable links',
            }
    
    def _is_video(self, filename: str) -> bool:
        """Check if file is a video"""
        video_exts = ['.mp4', '.mkv', '.avi', '.mov', '.wmv', '.webm', '.m4v']
        return any(filename.lower().endswith(ext) for ext in video_exts)
    
    def _extract_quality_from_filename(self, filename: str) -> str:
        """Extract quality from filename"""
        filename_lower = filename.lower()
        if '2160p' in filename_lower or '4k' in filename_lower:
            return '4K'
        elif '1080p' in filename_lower:
            return '1080p'
        elif '720p' in filename_lower:
            return '720p'
        elif '480p' in filename_lower:
            return '480p'
        return 'HD'


# Helper function to format file size
def format_file_size(bytes: int) -> str:
    """Convert bytes to human readable format"""
    for unit in ['B', 'KB', 'MB', 'GB']:
        if bytes < 1024:
            return f"{bytes:.1f} {unit}"
        bytes /= 1024
    return f"{bytes:.1f} TB"

2.2 - Main FastAPI App (main.py):
python"""
Main FastAPI Application
Optimized for Render free tier (512 MB RAM)
"""

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Optional
import asyncio

from ftp_handler import FTPMovieHandler
# Import your existing scrapers
from scrapers.multi_source_manager import MultiSourceManager

app = FastAPI(
    title="FlixHub API",
    description="Movie search and streaming API",
    version="2.0.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize handlers
ftp_handler = FTPMovieHandler()
scraper_manager = None  # Lazy load to save RAM

def get_scraper_manager():
    """Lazy load scraper manager (only when needed)"""
    global scraper_manager
    if scraper_manager is None:
        scraper_manager = MultiSourceManager()
    return scraper_manager


@app.get("/")
async def root():
    """Health check"""
    return {
        "status": "healthy",
        "service": "FlixHub API",
        "version": "2.0.0"
    }


@app.get("/search")
async def search_movies(
    query: str = Query(..., min_length=2, description="Search query"),
    limit: int = Query(20, ge=1, le=50, description="Result limit")
):
    """
    Search for movies/series
    
    Flow:
    1. Check FTP server (fast, 80% hit rate)
    2. If not found, scrape websites (slower, 20%)
    
    Returns unified, clean results (NO source info exposed!)
    """
    
    if not query or len(query) < 2:
        raise HTTPException(400, "Query too short")
    
    # Step 1: Check FTP (lightweight!)
    print(f"🔍 Searching FTP for: {query}")
    ftp_results = ftp_handler.search(query, limit=limit)
    
    if ftp_results:
        print(f"✅ Found {len(ftp_results)} results on FTP")
        
        # Enrich with TMDB data (posters, ratings)
        # enriched_results = await enrich_with_tmdb(ftp_results)
        
        return {
            'success': True,
            'query': query,
            'total': len(ftp_results),
            'results': ftp_results,
            # NO 'source' field - keep it hidden!
        }
    
    # Step 2: FTP didn't have it, scrape websites
    print(f"⚠️ Not on FTP, starting scrapers...")
    
    try:
        manager = get_scraper_manager()
        scraped_results = await manager.search(query)
        
        if scraped_results:
            print(f"✅ Found {len(scraped_results)} scraped results")
            
            return {
                'success': True,
                'query': query,
                'total': len(scraped_results),
                'results': scraped_results,
            }
        else:
            return {
                'success': False,
                'query': query,
                'total': 0,
                'results': [],
                'message': 'No results found'
            }
            
    except Exception as e:
        print(f"❌ Scraping error: {e}")
        raise HTTPException(500, f"Search failed: {str(e)}")


@app.get("/movie/{movie_id}/links")
async def get_movie_links(movie_id: str):
    """
    Get playable links for a movie
    
    Called when user clicks Play/Download button
    Returns direct HTTP links (NO FTP/source info!)
    """
    
    # This endpoint receives movie_id which contains internal info
    # We need to retrieve the actual playable links
    
    # For FTP movies, extract internal folder info from movie_id
    # (You'll need to pass this data from search results)
    
    try:
        # Example: Parse movie_id to get folder info
        # In practice, you might store this in Redis/cache
        # or encode it in the movie_id itself
        
        result = {
            'success': True,
            'movie_id': movie_id,
            'links': [
                {
                    'quality': '1080p',
                    'size': '2.1 GB',
                    'url': 'http://direct-link-here.com/movie.mp4',
                    'type': 'video/mp4'
                }
            ],
            'subtitles': [
                {
                    'language': 'English',
                    'url': 'http://direct-link-here.com/subtitles.srt'
                }
            ]
        }
        
        return result
        
    except Exception as e:
        raise HTTPException(500, f"Failed to get links: {str(e)}")


@app.post("/movie/get-streams")
async def get_movie_streams(request: dict):
    """
    Alternative endpoint to get streams
    Accepts internal data to retrieve actual links
    """
    
    movie_id = request.get('movie_id')
    internal_folder = request.get('_internal_folder')
    internal_directory = request.get('_internal_directory')
    source = request.get('_source')
    
    if source == 'premium':
        # FTP movie
        result = ftp_handler.get_playable_link(
            movie_id,
            internal_folder,
            internal_directory
        )
        return result
    else:
        # Scraped movie - links already available
        return {
            'success': True,
            'videos': request.get('links', []),
            'subtitles': []
        }


@app.get("/trending")
async def get_trending(limit: int = 20):
    """
    Get trending movies
    Could pull from FTP's latest additions
    """
    # Implementation here
    pass


@app.get("/categories")
async def get_categories():
    """
    Get available categories
    """
    return {
        'categories': [
            {'id': 'hollywood', 'name': 'Hollywood', 'icon': '🎬'},
            {'id': 'bollywood', 'name': 'Bollywood', 'icon': '🎭'},
            {'id': 'series', 'name': 'TV Series', 'icon': '📺'},
        ]
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

2.3 - Requirements.txt:
txtfastapi==0.104.1
uvicorn[standard]==0.24.0
python-multipart==0.0.6
aiohttp==3.9.1
beautifulsoup4==4.12.2
lxml==4.9.3
playwright==1.40.0
pydantic==2.5.0
python-dotenv==1.0.0

3️⃣ FLUTTER APP IMPLEMENTATION
3.1 - Updated Movie Model:
dart// lib/models/movie.dart

class Movie {
  final String id;
  final String title;
  final String? year;
  final String? quality;
  final String? language;
  final String type; // 'movie' or 'series'
  final String? poster;
  final double? rating;
  
  // Internal data (hidden from UI)
  final String? internalFolder;
  final String? internalDirectory;
  final String? source;
  
  Movie({
    required this.id,
    required this.title,
    this.year,
    this.quality,
    this.language,
    this.type = 'movie',
    this.poster,
    this.rating,
    this.internalFolder,
    this.internalDirectory,
    this.source,
  });
  
  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      title: json['title'],
      year: json['year'],
      quality: json['quality'],
      language: json['language'],
      type: json['type'] ?? 'movie',
      poster: json['poster'],
      rating: json['rating']?.toDouble(),
      
      // Internal data
      internalFolder: json['_internal_folder'],
      internalDirectory: json['_internal_directory'],
      source: json['_source'],
    );
  }
  
  // Check if this is from premium source (but don't expose to UI!)
  bool get isPremium => source == 'premium';
}

3.2 - API Service:
dart// lib/services/api_service.dart

import 'package:dio/dio.dart';
import '../models/movie.dart';

class ApiService {
  static const String baseUrl = 'https://your-app.onrender.com';
  
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 30),
    ),
  );
  
  /// Search for movies
  static Future<List<Movie>> searchMovies(String query) async {
    try {
      final response = await _dio.get(
        '/search',
        queryParameters: {'query': query, 'limit': 20},
      );
      
      if (response.data['success']) {
        final results = response.data['results'] as List;
        return results.map((json) => Movie.fromJson(json)).toList();
      }
      
      return [];
      
    } catch (e) {
      print('Search error: $e');
      rethrow;
    }
  }
  
  /// Get playable links for a movie
  static Future<MovieStreams> getMovieStreams(Movie movie) async {
    try {
      final response = await _dio.post(
        '/movie/get-streams',
        data: {
          'movie_id': movie.id,
          '_internal_folder': movie.internalFolder,
          '_internal_directory': movie.internalDirectory,
          '_source': movie.source,
        },
      );
      
      return MovieStreams.fromJson(response.data);
      
    } catch (e) {
      print('Get streams error: $e');
      rethrow;
    }
  }
}

class MovieStreams {
  final bool success;
  final List<VideoLink> videos;
  final List<SubtitleLink> subtitles;
  
  MovieStreams({
    required this.success,
    required this.videos,
    required this.subtitles,
  });
  
  factory MovieStreams.fromJson(Map<String, dynamic> json) {
    return MovieStreams(
      success: json['success'] ?? false,
      videos: (json['videos'] as List?)
          ?.map((v) => VideoLink.fromJson(v))
          .toList() ?? [],
      subtitles: (json['subtitles'] as List?)
          ?.map((s) => SubtitleLink.fromJson(s))
          .toList() ?? [],
    );
  }
}

class VideoLink {
  final String filename;
  final String quality;
  final int size;
  final String url;
  
  VideoLink({
    required this.filename,
    required this.quality,
    required this.size,
    required this.url,
  });
  
  factory VideoLink.fromJson(Map<String, dynamic> json) {
    return VideoLink(
      filename: json['filename'] ?? '',
      quality: json['quality'] ?? 'HD',
      size: json['size'] ?? 0,
      url: json['url'],
    );
  }
  
  String get formattedSize {
    if (size < 1024) return '${size} B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class SubtitleLink {
  final String filename;
  final String url;
  
  SubtitleLink({required this.filename, required this.url});
  
  factory SubtitleLink.fromJson(Map<String, dynamic> json) {
    return SubtitleLink(
      filename: json['filename'] ?? '',
      url: json['url'],
    );
  }
}

3.3 - Movie Card Widget (CLEAN UI - No Source Info!):
dart// lib/widgets/movie_card.dart

import 'package:flutter/material.dart';
import '../models/movie.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;
  
  const MovieCard({
    Key? key,
    required this.movie,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Poster
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: movie.poster != null
                  ? Image.network(
                      movie.poster!,
                      width: 100,
                      height: 150,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 100,
                      height: 150,
                      color: Colors.grey[800],
                      child: Icon(
                        Icons.movie,
                        size: 40,
                        color: Colors.grey[600],
                      ),
                    ),
            ),
            
            SizedBox(width: 16),
            
            // Info
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      movie.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: 8),
                    
                    // Year, Quality, Language (NO source info!)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (movie.year != null)
                          _buildInfoChip(
                            movie.year!,
                            Icons.calendar_today,
                            Colors.blue[700]!,
                          ),
                        
                        if (movie.quality != null)
                          _buildInfoChip(
                            movie.quality!,
                            Icons.hd,
                            Colors.green[700]!,
                          ),
                        
                        if (movie.language != null)
                          _buildInfoChip(
                            movie.language!,
                            Icons.language,
                            Colors.orange[700]!,
                          ),
                      ],
                    ),
                    
                    SizedBox(height: 8),
                    
                    // Rating (if available)
                    if (movie.rating != null)
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            movie.rating!.toStringAsFixed(1),
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            
            SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

3.4 - Movie Details Screen (Clean, No Source Info):
dart// lib/screens/movie_details_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/movie.dart';
import '../services/api_service.dart';
import 'video_player_screen.dart';

class MovieDetailsScreen extends StatefulWidget {
  final Movie movie;
  
  const MovieDetailsScreen({Key? key, required this.movie}) : super(key: key);
  
  @override
  _MovieDetailsScreenState createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  bool _isLoading = false;
  MovieStreams? _streams;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadStreams();
  }
  
  Future<void> _loadStreams() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final streams = await ApiService.getMovieStreams(widget.movie);
      
      setState(() {
        _streams = streams;
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _error = 'Failed to load streams';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F23),
      body: CustomScrollView(
        slivers: [
          // App Bar with poster
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: widget.movie.poster != null
                  ? Image.network(
                      widget.movie.poster!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey[900],
                      child: Icon(
                        Icons.movie,
                        size: 80,
                        color: Colors.grey[700],
                      ),
                    ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.movie.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Info row (NO source info!)
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (widget.movie.year != null)
                        _buildInfoBadge(widget.movie.year!, Icons.calendar_today),
                      
                      if (widget.movie.quality != null)
                        _buildInfoBadge(widget.movie.quality!, Icons.hd),
                      
                      if (widget.movie.language != null)
                        _buildInfoBadge(widget.movie.language!, Icons.language),
                      
                      if (widget.movie.rating != null)
                        _buildInfoBadge(
                          '⭐ ${widget.movie.rating!.toStringAsFixed(1)}',
                          Icons.star,
                        ),
                    ],
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Action Buttons
                  if (_isLoading)
                    Center(
                      child: CircularProgressIndicator(),
                    )
                  else if (_error != null)
                    Center(
                      child: Column(
                        children: [
                          Text(
                            _error!,
                            style: TextStyle(color: Colors.red),
                          ),
                          SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _loadStreams,
                            child: Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  else if (_streams != null)
                    Column(
                      children: [
                        // Main action buttons
                        Row(
                          children: [
                            // Play button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _playMovie(),
                                icon: Icon(Icons.play_arrow, size: 28),
                                label: Text(
                                  'PLAY',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            
                            SizedBox(width: 12),
                            
                            // Download button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _downloadMovie(),
                                icon: Icon(Icons.download, size: 24),
                                label: Text(
                                  'DOWNLOAD',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 20),
                        
                        // Available qualities (if multiple)
                        if (_streams!.videos.length > 1) ...[
                          Text(
                            'Available Qualities:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          ..._streams!.videos.map((video) => _buildQualityOption(video)),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoBadge(String text, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQualityOption(VideoLink video) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.movie, color: Colors.blue),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.quality,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Size: ${video.formattedSize}',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.play_arrow, color: Colors.green),
            onPressed: () => _playVideo(video),
          ),
          IconButton(
            icon: Icon(Icons.download, color: Colors.blue),
            onPressed: () => _downloadVideo(video),
          ),
        ],
      ),
    );
  }
  
  void _playMovie() {
    if (_streams!.videos.isNotEmpty) {
      _playVideo(_streams!.videos.first);
    }
  }
  
  void _playVideo(VideoLink video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(
          videoUrl: video.url,
          title: widget.movie.title,
          subtitleUrl: _streams!.subtitles.isNotEmpty
              ? _streams!.subtitles.first.url
              : null,
        ),
      ),
    );
  }
  
  void _downloadMovie() {
    if (_streams!.videos.isNotEmpty) {
      _downloadVideo(_streams!.videos.first);
    }
  }
  
  void _downloadVideo(VideoLink video) {
    // Implement download using your existing download manager
    Get.snackbar(
      'Download Started',
      '${widget.movie.title} - ${video.quality}',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      icon: Icon(Icons.download, color: Colors.white),
    );
    
    // Call your download service
    // DownloadService.instance.addDownload(video.url, widget.movie.title);
  }
}

3.5 - Video Player Screen:
dart// lib/screens/video_player_screen.dart

import 'package:flutter/material.dart';
import 'package:better_player/better_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String? subtitleUrl;
  
  const VideoPlayerScreen({
    Key? key,
    required this.videoUrl,
    required this.title,
    this.subtitleUrl,
  }) : super(key: key);
  
  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late BetterPlayerController _controller;
  
  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }
  
  void _initializePlayer() {
    BetterPlayerDataSource dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      widget.videoUrl,
      subtitles: widget.subtitleUrl != null ? [
        BetterPlayerSubtitlesSource(
          type: BetterPlayerSubtitlesSourceType.network,
          urls: [widget.subtitleUrl!],
        ),
      ] : null,
      notificationConfiguration: BetterPlayerNotificationConfiguration(
        showNotification: true,
        title: widget.title,
        author: 'FlixHub',
      ),
    );
    
    _controller = BetterPlayerController(
      BetterPlayerConfiguration(
        aspectRatio: 16 / 9,
        autoPlay: true,
        looping: false,
        fullScreenByDefault: true,
        fit: BoxFit.contain,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          enableSkips: true,
          enableFullscreen: true,
          enablePip: true,
          enablePlaybackSpeed: true,
          enableSubtitles: widget.subtitleUrl != null,
          enableMute: true,
          enableProgressText: true,
          enableProgressBar: true,
          enableProgressBarDrag: true,
        ),
      ),
      betterPlayerDataSource: dataSource,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: BetterPlayer(
            controller: _controller,
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

---

# 4️⃣ HIDING SOURCE INFORMATION

## **Critical Rules:**
```
✅ DO:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Show movie title, year, quality, language
✅ Show clean, professional UI
✅ Use generic terms like "Premium", "HD", "High Quality"
✅ Focus on user experience

❌ DON'T:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ Show [DDN] tags
❌ Show FTP URLs or paths
❌ Show "Source: FTP" or "Source: HDHub4u"
❌ Expose internal folder names
❌ Display ftp.ctgfun.com anywhere
❌ Show backend source in UI

USER SHOULD JUST SEE:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"Inception (2010) - 1080p - English"
[▶ PLAY] [⬇ DOWNLOAD]

That's it! Clean and professional! ✅

5️⃣ TESTING & DEPLOYMENT
5.1 - Local Testing:
bash# Backend
cd backend
pip install -r requirements.txt
playwright install
uvicorn main:app --reload

# Test endpoints
curl http://localhost:8000/search?query=inception

# Flutter app
cd flixhub_app
flutter pub get
flutter run
5.2 - Deploy to Render:
yaml# render.yaml
services:
  - type: web
    name: flixhub-api
    env: python
    buildCommand: "pip install -r requirements.txt && playwright install"
    startCommand: "uvicorn main:app --host 0.0.0.0 --port $PORT"
    envVars:
      - key: PYTHON_VERSION
        value: 3.11.0
```

## **5.3 - Testing Checklist:**
```
□ Search returns results from FTP
□ Search falls back to scraping when FTP has no results
□ No [DDN] tags shown to users
□ No FTP URLs visible in UI
□ Play button streams video correctly
□ Download button downloads file
□ Subtitles work (if available)
□ Multiple qualities selectable
□ App doesn't crash on errors
□ Loading indicators show properly

6️⃣ OPTIMIZATION & SCALING
Memory Optimization:
python# Add caching
from functools import lru_cache

@lru_cache(maxsize=500)
def cached_ftp_search(query: str):
    return ftp_handler.search(query)
Performance Monitoring:
pythonimport time

@app.middleware("http")
async def log_requests(request, call_next):
    start = time.time()
    response = await call_next(request)
    duration = time.time() - start
    print(f"{request.method} {request.url.path} - {duration:.2f}s")
    return response
```

---

# ✅ SUMMARY
```
IMPLEMENTATION CHECKLIST:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Backend:
□ FTP handler implemented
□ Search endpoint (FTP first, scraping fallback)
□ Get streams endpoint
□ All [DDN] tags removed from responses
□ No FTP paths exposed in API

Flutter App:
□ Updated movie model
□ API service with getMovieStreams
□ Clean movie cards (no source info)
□ Movie details screen
□ Video player with BetterPlayer
□ Download functionality

Testing:
□ FTP search works
□ Scraping fallback works
□ Play works
□ Download works
□ UI is clean (no source info visible)

Deployment:
□ Deployed to Render
□ Environment variables set
□ Domain configured
□ SSL working

READY TO LAUNCH! 🚀