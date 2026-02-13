"""
Homepage State Manager — tracks last-scraped movie for incremental sync.
Persists to /tmp/homepage_state.json.
"""

import json
import datetime
import logging
from pathlib import Path
from typing import Optional, Dict

logger = logging.getLogger(__name__)

STATE_FILE = Path("/tmp/homepage_state.json")


class HomepageState:
    """Singleton state tracker for incremental homepage scraping."""

    def __init__(self):
        self._state: Dict = self._load()

    # ── persistence ──────────────────────────────────────────────────────

    def _load(self) -> Dict:
        if STATE_FILE.exists():
            try:
                return json.loads(STATE_FILE.read_text())
            except Exception as e:
                logger.warning(f"Could not load state: {e}")
        return {}

    def _save(self):
        try:
            STATE_FILE.write_text(json.dumps(self._state, indent=2))
        except Exception as e:
            logger.error(f"Could not save state: {e}")

    # ── public API ───────────────────────────────────────────────────────

    def get_last_url(self, source: str) -> Optional[str]:
        """URL of the most-recently-scraped movie for *source*."""
        return self._state.get(source, {}).get("last_url")

    def update(self, source: str, url: str, title: str, total: int):
        """Record the newest movie after a successful scrape."""
        self._state[source] = {
            "last_url": url,
            "last_title": title,
            "total": total,
            "timestamp": datetime.datetime.now().isoformat(),
        }
        self._save()
        logger.info(f"[state] {source} → {title}")

    def get_info(self, source: str) -> Dict:
        return self._state.get(source, {})

    def reset(self, source: str):
        self._state.pop(source, None)
        self._save()
        logger.info(f"[state] {source} reset")


# Singleton
homepage_state = HomepageState()
