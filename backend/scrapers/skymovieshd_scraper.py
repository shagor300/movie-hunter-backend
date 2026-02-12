"""
SkyMoviesHD Scraper — extracts movies and Google Drive links from SkyMoviesHD.
Shares browser instance with the main MovieScraper for resource efficiency.
"""

import asyncio
import re
from bs4 import BeautifulSoup
from playwright.async_api import Page
from playwright_stealth import stealth_async
from typing import List, Dict
import logging

from .base_scraper import BaseMovieScraper

logger = logging.getLogger(__name__)

# Common user agent
USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"


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
    # SEARCH
    # =========================================================================

    async def search_movies(self, query: str, max_results: int = 20) -> List[Dict]:
        """
        Search for movies on SkyMoviesHD.
        1. Navigate to search URL
        2. Parse search results
        3. Clean titles, extract year/quality
        4. Match with TMDB
        """
        context, page = await self._new_stealth_page()
        movies = []

        try:
            logger.info(f"[{self.source_name}] Searching for: {query}")

            search_url = f"{self.base_url}/?s={query.replace(' ', '+')}"
            success = await self._navigate_safe(page, search_url)
            if not success:
                return movies

            await asyncio.sleep(3)

            content = await page.content()
            soup = BeautifulSoup(content, 'html.parser')

            # Find movie posts
            posts = soup.find_all(
                ['article', 'div'],
                class_=re.compile(r'post|item|movie|entry', re.I)
            )
            logger.info(f"[{self.source_name}] Found {len(posts)} posts")

            for post in posts[:max_results]:
                try:
                    movie_data = self._parse_search_result(post)
                    if not movie_data:
                        continue

                    raw_title = movie_data['title']
                    movie_url = movie_data['url']
                    poster_url = movie_data.get('poster')

                    # Clean title and extract year
                    clean_title, year = self._clean_title(raw_title)
                    quality = self._extract_quality(raw_title)

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
                            'poster': tmdb_data['poster_url'] or poster_url,
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
                            'poster': poster_url,
                        })

                except Exception as e:
                    logger.error(f"[{self.source_name}] Error parsing post: {e}")
                    continue

            logger.info(
                f"[{self.source_name}] Extracted {len(movies)} movies"
            )

        except Exception as e:
            logger.error(f"[{self.source_name}] Search error: {e}")
        finally:
            await page.close()
            await context.close()

        return movies

    def _parse_search_result(self, post) -> dict | None:
        """Extract title, URL, and poster from a search result element."""
        # Find title element
        title_elem = post.find(
            ['h2', 'h3', 'a'],
            class_=re.compile(r'title|entry-title', re.I)
        )
        if not title_elem:
            title_elem = post.find('a', href=True)
        if not title_elem:
            return None

        raw_title = title_elem.get_text(strip=True)
        if not raw_title or len(raw_title) < 3:
            return None

        # Find URL
        movie_url = None
        if title_elem.name == 'a':
            movie_url = title_elem.get('href')
        else:
            link = post.find('a', href=True)
            if link:
                movie_url = link['href']

        if not movie_url:
            return None

        # Find poster
        poster_elem = post.find('img', src=True)
        poster_url = poster_elem['src'] if poster_elem else None

        return {'title': raw_title, 'url': movie_url, 'poster': poster_url}

    # =========================================================================
    # LINK EXTRACTION
    # =========================================================================

    async def extract_links(self, movie_url: str) -> Dict:
        """
        Extract Google Drive links from a SkyMoviesHD movie page.
        1. Navigate to movie page
        2. Scroll to load all content
        3. Find Google Drive links via 3 methods
        4. Resolve shortener links
        """
        context, page = await self._new_stealth_page()

        result = {
            'links': [],
            'embed_links': [],
        }

        try:
            logger.info(f"[{self.source_name}] Extracting links from: {movie_url}")

            success = await self._navigate_safe(page, movie_url)
            if not success:
                return result

            await asyncio.sleep(3)

            # Scroll to load lazy content
            for _ in range(3):
                await page.evaluate('window.scrollBy(0, window.innerHeight)')
                await asyncio.sleep(1)

            content = await page.content()
            soup = BeautifulSoup(content, 'html.parser')

            found_links = []

            # --- Method 1: Find "Google Drive" section headers ---
            gdrive_headers = soup.find_all(
                string=re.compile(r'Google\s*Drive|G-?Drive|Download\s*Links', re.I)
            )
            for header in gdrive_headers:
                parent = header.find_parent()
                if not parent:
                    continue
                section = parent.find_next_sibling()
                if not section:
                    section = parent.find_parent()
                    if section:
                        section = section.find_next_sibling()
                if section:
                    for link in section.find_all('a', href=True):
                        self._collect_drive_link(link, found_links)

            # --- Method 2: Buttons with "Google Drive" text ---
            gdrive_buttons = soup.find_all(
                ['a', 'button'],
                string=re.compile(r'Google.*Drive|G-?Drive', re.I)
            )
            for button in gdrive_buttons:
                href = button.get('href')
                if href:
                    self._collect_drive_link(button, found_links)

            # --- Method 3: All links on page matching Drive patterns ---
            for link in soup.find_all('a', href=True):
                self._collect_drive_link(link, found_links)

            # Resolve shortener links
            found_links = await self._resolve_shorteners(found_links, page)

            result['links'] = found_links

            logger.info(
                f"[{self.source_name}] Found {len(found_links)} download links"
            )

        except Exception as e:
            logger.error(f"[{self.source_name}] Link extraction error: {e}")
        finally:
            await page.close()
            await context.close()

        return result

    def _collect_drive_link(self, link_elem, found_links: list):
        """Add a Drive-compatible link to found_links if not duplicate."""
        href = link_elem.get('href', '')
        if not href or not self._is_drive_link(href):
            return

        # Skip duplicates
        if any(l['url'] == href for l in found_links):
            return

        text = link_elem.get_text(strip=True)
        quality = self._extract_quality(text) if text else 'HD'

        found_links.append({
            'name': f"Google Drive - {quality}",
            'url': href,
            'quality': quality,
            'type': 'Google Drive',
            'source': self.source_name,
        })

    def _is_drive_link(self, url: str) -> bool:
        """Check if URL is a Google Drive link or known shortener."""
        patterns = [
            'drive.google.com',
            'docs.google.com',
            'gdrive',
            'gdtot',
            'hubdrive',
            'hubcloud',
        ]
        return any(p in url.lower() for p in patterns)

    async def _resolve_shorteners(self, links: List[Dict],
                                   page: Page) -> List[Dict]:
        """Resolve shortener links to final Google Drive URLs."""
        resolved = []

        for link in links:
            url = link['url']

            # Already a direct Drive link
            if 'drive.google.com/file/' in url or 'drive.google.com/uc' in url:
                resolved.append(link)
                continue

            # Try to follow the redirect
            try:
                logger.info(f"[{self.source_name}] Resolving shortener: {url}")
                await page.goto(url, wait_until='domcontentloaded', timeout=15000)
                await asyncio.sleep(2)

                current_url = page.url
                if 'drive.google.com' in current_url:
                    link['url'] = current_url
                    resolved.append(link)
                    logger.info(f"[{self.source_name}] Resolved to: {current_url}")
                else:
                    # Look for Drive link in the intermediate page
                    content = await page.content()
                    soup = BeautifulSoup(content, 'html.parser')
                    drive_link = soup.find(
                        'a', href=re.compile(r'drive\.google\.com')
                    )
                    if drive_link:
                        link['url'] = drive_link['href']
                        resolved.append(link)
                    else:
                        # Keep original
                        resolved.append(link)
                        logger.warning(
                            f"[{self.source_name}] Could not resolve: {url}"
                        )

            except Exception as e:
                logger.error(f"[{self.source_name}] Resolve error for {url}: {e}")
                resolved.append(link)

        return resolved
