"""
Cinefreak.net Scraper — Extracts cinecloud.site download links.

Workflow:
  1. Search movie on cinefreak.net/?s=query
  2. Parse search results (H3 article links)
  3. Open movie detail page
  4. Extract download links from H4 quality headers + cinecloud.site <a> tags

Cinefreak embeds download URLs directly in the HTML — no mediator
chains or intermediate host resolution needed.
"""

import asyncio
import re
from bs4 import BeautifulSoup
from playwright.async_api import Browser
from playwright_stealth import stealth_async
from typing import List, Dict, Optional
import logging
import httpx

from .base_scraper import BaseMovieScraper

logger = logging.getLogger(__name__)

# Common user agent
USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
)

# Known download host patterns for Cinefreak
CINECLOUD_HOSTS = [
    'cinecloud.site',
    'new5.cinecloud.site',
    'new4.cinecloud.site',
    'new3.cinecloud.site',
    'new2.cinecloud.site',
    'new1.cinecloud.site',
]


class CinefreakScraper(BaseMovieScraper):
    """
    Scraper for Cinefreak.net website.
    Extracts cinecloud.site download links directly from movie pages.
    """

    def __init__(self, base_url: str):
        super().__init__(base_url, 'Cinefreak')

    # =========================================================================
    # STEP 1: SEARCH
    # =========================================================================

    async def search_movies(self, query: str, max_results: int = 20) -> List[Dict]:
        """
        Search for movies on Cinefreak.net.
        Search page returns article posts with H3 title links.
        """
        movies = []

        try:
            logger.info(f"[{self.source_name}] 🔍 Searching for: {query}")

            search_url = f"{self.base_url}/?s={query.replace(' ', '+')}"
            content = await self._fetch_page(search_url)

            if not content:
                return movies

            soup = BeautifulSoup(content, 'html.parser')

            # Cinefreak search results are in <article> tags or <h3> links
            # Each result has a link to the movie page
            result_links = []

            # Method 1: Find article containers
            articles = soup.find_all('article')
            for article in articles:
                title_elem = article.find(['h2', 'h3'])
                link_elem = article.find('a', href=True)
                if title_elem and link_elem:
                    result_links.append({
                        'text': title_elem.get_text(strip=True),
                        'href': link_elem.get('href', ''),
                    })

            # Method 2: Find H3 header links directly (if no articles)
            if not result_links:
                h3_links = soup.find_all('h3')
                for h3 in h3_links:
                    link = h3.find('a', href=True)
                    if link:
                        result_links.append({
                            'text': link.get_text(strip=True),
                            'href': link.get('href', ''),
                        })

            # Method 3: Find all links that point to movie pages
            if not result_links:
                all_links = soup.find_all('a', href=True)
                for link in all_links:
                    href = link.get('href', '')
                    text = link.get_text(strip=True)
                    # Filter: must be a cinefreak.net post URL, not a category/tag
                    if (self.base_url in href and
                        text and len(text) > 10 and
                        '/category/' not in href and
                        '/?s=' not in href and
                        '/tag/' not in href and
                        '/page/' not in href and
                        href != self.base_url and
                        href != f"{self.base_url}/"):
                        result_links.append({'text': text, 'href': href})

            # Prepare query words for relevance matching
            query_words = [w.lower() for w in query.split()
                          if len(w) >= 3 and not w.isdigit()]
            seen_urls = set()

            for item in result_links:
                href = item['href']
                text = item['text']

                if not href or not text:
                    continue

                # Deduplicate by URL
                url_key = href.split('?')[0].rstrip('/')
                if url_key in seen_urls:
                    continue
                seen_urls.add(url_key)

                # Relevance filter
                combined = (text + ' ' + href).lower()
                if query_words and not any(word in combined for word in query_words):
                    logger.debug(
                        f"[{self.source_name}] Skipped (no relevance): {text[:60]}"
                    )
                    continue

                raw_title = text
                movie_url = href
                if not movie_url.startswith('http'):
                    movie_url = f"{self.base_url}{movie_url}"

                clean_title, year = self._clean_title(raw_title)
                quality = self._extract_quality(raw_title)

                if not clean_title or len(clean_title) < 2:
                    continue

                logger.info(
                    f"[{self.source_name}] ✅ Found: {clean_title} ({year}) - {quality}"
                )

                # Match with TMDB
                tmdb_data = await self._match_with_tmdb(clean_title, year)

                if tmdb_data:
                    movies.append({
                        'source': self.source_name,
                        'source_type': 'cinefreak',
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
                        'source_type': 'cinefreak',
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
                f"[{self.source_name}] 📊 Search complete: {len(movies)} movies found"
            )

        except Exception as e:
            logger.error(f"[{self.source_name}] Search error: {e}")

        return movies

    # =========================================================================
    # STEP 2: LINK EXTRACTION
    # =========================================================================

    async def extract_links(self, movie_url: str) -> Dict:
        """
        Extract cinecloud.site download links from a Cinefreak movie page.

        Cinefreak movie pages have a structured format:
          <h4>MovieTitle (Year) [Lang] Quality [Size]</h4>
          <a href="https://new5.cinecloud.site/f/xxxx">Download Links</a>
          <a href="...">▶ Watch Online</a>
        """
        result = {
            'links': [],
            'embed_links': [],
        }

        try:
            logger.info(f"[{self.source_name}] 📍 Opening movie page: {movie_url}")

            content = await self._fetch_page(movie_url)
            if not content:
                return result

            soup = BeautifulSoup(content, 'html.parser')

            # --- Extract download links ---
            download_links = []
            embed_links = []

            # Strategy 1: Parse H4 quality headers + following links
            h4_headers = soup.find_all('h4')
            for h4 in h4_headers:
                header_text = h4.get_text(strip=True)

                # Check if this H4 is a quality header (contains resolution info)
                quality_match = re.search(
                    r'(480p|720p|1080p|2160p|4K)', header_text, re.I
                )
                if not quality_match:
                    continue

                quality = quality_match.group(1).upper()

                # Extract size from header (e.g., "[580 MB]" or "[1.3 GB]")
                size_match = re.search(
                    r'\[(\d+(?:\.\d+)?\s*(?:MB|GB))\]', header_text, re.I
                )
                size = size_match.group(1) if size_match else ''

                # Extract SD/HD label
                hd_match = re.search(r'\b(SD|HD|FHD|UHD)\b', header_text, re.I)
                hd_label = hd_match.group(1).upper() if hd_match else ''
                quality_display = f"{quality} {hd_label}".strip() if hd_label else quality

                # Find all links following this H4 (siblings or in next elements)
                # BeautifulSoup: iterate next siblings until next H4 or H3
                current = h4.next_sibling
                while current:
                    if hasattr(current, 'name') and current.name in ('h4', 'h3', 'h2'):
                        break  # Stop at next quality header

                    if hasattr(current, 'find_all'):
                        links = current.find_all('a', href=True)
                        for link in links:
                            href = link.get('href', '')
                            link_text = link.get_text(strip=True)
                            self._categorize_link(
                                href, link_text, quality_display, size,
                                download_links, embed_links
                            )

                    # Also check if current itself is an <a> tag
                    if hasattr(current, 'name') and current.name == 'a':
                        href = current.get('href', '')
                        link_text = current.get_text(strip=True)
                        self._categorize_link(
                            href, link_text, quality_display, size,
                            download_links, embed_links
                        )

                    current = current.next_sibling

            # Strategy 2: Fallback — find ALL cinecloud.site links on the page
            if not download_links:
                logger.info(
                    f"[{self.source_name}] H4 parsing found 0 links, "
                    f"trying fallback (all cinecloud links)"
                )
                all_links = soup.find_all('a', href=True)
                for link in all_links:
                    href = link.get('href', '')
                    link_text = link.get_text(strip=True)

                    if self._is_cinecloud_url(href):
                        # Try to extract quality from surrounding text
                        parent_text = ''
                        if link.parent:
                            parent_text = link.parent.get_text(strip=True)

                        quality = self._extract_quality(parent_text) or 'HD'

                        download_links.append({
                            'url': href,
                            'quality': quality,
                            'size': '',
                            'name': f'CineCloud - {quality}',
                            'type': 'download',
                            'source': self.source_name,
                            'source_host': 'cinecloud',
                        })

            # Deduplicate by URL
            seen_urls = set()
            unique_links = []
            for link in download_links:
                url_key = link['url'].split('?')[0]
                if url_key not in seen_urls:
                    seen_urls.add(url_key)
                    unique_links.append(link)

            result['links'] = unique_links
            result['embed_links'] = embed_links

            logger.info(
                f"[{self.source_name}] 🎉 Extraction complete! "
                f"{len(unique_links)} download links, "
                f"{len(embed_links)} embed links"
            )

        except Exception as e:
            logger.error(f"[{self.source_name}] Link extraction error: {e}")

        return result

    # =========================================================================
    # HELPERS
    # =========================================================================

    def _categorize_link(self, href: str, link_text: str,
                         quality: str, size: str,
                         download_links: list, embed_links: list):
        """Categorize a link as download or embed based on its URL."""
        if not href or href.startswith('#') or 'javascript:' in href:
            return

        # CineCloud download link
        if self._is_cinecloud_url(href):
            # /f/ pattern = direct download, /x/ pattern = streaming
            if '/f/' in href:
                download_links.append({
                    'url': href,
                    'quality': quality,
                    'size': size,
                    'name': f'CineCloud - {quality}' + (f' ({size})' if size else ''),
                    'type': 'download',
                    'source': self.source_name,
                    'source_host': 'cinecloud',
                })
            elif '/x/' in href:
                embed_links.append({
                    'url': href,
                    'quality': quality,
                    'player': 'CineCloud',
                    'type': 'embed',
                    'source': self.source_name,
                })

        # Watch Online via generating.php (contains embedded stream)
        elif 'generating.php' in href:
            embed_links.append({
                'url': href,
                'quality': quality,
                'player': 'CineFreak Player',
                'type': 'embed',
                'source': self.source_name,
            })

    def _is_cinecloud_url(self, url: str) -> bool:
        """Check if URL is a CineCloud download/streaming URL."""
        url_lower = url.lower()
        return any(host in url_lower for host in CINECLOUD_HOSTS)

    async def _fetch_page(self, url: str) -> Optional[str]:
        """
        Fetch a page via HTTP. Falls back to Playwright if Cloudflare is detected.
        """
        try:
            # --- Primary: httpx (fast, no JS) ---
            async with httpx.AsyncClient(
                headers={"User-Agent": USER_AGENT},
                timeout=15.0,
                follow_redirects=True
            ) as client:
                resp = await client.get(url)

                # Check for Cloudflare challenge
                if resp.status_code in (403, 503):
                    cf_headers = resp.headers.get('server', '').lower()
                    if 'cloudflare' in cf_headers or 'cf-ray' in resp.headers:
                        logger.warning(
                            f"[{self.source_name}] Cloudflare detected, "
                            f"falling back to Playwright"
                        )
                        return await self._fetch_with_playwright(url)

                if resp.status_code != 200:
                    logger.error(
                        f"[{self.source_name}] HTTP {resp.status_code} for {url}"
                    )
                    return None

                return resp.text

        except Exception as e:
            logger.warning(
                f"[{self.source_name}] httpx failed ({e}), "
                f"trying Playwright fallback"
            )
            return await self._fetch_with_playwright(url)

    async def _fetch_with_playwright(self, url: str) -> Optional[str]:
        """Fallback: fetch page with Playwright (handles Cloudflare)."""
        if not self.browser:
            logger.error(f"[{self.source_name}] No browser available for fallback")
            return None

        context = None
        page = None
        try:
            context = await self.browser.new_context(user_agent=USER_AGENT)
            page = await context.new_page()
            await stealth_async(page)
            await page.goto(url, wait_until='domcontentloaded', timeout=40000)
            # Wait for Cloudflare challenge to resolve
            await asyncio.sleep(5)
            content = await page.content()
            logger.info(f"[{self.source_name}] ✅ Page loaded via Playwright")
            return content
        except Exception as e:
            logger.error(f"[{self.source_name}] Playwright fallback failed: {e}")
            return None
        finally:
            if page:
                await page.close()
            if context:
                await context.close()
