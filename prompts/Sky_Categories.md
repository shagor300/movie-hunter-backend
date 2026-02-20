Hi Antigravity,

SkyMoviesHD search is broken. Instead of fixing the broken 
search, implement a SMARTER CATEGORY-BASED approach.

SITE STRUCTURE:
SkyMoviesHD has these categories:

1. Bollywood Movies
2. South Indian Hindi Dubbed Movies
3. Bengali Movies
4. Pakistani Movies
5. Hollywood English Movies
6. Hollywood Hindi Dubbed Movies
7. Tamil Movies
8. Telugu Movies
9. Punjabi Movies
10. Bhojpuri Movies
11. Bangladeshi Movies
12. Marathi Movies
13. Kannada Movies

CURRENT PROBLEM:
- Search returns 0 results always
- But movies clearly exist in categories
- Playwright loads page but finds nothing

NEW APPROACH - TWO METHODS:

════════════════════════════════
METHOD 1: CATEGORY URL SEARCH
════════════════════════════════

Instead of search box, scrape category pages directly:
```python
# Category URL mapping
SKYMOVIESHD_CATEGORIES = {
    'bollywood': 'https://skymovieshd.mba/cat/bollywood/',
    'south_dubbed': 'https://skymovieshd.mba/cat/south-indian-hindi-dubbed-movies/',
    'bengali': 'https://skymovieshd.mba/cat/bengali-movies/',
    'pakistani': 'https://skymovieshd.mba/cat/pakistani-movies/',
    'hollywood_english': 'https://skymovieshd.mba/cat/hollywood-english-movies/',
    'hollywood_dubbed': 'https://skymovieshd.mba/cat/hollywood-hindi-dubbed-movies/',
    'tamil': 'https://skymovieshd.mba/cat/tamil-movies/',
    'telugu': 'https://skymovieshd.mba/cat/telugu-movies/',
    'punjabi': 'https://skymovieshd.mba/cat/punjabi-movies/',
    'bhojpuri': 'https://skymovieshd.mba/cat/bhojpuri-movies/',
    'bangladeshi': 'https://skymovieshd.mba/cat/bangladeshi-movies/',
    'marathi': 'https://skymovieshd.mba/cat/marathi-movies/',
    'kannada': 'https://skymovieshd.mba/cat/kannada-movies/',
}

async def search_skymovieshd_by_category(query: str, year: str = None):
    """
    Search SkyMoviesHD by browsing category pages
    and matching movie title
    """
    results = []
    
    # Determine which categories to search
    # based on movie language/type
    categories_to_search = _get_relevant_categories(query)
    
    for category_url in categories_to_search:
        movies = await _scrape_category_page(category_url, query)
        results.extend(movies)
        
        if results:
            break  # Found results, stop searching
    
    return results
```

════════════════════════════════
METHOD 2: FIXED SEARCH URL
════════════════════════════════

Also try these search URL formats 
(one of them should work):
```python
SEARCH_URL_FORMATS = [
    "https://skymovieshd.mba/?s={query}",
    "https://skymovieshd.mba/?s={query}&post_type=post",
    "https://skymovieshd.mba/search/{query}",
    "https://skymovieshd.mba/?search={query}",
]

async def try_all_search_urls(query: str):
    for url_format in SEARCH_URL_FORMATS:
        url = url_format.format(query=query.replace(' ', '+'))
        
        try:
            # Load page
            await page.goto(url, wait_until='networkidle')
            await page.wait_for_timeout(2000)
            
            # Take screenshot for debugging
            await page.screenshot(
                path=f"/tmp/sky_search_{query.replace(' ','_')}.png"
            )
            
            # Try multiple selectors
            for selector in [
                'article h2 a',
                '.post-title a',
                'h2.entry-title a',
                '.title a',
                'div.post h2 a',
                'h2 a',
            ]:
                elements = await page.query_selector_all(selector)
                if elements:
                    print(f"✅ URL: {url}")
                    print(f"✅ Selector: {selector}")
                    print(f"✅ Found: {len(elements)} results")
                    return elements
                    
        except Exception as e:
            print(f"❌ Failed URL {url}: {e}")
            continue
    
    return []
```

════════════════════════════════
COMPLETE FIXED SCRAPER:
════════════════════════════════
```python
# scrapers/skymovieshd_scraper_v2.py

import asyncio
import httpx
from playwright.async_api import async_playwright

SKYMOVIESHD_BASE = "https://skymovieshd.mba"

# Category URLs - try these exact URLs
CATEGORIES = {
    'bollywood': f'{SKYMOVIESHD_BASE}/cat/bollywood/',
    'south_hindi': f'{SKYMOVIESHD_BASE}/cat/south-indian-hindi-dubbed-movies/',
    'bengali': f'{SKYMOVIESHD_BASE}/cat/bengali-movies/',
    'pakistani': f'{SKYMOVIESHD_BASE}/cat/pakistani-movies/',
    'hollywood_eng': f'{SKYMOVIESHD_BASE}/cat/hollywood-english-movies/',
    'hollywood_hindi': f'{SKYMOVIESHD_BASE}/cat/hollywood-hindi-dubbed-movies/',
    'tamil': f'{SKYMOVIESHD_BASE}/cat/tamil-movies/',
    'telugu': f'{SKYMOVIESHD_BASE}/cat/telugu-movies/',
    'punjabi': f'{SKYMOVIESHD_BASE}/cat/punjabi-movies/',
    'bhojpuri': f'{SKYMOVIESHD_BASE}/cat/bhojpuri-movies/',
    'bangladeshi': f'{SKYMOVIESHD_BASE}/cat/bangladeshi-movies/',
    'marathi': f'{SKYMOVIESHD_BASE}/cat/marathi-movies/',
    'kannada': f'{SKYMOVIESHD_BASE}/cat/kannada-movies/',
}

class SkyMoviesHDScraperV2:
    
    async def search(self, query: str, year: str = None):
        """
        Main search function - tries multiple methods
        """
        print(f"[SkyMoviesHD] Searching: {query} {year or ''}")
        
        # Method 1: Try direct search URL
        results = await self._search_by_url(query, year)
        
        if results:
            print(f"[SkyMoviesHD] ✅ URL search: {len(results)} found")
            return results
        
        # Method 2: Try category browsing
        results = await self._search_by_category(query, year)
        
        if results:
            print(f"[SkyMoviesHD] ✅ Category search: {len(results)} found")
            return results
        
        print(f"[SkyMoviesHD] ❌ No results for: {query}")
        return []
    
    async def _search_by_url(self, query: str, year: str = None):
        """Try search URL directly"""
        async with async_playwright() as p:
            browser = await p.chromium.launch(
                headless=True,
                args=['--no-sandbox', '--disable-setuid-sandbox']
            )
            
            try:
                context = await browser.new_context(
                    user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
                )
                page = await context.new_page()
                
                # Try different search queries
                queries_to_try = []
                if year:
                    queries_to_try.append(f"{query} {year}")
                queries_to_try.append(query)
                
                for search_query in queries_to_try:
                    encoded = search_query.replace(' ', '+')
                    search_url = f"{SKYMOVIESHD_BASE}/?s={encoded}"
                    
                    print(f"[SkyMoviesHD] Trying URL: {search_url}")
                    
                    try:
                        await page.goto(
                            search_url,
                            wait_until='networkidle',
                            timeout=15000
                        )
                        
                        # Wait for content
                        await page.wait_for_timeout(2000)
                        
                        # Debug: save screenshot
                        await page.screenshot(
                            path=f"/tmp/sky_{query.replace(' ','_')}.png"
                        )
                        
                        # Try to find movie links
                        movie_links = await self._extract_movie_links(page, query)
                        
                        if movie_links:
                            return movie_links
                            
                    except Exception as e:
                        print(f"[SkyMoviesHD] URL error: {e}")
                        continue
                
                return []
                
            finally:
                await browser.close()
    
    async def _search_by_category(self, query: str, year: str = None):
        """Search by browsing all category pages"""
        async with async_playwright() as p:
            browser = await p.chromium.launch(headless=True)
            
            try:
                context = await browser.new_context(
                    user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
                )
                page = await context.new_page()
                
                # Search ALL categories
                for cat_name, cat_url in CATEGORIES.items():
                    print(f"[SkyMoviesHD] Searching category: {cat_name}")
                    
                    results = await self._search_in_category(
                        page, cat_url, query, year
                    )
                    
                    if results:
                        print(f"[SkyMoviesHD] ✅ Found in {cat_name}: {len(results)}")
                        return results
                
                return []
                
            finally:
                await browser.close()
    
    async def _search_in_category(self, page, cat_url, query, year=None):
        """Search within a specific category page"""
        try:
            await page.goto(cat_url, wait_until='networkidle', timeout=15000)
            await page.wait_for_timeout(2000)
            
            # Get all movie links on this category page
            all_links = await self._extract_movie_links(page, query, year)
            
            return all_links
            
        except Exception as e:
            print(f"[SkyMoviesHD] Category error: {e}")
            return []
    
    async def _extract_movie_links(self, page, query, year=None):
        """Extract matching movie links from current page"""
        found_links = []
        
        # Try multiple CSS selectors
        selectors = [
            'article h2 a',
            '.post-title a',
            'h2.entry-title a',
            '.entry-title a',
            'h2 a',
            'div.post h2 a',
            'a[href*="skymovieshd"]',
        ]
        
        for selector in selectors:
            try:
                elements = await page.query_selector_all(selector)
                
                if not elements:
                    continue
                
                print(f"[SkyMoviesHD] Selector '{selector}': {len(elements)} elements")
                
                # Check each element for matching title
                for element in elements:
                    href = await element.get_attribute('href')
                    text = await element.inner_text()
                    
                    if not href or not text:
                        continue
                    
                    # Check if this matches our query
                    if self._is_match(text, query, year):
                        print(f"[SkyMoviesHD] ✅ Match: {text}")
                        found_links.append({
                            'url': href,
                            'title': text.strip(),
                        })
                
                if found_links:
                    return found_links
                    
            except Exception as e:
                continue
        
        return found_links
    
    def _is_match(self, title: str, query: str, year: str = None) -> bool:
        """Check if movie title matches search query"""
        title_lower = title.lower()
        query_lower = query.lower()
        
        # Query words must all be in title
        query_words = query_lower.split()
        
        if not all(word in title_lower for word in query_words):
            return False
        
        # Year check (optional)
        if year and year not in title:
            return False  # Strict year match
        
        return True
```

════════════════════════════════
TESTING:
════════════════════════════════

Test these movies after fix:

1. "Shikari 2016" 
   → Should find Bengali Shikari (2016)
   → skymovieshd.mba/cat/bengali-movies/

2. "Pathaan 2023"
   → Should find in Bollywood category

3. "KGF 2022"
   → Should find in South Hindi Dubbed

4. "Inception 2010"
   → Should find in Hollywood English

EXPECTED LOGS AFTER FIX:
[SkyMoviesHD] Searching: Shikari 2016
[SkyMoviesHD] Trying URL: skymovieshd.mba/?s=Shikari+2016
[SkyMoviesHD] Selector 'article h2 a': 12 elements
[SkyMoviesHD] ✅ Match: Shikari (2016) Bengali 720p
[SkyMoviesHD] ✅ Match: Shikari (2016) Bengali 1080p
[SkyMoviesHD] ✅ URL search: 4 found
[SkyMoviesHD] contributed 4 links ✅

PRIORITY: HIGH
This fix will significantly increase link availability for users.

Thank you!