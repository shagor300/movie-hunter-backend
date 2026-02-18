"""
Multi-Source Manager — orchestrates parallel search across HDHub4u + SkyMoviesHD.
Deduplicates by TMDB ID (keeps highest-priority source).
"""

import asyncio
import logging
from typing import List, Dict, Optional
from urllib.parse import quote

from config.sources import MovieSources
from scrapers.skymovieshd_scraper import SkyMoviesHDScraper
from scrapers.cinefreak_scraper import CinefreakScraper

logger = logging.getLogger(__name__)


class MultiSourceManager:
    """Manages search and link extraction across multiple movie sources."""

    def __init__(self):
        self.sky_scraper: Optional[SkyMoviesHDScraper] = None
        self.cinefreak_scraper: Optional[CinefreakScraper] = None
        self._initialized = False
        # Will be set by init_scrapers via main.py lifespan
        self._hdhub4u_scraper = None  # Reference to the MovieScraper instance

    def init_scrapers(self, browser, hdhub4u_scraper=None, download_resolver=None):
        """Initialize all source scrapers with a shared browser."""
        # Store reference to HDHub4u scraper for combined operations
        self._hdhub4u_scraper = hdhub4u_scraper

        if MovieSources.SKYMOVIESHD_ENABLED:
            self.sky_scraper = SkyMoviesHDScraper(MovieSources.SKYMOVIESHD_BASE_URL)
            self.sky_scraper.set_browser(browser)
            # Attach download resolver for intermediate host click-through
            if download_resolver:
                self.sky_scraper.set_download_resolver(download_resolver)
            logger.info("SkyMoviesHD scraper initialized (shared browser + resolver)")

        if MovieSources.CINEFREAK_ENABLED:
            self.cinefreak_scraper = CinefreakScraper(MovieSources.CINEFREAK_BASE_URL)
            self.cinefreak_scraper.set_browser(browser)
            logger.info("Cinefreak scraper initialized (shared browser)")

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

        # Cinefreak search
        if self.cinefreak_scraper:
            tasks.append(self._search_source(
                self.cinefreak_scraper, query, max_per_source
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
        elif source_type == 'cinefreak' and self.cinefreak_scraper:
            return await self.cinefreak_scraper.extract_links(movie_url)
        else:
            logger.warning(f"Unknown source type: {source_type}")
            return {'links': [], 'embed_links': []}

    async def extract_links_all_sources(self, title: str, year: str = None,
                                         tmdb_id: int = 0) -> Dict:
        """
        Try to extract links from ALL enabled sources for a given title.
        Searches SkyMoviesHD + HDHub4u in parallel and combines results.
        Returns combined { 'links': [...], 'embed_links': [...] }
        """
        if not self._initialized:
            return {'links': [], 'embed_links': []}

        all_links = []
        all_embeds = []
        tasks = []

        # --- SkyMoviesHD: search → pick first result → extract links ---
        if self.sky_scraper:
            tasks.append(('skymovieshd', self._sky_search_and_extract(title, year)))

        # --- Cinefreak: search → pick first result → extract links ---
        if self.cinefreak_scraper:
            tasks.append(('cinefreak', self._cinefreak_search_and_extract(title, year)))

        # --- HDHub4u: use the existing MovieScraper ---
        if self._hdhub4u_scraper and MovieSources.HDHUB4U_ENABLED:
            tasks.append(('hdhub4u', self._hdhub4u_search_and_extract(title, year, tmdb_id)))

        if not tasks:
            return {'links': [], 'embed_links': []}

        # Run all extractions in parallel with timeout
        coroutines = [t[1] for t in tasks]
        source_names = [t[0] for t in tasks]

        results = await asyncio.gather(*coroutines, return_exceptions=True)

        for source_name, result in zip(source_names, results):
            if isinstance(result, Exception):
                logger.error(f"[{source_name}] extraction failed: {result}")
                continue
            if isinstance(result, dict):
                source_links = result.get('links', [])
                source_embeds = result.get('embed_links', [])
                # Tag each link with its source
                for link in source_links:
                    if 'source_site' not in link:
                        link['source_site'] = source_name
                all_links.extend(source_links)
                all_embeds.extend(source_embeds)
                logger.info(
                    f"[{source_name}] contributed {len(source_links)} links, "
                    f"{len(source_embeds)} embeds"
                )

        # Deduplicate links by URL
        seen_urls = set()
        unique_links = []
        for link in all_links:
            url = link.get('url', '').split('?')[0]
            if url and url not in seen_urls:
                seen_urls.add(url)
                unique_links.append(link)

        logger.info(
            f"Multi-source extraction: {len(all_links)} total → "
            f"{len(unique_links)} unique links + {len(all_embeds)} embeds"
        )

        return {'links': unique_links, 'embed_links': all_embeds}

    async def _sky_search_and_extract(self, title: str, year: str = None) -> Dict:
        """Search SkyMoviesHD for a title, then extract links from first result."""
        try:
            query = f"{title} {year}" if year else title
            results = await asyncio.wait_for(
                self.sky_scraper.search_movies(query, max_results=3),
                timeout=MovieSources.SEARCH_TIMEOUT
            )

            # Retry without year if no results (site may not index year)
            if not results and year:
                logger.info(f"[SkyMoviesHD] Retrying search without year: {title}")
                results = await asyncio.wait_for(
                    self.sky_scraper.search_movies(title, max_results=3),
                    timeout=MovieSources.SEARCH_TIMEOUT
                )

            if not results:
                logger.info(f"[SkyMoviesHD] No results for: {query}")
                return {'links': [], 'embed_links': []}

            # Use the first (best) match
            movie_url = results[0].get('url')
            if not movie_url:
                return {'links': [], 'embed_links': []}

            logger.info(f"[SkyMoviesHD] Extracting links from: {movie_url}")
            return await asyncio.wait_for(
                self.sky_scraper.extract_links(movie_url),
                timeout=120  # HubDrive countdowns can take 30s+ each
            )

        except asyncio.TimeoutError:
            logger.error("[SkyMoviesHD] Search+extract timed out")
            return {'links': [], 'embed_links': []}
        except Exception as e:
            logger.error(f"[SkyMoviesHD] Search+extract error: {e}")
            return {'links': [], 'embed_links': []}

    async def _hdhub4u_search_and_extract(self, title: str, year: str = None,
                                            tmdb_id: int = 0) -> Dict:
        """Use the HDHub4u MovieScraper to search and extract links."""
        try:
            links = await asyncio.wait_for(
                self._hdhub4u_scraper.generate_download_links(tmdb_id, title, year),
                timeout=60
            )
            return {'links': links, 'embed_links': []}
        except asyncio.TimeoutError:
            logger.error("[HDHub4u] Search+extract timed out")
            return {'links': [], 'embed_links': []}
        except Exception as e:
            logger.error(f"[HDHub4u] Search+extract error: {e}")
            return {'links': [], 'embed_links': []}

    async def _cinefreak_search_and_extract(self, title: str, year: str = None) -> Dict:
        """Search Cinefreak for a title, then extract links from first result."""
        try:
            query = f"{title} {year}" if year else title
            results = await asyncio.wait_for(
                self.cinefreak_scraper.search_movies(query, max_results=3),
                timeout=MovieSources.SEARCH_TIMEOUT
            )

            # Retry without year if no results
            if not results and year:
                logger.info(f"[Cinefreak] Retrying search without year: {title}")
                results = await asyncio.wait_for(
                    self.cinefreak_scraper.search_movies(title, max_results=3),
                    timeout=MovieSources.SEARCH_TIMEOUT
                )

            if not results:
                logger.info(f"[Cinefreak] No results for: {query}")
                return {'links': [], 'embed_links': []}

            # Use the first (best) match
            movie_url = results[0].get('url')
            if not movie_url:
                return {'links': [], 'embed_links': []}

            logger.info(f"[Cinefreak] Extracting links from: {movie_url}")
            return await asyncio.wait_for(
                self.cinefreak_scraper.extract_links(movie_url),
                timeout=60
            )

        except asyncio.TimeoutError:
            logger.error("[Cinefreak] Search+extract timed out")
            return {'links': [], 'embed_links': []}
        except Exception as e:
            logger.error(f"[Cinefreak] Search+extract error: {e}")
            return {'links': [], 'embed_links': []}
