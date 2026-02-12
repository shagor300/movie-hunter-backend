"""
Multi-Source Manager — orchestrates parallel search across HDHub4u + SkyMoviesHD.
Deduplicates by TMDB ID (keeps highest-priority source).
"""

import asyncio
import logging
from typing import List, Dict, Optional

from config.sources import MovieSources
from scrapers.skymovieshd_scraper import SkyMoviesHDScraper

logger = logging.getLogger(__name__)


class MultiSourceManager:
    """Manages search and link extraction across multiple movie sources."""

    def __init__(self):
        self.sky_scraper: Optional[SkyMoviesHDScraper] = None
        self._initialized = False

    def init_scrapers(self, browser):
        """Initialize all source scrapers with a shared browser."""
        if MovieSources.SKYMOVIESHD_ENABLED:
            self.sky_scraper = SkyMoviesHDScraper(MovieSources.SKYMOVIESHD_BASE_URL)
            self.sky_scraper.set_browser(browser)
            logger.info("SkyMoviesHD scraper initialized (shared browser)")

        self._initialized = True
        MovieSources.print_config()

    async def search_all_sources(self, query: str,
                                  max_per_source: int = 20) -> List[Dict]:
        """
        Search all enabled sources in parallel and combine results.
        Deduplicates by TMDB ID, keeping the higher-priority source.
        """
        if not self._initialized:
            logger.warning("MultiSourceManager not initialized")
            return []

        tasks = []

        # SkyMoviesHD search
        if self.sky_scraper:
            tasks.append(self._search_source(
                self.sky_scraper, query, max_per_source
            ))

        if not tasks:
            return []

        # Run all searches in parallel
        results = await asyncio.gather(*tasks, return_exceptions=True)

        # Flatten and deduplicate
        all_movies = []
        for result in results:
            if isinstance(result, list):
                all_movies.extend(result)
            elif isinstance(result, Exception):
                logger.error(f"Source search failed: {result}")

        # Deduplicate by TMDB ID (keep first occurrence = higher priority)
        seen_ids = set()
        unique_movies = []
        for movie in all_movies:
            tmdb_id = movie.get('tmdb_id')
            if tmdb_id and tmdb_id in seen_ids:
                continue
            if tmdb_id:
                seen_ids.add(tmdb_id)
            unique_movies.append(movie)

        logger.info(
            f"Multi-source search: {len(all_movies)} total → "
            f"{len(unique_movies)} unique results"
        )
        return unique_movies

    async def _search_source(self, scraper, query: str,
                              max_results: int) -> List[Dict]:
        """Search a single source with a timeout."""
        try:
            return await asyncio.wait_for(
                scraper.search_movies(query, max_results),
                timeout=MovieSources.SEARCH_TIMEOUT
            )
        except asyncio.TimeoutError:
            logger.error(
                f"[{scraper.source_name}] Search timed out after "
                f"{MovieSources.SEARCH_TIMEOUT}s"
            )
            return []
        except Exception as e:
            logger.error(f"[{scraper.source_name}] Search error: {e}")
            return []

    async def extract_links_from_source(self, source_type: str,
                                         movie_url: str) -> Dict:
        """Route link extraction to the correct scraper based on source type."""
        if source_type == 'skymovieshd' and self.sky_scraper:
            return await self.sky_scraper.extract_links(movie_url)
        else:
            logger.warning(f"Unknown source type: {source_type}")
            return {'links': [], 'embed_links': []}
