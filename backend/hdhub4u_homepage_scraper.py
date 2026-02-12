import asyncio
import re
from bs4 import BeautifulSoup
from typing import List, Dict, Optional
import logging
import httpx

logger = logging.getLogger(__name__)

# TMDB Configuration
TMDB_API_KEY = "7efd8424c17ff5b3e8dc9cebf4a33f73"
TMDB_BASE_URL = "https://api.themoviedb.org/3"
TMDB_IMAGE_BASE = "https://image.tmdb.org/t/p/w500"

# Patterns to filter out non-movie items (e.g. pages, categories)
SKIP_PATTERNS = re.compile(
    r'(genre|category|contact|about|dmca|disclaimer|privacy|terms|faq|page/\d)',
    re.I,
)

# Movie title in link text like: "MovieName (2025) ... Full Movie"
MOVIE_LINK_PATTERN = re.compile(
    r'^(.+?\(\d{4}\))',
    re.I,
)


class HDHub4uScraper:
    """Scrape latest movies from HDHub4u homepage and enrich with TMDB data.

    Primary strategy: lightweight httpx fetch (no browser needed).
    Fallback: Playwright via shared browser instance (if httpx fails).
    """

    def __init__(self, scraper_instance):
        self.homepage_url = "https://new3.hdhub4u.fo"
        self._scraper = scraper_instance  # shared MovieScraper (for fallback)

    async def scrape_homepage(self, max_movies: int = 50) -> List[Dict]:
        """Scrape latest movies from HDHub4u homepage."""

        # --- Strategy 1: Lightweight httpx (no browser) ---
        movies = await self._scrape_with_httpx(max_movies)

        # --- Strategy 2: Playwright fallback ---
        if not movies:
            logger.info("httpx approach returned 0 movies, trying Playwright fallback")
            movies = await self._scrape_with_playwright(max_movies)

        logger.info(f"Total movies with TMDB data: {len(movies)}")
        return movies

    async def _scrape_with_httpx(self, max_movies: int) -> List[Dict]:
        """Fetch page with httpx and parse — no Playwright needed."""
        movies = []
        try:
            headers = {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
                              'AppleWebKit/537.36 (KHTML, like Gecko) '
                              'Chrome/120.0.0.0 Safari/537.36',
                'Accept': 'text/html,application/xhtml+xml',
                'Accept-Language': 'en-US,en;q=0.9',
            }

            async with httpx.AsyncClient(
                timeout=20.0,
                follow_redirects=True,
                headers=headers,
            ) as client:
                response = await client.get(self.homepage_url)

                if response.status_code != 200:
                    logger.error(f"Homepage returned {response.status_code}")
                    return []

                html = response.text

            movies = await self._parse_html(html, max_movies)
            logger.info(f"httpx strategy found {len(movies)} movies")

        except Exception as e:
            logger.error(f"httpx scrape error: {e}")

        return movies

    async def _scrape_with_playwright(self, max_movies: int) -> List[Dict]:
        """Fallback: use Playwright browser."""
        browser = self._scraper.browser
        if not browser:
            logger.error("Shared browser not initialised yet")
            return []

        context = await browser.new_context(
            user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        )
        page = await context.new_page()

        movies = []
        try:
            logger.info(f"Playwright fallback: {self.homepage_url}")
            await page.goto(
                self.homepage_url,
                wait_until="domcontentloaded",
                timeout=30000,
            )
            await asyncio.sleep(3)

            # Scroll to load content
            for _ in range(3):
                await page.evaluate("window.scrollBy(0, window.innerHeight)")
                await asyncio.sleep(1)

            content = await page.content()
            movies = await self._parse_html(content, max_movies)
            logger.info(f"Playwright strategy found {len(movies)} movies")

        except Exception as e:
            logger.error(f"Playwright scrape error: {e}")
        finally:
            await page.close()
            await context.close()

        return movies

    async def _parse_html(self, html: str, max_movies: int) -> List[Dict]:
        """Parse HTML and extract movie entries with TMDB enrichment."""
        soup = BeautifulSoup(html, 'html.parser')
        movies = []
        seen_urls = set()

        # --- Strategy A: Find article/div posts ---
        articles = soup.find_all(
            ['article', 'div'],
            class_=re.compile(r'post|item|movie|entry|blog-item', re.I),
        )

        if articles:
            for article in articles[:max_movies * 2]:
                movie = self._extract_from_element(article)
                if movie and movie['url'] not in seen_urls:
                    seen_urls.add(movie['url'])
                    movies.append(movie)
                if len(movies) >= max_movies:
                    break

        # --- Strategy B: Find all links matching movie pattern ---
        if not movies:
            logger.info("No article elements found, trying link-based extraction")
            all_links = soup.find_all('a', href=True)

            for link in all_links:
                href = link.get('href', '')
                text = link.get_text(strip=True)

                if not text or len(text) < 10:
                    continue
                if SKIP_PATTERNS.search(href):
                    continue
                if href in seen_urls:
                    continue

                # Look for links with year in title text
                year_match = re.search(r'\((\d{4})\)', text)
                if not year_match:
                    continue

                if 'Full Movie' in text or 'Full Series' in text or 'Season' in text:
                    seen_urls.add(href)
                    clean_title, year = self._clean_title(text)
                    if clean_title:
                        movies.append({
                            'raw_title': text,
                            'clean_title': clean_title,
                            'year': year,
                            'url': href,
                        })

                if len(movies) >= max_movies:
                    break

        # --- Enrich with TMDB data ---
        enriched = []
        for entry in movies:
            clean_title = entry.get('clean_title')
            year = entry.get('year')
            url = entry.get('url')
            raw_title = entry.get('raw_title', clean_title)

            if not clean_title:
                continue

            tmdb_data = await self._get_tmdb_data(clean_title, year)

            if tmdb_data:
                enriched.append({
                    'hdhub4u_url': url,
                    'hdhub4u_title': raw_title,
                    'tmdb_id': tmdb_data['id'],
                    'title': tmdb_data['title'],
                    'poster_url': tmdb_data['poster_url'],
                    'backdrop_url': tmdb_data['backdrop_url'],
                    'rating': tmdb_data['rating'],
                    'overview': tmdb_data['overview'],
                    'release_date': tmdb_data['release_date'],
                    'year': year,
                })

                logger.info(
                    f"Matched: {tmdb_data['title']} "
                    f"(TMDB ID: {tmdb_data['id']})"
                )

        return enriched

    def _extract_from_element(self, element) -> Optional[Dict]:
        """Extract movie data from an article/div element."""
        try:
            title_elem = element.find(
                ['h2', 'h3', 'a'],
                class_=re.compile(r'title|entry-title', re.I),
            )
            if not title_elem:
                title_elem = element.find('a', href=True)

            if not title_elem:
                return None

            raw_title = title_elem.get_text(strip=True)
            movie_url = (
                title_elem.get('href')
                if title_elem.name == 'a'
                else None
            )

            if not movie_url:
                link = element.find('a', href=True)
                if link:
                    movie_url = link['href']

            if not movie_url or not raw_title:
                return None
            if SKIP_PATTERNS.search(movie_url):
                return None

            clean_title, year = self._clean_title(raw_title)
            return {
                'raw_title': raw_title,
                'clean_title': clean_title,
                'year': year,
                'url': movie_url,
            }
        except Exception as e:
            logger.error(f"Error parsing element: {e}")
            return None

    # ------------------------------------------------------------------ #
    # Helpers
    # ------------------------------------------------------------------ #

    @staticmethod
    def _clean_title(raw_title: str) -> tuple:
        """Clean movie title and extract year."""
        title = re.sub(
            r'\b(480p|720p|1080p|2160p|4K|DS4K|HDRip|BluRay|WEB-DL|WEBRip|'
            r'HEVC|x264|x265|10Bit|HQ|HDTC|UNCUT|ESub|ESubs)\b',
            '', raw_title, flags=re.I,
        )
        title = re.sub(
            r'\b(Hindi|English|Tamil|Telugu|Punjabi|Malayalam|Kannada|Bengali|'
            r'Dual\s*Audio|Multi\s*Audio|Dubbed|LiNE|DD\d[\.\d]*|Studio\s*Dub)\b',
            '', title, flags=re.I,
        )
        title = re.sub(r'\b\d+(\.\d+)?\s*(GB|MB)\b', '', title, flags=re.I)
        # Remove bracketed extras like [x264/HEVC], [ALL Episodes], [EP-xx Added]
        title = re.sub(r'\[.*?\]', '', title)
        # Remove "Full Movie", "Full Series", etc.
        title = re.sub(r'\b(Full\s*Movie|Full\s*Series|Without-ADs)\b', '', title, flags=re.I)
        # Remove "Season X" but keep the show name
        title = re.sub(r'\(Season\s*\d+\)', '', title, flags=re.I)

        year_match = re.search(r'\b(19\d{2}|20\d{2})\b', title)
        year = year_match.group(1) if year_match else None

        if year:
            title = title.replace(f'({year})', '').replace(year, '', 1)

        title = re.sub(r'[:\-\|&]+', ' ', title)
        title = re.sub(r'\s+', ' ', title)
        title = title.strip().strip('()')

        return title, year

    async def _get_tmdb_data(
        self, title: str, year: Optional[str] = None
    ) -> Optional[Dict]:
        """Get TMDB data for a movie using httpx."""
        try:
            search_url = f"{TMDB_BASE_URL}/search/movie"
            params = {
                'api_key': TMDB_API_KEY,
                'query': title,
                'include_adult': 'false',
            }

            if year:
                params['year'] = year

            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.get(search_url, params=params)

                if response.status_code == 200:
                    data = response.json()
                    results = data.get('results', [])

                    if not results and year:
                        params.pop('year')
                        response = await client.get(search_url, params=params)
                        data = response.json()
                        results = data.get('results', [])

                    if results:
                        movie = results[0]
                        return {
                            'id': movie['id'],
                            'title': movie['title'],
                            'poster_url': (
                                f"{TMDB_IMAGE_BASE}{movie['poster_path']}"
                                if movie.get('poster_path')
                                else None
                            ),
                            'backdrop_url': (
                                f"https://image.tmdb.org/t/p/original"
                                f"{movie['backdrop_path']}"
                                if movie.get('backdrop_path')
                                else None
                            ),
                            'rating': round(
                                movie.get('vote_average', 0), 1
                            ),
                            'overview': movie.get('overview', ''),
                            'release_date': movie.get('release_date', ''),
                        }

            return None

        except Exception as e:
            logger.error(f"TMDB search error for '{title}': {e}")
            return None
