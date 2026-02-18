"""
Centralized configuration for all movie sources.
Update domains easily via Render environment variables.
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

    # ===== Cinefreak Configuration =====
    CINEFREAK_BASE_URL = os.getenv('CINEFREAK_URL', 'https://cinefreak.net')
    CINEFREAK_ENABLED = os.getenv('CINEFREAK_ENABLED', 'true').lower() == 'true'

    # ===== Search Configuration =====
    MAX_RESULTS_PER_SOURCE = int(os.getenv('MAX_RESULTS_PER_SOURCE', '20'))
    SEARCH_TIMEOUT = int(os.getenv('SEARCH_TIMEOUT', '30'))

    # ===== TMDB Configuration =====
    TMDB_API_KEY = os.getenv("TMDB_API_KEY", "7efd8424c17ff5b3e8dc9cebf4a33f73")
    TMDB_BASE_URL = "https://api.themoviedb.org/3"
    TMDB_IMAGE_BASE = "https://image.tmdb.org/t/p/w500"

    @classmethod
    def get_enabled_sources(cls) -> list:
        """Get list of enabled sources with their configuration."""
        sources = []

        if cls.HDHUB4U_ENABLED:
            sources.append({
                'name': 'HDHub4u',
                'base_url': cls.HDHUB4U_BASE_URL,
                'type': 'hdhub4u',
                'priority': 1,
            })

        if cls.SKYMOVIESHD_ENABLED:
            sources.append({
                'name': 'SkyMoviesHD',
                'base_url': cls.SKYMOVIESHD_BASE_URL,
                'type': 'skymovieshd',
                'priority': 2,
            })

        if cls.CINEFREAK_ENABLED:
            sources.append({
                'name': 'Cinefreak',
                'base_url': cls.CINEFREAK_BASE_URL,
                'type': 'cinefreak',
                'priority': 3,
            })

        return sources

    @classmethod
    def print_config(cls):
        """Print current configuration (for startup logging)."""
        logger.info("=" * 60)
        logger.info("MOVIE SOURCES CONFIGURATION")
        logger.info("=" * 60)

        if cls.HDHUB4U_ENABLED:
            logger.info(f"  HDHub4u:      {cls.HDHUB4U_BASE_URL}")
        else:
            logger.info("  HDHub4u:      DISABLED")

        if cls.SKYMOVIESHD_ENABLED:
            logger.info(f"  SkyMoviesHD:  {cls.SKYMOVIESHD_BASE_URL}")
        else:
            logger.info("  SkyMoviesHD:  DISABLED")

        if cls.CINEFREAK_ENABLED:
            logger.info(f"  Cinefreak:    {cls.CINEFREAK_BASE_URL}")
        else:
            logger.info("  Cinefreak:    DISABLED")

        logger.info(f"  Max results/source: {cls.MAX_RESULTS_PER_SOURCE}")
        logger.info(f"  Search timeout:     {cls.SEARCH_TIMEOUT}s")
        logger.info("=" * 60)
