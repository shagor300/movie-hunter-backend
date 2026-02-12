# 🎬 MovieHub - Multi-Source Implementation Guide (SkyMoviesHD + HDHub4u)

**Complete Advanced Implementation for Google Antigravity / AI Assistant**

---

## 📋 **Project Overview**

### **Current State:**
- ✅ HDHub4u scraper working
- ✅ Single source for movies
- ✅ Download link extraction working

### **New Requirements:**
1. ✅ Add **SkyMoviesHD** (`https://skymovieshd.mba/`) as second source
2. ✅ **Multi-source search** - Search both HDHub4u AND SkyMoviesHD simultaneously
3. ✅ Extract **Google Drive Direct Links** from SkyMoviesHD
4. ✅ **Modular configuration** - Easy domain updates via Render environment variables
5. ✅ **Bypass shortener links** - Resolve intermediate redirect pages
6. ✅ **Combine results** - Show movies from both sources in one list

---

## 🎯 **Architecture Overview**

### **Multi-Source Search Flow:**

```
User searches: "Inception"
    ↓
Backend searches BOTH sources in parallel:
  ┌─────────────────┬──────────────────┐
  │   HDHub4u.fo    │  SkyMoviesHD.mba │
  └─────────────────┴──────────────────┘
         ↓                    ↓
    20 results           15 results
         ↓                    ↓
    Match with TMDB     Match with TMDB
         └────────┬────────────┘
                  ↓
         Combine & Deduplicate
         (by TMDB ID)
                  ↓
         35 unique movies
                  ↓
         App shows all results
         with source badges
```

### **Link Extraction Flow:**

```
User clicks movie from SkyMoviesHD:
    ↓
Navigate to movie page
    ↓
Scroll to "Download Links" section
    ↓
Find "Google Drive Direct Links" button
    ↓
Extract all Drive links
    ↓
Resolve shortener links (if any):
  - Follow redirects
  - Handle intermediate pages
  - Extract final Drive URL
    ↓
Return clean Google Drive links
```

---

## 🗂️ **File Structure**

```
backend/
├── config/
│   └── sources.py                    # NEW - Centralized source configuration
├── scrapers/
│   ├── __init__.py                   # NEW - Package init
│   ├── base_scraper.py               # NEW - Base class for all scrapers
│   ├── hdhub4u_scraper.py            # REFACTOR - Move existing logic here
│   └── skymovieshd_scraper.py        # NEW - SkyMoviesHD scraper
├── utils/
│   └── shortener_resolver.py        # NEW - Resolve shortener links
├── multi_source_manager.py           # NEW - Manages multiple sources
├── main.py                           # UPDATE - Add multi-source endpoints
└── requirements.txt                  # KEEP - No new dependencies needed
```

---

## 🔧 **IMPLEMENTATION**

### **File 1: Source Configuration (Modular)**

**File:** `backend/config/sources.py`

```python
"""
Centralized configuration for all movie sources
Update domains easily via Render environment variables
"""

import os
import logging

logger = logging.getLogger(__name__)

class MovieSources:
    """Configuration for all movie sources"""
    
    # ===== HDHub4u Configuration =====
    HDHUB4U_BASE_URL = os.getenv('HDHUB4U_URL', 'https://new3.hdhub4u.fo')
    HDHUB4U_ENABLED = os.getenv('HDHUB4U_ENABLED', 'true').lower() == 'true'
    
    # ===== SkyMoviesHD Configuration =====
    SKYMOVIESHD_BASE_URL = os.getenv('SKYMOVIESHD_URL', 'https://skymovieshd.mba')
    SKYMOVIESHD_ENABLED = os.getenv('SKYMOVIESHD_ENABLED', 'true').lower() == 'true'
    
    # ===== Search Configuration =====
    MAX_RESULTS_PER_SOURCE = int(os.getenv('MAX_RESULTS_PER_SOURCE', '20'))
    SEARCH_TIMEOUT = int(os.getenv('SEARCH_TIMEOUT', '30'))
    
    # ===== TMDB Configuration =====
    TMDB_API_KEY = "7efd8424c17ff5b3e8dc9cebf4a33f73"
    TMDB_BASE_URL = "https://api.themoviedb.org/3"
    TMDB_IMAGE_BASE = "https://image.tmdb.org/t/p/w500"
    
    @classmethod
    def get_enabled_sources(cls) -> list:
        """
        Get list of enabled sources
        Returns list of dicts with source info
        """
        sources = []
        
        if cls.HDHUB4U_ENABLED:
            sources.append({
                'name': 'HDHub4u',
                'base_url': cls.HDHUB4U_BASE_URL,
                'type': 'hdhub4u',
                'priority': 1  # Higher priority (shown first)
            })
        
        if cls.SKYMOVIESHD_ENABLED:
            sources.append({
                'name': 'SkyMoviesHD',
                'base_url': cls.SKYMOVIESHD_BASE_URL,
                'type': 'skymovieshd',
                'priority': 2
            })
        
        return sources
    
    @classmethod
    def print_config(cls):
        """Print current configuration (for debugging)"""
        print("\n" + "="*70)
        print("🎬 MOVIE SOURCES CONFIGURATION")
        print("="*70)
        
        if cls.HDHUB4U_ENABLED:
            print(f"✅ HDHub4u:      {cls.HDHUB4U_BASE_URL}")
        else:
            print(f"❌ HDHub4u:      Disabled")
        
        if cls.SKYMOVIESHD_ENABLED:
            print(f"✅ SkyMoviesHD:  {cls.SKYMOVIESHD_BASE_URL}")
        else:
            print(f"❌ SkyMoviesHD:  Disabled")
        
        print(f"\n⚙️  Max results per source: {cls.MAX_RESULTS_PER_SOURCE}")
        print(f"⏱️  Search timeout: {cls.SEARCH_TIMEOUT}s")
        print("="*70 + "\n")
```

---

### **File 2: Base Scraper Class**

**File:** `backend/scrapers/base_scraper.py`

```python
"""
Base scraper class - All movie scrapers inherit from this
Provides common functionality like TMDB matching, title cleaning, etc.
"""

from abc import ABC, abstractmethod
from typing import List, Dict, Optional
from playwright.async_api import Page, Browser
import requests
import re
import logging

from config.sources import MovieSources

logger = logging.getLogger(__name__)

class BaseMovieScraper(ABC):
    """Abstract base class for all movie scrapers"""
    
    def __init__(self, base_url: str, source_name: str):
        self.base_url = base_url
        self.source_name = source_name
        self.browser: Optional[Browser] = None
    
    @abstractmethod
    async def search_movies(self, query: str, max_results: int = 20) -> List[Dict]:
        """
        Search for movies on this source
        MUST be implemented by each scraper
        
        Returns list of dicts with movie info
        """
        pass
    
    @abstractmethod
    async def extract_links(self, movie_url: str) -> Dict:
        """
        Extract download/streaming links from movie page
        MUST be implemented by each scraper
        
        Returns dict with watch_links and download_links
        """
        pass
    
    # ===== Helper Methods (used by all scrapers) =====
    
    async def _navigate_safe(self, page: Page, url: str, wait_for: str = 'domcontentloaded'):
        """Safely navigate to URL with error handling"""
        try:
            logger.info(f"🔗 [{self.source_name}] Navigating to: {url}")
            await page.goto(url, wait_until=wait_for, timeout=30000)
            return True
        except Exception as e:
            logger.error(f"❌ [{self.source_name}] Navigation failed: {e}")
            return False
    
    def _clean_title(self, title: str) -> tuple:
        """
        Clean movie title and extract year
        
        Input: "Inception 2010 1080p BluRay Hindi Dubbed"
        Output: ("Inception", "2010")
        """
        # Remove quality markers
        title = re.sub(r'\b(480p|720p|1080p|2160p|4K|HDRip|BluRay|WEB-DL|HEVC|x264|x265)\b', '', title, flags=re.I)
        
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
        
        # Clean up separators and spaces
        title = re.sub(r'[:\-\|]+', ' ', title)
        title = re.sub(r'\s+', ' ', title)
        title = title.strip()
        
        return title, year
    
    def _extract_quality(self, text: str) -> str:
        """Extract quality from text"""
        match = re.search(r'(480p|720p|1080p|2160p|4K|HD|FHD|UHD)', text, re.I)
        return match.group(1).upper() if match else 'HD'
    
    async def _match_with_tmdb(self, title: str, year: Optional[str] = None) -> Optional[Dict]:
        """
        Match movie with TMDB database to get poster, rating, etc.
        """
        try:
            params = {
                'api_key': MovieSources.TMDB_API_KEY,
                'query': title,
                'include_adult': 'false'
            }
            
            if year:
                params['year'] = year
            
            response = requests.get(
                f"{MovieSources.TMDB_BASE_URL}/search/movie",
                params=params,
                timeout=10
            )
            
            if response.status_code == 200:
                data = response.json()
                results = data.get('results', [])
                
                # Try without year if no results
                if not results and year:
                    params.pop('year')
                    response = requests.get(
                        f"{MovieSources.TMDB_BASE_URL}/search/movie",
                        params=params,
                        timeout=10
                    )
                    data = response.json()
                    results = data.get('results', [])
                
                if results:
                    movie = results[0]  # Take first result
                    
                    return {
                        'tmdb_id': movie['id'],
                        'title': movie['title'],
                        'poster_url': f"{MovieSources.TMDB_IMAGE_BASE}{movie['poster_path']}" if movie.get('poster_path') else None,
                        'backdrop_url': f"https://image.tmdb.org/t/p/original{movie['backdrop_path']}" if movie.get('backdrop_path') else None,
                        'rating': round(movie.get('vote_average', 0), 1),
                        'overview': movie.get('overview', ''),
                        'release_date': movie.get('release_date', ''),
                    }
            
            return None
            
        except Exception as e:
            logger.error(f"TMDB match error for '{title}': {e}")
            return None
```

---

### **File 3: SkyMoviesHD Scraper (Complete)**

**File:** `backend/scrapers/skymovieshd_scraper.py`

```python
"""
SkyMoviesHD Scraper
Extracts movies and Google Drive links from SkyMoviesHD.mba
"""

import asyncio
import re
from bs4 import BeautifulSoup
from playwright.async_api import async_playwright, Page
from typing import List, Dict, Optional
import logging

from .base_scraper import BaseMovieScraper

logger = logging.getLogger(__name__)

class SkyMoviesHDScraper(BaseMovieScraper):
    """Scraper for SkyMoviesHD website"""
    
    def __init__(self, base_url: str):
        super().__init__(base_url, 'SkyMoviesHD')
        self.playwright = None
        self.browser = None
    
    async def init_browser(self):
        """Initialize Playwright browser"""
        if not self.browser:
            self.playwright = await async_playwright().start()
            self.browser = await self.playwright.chromium.launch(
                headless=True,
                args=['--no-sandbox', '--disable-setuid-sandbox']
            )
            logger.info(f"✅ [{self.source_name}] Browser initialized")
    
    async def search_movies(self, query: str, max_results: int = 20) -> List[Dict]:
        """
        Search for movies on SkyMoviesHD
        
        Steps:
        1. Navigate to search URL
        2. Parse search results
        3. Extract movie info
        4. Match with TMDB
        """
        await self.init_browser()
        
        context = await self.browser.new_context(
            user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        )
        page = await context.new_page()
        
        movies = []
        
        try:
            logger.info(f"🔍 [{self.source_name}] Searching for: {query}")
            
            # Build search URL
            search_url = f"{self.base_url}/?s={query.replace(' ', '+')}"
            
            # Navigate
            success = await self._navigate_safe(page, search_url)
            if not success:
                return movies
            
            await asyncio.sleep(3)
            
            # Get page content
            content = await page.content()
            soup = BeautifulSoup(content, 'html.parser')
            
            # Find movie posts
            # Adjust selectors based on actual SkyMoviesHD structure
            posts = soup.find_all(['article', 'div'], 
                                 class_=re.compile(r'post|item|movie|entry', re.I))
            
            logger.info(f"📄 [{self.source_name}] Found {len(posts)} posts")
            
            for post in posts[:max_results]:
                try:
                    # Extract title
                    title_elem = post.find(['h2', 'h3', 'a'], 
                                          class_=re.compile(r'title|entry-title', re.I))
                    
                    if not title_elem:
                        title_elem = post.find('a', href=True)
                    
                    if not title_elem:
                        continue
                    
                    raw_title = title_elem.get_text(strip=True)
                    
                    # Extract URL
                    movie_url = None
                    if title_elem.name == 'a':
                        movie_url = title_elem.get('href')
                    else:
                        link = post.find('a', href=True)
                        if link:
                            movie_url = link['href']
                    
                    if not movie_url or not raw_title:
                        continue
                    
                    # Extract poster
                    poster_elem = post.find('img', src=True)
                    poster_url = poster_elem['src'] if poster_elem else None
                    
                    # Clean title and extract year
                    clean_title, year = self._clean_title(raw_title)
                    
                    # Extract quality
                    quality = self._extract_quality(raw_title)
                    
                    logger.info(f"📌 [{self.source_name}] Found: {clean_title} ({year}) - {quality}")
                    
                    # Match with TMDB
                    tmdb_data = await self._match_with_tmdb(clean_title, year)
                    
                    if tmdb_data:
                        movies.append({
                            'source': self.source_name,
                            'source_type': 'skymovieshd',
                            'title': tmdb_data['title'],
                            'original_title': raw_title,
                            'url': movie_url,
                            'year': year,
                            'quality': quality,
                            'poster': tmdb_data['poster_url'] or poster_url,
                            'backdrop': tmdb_data['backdrop_url'],
                            'tmdb_id': tmdb_data['tmdb_id'],
                            'rating': tmdb_data['rating'],
                            'overview': tmdb_data['overview'],
                            'release_date': tmdb_data['release_date'],
                        })
                    else:
                        # Add without TMDB data
                        movies.append({
                            'source': self.source_name,
                            'source_type': 'skymovieshd',
                            'title': clean_title,
                            'original_title': raw_title,
                            'url': movie_url,
                            'year': year,
                            'quality': quality,
                            'poster': poster_url,
                        })
                
                except Exception as e:
                    logger.error(f"Error parsing post: {e}")
                    continue
            
            logger.info(f"✅ [{self.source_name}] Successfully extracted {len(movies)} movies")
            
        except Exception as e:
            logger.error(f"❌ [{self.source_name}] Search error: {e}")
        
        finally:
            await page.close()
            await context.close()
        
        return movies
    
    async def extract_links(self, movie_url: str) -> Dict:
        """
        Extract Google Drive links from SkyMoviesHD movie page
        
        Steps:
        1. Navigate to movie page
        2. Scroll to load content
        3. Find "Google Drive Direct Links" section
        4. Extract all Drive links
        5. Resolve shortener links
        """
        await self.init_browser()
        
        context = await self.browser.new_context(
            user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        )
        page = await context.new_page()
        
        result = {
            'watch_links': [],
            'download_links': []
        }
        
        try:
            logger.info(f"🔗 [{self.source_name}] Extracting links from: {movie_url}")
            
            # Navigate to movie page
            success = await self._navigate_safe(page, movie_url)
            if not success:
                return result
            
            await asyncio.sleep(3)
            
            # Scroll to load all content
            for _ in range(3):
                await page.evaluate('window.scrollBy(0, window.innerHeight)')
                await asyncio.sleep(1)
            
            content = await page.content()
            soup = BeautifulSoup(content, 'html.parser')
            
            # ===== Method 1: Find "Google Drive" section by text =====
            gdrive_headers = soup.find_all(text=re.compile(r'Google\s*Drive|G-?Drive|Download\s*Links', re.I))
            
            for header in gdrive_headers:
                # Get parent element
                parent = header.find_parent()
                if not parent:
                    continue
                
                # Find next sibling or parent's next sibling
                section = parent.find_next_sibling()
                if not section:
                    section = parent.find_parent().find_next_sibling()
                
                if section:
                    # Find all links in this section
                    links = section.find_all('a', href=True)
                    
                    for link in links:
                        href = link['href']
                        text = link.get_text(strip=True)
                        
                        # Check if it's a Google Drive link
                        if self._is_drive_link(href):
                            quality = self._extract_quality(text)
                            
                            result['download_links'].append({
                                'name': f"Google Drive - {quality}",
                                'url': href,
                                'quality': quality,
                                'type': 'Google Drive',
                                'source': self.source_name,
                                'link_type': 'download'
                            })
            
            # ===== Method 2: Find buttons with "Google Drive" text =====
            gdrive_buttons = soup.find_all(['a', 'button'], 
                                         text=re.compile(r'Google.*Drive|G-?Drive', re.I))
            
            for button in gdrive_buttons:
                href = button.get('href')
                if href and self._is_drive_link(href):
                    text = button.get_text(strip=True)
                    quality = self._extract_quality(text)
                    
                    # Avoid duplicates
                    if not any(link['url'] == href for link in result['download_links']):
                        result['download_links'].append({
                            'name': f"Google Drive - {quality}",
                            'url': href,
                            'quality': quality,
                            'type': 'Google Drive',
                            'source': self.source_name,
                            'link_type': 'download'
                        })
            
            # ===== Method 3: Find all Drive links on page =====
            all_links = soup.find_all('a', href=True)
            
            for link in all_links:
                href = link['href']
                
                if self._is_drive_link(href):
                    text = link.get_text(strip=True)
                    quality = self._extract_quality(text) or 'HD'
                    
                    # Avoid duplicates
                    if not any(l['url'] == href for l in result['download_links']):
                        result['download_links'].append({
                            'name': f"Google Drive - {quality}",
                            'url': href,
                            'quality': quality,
                            'type': 'Google Drive',
                            'source': self.source_name,
                            'link_type': 'download'
                        })
            
            # ===== Resolve shortener links =====
            result['download_links'] = await self._resolve_shorteners(
                result['download_links'], 
                page
            )
            
            logger.info(f"✅ [{self.source_name}] Found {len(result['download_links'])} download links")
            
        except Exception as e:
            logger.error(f"❌ [{self.source_name}] Link extraction error: {e}")
        
        finally:
            await page.close()
            await context.close()
        
        return result
    
    def _is_drive_link(self, url: str) -> bool:
        """Check if URL is a Google Drive link or shortener"""
        drive_patterns = [
            'drive.google.com',
            'docs.google.com',
            'gdrive',
            # Common shorteners used before Drive links
            'bit.ly',
            'tinyurl',
            't.me',  # Telegram links sometimes lead to Drive
        ]
        
        return any(pattern in url.lower() for pattern in drive_patterns)
    
    async def _resolve_shorteners(self, links: List[Dict], page: Page) -> List[Dict]:
        """
        Resolve shortener links to final Google Drive URLs
        SkyMoviesHD often uses intermediate shortener pages
        """
        resolved_links = []
        
        for link in links:
            url = link['url']
            
            # Already a direct Drive link?
            if 'drive.google.com/file/' in url or 'drive.google.com/uc' in url:
                resolved_links.append(link)
                logger.info(f"✅ Already direct Drive link: {url}")
                continue
            
            # Try to resolve shortener
            try:
                logger.info(f"🔗 Resolving shortener: {url}")
                
                # Navigate to shortener page
                await page.goto(url, wait_until='domcontentloaded', timeout=15000)
                await asyncio.sleep(2)
                
                # Check if redirected to Drive
                current_url = page.url
                
                if 'drive.google.com' in current_url:
                    # Successfully redirected
                    link['url'] = current_url
                    resolved_links.append(link)
                    logger.info(f"✅ Resolved to: {current_url}")
                else:
                    # Look for Drive link in page
                    content = await page.content()
                    soup = BeautifulSoup(content, 'html.parser')
                    
                    drive_link = soup.find('a', href=re.compile(r'drive\.google\.com'))
                    
                    if drive_link:
                        link['url'] = drive_link['href']
                        resolved_links.append(link)
                        logger.info(f"✅ Found Drive link in page")
                    else:
                        # Keep original URL
                        resolved_links.append(link)
                        logger.warning(f"⚠️ Could not resolve: {url}")
            
            except Exception as e:
                logger.error(f"Error resolving {url}: {e}")
                # Keep original URL
                resolved_links.append(link)
        
        return resolved_links
    
    async def close(self):
        """Cleanup browser"""
        if self.browser:
            await self.browser.close()
        if self.playwright:
            await self.playwright.stop()
```

---

I'll create the remaining files in the next message to stay within limits. The guide continues with the Multi-Source Manager, API endpoints, and Flutter integration.