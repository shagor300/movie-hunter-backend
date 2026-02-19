"""
SkyMoviesHD Scraper — Full Google Drive extraction workflow.

Implements the complete 7-step workflow from skymovieshdlink.md:
  1. Search movie on skymovieshd.mba
  2. Open movie detail page
  3. Find "Google Drive Direct Links" section
  4. Extract intermediate host links (HubDrive, HubCloud, GDFlix)
  5. Visit each intermediate page (Playwright)
  6. Extract final Google Drive link
  7. Return only Google Drive links
"""

import asyncio
import re
from bs4 import BeautifulSoup
from playwright.async_api import Page, Browser, TimeoutError as PlaywrightTimeout
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

# Known mediator/shortener hosts (movie page → these → intermediate hosts)
MEDIATOR_HOSTS = [
    'howblogs.xyz', 'hblinks.dad', 'gadgetsweb.xyz',
    'cryptoinsights.site', 'adrinolinks.in', 'newshub.live',
    'gplinks.co', 'kolop.net',
]

# Intermediate file hosts (these contain the actual download buttons)
INTERMEDIATE_HOSTS = {
    'hubdrive': ['hubdrive.space', 'hubdrive.dad'],
    'hubcloud': ['hubcloud.foo', 'hubcloud.in'],
    'gdflix':   ['gdflix.dev', 'new1.gdflix.app', 'gdflix.cfd'],
    'dgdrive':  ['dgdrive.site'],
    'filepress': ['filepress.wiki', 'new1.filepress.wiki'],
    'gofile':   ['gofile.io'],
    'gdtot':    ['gdtot.cfd', 'new6.gdtot.sbs'],
}

# Final target: Google Drive domains
GDRIVE_PATTERNS = [
    r'drive\.google\.com',
    r'docs\.google\.com',
]

# Streaming embed hosts
EMBED_HOSTS = [
    'hglink.to', 'vidhide.com', 'vidsrc', 'filmxy',
    'streamtape.com', 'doodstream', 'mixdrop',
]

# ── SkyMoviesHD Category URLs ──
# Used as a fallback when direct search returns 0 results.
SKYMOVIESHD_CATEGORIES = {
    'bollywood':        '/cat/bollywood/',
    'south_dubbed':     '/cat/south-indian-hindi-dubbed-movies/',
    'bengali':          '/cat/bengali-movies/',
    'pakistani':        '/cat/pakistani-movies/',
    'hollywood_english': '/cat/hollywood-english-movies/',
    'hollywood_dubbed': '/cat/hollywood-hindi-dubbed-movies/',
    'tamil':            '/cat/tamil-movies/',
    'telugu':           '/cat/telugu-movies/',
    'punjabi':          '/cat/punjabi-movies/',
    'bhojpuri':         '/cat/bhojpuri-movies/',
    'bangladeshi':      '/cat/bangladeshi-movies/',
    'marathi':          '/cat/marathi-movies/',
    'kannada':          '/cat/kannada-movies/',
}

# CSS selectors to find movie links on search/category pages
MOVIE_LINK_SELECTORS = [
    'article h2 a',
    '.post-title a',
    'h2.entry-title a',
    '.entry-title a',
    'div.post h2 a',
    'h2 a',
]


class SkyMoviesHDScraper(BaseMovieScraper):
    """
    Scraper for SkyMoviesHD website.
    Extracts final Google Drive links by navigating through mediators
    and intermediate file hosts.
    """

    def __init__(self, base_url: str):
        super().__init__(base_url, 'SkyMoviesHD')
        self._download_resolver = None  # DownloadLinkResolver for click-through

    def set_download_resolver(self, resolver):
        """Set the shared DownloadLinkResolver for intermediate host resolution."""
        self._download_resolver = resolver
        logger.info(f"[{self.source_name}] DownloadLinkResolver attached")

    async def _new_stealth_page(self):
        """Create a new stealth browser context + page."""
        if not self.browser:
            raise RuntimeError("Browser not set — call set_browser() first")
        context = await self.browser.new_context(user_agent=USER_AGENT)
        page = await context.new_page()
        await stealth_async(page)
        return context, page

    # =========================================================================
    # STEP 1: SEARCH (two-method approach)
    # =========================================================================

    async def search_movies(self, query: str, max_results: int = 20) -> List[Dict]:
        """
        Search for movies on SkyMoviesHD.

        Method 1: Direct URL search (/?s=query) with proper CSS selectors.
        Method 2: Category-based browsing (fallback when URL search fails).
        """
        logger.info(f"[{self.source_name}] 🔍 Step 1: Searching for: {query}")

        # --- Method 1: URL-based search ---
        movies = await self._search_by_url(query, max_results)
        if movies:
            logger.info(
                f"[{self.source_name}] ✅ URL search found {len(movies)} results"
            )
            return movies

        # --- Method 2: Category-based search (fallback) ---
        logger.info(
            f"[{self.source_name}] URL search returned 0, trying category search..."
        )
        movies = await self._search_by_category(query, max_results)
        if movies:
            logger.info(
                f"[{self.source_name}] ✅ Category search found {len(movies)} results"
            )
            return movies

        logger.info(
            f"[{self.source_name}] 📊 Search complete: 0 movies found"
        )
        return []

    async def _search_by_url(self, query: str, max_results: int = 20) -> List[Dict]:
        """
        Method 1: Search via the site's /?s=query endpoint.
        Uses Playwright for JS rendering + proper CSS selectors.
        """
        movies = []
        if not self.browser:
            return movies

        context = None
        page = None
        try:
            context, page = await self._new_stealth_page()
            search_url = f"{self.base_url}/?s={query.replace(' ', '+')}"
            logger.info(f"[{self.source_name}] Trying URL: {search_url}")

            await page.goto(
                search_url, wait_until='domcontentloaded', timeout=20000
            )
            await asyncio.sleep(2)

            # Extract matching movies from the rendered page
            movies = await self._extract_movies_from_page(page, query, max_results)

        except Exception as e:
            logger.warning(f"[{self.source_name}] URL search error: {e}")
        finally:
            if page:
                await page.close()
            if context:
                await context.close()

        return movies

    async def _search_by_category(self, query: str, max_results: int = 20) -> List[Dict]:
        """
        Method 2: Browse category pages and match movie titles.
        Searches ALL categories until results are found.
        """
        movies = []
        if not self.browser:
            return movies

        context = None
        page = None
        try:
            context, page = await self._new_stealth_page()

            for cat_name, cat_path in SKYMOVIESHD_CATEGORIES.items():
                cat_url = f"{self.base_url}{cat_path}"
                logger.info(
                    f"[{self.source_name}] Searching category: {cat_name}"
                )

                try:
                    await page.goto(
                        cat_url, wait_until='domcontentloaded', timeout=15000
                    )
                    await asyncio.sleep(1.5)

                    found = await self._extract_movies_from_page(
                        page, query, max_results
                    )
                    if found:
                        logger.info(
                            f"[{self.source_name}] ✅ Found {len(found)} in {cat_name}"
                        )
                        movies.extend(found)
                        break  # Stop after first category with results

                except Exception as e:
                    logger.debug(
                        f"[{self.source_name}] Category {cat_name} error: {e}"
                    )
                    continue

        except Exception as e:
            logger.error(f"[{self.source_name}] Category search error: {e}")
        finally:
            if page:
                await page.close()
            if context:
                await context.close()

        return movies

    async def _extract_movies_from_page(
        self, page, query: str, max_results: int = 20
    ) -> List[Dict]:
        """
        Extract matching movie links from the current page using CSS selectors.
        Shared by both URL search and category search.
        """
        movies = []
        seen_urls = set()

        # Prepare query words for matching (ignore short words and years)
        query_words = [
            w.lower() for w in query.split()
            if len(w) >= 2 and not (w.isdigit() and len(w) == 4)
        ]
        # Extract year from query if present
        query_year = None
        for word in query.split():
            if word.isdigit() and len(word) == 4:
                query_year = word
                break

        # Try each CSS selector until we find movie links
        for selector in MOVIE_LINK_SELECTORS:
            try:
                elements = await page.query_selector_all(selector)
                if not elements:
                    continue

                logger.debug(
                    f"[{self.source_name}] Selector '{selector}': "
                    f"{len(elements)} elements"
                )

                for element in elements:
                    href = await element.get_attribute('href')
                    text = await element.inner_text()

                    if not href or not text or len(text.strip()) < 5:
                        continue

                    # Skip navigation / non-movie links
                    if any(skip in href for skip in [
                        '/category/', '/cat/', '/search.php', '/page/',
                        '#', 'javascript:', 'facebook.com', 'twitter.com'
                    ]):
                        continue

                    # Deduplicate by URL
                    url_key = href.split('?')[0].rstrip('/')
                    if url_key in seen_urls:
                        continue
                    seen_urls.add(url_key)

                    # Check if title matches the query
                    raw_title = text.strip()
                    if not self._is_title_match(raw_title, query_words, query_year):
                        continue

                    # Ensure full URL
                    movie_url = href
                    if not movie_url.startswith('http'):
                        movie_url = f"{self.base_url}{movie_url}"

                    clean_title, year = self._clean_title(raw_title)
                    quality = self._extract_quality(raw_title)

                    if not clean_title or len(clean_title) < 2:
                        continue

                    logger.info(
                        f"[{self.source_name}] ✅ Found: {clean_title}"
                        f" ({year}) - {quality}"
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
                            'year': year or tmdb_data.get(
                                'release_date', ''
                            )[:4],
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
                        return movies

                # If we found movies with this selector, stop trying others
                if movies:
                    return movies

            except Exception as e:
                logger.debug(
                    f"[{self.source_name}] Selector '{selector}' error: {e}"
                )
                continue

        return movies

    def _is_title_match(
        self, title: str, query_words: List[str], query_year: str = None
    ) -> bool:
        """
        Check if a page title matches the search query.
        All query words must appear in the title.
        """
        title_lower = title.lower()

        # All query words must be present in the title
        if not all(word in title_lower for word in query_words):
            return False

        # If a year was specified, it should appear in the title
        if query_year and query_year not in title:
            return False

        return True

    # =========================================================================
    # STEPS 2-7: FULL LINK EXTRACTION
    # =========================================================================

    async def extract_links(self, movie_url: str) -> Dict:
        """
        Full 7-step Google Drive extraction workflow:
          Step 2: Open movie detail page (HTTP)
          Step 3: Find "Google Drive Direct Links" + embed links
          Step 4: Follow mediator to get intermediate host URLs (HTTP)
          Step 5: Visit each intermediate page (Playwright)
          Step 6: Click download, extract Google Drive URL
          Step 7: Return only Google Drive links
        """
        result = {
            'links': [],           # Final Google Drive links
            'embed_links': [],     # Streaming embed links
            'intermediate_links': [],  # For debugging
        }

        try:
            # ── Step 2: Fetch movie detail page ──
            logger.info(f"[{self.source_name}] 📍 Step 2: Opening movie page: {movie_url}")

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

            # ── Step 3: Find mediator links + embed links ──
            logger.info(f"[{self.source_name}] 📍 Step 3: Extracting links from movie page...")

            for link in all_links:
                href = link.get('href', '')
                text = link.get_text(strip=True)

                if not href or href.startswith('#') or 'javascript:' in href:
                    continue

                # Check for mediator links (howblogs.xyz, etc.)
                if self._is_mediator_link(href):
                    mediator_urls.append({'url': href, 'text': text})
                    logger.info(f"[{self.source_name}] 🔗 Mediator: {text} → {href}")

                # Check for streaming embeds
                elif self._is_embed_link(href):
                    embed_urls.append({
                        'url': href,
                        'quality': self._extract_quality(text) if text else 'HD',
                        'player': text or 'Player',
                        'type': 'embed',
                    })

            result['embed_links'] = embed_urls

            if not mediator_urls:
                logger.warning(f"[{self.source_name}] ⚠️ No mediator links found")
                return result

            # ── Step 4: Follow mediators → get intermediate host URLs ──
            logger.info(
                f"[{self.source_name}] 📍 Step 4: Following {len(mediator_urls)} mediator links..."
            )
            intermediate_links = await self._resolve_mediators(mediator_urls)
            result['intermediate_links'] = intermediate_links

            if not intermediate_links:
                logger.warning(f"[{self.source_name}] ⚠️ No intermediate host links found")
                return result

            logger.info(
                f"[{self.source_name}] ✅ Found {len(intermediate_links)} intermediate links"
            )

            # ── Steps 5-6: Visit intermediate hosts → Extract GDrive URLs ──
            logger.info(
                f"[{self.source_name}] 📍 Steps 5-6: Extracting Google Drive links..."
            )
            gdrive_links = await self._extract_gdrive_from_intermediates(intermediate_links)

            # ── Step 7: Return only Google Drive links ──
            result['links'] = gdrive_links

            logger.info(
                f"[{self.source_name}] 🎉 Extraction complete! "
                f"{len(gdrive_links)} Google Drive links, "
                f"{len(embed_urls)} embed links"
            )

        except Exception as e:
            logger.error(f"[{self.source_name}] Link extraction error: {e}")

        return result

    # =========================================================================
    # STEP 4: MEDIATOR RESOLUTION (HTTP)
    # =========================================================================

    async def _resolve_mediators(self, mediator_urls: List[Dict]) -> List[Dict]:
        """
        Follow mediator pages (howblogs.xyz) via HTTP to extract
        intermediate host URLs (hubdrive, gdflix, hubcloud, etc.)
        """
        all_intermediate = []
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
                all_intermediate.extend(result)
            elif isinstance(result, Exception):
                logger.error(f"[{self.source_name}] Mediator error: {result}")

        # Deduplicate by URL
        seen = set()
        unique = []
        for link in all_intermediate:
            url_key = link['url'].split('?')[0]
            if url_key not in seen:
                seen.add(url_key)
                unique.append(link)

        return unique

    async def _fetch_mediator_page(self, mediator_url: str,
                                     button_text: str) -> List[Dict]:
        """
        Fetch a mediator page (howblogs.xyz/375923) and extract
        intermediate host URLs from content.
        """
        links = []

        try:
            logger.info(f"[{self.source_name}] 🌐 Fetching mediator: {mediator_url}")

            async with httpx.AsyncClient(
                headers={"User-Agent": USER_AGENT},
                timeout=15.0,
                follow_redirects=True
            ) as client:
                resp = await client.get(mediator_url)
                if resp.status_code != 200:
                    return links
                content = resp.text

            soup = BeautifulSoup(content, 'html.parser')

            # Build regex to match intermediate host URLs
            all_host_domains = []
            for domains in INTERMEDIATE_HOSTS.values():
                all_host_domains.extend(domains)

            # Also add Google Drive domains (sometimes they're direct on mediator)
            host_pattern = re.compile(
                r'https?://[^\s"\'<>\]]*(?:' +
                '|'.join(re.escape(h) for h in all_host_domains) +
                r'|' + '|'.join(GDRIVE_PATTERNS) +
                r')[^\s"\'<>\]]*',
                re.IGNORECASE
            )

            found_urls = set()

            # Method 1: Find in <a> tags
            for a in soup.find_all('a', href=True):
                href = a.get('href', '')
                if host_pattern.match(href):
                    found_urls.add(href)

            # Method 2: Find in raw text (common for howblogs.xyz)
            text_content = soup.get_text()
            for match in host_pattern.finditer(text_content):
                url = match.group(0).rstrip('.')
                found_urls.add(url)

            # Method 3: Find in page source (JS-embedded)
            for match in host_pattern.finditer(content):
                url = match.group(0).rstrip('.')
                found_urls.add(url)

            # Build intermediate link objects
            for url in found_urls:
                host_type = self._identify_host(url)
                quality = self._extract_quality(button_text)

                links.append({
                    'url': url,
                    'host_type': host_type or 'unknown',
                    'quality': quality,
                    'text': button_text,
                    'source': self.source_name,
                })

            logger.info(
                f"[{self.source_name}] Mediator '{button_text}' → "
                f"{len(links)} intermediate links"
            )

        except Exception as e:
            logger.error(f"[{self.source_name}] Mediator fetch error: {e}")

        return links

    # =========================================================================
    # STEPS 5-6: GOOGLE DRIVE EXTRACTION FROM INTERMEDIATE HOSTS (Playwright)
    # =========================================================================

    async def _extract_gdrive_from_intermediates(self, intermediate_links: List[Dict]) -> List[Dict]:
        """
        Convert intermediate host links into download links.

        FAST PATH: Returns intermediate URLs directly as download links
        (HubDrive, HubCloud, GoFile, etc.) without Playwright resolution.
        Resolution happens at download time via /api/resolve-download-link.

        Only Google Drive URLs that are already direct are resolved inline.
        """
        download_links = []

        for link in intermediate_links:
            url = link.get('url', '')
            host_type = link.get('host_type', 'unknown')
            quality = link.get('quality', 'HD')

            if not url:
                continue

            # If it's already a Google Drive URL, return as-is
            if self._is_gdrive_url(url):
                download_links.append({
                    'url': url,
                    'quality': quality,
                    'source_host': 'gdrive',
                    'original_url': url,
                    'name': f'Google Drive - {quality}',
                    'type': 'Google Drive',
                    'source': self.source_name,
                })
                logger.info(f"[{self.source_name}] ✅ Direct GDrive: {url[:80]}")
                continue

            # For all other hosts — return the intermediate URL directly.
            # The Flutter app will resolve it at download time.
            host_label = host_type.replace('_', ' ').title()
            download_links.append({
                'url': url,
                'quality': quality,
                'source_host': host_type,
                'original_url': url,
                'name': f'{host_label} - {quality}',
                'type': host_label,
                'source': self.source_name,
                'needs_resolution': True,  # Flag for the Flutter app
            })
            logger.info(
                f"[{self.source_name}] 📎 Intermediate link ({host_type}): {url[:80]}"
            )

        logger.info(
            f"[{self.source_name}] 📊 Returning {len(download_links)} download links "
            f"(fast path — no Playwright resolution)"
        )
        return download_links

    async def _extract_gdrive_from_page(self, intermediate_link: Dict) -> Optional[Dict]:
        """
        Extract Google Drive URL from a single intermediate host page.

        Multi-method approach:
          Method 1: Direct <a> links to drive.google.com
          Method 2: Click download button → wait for timer → extract URL
          Method 3: Check iframes
          Method 4: Regex search in page content
        """
        url = intermediate_link['url']
        host_type = intermediate_link.get('host_type', 'unknown')
        quality = intermediate_link.get('quality', 'HD')

        # --- If it's already a Google Drive URL, return directly ---
        if self._is_gdrive_url(url):
            logger.info(f"[{self.source_name}] ✅ Already a Google Drive URL: {url}")
            return {
                'url': url,
                'quality': quality,
                'source_host': 'direct',
                'original_url': url,
                'name': f'Google Drive - {quality}',
                'type': 'Google Drive',
                'source': self.source_name,
            }

        # --- Use DownloadLinkResolver if available (for hubdrive/hubcloud/gofile) ---
        if self._download_resolver and host_type in ('hubdrive', 'hubcloud', 'gofile'):
            try:
                logger.info(
                    f"[{self.source_name}] 🖱️ Using DownloadLinkResolver for {host_type}: {url}"
                )
                result = await asyncio.wait_for(
                    self._download_resolver.resolve_download_link(url),
                    timeout=40  # Fail fast — don't block other links
                )
                if result.get('success') and result.get('direct_url'):
                    direct_url = result['direct_url']
                    logger.info(
                        f"[{self.source_name}] ✅ Resolved {host_type} → {direct_url[:80]}..."
                    )
                    return {
                        'url': direct_url,
                        'quality': quality,
                        'source_host': host_type,
                        'original_url': url,
                        'name': f'{host_type.title()} - {quality}',
                        'type': 'Google Drive',
                        'source': self.source_name,
                        'filename': result.get('filename'),
                        'filesize': result.get('filesize'),
                    }
                else:
                    logger.warning(
                        f"[{self.source_name}] ❌ Resolver failed for {host_type}: "
                        f"{result.get('error')}"
                    )
            except asyncio.TimeoutError:
                logger.error(f"[{self.source_name}] ⏱️ Resolver timeout for {host_type}")
            except Exception as e:
                logger.error(f"[{self.source_name}] Resolver error: {e}")

        # --- Fallback: Use browser to visit the page and extract GDrive link ---
        if not self.browser:
            logger.warning(f"[{self.source_name}] No browser available for fallback")
            return None

        context = None
        page = None

        try:
            logger.info(
                f"[{self.source_name}] 🌐 Fallback browser extraction for: {url}"
            )

            context = await self.browser.new_context(user_agent=USER_AGENT)
            page = await context.new_page()
            await stealth_async(page)

            # Navigate to intermediate page
            await page.goto(url, wait_until='domcontentloaded', timeout=20000)
            await asyncio.sleep(2)

            # --- Method 1: Direct links to drive.google.com ---
            gdrive_url = await self._find_gdrive_direct_links(page)
            if gdrive_url:
                logger.info(f"[{self.source_name}] ✅ Method 1 (direct link): {gdrive_url[:80]}")
                return self._build_gdrive_result(gdrive_url, quality, host_type, url)

            # --- Method 2: Click download button → wait → extract ---
            gdrive_url = await self._click_and_extract(page)
            if gdrive_url:
                logger.info(f"[{self.source_name}] ✅ Method 2 (button click): {gdrive_url[:80]}")
                return self._build_gdrive_result(gdrive_url, quality, host_type, url)

            # --- Method 3: Check iframes ---
            gdrive_url = await self._check_iframes(page)
            if gdrive_url:
                logger.info(f"[{self.source_name}] ✅ Method 3 (iframe): {gdrive_url[:80]}")
                return self._build_gdrive_result(gdrive_url, quality, host_type, url)

            # --- Method 4: Regex search in page content ---
            gdrive_url = await self._regex_search_content(page)
            if gdrive_url:
                logger.info(f"[{self.source_name}] ✅ Method 4 (regex): {gdrive_url[:80]}")
                return self._build_gdrive_result(gdrive_url, quality, host_type, url)

            logger.warning(
                f"[{self.source_name}] ❌ No Google Drive link found at {url}"
            )
            return None

        except Exception as e:
            logger.error(f"[{self.source_name}] Browser extraction error: {e}")
            return None

        finally:
            if page:
                await page.close()
            if context:
                await context.close()

    # =========================================================================
    # GOOGLE DRIVE EXTRACTION METHODS (for fallback browser approach)
    # =========================================================================

    async def _find_gdrive_direct_links(self, page: Page) -> Optional[str]:
        """Method 1: Find direct <a> links to Google Drive."""
        selectors = [
            'a[href*="drive.google.com"]',
            'a[href*="docs.google.com"]',
        ]
        for sel in selectors:
            try:
                elements = await page.query_selector_all(sel)
                for el in elements:
                    href = await el.get_attribute('href')
                    if href and self._is_gdrive_url(href):
                        return href
            except Exception:
                continue
        return None

    async def _click_and_extract(self, page: Page) -> Optional[str]:
        """Method 2: Click download button, wait for timer, extract URL."""
        # Try clicking download buttons
        button_selectors = [
            'a:has-text("Download")',
            'button:has-text("Download")',
            'a:has-text("Get Link")',
            'a:has-text("Direct")',
            'button:has-text("Direct")',
            'button:has-text("Instant")',
            'a.btn-download', '.download-btn', '#download-button',
        ]

        clicked = False
        for sel in button_selectors:
            try:
                await page.wait_for_selector(sel, timeout=3000)
                await page.click(sel)
                logger.info(f"[{self.source_name}] 🖱️ Clicked: {sel}")
                clicked = True
                break
            except PlaywrightTimeout:
                continue
            except Exception:
                continue

        if not clicked:
            # JS fallback click
            try:
                await page.evaluate("""
                    () => {
                        const btns = Array.from(document.querySelectorAll('button, a'));
                        const btn = btns.find(b =>
                            b.textContent.toLowerCase().includes('download') ||
                            b.textContent.toLowerCase().includes('direct') ||
                            b.textContent.toLowerCase().includes('get link')
                        );
                        if (btn) btn.click();
                    }
                """)
                clicked = True
            except Exception:
                pass

        if not clicked:
            return None

        # Wait for countdown timer
        await asyncio.sleep(3)

        countdown_selectors = [
            '#countdown', '.countdown', '.timer',
            'span:has-text("seconds")', 'span:has-text("sec")',
            'div:has-text("wait")', 'div:has-text("please wait")',
            '#timer', '.count-down',
        ]
        countdown_found = False
        for sel in countdown_selectors:
            try:
                await page.wait_for_selector(sel, timeout=3000)
                countdown_found = True
                break
            except PlaywrightTimeout:
                continue

        if countdown_found:
            # Wait for countdown to finish (max 60s)
            for i in range(60):
                await asyncio.sleep(1)
                try:
                    final_btn = await page.query_selector(
                        'a:has-text("Download Here"), button:has-text("Download Here")'
                    )
                    if final_btn:
                        logger.info(f"[{self.source_name}] ⏱️ Countdown finished after {i+1}s")
                        break
                except Exception:
                    continue
        else:
            await asyncio.sleep(5)

        # Check if current URL is Google Drive
        current_url = page.url
        if self._is_gdrive_url(current_url):
            return current_url

        # Look for Google Drive links on current page
        gdrive_url = await self._find_gdrive_direct_links(page)
        if gdrive_url:
            return gdrive_url

        # Try clicking "Download Here" button
        try:
            dl_here = await page.query_selector(
                'a:has-text("Download Here"), button:has-text("Download Here")'
            )
            if dl_here:
                href = await dl_here.get_attribute('href')
                if href and self._is_gdrive_url(href):
                    return href
                # Click and check
                await dl_here.click()
                await asyncio.sleep(3)
                if self._is_gdrive_url(page.url):
                    return page.url
                return await self._find_gdrive_direct_links(page)
        except Exception:
            pass

        return None

    async def _check_iframes(self, page: Page) -> Optional[str]:
        """Method 3: Check iframes for Google Drive URLs."""
        try:
            iframes = await page.query_selector_all('iframe[src]')
            for iframe in iframes:
                src = await iframe.get_attribute('src')
                if src and self._is_gdrive_url(src):
                    return src
        except Exception:
            pass
        return None

    async def _regex_search_content(self, page: Page) -> Optional[str]:
        """Method 4: Regex search page content for Google Drive URLs."""
        try:
            content = await page.content()
            pattern = re.compile(
                r'https://(?:drive|docs)\.google\.com/[^\s"\'<>\)]+',
                re.IGNORECASE
            )
            matches = pattern.findall(content)
            if matches:
                # Return the first valid one
                for match in matches:
                    # Clean up trailing characters
                    match = match.rstrip('.,;:')
                    if '/file/d/' in match or '/uc?' in match:
                        return match
                return matches[0].rstrip('.,;:')
        except Exception:
            pass
        return None

    # =========================================================================
    # HELPERS
    # =========================================================================

    def _build_gdrive_result(self, gdrive_url: str, quality: str,
                              host_type: str, original_url: str) -> Dict:
        """Build a standardized Google Drive link result."""
        return {
            'url': gdrive_url,
            'quality': quality,
            'source_host': host_type,
            'original_url': original_url,
            'name': f'Google Drive - {quality}',
            'type': 'Google Drive',
            'source': self.source_name,
        }

    def _is_gdrive_url(self, url: str) -> bool:
        """Check if URL is a Google Drive URL."""
        url_lower = url.lower()
        return 'drive.google.com' in url_lower or 'docs.google.com' in url_lower

    def _is_mediator_link(self, url: str) -> bool:
        """Check if URL points to a known mediator/shortener host."""
        url_lower = url.lower()
        return any(host in url_lower for host in MEDIATOR_HOSTS)

    def _is_embed_link(self, url: str) -> bool:
        """Check if URL points to a known streaming embed host."""
        url_lower = url.lower()
        return any(host in url_lower for host in EMBED_HOSTS)

    def _is_intermediate_link(self, url: str) -> bool:
        """Check if URL points to a known intermediate file host."""
        return self._identify_host(url) is not None

    def _identify_host(self, url: str) -> Optional[str]:
        """Identify which intermediate host type a URL belongs to."""
        url_lower = url.lower()
        for host_type, domains in INTERMEDIATE_HOSTS.items():
            for domain in domains:
                if domain in url_lower:
                    return host_type
        # Also check if it's a direct Google Drive link
        if self._is_gdrive_url(url):
            return 'gdrive'
        return None
