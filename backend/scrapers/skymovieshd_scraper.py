"""
SkyMoviesHD Scraper — extracts movies and download links from SkyMoviesHD.
Follows the real site workflow:
  1. Search → flat link list page
  2. Movie page → find "Google Drive Direct Links" (howblogs.xyz mediator)
  3. Mediator page → extract actual drive/download links
"""

import asyncio
import re
from bs4 import BeautifulSoup
from playwright.async_api import Page
from playwright_stealth import stealth_async
from typing import List, Dict
import logging
import httpx

from .base_scraper import BaseMovieScraper

logger = logging.getLogger(__name__)

# Common user agent
USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"

# Known download hosts that appear on mediator pages
DOWNLOAD_HOSTS = [
    'drive.google.com', 'docs.google.com',
    'dgdrive.site', 'gdrive', 'gdtot', 'gdflix',
    'hubdrive', 'hubcloud', 'gofile.io',
    'filepress', 'pixeldrain.com', 'krakenfiles.com',
    'terabox.com', 'mega.nz', 'mediafire.com',
]

# Known mediator/shortener hosts
MEDIATOR_HOSTS = [
    'howblogs.xyz', 'hblinks.dad', 'gadgetsweb.xyz',
    'cryptoinsights.site', 'adrinolinks.in', 'newshub.live',
    'gplinks.co', 'kolop.net',
]

# Streaming embed hosts
EMBED_HOSTS = [
    'hglink.to', 'vidhide.com', 'vidsrc', 'filmxy',
    'streamtape.com', 'doodstream', 'mixdrop',
]


class SkyMoviesHDScraper(BaseMovieScraper):
    """Scraper for SkyMoviesHD website."""

    def __init__(self, base_url: str):
        super().__init__(base_url, 'SkyMoviesHD')

    async def _new_stealth_page(self):
        """Create a new stealth browser context + page."""
        if not self.browser:
            raise RuntimeError("Browser not set — call set_browser() first")
        context = await self.browser.new_context(user_agent=USER_AGENT)
        page = await context.new_page()
        await stealth_async(page)
        return context, page

    # =========================================================================
    # SEARCH (Step 1-3)
    # =========================================================================

    async def search_movies(self, query: str, max_results: int = 20) -> List[Dict]:
        """
        Search for movies on SkyMoviesHD.
        The search page returns a flat list of <a> links (no article/div posts).
        Each link points to /movie/Title-Here.html.
        """
        movies = []

        try:
            logger.info(f"[{self.source_name}] Searching for: {query}")

            # Use HTTP first (faster, no browser needed for search)
            search_url = f"{self.base_url}/?s={query.replace(' ', '+')}"
            
            async with httpx.AsyncClient(
                headers={"User-Agent": USER_AGENT},
                timeout=15.0,
                follow_redirects=True
            ) as client:
                resp = await client.get(search_url)
                if resp.status_code != 200:
                    logger.error(f"[{self.source_name}] Search HTTP {resp.status_code}")
                    return movies

                content = resp.text

            soup = BeautifulSoup(content, 'html.parser')

            # SkyMoviesHD search returns flat <a> links to /movie/*.html
            all_links = soup.find_all('a', href=True)

            for link in all_links:
                href = link.get('href', '')
                text = link.get_text(strip=True)

                # Only pick links to movie pages
                if '/movie/' not in href or not text or len(text) < 5:
                    continue

                # Skip category/nav links
                if '/category/' in href or '/search.php' in href:
                    continue

                raw_title = text
                movie_url = href

                # Ensure full URL
                if not movie_url.startswith('http'):
                    movie_url = f"{self.base_url}{movie_url}"

                # Clean title and extract year/quality
                clean_title, year = self._clean_title(raw_title)
                quality = self._extract_quality(raw_title)

                if not clean_title or len(clean_title) < 2:
                    continue

                logger.info(
                    f"[{self.source_name}] Found: {clean_title} ({year}) - {quality}"
                )

                # Match with TMDB
                tmdb_data = await self._match_with_tmdb(clean_title, year)

                if tmdb_data:
                    movies.append({
                        'source': self.source_name,
                        'source_type': 'skymovieshd',
                        'title': tmdb_data['title'],
                        'original_title': raw_title,
                        'url': movie_url,
                        'year': year or tmdb_data.get('release_date', '')[:4],
                        'quality': quality,
                        'poster': tmdb_data['poster_url'],
                        'backdrop': tmdb_data.get('backdrop_url'),
                        'tmdb_id': tmdb_data['tmdb_id'],
                        'rating': tmdb_data['rating'],
                        'overview': tmdb_data['overview'],
                        'release_date': tmdb_data['release_date'],
                    })
                else:
                    movies.append({
                        'source': self.source_name,
                        'source_type': 'skymovieshd',
                        'title': clean_title,
                        'original_title': raw_title,
                        'url': movie_url,
                        'year': year,
                        'quality': quality,
                        'poster': None,
                    })

                if len(movies) >= max_results:
                    break

            logger.info(
                f"[{self.source_name}] Extracted {len(movies)} movies from search"
            )

        except Exception as e:
            logger.error(f"[{self.source_name}] Search error: {e}")

        return movies

    # =========================================================================
    # LINK EXTRACTION (Step 4-5)
    # =========================================================================

    async def extract_links(self, movie_url: str) -> Dict:
        """
        Extract download links from a SkyMoviesHD movie page.
        Workflow:
          1. Fetch movie page (HTTP)
          2. Find "Google Drive Direct Links" and SERVER links (mediator URLs)
          3. Follow each mediator URL to get actual download links
          4. Find "WATCH ONLINE" embed links
        """
        result = {
            'links': [],
            'embed_links': [],
        }

        try:
            logger.info(f"[{self.source_name}] Extracting links from: {movie_url}")

            # Step 1: Fetch movie page via HTTP (fast)
            async with httpx.AsyncClient(
                headers={"User-Agent": USER_AGENT},
                timeout=15.0,
                follow_redirects=True
            ) as client:
                resp = await client.get(movie_url)
                if resp.status_code != 200:
                    logger.error(f"[{self.source_name}] Movie page HTTP {resp.status_code}")
                    return result
                movie_html = resp.text

            soup = BeautifulSoup(movie_html, 'html.parser')
            all_links = soup.find_all('a', href=True)

            mediator_urls = []
            embed_urls = []

            for link in all_links:
                href = link.get('href', '')
                text = link.get_text(strip=True)

                # Skip self-referencing and navigation links
                if not href or href.startswith('#') or 'javascript:' in href:
                    continue

                # Check for mediator links (howblogs.xyz, etc.)
                if self._is_mediator_link(href):
                    mediator_urls.append({
                        'url': href,
                        'text': text,
                    })
                    logger.info(f"[{self.source_name}] Found mediator: {text} → {href}")

                # Check for embed/streaming links
                elif self._is_embed_link(href):
                    embed_urls.append({
                        'url': href,
                        'quality': self._extract_quality(text) if text else 'HD',
                        'player': text or 'Player',
                        'type': 'embed',
                    })

                # Check for direct download links on the page itself
                elif self._is_download_link(href):
                    quality = self._extract_quality(text) if text else 'HD'
                    result['links'].append({
                        'name': text[:80] if text else f'Download - {quality}',
                        'url': href,
                        'quality': quality,
                        'type': 'Google Drive',
                        'source': self.source_name,
                    })

            # Step 2: Follow mediator links to get actual download URLs
            if mediator_urls:
                logger.info(
                    f"[{self.source_name}] Following {len(mediator_urls)} mediator links..."
                )
                download_links = await self._resolve_mediator_links(mediator_urls)
                result['links'].extend(download_links)

            # Deduplicate links by URL
            seen = set()
            unique_links = []
            for link in result['links']:
                url_key = link['url'].split('?')[0]
                if url_key not in seen:
                    seen.add(url_key)
                    unique_links.append(link)
            result['links'] = unique_links

            result['embed_links'] = embed_urls

            logger.info(
                f"[{self.source_name}] Final: {len(result['links'])} download links, "
                f"{len(result['embed_links'])} embed links"
            )

        except Exception as e:
            logger.error(f"[{self.source_name}] Link extraction error: {e}")

        return result

    async def _resolve_mediator_links(self, mediator_urls: List[Dict]) -> List[Dict]:
        """
        Follow mediator/shortener URLs (howblogs.xyz, etc.) to extract
        actual download links. Uses HTTP GET — no browser needed.
        """
        all_links = []

        # Process mediators concurrently (max 3 at a time)
        semaphore = asyncio.Semaphore(3)

        async def resolve_one(mediator: Dict) -> List[Dict]:
            async with semaphore:
                return await self._fetch_mediator_page(
                    mediator['url'], mediator['text']
                )

        tasks = [resolve_one(m) for m in mediator_urls]
        results = await asyncio.gather(*tasks, return_exceptions=True)

        for result in results:
            if isinstance(result, list):
                all_links.extend(result)
            elif isinstance(result, Exception):
                logger.error(f"[{self.source_name}] Mediator resolve error: {result}")

        return all_links

    async def _fetch_mediator_page(self, mediator_url: str, 
                                     button_text: str) -> List[Dict]:
        """
        Fetch a mediator page (e.g., howblogs.xyz/375923) and extract
        download links from its content.
        """
        links = []

        try:
            logger.info(f"[{self.source_name}] Resolving mediator: {mediator_url}")

            async with httpx.AsyncClient(
                headers={"User-Agent": USER_AGENT},
                timeout=15.0,
                follow_redirects=True
            ) as client:
                resp = await client.get(mediator_url)
                if resp.status_code != 200:
                    logger.warning(
                        f"[{self.source_name}] Mediator HTTP {resp.status_code}: {mediator_url}"
                    )
                    return links

                content = resp.text

            soup = BeautifulSoup(content, 'html.parser')

            # Method 1: Find download links in <a> tags
            for a in soup.find_all('a', href=True):
                href = a.get('href', '')
                if self._is_download_link(href):
                    text = a.get_text(strip=True)
                    quality = self._extract_quality(text or button_text)
                    links.append({
                        'name': f"{button_text} - {quality}" if button_text else f'Download - {quality}',
                        'url': href,
                        'quality': quality,
                        'type': 'Google Drive',
                        'source': self.source_name,
                    })

            # Method 2: Find download links in plain text (common for howblogs.xyz)
            # These links appear as raw URLs in the page content
            url_pattern = re.compile(
                r'https?://[^\s"\'<>\]]+(?:' +
                '|'.join(re.escape(h) for h in DOWNLOAD_HOSTS) +
                r')[^\s"\'<>\]]*',
                re.IGNORECASE
            )

            existing_urls = {l['url'] for l in links}
            text_content = soup.get_text()

            for match in url_pattern.finditer(text_content):
                url = match.group(0).rstrip('.')
                if url not in existing_urls:
                    existing_urls.add(url)
                    quality = self._extract_quality(button_text)
                    links.append({
                        'name': f"{button_text} - {quality}" if button_text else f'Download - {quality}',
                        'url': url,
                        'quality': quality,
                        'type': 'Google Drive',
                        'source': self.source_name,
                    })

            # Method 3: Find links in page source (JS-embedded URLs)
            for match in url_pattern.finditer(content):
                url = match.group(0).rstrip('.')
                if url not in existing_urls:
                    existing_urls.add(url)
                    quality = self._extract_quality(button_text)
                    links.append({
                        'name': f"{button_text} - {quality}" if button_text else f'Download - {quality}',
                        'url': url,
                        'quality': quality,
                        'type': 'Google Drive',
                        'source': self.source_name,
                    })

            logger.info(
                f"[{self.source_name}] Mediator '{button_text}' → {len(links)} links"
            )

        except Exception as e:
            logger.error(
                f"[{self.source_name}] Error fetching mediator {mediator_url}: {e}"
            )

        return links

    # =========================================================================
    # HELPERS
    # =========================================================================

    def _is_download_link(self, url: str) -> bool:
        """Check if URL points to a known download host."""
        url_lower = url.lower()
        return any(host in url_lower for host in DOWNLOAD_HOSTS)

    def _is_mediator_link(self, url: str) -> bool:
        """Check if URL points to a known mediator/shortener host."""
        url_lower = url.lower()
        return any(host in url_lower for host in MEDIATOR_HOSTS)

    def _is_embed_link(self, url: str) -> bool:
        """Check if URL points to a known streaming embed host."""
        url_lower = url.lower()
        return any(host in url_lower for host in EMBED_HOSTS)
