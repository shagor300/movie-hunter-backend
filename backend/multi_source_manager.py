"""
Multi-Source Manager — orchestrates parallel search across FTP + HDHub4u + SkyMoviesHD.
Deduplicates by TMDB ID (keeps highest-priority source).
"""

import asyncio
import logging
import re
from concurrent.futures import ThreadPoolExecutor
from typing import List, Dict, Optional
from urllib.parse import quote

from config.sources import MovieSources
from ftp_handler import FTPMovieHandler
from scrapers.skymovieshd_scraper import SkyMoviesHDScraper
from scrapers.cinefreak_scraper import CinefreakScraper

logger = logging.getLogger(__name__)

# Shared thread pool for blocking FTP calls
_ftp_executor = ThreadPoolExecutor(max_workers=2, thread_name_prefix="ftp")


class MultiSourceManager:
    """Manages search and link extraction across multiple movie sources."""

    def __init__(self):
        self.ftp_handler: Optional[FTPMovieHandler] = None
        self.sky_scraper: Optional[SkyMoviesHDScraper] = None
        self.cinefreak_scraper: Optional[CinefreakScraper] = None
        self._initialized = False
        # Will be set by init_scrapers via main.py lifespan
        self._hdhub4u_scraper = None  # Reference to the MovieScraper instance

    def init_scrapers(self, browser, hdhub4u_scraper=None, download_resolver=None):
        """Initialize all source scrapers with a shared browser."""
        # Store reference to HDHub4u scraper for combined operations
        self._hdhub4u_scraper = hdhub4u_scraper

        # FTP handler — no browser needed (uses Python's ftplib)
        if MovieSources.FTP_ENABLED:
            self.ftp_handler = FTPMovieHandler(
                host=MovieSources.FTP_HOST,
                timeout=MovieSources.FTP_TIMEOUT,
            )
            logger.info("FTP handler initialized (host=%s)", MovieSources.FTP_HOST)

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
        if source_type == 'ftp' and self.ftp_handler:
            # FTP uses folder path, not URL — handled separately
            logger.info("FTP extraction requires folder info, use extract_links_all_sources")
            return {'links': [], 'embed_links': []}
        elif source_type == 'skymovieshd' and self.sky_scraper:
            return await self.sky_scraper.extract_links(movie_url)
        elif source_type == 'cinefreak' and self.cinefreak_scraper:
            return await self.cinefreak_scraper.extract_links(movie_url)
        else:
            logger.warning(f"Unknown source type: {source_type}")
            return {'links': [], 'embed_links': []}

    async def extract_links_all_sources(self, title: str, year: str = None,
                                         tmdb_id: int = 0) -> Dict:
        """
        Priority-based link extraction with validation.
        Runs sources SEQUENTIALLY — stops at the first one that returns links.

        Priority order:
          P1: FTP  (fastest, ~1-2s)
          P2: HDHub4u
          P3: SkyMoviesHD
          P4: Cinefreak
        """
        if not self._initialized:
            return {'links': [], 'embed_links': []}

        # ── P1: FTP (highest priority, fastest) ──
        if self.ftp_handler:
            logger.info("[extract_links] [P1] FTP for: %s", title)
            try:
                ftp_result = await self._ftp_search_and_extract(title, year)
                ftp_links = ftp_result.get('links', [])

                if ftp_links:
                    logger.info(
                        "[extract_links] ✅ FTP: %d links | 🛑 STOP",
                        len(ftp_links),
                    )
                    for link in ftp_links:
                        if 'source_site' not in link:
                            link['source_site'] = 'ftp'
                    return {
                        'links': ftp_links,
                        'embed_links': ftp_result.get('embed_links', []),
                    }
                else:
                    logger.info("[extract_links] FTP empty → trying scrapers")
            except Exception as e:
                logger.error("[extract_links] FTP failed: %s → trying scrapers", e)

        # ── P2: HDHub4u ──
        if self._hdhub4u_scraper and MovieSources.HDHUB4U_ENABLED:
            logger.info("[extract_links] [P2] HDHub4u for: %s", title)
            try:
                result = await self._hdhub4u_search_and_extract(title, year, tmdb_id)
                hd_links = result.get('links', [])
                if hd_links:
                    # Validate: make sure results match the query title
                    validated = self._validate_results(title, hd_links)
                    if validated:
                        for link in validated:
                            if 'source_site' not in link:
                                link['source_site'] = 'hdhub4u'
                        logger.info(
                            "[extract_links] ✅ HDHub4u: %d links | 🛑 STOP",
                            len(validated),
                        )
                        return {
                            'links': validated,
                            'embed_links': result.get('embed_links', []),
                        }
                    else:
                        logger.warning(
                            "[extract_links] HDHub4u: %d links rejected by validation",
                            len(hd_links),
                        )
            except Exception as e:
                logger.error("[extract_links] HDHub4u failed: %s", e)

        # ── P3: SkyMoviesHD ──
        if self.sky_scraper:
            logger.info("[extract_links] [P3] SkyMoviesHD for: %s", title)
            try:
                result = await self._sky_search_and_extract(title, year)
                sky_links = result.get('links', [])
                if sky_links:
                    validated = self._validate_results(title, sky_links)
                    if validated:
                        for link in validated:
                            if 'source_site' not in link:
                                link['source_site'] = 'skymovieshd'
                        logger.info(
                            "[extract_links] ✅ SkyMoviesHD: %d links | 🛑 STOP",
                            len(validated),
                        )
                        return {
                            'links': validated,
                            'embed_links': result.get('embed_links', []),
                        }
                    else:
                        logger.warning(
                            "[extract_links] SkyMoviesHD: %d links rejected by validation",
                            len(sky_links),
                        )
            except Exception as e:
                logger.error("[extract_links] SkyMoviesHD failed: %s", e)

        # ── P4: Cinefreak ──
        if self.cinefreak_scraper:
            logger.info("[extract_links] [P4] Cinefreak for: %s", title)
            try:
                result = await self._cinefreak_search_and_extract(title, year)
                cf_links = result.get('links', [])
                if cf_links:
                    validated = self._validate_results(title, cf_links)
                    if validated:
                        for link in validated:
                            if 'source_site' not in link:
                                link['source_site'] = 'cinefreak'
                        logger.info(
                            "[extract_links] ✅ Cinefreak: %d links | 🛑 STOP",
                            len(validated),
                        )
                        return {
                            'links': validated,
                            'embed_links': result.get('embed_links', []),
                        }
                    else:
                        logger.warning(
                            "[extract_links] Cinefreak: %d links rejected by validation",
                            len(cf_links),
                        )
            except Exception as e:
                logger.error("[extract_links] Cinefreak failed: %s", e)

        logger.warning("[extract_links] ❌ NO RESULTS for: '%s'", title)
        return {'links': [], 'embed_links': []}

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

    async def _ftp_search_and_extract(self, title: str, year: str = None) -> Dict:
        """
        Search FTP for a title, then get playable links from matching folders.

        FTP operations are blocking (ftplib), so we run them in a thread pool
        executor to avoid blocking the async event loop.
        """
        try:
            loop = asyncio.get_running_loop()
            query = f"{title} {year}" if year else title

            # Step 1: Search for matching folders (blocking → thread)
            matches = await asyncio.wait_for(
                loop.run_in_executor(_ftp_executor, self.ftp_handler.search, query, 5),
                timeout=15,
            )

            if not matches:
                logger.info("[FTP] No results for: %s", query)
                return {'links': [], 'embed_links': []}

            # Step 2: Get playable links from the best match
            best = matches[0]
            result = await asyncio.wait_for(
                loop.run_in_executor(
                    _ftp_executor,
                    self.ftp_handler.get_playable_links,
                    best["_internal_folder"],
                    best["_internal_directory"],
                ),
                timeout=15,
            )

            ftp_links = result.get("links", [])
            logger.info("[FTP] Found %d direct links for: %s", len(ftp_links), query)
            return {'links': ftp_links, 'embed_links': []}

        except asyncio.TimeoutError:
            logger.error("[FTP] Search+extract timed out")
            return {'links': [], 'embed_links': []}
        except Exception as e:
            logger.error("[FTP] Search+extract error: %s", e)
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

    @staticmethod
    def _validate_results(query: str, results: list) -> list:
        """Filter out scraper results whose title doesn't match the query.

        Prevents issues like searching 'Young Sherlock' but getting 'O Romeo'.
        Uses word overlap + SequenceMatcher to decide relevance.
        """
        if not results:
            return []

        from difflib import SequenceMatcher

        query_clean = re.sub(r'[._\-\[\]\(\)0-9]', ' ', query.lower()).strip()
        query_clean = re.sub(r'\s+', ' ', query_clean)
        query_words = set(w for w in query_clean.split() if len(w) > 2)

        # For very short queries (1-2 words), lower the common-words threshold
        min_common = 1 if len(query_words) <= 2 else 2

        validated = []
        for result in results:
            # Check both 'title' and 'name' fields (scrapers use 'name' for links)
            title = result.get('title', '') or result.get('name', '')
            title = title.lower() if title else ''
            if not title:
                # If no title/name at all, pass it through (don't reject blindly)
                validated.append(result)
                continue

            title_clean = re.sub(r'[._\-\[\]\(\)0-9]', ' ', title).strip()
            title_clean = re.sub(r'\s+', ' ', title_clean)
            title_words = set(w for w in title_clean.split() if len(w) > 2)

            common = query_words & title_words
            similarity = SequenceMatcher(None, query_clean, title_clean).ratio()

            # Also check if the query is a substring of the title
            substring_match = query_clean in title_clean

            if len(common) >= min_common or similarity >= 0.5 or substring_match:
                validated.append(result)
            else:
                logger.warning(
                    "[MultiSource] ✗ Reject: '%s' ≠ '%s' (sim=%.2f, common=%d)",
                    query, result.get('title') or result.get('name'), similarity, len(common),
                )

        return validated

