import asyncio
import os
import re
import json
import aiosqlite
import httpx
from datetime import datetime, timedelta
from typing import List, Dict, Optional
from playwright.async_api import async_playwright, Browser
from playwright_stealth import stealth_async
from bs4 import BeautifulSoup
from urllib.parse import urljoin, quote
from thefuzz import fuzz
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# --- Configuration ---
TMDB_API_KEY = os.getenv("TMDB_API_KEY", "7efd8424c17ff5b3e8dc9cebf4a33f73")
TMDB_BASE_URL = "https://api.themoviedb.org/3"
TMDB_IMAGE_BASE = "https://image.tmdb.org/t/p/w500"
TMDB_BACKDROP_BASE = "https://image.tmdb.org/t/p/original"

# --- Scraping Domains ---
DOMAINS = {
    "HDHub4u": "https://new3.hdhub4u.fo",
    "KatmovieHD": "https://new.katmoviehd.cymru"
}

# Common user agent
USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"


# --- Cache Manager ---
class CacheManager:
    def __init__(self, db_path: str = "scraper_cache.db"):
        self.db_path = db_path
        self._lock = asyncio.Lock()

    async def init_db(self) -> None:
        """Initialize the SQLite database schema."""
        async with self._lock:
            try:
                async with aiosqlite.connect(self.db_path) as db:
                    await db.execute("""
                        CREATE TABLE IF NOT EXISTS links_cache (
                            movie_id TEXT PRIMARY KEY,
                            data TEXT NOT NULL,
                            timestamp DATETIME NOT NULL
                        )
                    """)
                    await db.commit()
                    logger.info("Database initialized successfully")
            except Exception as e:
                logger.error(f"Database initialization error: {e}")

    async def get_links(self, movie_id: str) -> Optional[List[Dict]]:
        """Retrieve cached download links if they exist and are fresh (< 7 days)."""
        try:
            async with self._lock:
                async with aiosqlite.connect(self.db_path) as db:
                    async with db.execute(
                        "SELECT data, timestamp FROM links_cache WHERE movie_id = ?",
                        (movie_id,)
                    ) as cursor:
                        row = await cursor.fetchone()
                        if row:
                            data, timestamp = row
                            ts = datetime.strptime(timestamp, "%Y-%m-%d %H:%M:%S")
                            if datetime.now() - ts < timedelta(days=7):
                                logger.info(f"Cache hit for: {movie_id}")
                                return json.loads(data)
                            logger.info(f"Cache expired for: {movie_id}")
        except Exception as e:
            logger.warning(f"Cache retrieval error: {e}")
        return None

    async def set_links(self, movie_id: str, data: List[Dict]) -> None:
        """Store download links in the cache."""
        try:
            async with self._lock:
                async with aiosqlite.connect(self.db_path) as db:
                    await db.execute(
                        "INSERT OR REPLACE INTO links_cache (movie_id, data, timestamp) VALUES (?, ?, ?)",
                        (movie_id, json.dumps(data), datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
                    )
                    await db.commit()
                    logger.info(f"Cache updated for: {movie_id}")
        except Exception as e:
            logger.error(f"Cache storage error: {e}")

    async def delete(self, movie_id: str) -> None:
        """Delete a specific movie's cached links."""
        try:
            async with self._lock:
                async with aiosqlite.connect(self.db_path) as db:
                    await db.execute("DELETE FROM links_cache WHERE movie_id = ?", (movie_id,))
                    await db.commit()
                    logger.info(f"Cache deleted for: {movie_id}")
        except Exception as e:
            logger.error(f"Cache deletion error: {e}")


# --- TMDB Helper ---
class TMDBHelper:
    """Async TMDB API client using httpx."""

    def __init__(self):
        self._client: Optional[httpx.AsyncClient] = None

    async def _get_client(self) -> httpx.AsyncClient:
        if self._client is None or self._client.is_closed:
            self._client = httpx.AsyncClient(timeout=10.0)
        return self._client

    async def close(self) -> None:
        if self._client and not self._client.is_closed:
            await self._client.aclose()

    @staticmethod
    def _format_movie(movie: Dict) -> Dict:
        """Shared formatter — single source of truth for movie dict shape."""
        return {
            "tmdb_id": movie.get('id'),
            "title": movie.get('title'),
            "original_title": movie.get('original_title'),
            "poster": f"{TMDB_IMAGE_BASE}{movie['poster_path']}" if movie.get('poster_path') else None,
            "backdrop": f"{TMDB_BACKDROP_BASE}{movie['backdrop_path']}" if movie.get('backdrop_path') else None,
            "rating": round(movie.get('vote_average', 0), 1),
            "release_date": movie.get('release_date'),
            "overview": movie.get('overview', 'No overview available'),
            "popularity": movie.get('popularity'),
        }

    async def get_trending_movies(self) -> List[Dict]:
        """Fetch trending movies from TMDB (non-blocking)."""
        try:
            client = await self._get_client()
            resp = await client.get(f"{TMDB_BASE_URL}/trending/movie/week?api_key={TMDB_API_KEY}")
            resp.raise_for_status()
            data = resp.json()
            return [self._format_movie(m) for m in data.get('results', [])[:20]]
        except Exception as e:
            logger.error(f"TMDB trending error: {e}")
            return []

    async def search_movie(self, query: str) -> List[Dict]:
        """Search movies on TMDB (non-blocking)."""
        try:
            client = await self._get_client()
            resp = await client.get(f"{TMDB_BASE_URL}/search/movie?api_key={TMDB_API_KEY}&query={quote(query)}")
            resp.raise_for_status()
            data = resp.json()
            return [self._format_movie(m) for m in data.get('results', [])[:15]]
        except Exception as e:
            logger.error(f"TMDB search error: {e}")
            return []

    async def get_movie_details(self, tmdb_id: int) -> Optional[Dict]:
        """Fetch detailed movie info from TMDB (non-blocking)."""
        try:
            client = await self._get_client()
            resp = await client.get(f"{TMDB_BASE_URL}/movie/{tmdb_id}?api_key={TMDB_API_KEY}")
            resp.raise_for_status()
            movie = resp.json()
            details = self._format_movie(movie)
            details.update({
                "runtime": movie.get('runtime'),
                "genres": [g['name'] for g in movie.get('genres', [])],
                "tagline": movie.get('tagline'),
                "imdb_id": movie.get('imdb_id'),
            })
            return details
        except Exception as e:
            logger.error(f"TMDB details error: {e}")
            return None


# --- Download link patterns ---
DOWNLOAD_PATTERNS = [
    'drive.google', 'pixeldrain', 'hubcloud', 'mediafire',
    'mega.nz', 'dropbox', 'wetransfer', 'terabox',
    'gdtot', 'filepress', 'streamtape', 'doodstream',
    'uptobox', 'gofile', 'gdrive', 'drivebot',
    'instantdownload', 'uploadrar', 'rapidgator',
    'katfile', 'nitroflare', 'turbobit', 'clicknupload',
    'send.cm', 'anonfiles', 'bayfiles', 'mixdrop',
    # Intermediary / shortener domains commonly used
    'howblogs', 'htpmovies', 'shrinkme', 'adrinolinks',
    'mdiskpro', 'kolop', 'gdflix', 'new1.gdflix',
    'filecrypt', 'ouo.io', 'ouo.press', 'shorte.st',
    'linkvertise', 'exe.io', '1fichier', 'krakenfiles',
    'uploadhaven', 'hexupload', 'fastclick',
]

SKIP_URL_PATTERNS = ['#', 'javascript:', 'mailto:', '/page/', '/category/']


# --- Movie Scraper ---
class MovieScraper:
    def __init__(self, max_concurrent: int = 2):
        self.cache = CacheManager()
        self.browser: Optional[Browser] = None
        self.playwright = None
        self.semaphore = asyncio.Semaphore(max_concurrent)
        self._initialized = False

    async def startup(self) -> None:
        """Initialize the Playwright browser and cache DB."""
        if self._initialized:
            return
        try:
            logger.info("Starting MovieScraper...")
            await self.cache.init_db()
            self.playwright = await async_playwright().start()
            self.browser = await self.playwright.chromium.launch(
                headless=True,
                args=['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage', '--disable-gpu']
            )
            self._initialized = True
            logger.info("MovieScraper ready")
        except Exception as e:
            logger.error(f"Startup error: {e}")
            raise

    async def shutdown(self) -> None:
        """Release all browser resources."""
        try:
            if self.browser:
                await self.browser.close()
            if self.playwright:
                await self.playwright.stop()
            self._initialized = False
            logger.info("MovieScraper shutdown complete")
        except Exception as e:
            logger.error(f"Shutdown error: {e}")

    async def _new_stealth_page(self):
        """Create a new browser context + page with stealth applied."""
        context = await self.browser.new_context(user_agent=USER_AGENT)
        page = await context.new_page()
        await stealth_async(page)
        return context, page

    async def search_site_for_movie(self, site_name: str, title: str, year: str = None) -> List[str]:
        """Search a single site for movie page URLs using fuzzy title matching."""
        async with self.semaphore:
            base_url = DOMAINS.get(site_name)
            if not base_url:
                return []

            search_query = f"{title} {year}" if year else title
            search_url = f"{base_url}/?s={quote(search_query)}"

            context, page = await self._new_stealth_page()
            urls = []

            try:
                logger.info(f"Searching {site_name} for: {search_query}")
                await page.goto(search_url, wait_until="domcontentloaded", timeout=20000)
                await asyncio.sleep(2)

                content = await page.content()
                soup = BeautifulSoup(content, 'html.parser')

                # Method 1: Find structured article/post links
                for article in soup.find_all(['article', 'div'], class_=re.compile(r'post|item|movie')):
                    a = article.find('a', href=True)
                    if a:
                        text = a.get_text(strip=True)
                        href = a['href']
                        if len(text) > 3 and fuzz.partial_ratio(title.lower(), text.lower()) > 65:
                            full_url = urljoin(base_url, href)
                            if base_url in full_url and full_url not in urls:
                                urls.append(full_url)

                # Method 2: Fallback to all <a> links with stricter matching
                if not urls:
                    for a in soup.find_all('a', href=True):
                        text = a.get_text(strip=True)
                        href = a['href']
                        if len(text) > 5 and fuzz.partial_ratio(title.lower(), text.lower()) > 70:
                            full_url = urljoin(base_url, href)
                            if base_url in full_url and full_url not in urls:
                                urls.append(full_url)

                logger.info(f"Found {len(urls)} URLs from {site_name}")
            except Exception as e:
                logger.error(f"Error searching {site_name}: {e}")
            finally:
                await page.close()
                await context.close()

            return urls[:5]

    @staticmethod
    def _extract_quality(text: str) -> str:
        """Extract video quality from surrounding text."""
        match = re.search(r'(480p|720p|1080p|2160p|4K|2K|HDRip|BluRay|WEB-DL)', text, re.IGNORECASE)
        return match.group(1).upper() if match else "HD"

    @staticmethod
    def _extract_language(text: str) -> str:
        """Extract language/type from surrounding text."""
        patterns = [
            (r'hindi|dubbed', "Hindi Dubbed"),
            (r'english|eng', "English"),
            (r'dual\s*audio', "Dual Audio"),
            (r'multi\s*audio', "Multi Audio"),
        ]
        for pattern, label in patterns:
            if re.search(pattern, text, re.IGNORECASE):
                return label
        return "Download"

    async def extract_links_from_url(self, url: str) -> List[Dict]:
        """Extract download links from a movie page using multiple strategies."""
        links = []
        context, page = await self._new_stealth_page()

        try:
            logger.info(f"Extracting links from: {url}")
            await page.goto(url, wait_until="domcontentloaded", timeout=25000)
            await asyncio.sleep(2)

            # Scroll to trigger lazy-loaded content
            for _ in range(2):
                await page.evaluate("window.scrollBy(0, window.innerHeight)")
                await asyncio.sleep(0.5)

            content = await page.content()
            soup = BeautifulSoup(content, 'html.parser')

            # Strategy 1: Extract from all <a> tags matching download patterns
            for a in soup.find_all('a', href=True):
                href = a['href']
                text = a.get_text(strip=True)

                if any(skip in href.lower() for skip in SKIP_URL_PATTERNS):
                    continue

                if any(p in href.lower() for p in DOWNLOAD_PATTERNS):
                    parent_text = a.parent.get_text(strip=True) if a.parent else ""
                    combined = f"{text} {parent_text}"

                    links.append({
                        "quality": self._extract_quality(combined),
                        "url": href,
                        "name": text[:80] if text else f"{self._extract_language(combined)} - {self._extract_quality(combined)}",
                        "type": self._extract_language(combined),
                        "source": url,
                    })

            # Strategy 2: Check data-link attributes on interactive elements
            for elem in soup.find_all(['button', 'div', 'span', 'p'], attrs={'data-link': True}):
                data_link = elem.get('data-link')
                if data_link and any(p in data_link.lower() for p in DOWNLOAD_PATTERNS):
                    links.append({
                        "quality": "HD",
                        "url": data_link,
                        "name": elem.get_text(strip=True)[:80] or "Download Link",
                        "type": "Download",
                        "source": url,
                    })

            # Strategy 3: Scan download sections/containers
            for section in soup.find_all(['div', 'section'], class_=re.compile(r'download|links|content', re.IGNORECASE)):
                for a in section.find_all('a', href=True):
                    href = a['href']
                    if any(p in href.lower() for p in DOWNLOAD_PATTERNS):
                        text = a.get_text(strip=True)
                        links.append({
                            "quality": "HD",
                            "url": href,
                            "name": text[:80] if text else "Download",
                            "type": "Download",
                            "source": url,
                        })

            # Strategy 4: Find embedded links in JavaScript source
            js_links = re.findall(
                r'https?://[^\s"\'<>]+(?:drive\.google|pixeldrain|gdtot|filepress|terabox|gofile\.io|hubcloud)[^\s"\'<>]*',
                content, re.IGNORECASE
            )
            existing_urls = {l['url'] for l in links}
            for js_link in js_links:
                if js_link not in existing_urls:
                    links.append({
                        "quality": "HD",
                        "url": js_link,
                        "name": "Download Link (JS)",
                        "type": "Download",
                        "source": url,
                    })

            # Strategy 5: Extract links from header tags (h1-h6)
            # Sites like KatmovieHD wrap download links inside header elements
            for header in soup.find_all(['h1', 'h2', 'h3', 'h4', 'h5', 'h6']):
                for a in header.find_all('a', href=True):
                    href = a['href']
                    text = a.get_text(strip=True)
                    if any(p in href.lower() for p in DOWNLOAD_PATTERNS):
                        header_text = header.get_text(strip=True)
                        links.append({
                            "quality": self._extract_quality(header_text),
                            "url": href,
                            "name": text[:80] if text else f"Download - {self._extract_quality(header_text)}",
                            "type": self._extract_language(header_text),
                            "source": url,
                        })

            # Deduplicate by cleaned URL
            seen = set()
            unique_links = []
            for link in links:
                clean_url = link['url'].split('?')[0]
                if clean_url not in seen:
                    seen.add(clean_url)
                    unique_links.append(link)

            logger.info(f"Extracted {len(unique_links)} unique links from {url}")

            if not unique_links:
                logger.warning(f"No download links found on {url}")

        except Exception as e:
            logger.error(f"Error extracting from {url}: {e}")
            unique_links = []
        finally:
            await page.close()
            await context.close()

        return unique_links

    async def generate_download_links(self, tmdb_id: int, title: str, year: str = None) -> List[Dict]:
        """
        Main entry point: search all sites, extract links, and cache results.
        Handles its own caching — callers should NOT pre-check the cache.
        """
        await self.startup()

        cache_key = f"tmdb_{tmdb_id}"
        cached = await self.cache.get_links(cache_key)
        if cached:
            logger.info(f"Returning {len(cached)} cached links for '{title}'")
            return cached

        # Search all sites in parallel
        tasks = [self.search_site_for_movie(site, title, year) for site in DOMAINS]
        results = await asyncio.gather(*tasks, return_exceptions=True)

        all_urls = []
        for site_urls in results:
            if isinstance(site_urls, list):
                all_urls.extend(site_urls)

        all_urls = list(set(all_urls))[:4]  # Limit to 4 to stay within Render's resource budget
        logger.info(f"Found {len(all_urls)} URLs to scrape for '{title}'")

        # Extract links from all URLs in parallel (bounded by semaphore)
        extract_tasks = [self.extract_links_from_url(url) for url in all_urls]
        extract_results = await asyncio.gather(*extract_tasks, return_exceptions=True)

        all_links = []
        for result in extract_results:
            if isinstance(result, list):
                all_links.extend(result)

        if all_links:
            await self.cache.set_links(cache_key, all_links)

        logger.info(f"Total {len(all_links)} download links found for '{title}'")
        return all_links


# --- Global Instances ---
scraper_instance = MovieScraper()
tmdb_helper = TMDBHelper()
