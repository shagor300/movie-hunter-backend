"""
Embed Link Extractor - Extract streaming/embed links from movie pages.

Separate from download links — these are for in-app video playback.
Finds iframe sources, embed player URLs, and streaming links.
"""

import re
import logging
from bs4 import BeautifulSoup
from typing import List, Dict, Optional
from playwright.async_api import Page

logger = logging.getLogger(__name__)

# Known embed/streaming host patterns
EMBED_HOST_PATTERNS = [
    'hdstream4u.com/file/',
    'vidsrc',
    'embedstream',
    'streamtape',
    'doodstream',
    'mixdrop',
    'upstream',
    'vidcloud',
    'filemoon',
    'streamwish',
    'vidhide',
    'embedsb',
    'sbembed',
    '/embed/',
    '/player/',
    '/e/',
]

# URLs to skip
SKIP_PATTERNS = [
    'javascript:', 'mailto:', '#', 'facebook.com', 'twitter.com',
    'instagram.com', 'google.com/recaptcha', 'cdn-cgi',
]


class EmbedLinkExtractor:
    # User-friendly name mappings for embed players
    BEAUTIFUL_NAMES = {
        1: "⚡ Instant Play (Recommended)",
        2: "🚀 High Speed Player",
        3: "📺 Standard Player",
        4: "🔄 Backup Player",
        5: "⭐ Premium Player",
    }

    SPEED_INDICATORS = {
        1: "fastest",
        2: "fast",
        3: "medium",
    }

    def _is_embed_url(self, url: str) -> bool:
        """Check if a URL matches known embed/streaming patterns."""
        url_lower = url.lower()
        if any(skip in url_lower for skip in SKIP_PATTERNS):
            return False
        return any(pattern in url_lower for pattern in EMBED_HOST_PATTERNS)

    def _extract_quality(self, text: str) -> str:
        """Extract video quality from surrounding text."""
        match = re.search(r'(480p|720p|1080p|2160p|4K|HD|FHD|UHD)', text, re.I)
        return match.group(1).upper() if match else 'HD'

    def _extract_player_name(self, url: str, text: str = '') -> str:
        """Determine player name from URL or text."""
        url_lower = url.lower()
        player_map = {
            'vidsrc': 'VidSrc',
            'streamtape': 'StreamTape',
            'doodstream': 'DoodStream',
            'mixdrop': 'MixDrop',
            'filemoon': 'FileMoon',
            'streamwish': 'StreamWish',
            'vidhide': 'VidHide',
            'hdstream4u': 'HDStream4u',
            'upstream': 'UpStream',
            'vidcloud': 'VidCloud',
        }
        for key, name in player_map.items():
            if key in url_lower:
                return name

        # Check for player number in text
        match = re.search(r'player[-\s]*(\d+)', text, re.I)
        if match:
            return f"Player-{match.group(1)}"
        return 'Embedded Player'

    def _beautify_links(self, embed_links: list) -> list:
        """Post-process embed links with beautiful names, speed indicators, and recommendation flags."""
        for i, link in enumerate(embed_links):
            player_number = i + 1
            link['name'] = self.BEAUTIFUL_NAMES.get(player_number, f"🎬 Player {player_number}")
            link['display_name'] = f"{link['name']} - {link.get('quality', 'HD')}"
            link['speed_indicator'] = self.SPEED_INDICATORS.get(player_number, 'backup')
            link['player_number'] = player_number
            link['is_recommended'] = player_number == 1
        return embed_links

    def extract_from_html(self, html: str, page_url: str) -> List[Dict]:
        """
        Extract embed links from HTML content.
        
        Returns list of dicts with keys: url, quality, player, type, name, speed_indicator, is_recommended
        """
        soup = BeautifulSoup(html, 'html.parser')
        embed_links = []
        seen_urls = set()

        # --- Method 1: Find iframe sources ---
        for iframe in soup.find_all('iframe', src=True):
            src = iframe.get('src', '').strip()
            if not src or src in seen_urls:
                continue
            if self._is_embed_url(src):
                seen_urls.add(src)
                embed_links.append({
                    'url': src if src.startswith('http') else f'https:{src}',
                    'quality': self._extract_quality(str(iframe.parent)),
                    'player': self._extract_player_name(src),
                    'type': 'embed',
                })

        # --- Method 2: Find links in "Watch Online" or "Embed" sections ---
        for heading in soup.find_all(['h2', 'h3', 'h4', 'p', 'strong']):
            heading_text = heading.get_text(strip=True).lower()
            if not any(kw in heading_text for kw in ['watch', 'stream', 'embed', 'player', 'online']):
                continue

            # Search siblings and parent for links
            container = heading.parent or heading
            for link in container.find_all('a', href=True):
                href = link['href'].strip()
                if not href or href in seen_urls:
                    continue
                if self._is_embed_url(href):
                    text = link.get_text(strip=True)
                    seen_urls.add(href)
                    embed_links.append({
                        'url': href,
                        'quality': self._extract_quality(text),
                        'player': self._extract_player_name(href, text),
                        'type': 'embed',
                    })

        # --- Method 3: Scan ALL links for embed patterns ---
        for link in soup.find_all('a', href=True):
            href = link['href'].strip()
            if not href or href in seen_urls:
                continue
            text = link.get_text(strip=True).lower()
            # Skip explicit download links
            if any(kw in text for kw in ['download', 'direct download', 'instant']):
                continue
            if self._is_embed_url(href):
                full_text = link.get_text(strip=True)
                seen_urls.add(href)
                embed_links.append({
                    'url': href,
                    'quality': self._extract_quality(full_text),
                    'player': self._extract_player_name(href, full_text),
                    'type': 'embed',
                })

        # Assign beautiful names and metadata
        embed_links = self._beautify_links(embed_links)

        logger.info(f"Found {len(embed_links)} embed links from {page_url}")
        return embed_links

    async def extract_from_page(self, page: Page, url: str) -> List[Dict]:
        """
        Extract embed links from an already-loaded Playwright page.
        Falls back to raw HTML parsing.
        """
        try:
            content = await page.content()
            return self.extract_from_html(content, url)
        except Exception as e:
            logger.error(f"Embed extraction error: {e}")
            return []
