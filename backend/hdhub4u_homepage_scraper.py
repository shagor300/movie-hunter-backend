import asyncio
import re
from bs4 import BeautifulSoup
from typing import List, Dict, Optional
import logging

logger = logging.getLogger(__name__)

# TMDB Configuration
TMDB_API_KEY = "7efd8424c17ff5b3e8dc9cebf4a33f73"
TMDB_BASE_URL = "https://api.themoviedb.org/3"
TMDB_IMAGE_BASE = "https://image.tmdb.org/t/p/w500"


class HDHub4uScraper:
    """Scrape latest movies from HDHub4u homepage and enrich with TMDB data.

    Reuses the shared Playwright browser from scraper_instance to avoid
    spawning a second Chromium process (critical for Render free-tier memory).
    """

    def __init__(self, scraper_instance):
        self.homepage_url = "https://new3.hdhub4u.fo"
        self._scraper = scraper_instance  # shared MovieScraper

    async def scrape_homepage(self, max_movies: int = 50) -> List[Dict]:
        """Scrape latest movies from HDHub4u homepage."""
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
            logger.info(f"Scraping HDHub4u homepage: {self.homepage_url}")

            await page.goto(self.homepage_url, wait_until="domcontentloaded", timeout=30000)
            await asyncio.sleep(3)

            # Scroll to load more content
            for _ in range(3):
                await page.evaluate("window.scrollBy(0, window.innerHeight)")
                await asyncio.sleep(1)

            content = await page.content()
            soup = BeautifulSoup(content, 'html.parser')

            # Find movie posts
            articles = soup.find_all(
                ['article', 'div'],
                class_=re.compile(r'post|item|movie|entry', re.I),
            )

            for article in articles[:max_movies]:
                try:
                    title_elem = article.find(
                        ['h2', 'h3', 'a'],
                        class_=re.compile(r'title|entry-title', re.I),
                    )
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

                    clean_title, year = self._clean_title(raw_title)

                    logger.info(f"Found: {clean_title} ({year}) - {movie_url}")

                    tmdb_data = await self._get_tmdb_data(clean_title, year)

                    if tmdb_data:
                        movies.append({
                            'hdhub4u_url': movie_url,
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

                        logger.info(f"Matched: {tmdb_data['title']} (TMDB ID: {tmdb_data['id']})")

                except Exception as e:
                    logger.error(f"Error parsing article: {e}")
                    continue

        except Exception as e:
            logger.error(f"Scraping error: {e}")
        finally:
            await page.close()
            await context.close()

        logger.info(f"Total movies with TMDB data: {len(movies)}")
        return movies

    # ------------------------------------------------------------------ #
    # Helpers
    # ------------------------------------------------------------------ #

    @staticmethod
    def _clean_title(raw_title: str) -> tuple:
        """Clean movie title and extract year."""
        title = re.sub(
            r'\b(480p|720p|1080p|2160p|4K|HDRip|BluRay|WEB-DL|HEVC|x264|x265)\b',
            '', raw_title, flags=re.I,
        )
        title = re.sub(
            r'\b(Hindi|English|Tamil|Telugu|Dual\s*Audio|Multi\s*Audio|Dubbed)\b',
            '', title, flags=re.I,
        )
        title = re.sub(r'\b\d+(\.\d+)?\s*(GB|MB)\b', '', title, flags=re.I)

        year_match = re.search(r'\b(19\d{2}|20\d{2})\b', title)
        year = year_match.group(1) if year_match else None

        if year:
            title = title.replace(year, '')

        title = re.sub(r'[:\-\|]+', ' ', title)
        title = re.sub(r'\s+', ' ', title)
        title = title.strip()

        return title, year

    async def _get_tmdb_data(self, title: str, year: Optional[str] = None) -> Optional[Dict]:
        """Get TMDB data for a movie using the shared httpx client."""
        import httpx

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
