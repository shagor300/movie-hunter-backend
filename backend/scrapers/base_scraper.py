"""
Base scraper class — all movie source scrapers inherit from this.
Provides common helpers: title cleaning, quality extraction, TMDB matching.
"""

from abc import ABC, abstractmethod
from typing import List, Dict, Optional
from playwright.async_api import Page, Browser
import httpx
import re
import logging

logger = logging.getLogger(__name__)

# TMDB config (shared across scrapers)
TMDB_API_KEY = "7efd8424c17ff5b3e8dc9cebf4a33f73"
TMDB_BASE_URL = "https://api.themoviedb.org/3"
TMDB_IMAGE_BASE = "https://image.tmdb.org/t/p/w500"


class BaseMovieScraper(ABC):
    """Abstract base class for all movie scrapers."""

    def __init__(self, base_url: str, source_name: str):
        self.base_url = base_url
        self.source_name = source_name
        self.browser: Optional[Browser] = None

    def set_browser(self, browser: Browser):
        """Share a browser instance from the main scraper."""
        self.browser = browser
        logger.info(f"[{self.source_name}] Browser shared successfully")

    @abstractmethod
    async def search_movies(self, query: str, max_results: int = 20) -> List[Dict]:
        """Search for movies on this source. Must be implemented."""
        pass

    @abstractmethod
    async def extract_links(self, movie_url: str) -> Dict:
        """Extract download/streaming links from a movie page. Must be implemented."""
        pass

    # ===== Common Helpers =====

    async def _navigate_safe(self, page: Page, url: str,
                              wait_for: str = 'domcontentloaded') -> bool:
        """Safely navigate to URL with error handling."""
        try:
            logger.info(f"[{self.source_name}] Navigating to: {url}")
            await page.goto(url, wait_until=wait_for, timeout=30000)
            return True
        except Exception as e:
            logger.error(f"[{self.source_name}] Navigation failed: {e}")
            return False

    def _clean_title(self, title: str) -> tuple:
        """
        Clean movie title and extract year.

        Input:  "Inception 2010 1080p BluRay Hindi Dubbed"
        Output: ("Inception", "2010")
        """
        # Remove quality markers
        title = re.sub(
            r'\b(480p|720p|1080p|2160p|4K|HDRip|BluRay|WEB-DL|WEBRip|HEVC|x264|x265|BRRip)\b',
            '', title, flags=re.I
        )
        # Remove language markers
        title = re.sub(
            r'\b(Hindi|English|Tamil|Telugu|Dual\s*Audio|Multi\s*Audio|Dubbed|ORG)\b',
            '', title, flags=re.I
        )
        # Remove size markers
        title = re.sub(r'\b\d+(\.\d+)?\s*(GB|MB)\b', '', title, flags=re.I)

        # Extract year
        year_match = re.search(r'\b(19\d{2}|20\d{2})\b', title)
        year = year_match.group(1) if year_match else None

        # Remove year from title
        if year:
            title = title.replace(year, '')

        # Clean up separators and whitespace
        title = re.sub(r'[:\-\|]+', ' ', title)
        title = re.sub(r'\s+', ' ', title).strip()

        return title, year

    def _extract_quality(self, text: str) -> str:
        """Extract quality tag from text."""
        match = re.search(r'(480p|720p|1080p|2160p|4K|HD|FHD|UHD)', text, re.I)
        return match.group(1).upper() if match else 'HD'

    async def _match_with_tmdb(self, title: str,
                                year: Optional[str] = None) -> Optional[Dict]:
        """Match a title against the TMDB database."""
        try:
            params = {
                'api_key': TMDB_API_KEY,
                'query': title,
                'include_adult': 'false',
            }
            if year:
                params['year'] = year

            async with httpx.AsyncClient(timeout=10) as client:
                resp = await client.get(
                    f"{TMDB_BASE_URL}/search/movie", params=params
                )

                if resp.status_code != 200:
                    return None

                data = resp.json()
                results = data.get('results', [])

                # Retry without year if no results
                if not results and year:
                    params.pop('year')
                    resp = await client.get(
                        f"{TMDB_BASE_URL}/search/movie", params=params
                    )
                    data = resp.json()
                    results = data.get('results', [])

                if results:
                    movie = results[0]
                    return {
                        'tmdb_id': movie['id'],
                        'title': movie['title'],
                        'poster_url': (
                            f"{TMDB_IMAGE_BASE}{movie['poster_path']}"
                            if movie.get('poster_path') else None
                        ),
                        'backdrop_url': (
                            f"https://image.tmdb.org/t/p/original{movie['backdrop_path']}"
                            if movie.get('backdrop_path') else None
                        ),
                        'rating': round(movie.get('vote_average', 0), 1),
                        'overview': movie.get('overview', ''),
                        'release_date': movie.get('release_date', ''),
                    }

            return None

        except Exception as e:
            logger.error(f"TMDB match error for '{title}': {e}")
            return None
