"""
FTP Handler — Lightweight HTTP-based integration for ftp.ctgfun.com.

Browses and searches movie folders via HTTP directory listings (Apache index
pages), then generates direct HTTP links for streaming/downloading.

Uses httpx + BeautifulSoup instead of ftplib — works even when FTP port 21
is blocked (e.g. on Render free-tier hosting).
"""

import hashlib
import logging
import re
from typing import Dict, List, Optional, Tuple
from urllib.parse import quote, unquote, urljoin

import httpx
from bs4 import BeautifulSoup

logger = logging.getLogger(__name__)

# Shared HTTP client (connection pooling, timeouts)
_http_client: Optional[httpx.Client] = None


def _get_client(timeout: int = 10) -> httpx.Client:
    """Lazy-init a shared httpx client."""
    global _http_client
    if _http_client is None or _http_client.is_closed:
        _http_client = httpx.Client(
            timeout=timeout,
            follow_redirects=True,
            headers={
                "User-Agent": (
                    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                    "AppleWebKit/537.36 (KHTML, like Gecko) "
                    "Chrome/120.0.0.0 Safari/537.36"
                )
            },
        )
    return _http_client


class FTPMovieHandler:
    """Search and browse movies on an FTP server via HTTP directory listings."""

    def __init__(
        self,
        host: str = "ftp.ctgfun.com",
        user: str = "anonymous",
        password: str = "",
        timeout: int = 10,
    ):
        self.host = host
        self.timeout = timeout
        self.base_url = f"http://{host}"

        # Directories to search (order matters — searched first to last)
        self.search_dirs = [
            "/English",
            "/Indian/Hindi Movies",
            "/TV_Series",
        ]

        # Cache parsed directory listings for the duration of a search
        self._dir_cache: Dict[str, List[Tuple[str, str, str]]] = {}

    # ------------------------------------------------------------------
    # Public API  (same signatures as the old ftplib version)
    # ------------------------------------------------------------------

    def search(self, query: str, limit: int = 20) -> List[Dict]:
        """
        Search for movies/series in the FTP server via HTTP.

        Returns a list of dicts with clean metadata (no FTP paths exposed).
        """
        query = query.lower().strip()
        if not query:
            return []

        results: List[Dict] = []

        for directory in self.search_dirs:
            try:
                items = self._list_directory(directory)

                for name, _date, _size in items:
                    if self._matches(query, name):
                        movie = self._parse_folder(name, directory)
                        if movie:
                            results.append(movie)
                        if len(results) >= limit:
                            break

                if len(results) >= limit:
                    break
            except Exception as exc:
                logger.warning("HTTP directory search error in %s: %s", directory, exc)
                continue

        # Clear per-search cache
        self._dir_cache.clear()
        return results

    def get_playable_links(
        self,
        internal_folder: str,
        internal_directory: str,
    ) -> Dict:
        """
        Get video + subtitle links from a specific FTP folder via HTTP.

        Returns direct HTTP links (``http://host/path/file.ext``) that can
        be streamed or downloaded without any intermediate resolution.
        """
        try:
            folder_path = f"{internal_directory}/{internal_folder}"

            # Try listing files in the folder directly
            items = self._list_directory(folder_path)

            videos: List[Dict] = []
            subtitles: List[Dict] = []

            # Check if items are sub-folders (e.g. season folders)
            # If so, we need to go one level deeper
            sub_folders = [
                (name, date, size) for name, date, size in items
                if name.endswith("/") and name != "../"
            ]

            if sub_folders and not any(
                self._is_video(name) for name, _d, _s in items
            ):
                # Items are all sub-folders — recurse one level into each
                for sub_name, _date, _size in sub_folders:
                    sub_path = f"{folder_path}/{sub_name.rstrip('/')}"
                    try:
                        sub_items = self._list_directory(sub_path)
                        for name, _d, size_str in sub_items:
                            clean_name = name.rstrip("/")
                            if self._is_video(clean_name):
                                quality = self._extract_quality(clean_name)
                                display = self._clean_filename(clean_name)
                                url = f"{self.base_url}{sub_path}/{quote(clean_name)}"
                                size = self._parse_size_str(size_str)
                                episode = self._extract_episode_info(clean_name)
                                link_name = f"{episode} — {quality}" if episode else f"{display} — {quality}"

                                videos.append({
                                    "name": link_name,
                                    "url": url,
                                    "quality": quality,
                                    "size": size,
                                    "size_label": _format_size(size) if size else size_str,
                                    "source": "Premium",
                                    "type": "direct",
                                    "episode": episode,
                                })
                            elif clean_name.lower().endswith(".srt"):
                                subtitles.append({
                                    "filename": clean_name,
                                    "url": f"{self.base_url}{sub_path}/{quote(clean_name)}",
                                })
                    except Exception as exc:
                        logger.debug("Sub-folder listing error %s: %s", sub_path, exc)
                        continue
            else:
                # Items are files — process directly
                for name, _date, size_str in items:
                    clean_name = name.rstrip("/")
                    if clean_name == ".." or clean_name == "../":
                        continue

                    if self._is_video(clean_name):
                        quality = self._extract_quality(clean_name)
                        display = self._clean_filename(clean_name)
                        url = f"{self.base_url}{folder_path}/{quote(clean_name)}"
                        size = self._parse_size_str(size_str)
                        episode = self._extract_episode_info(clean_name)
                        link_name = f"{episode} — {quality}" if episode else f"{display} — {quality}"

                        videos.append({
                            "name": link_name,
                            "url": url,
                            "quality": quality,
                            "size": size,
                            "size_label": _format_size(size) if size else size_str,
                            "source": "Premium",
                            "type": "direct",
                            "episode": episode,
                        })
                    elif clean_name.lower().endswith(".srt"):
                        subtitles.append({
                            "filename": clean_name,
                            "url": f"{self.base_url}{folder_path}/{quote(clean_name)}",
                        })

            self._dir_cache.clear()

            return {
                "success": True,
                "links": videos,
                "subtitles": subtitles,
            }

        except Exception as exc:
            logger.error("HTTP get_playable_links error: %s", exc)
            return {"success": False, "links": [], "subtitles": []}

    def browse_latest(self, directory: str = "/English", limit: int = 30) -> List[Dict]:
        """
        Browse the latest entries in a given directory via HTTP.

        Returns a list of parsed movie dicts (most recent first, sorted by
        the modification date from the directory listing).
        """
        results: List[Dict] = []

        try:
            items = self._list_directory(directory)

            # Sort by date descending (most recent first)
            # Date format from Apache: "DD-Mon-YYYY HH:MM"
            items_sorted = sorted(items, key=lambda x: x[1], reverse=True)

            for name, _date, _size in items_sorted:
                if name == "../" or name == "..":
                    continue
                movie = self._parse_folder(name.rstrip("/"), directory)
                if movie:
                    results.append(movie)
                if len(results) >= limit:
                    break

            self._dir_cache.clear()

        except Exception as exc:
            logger.error("HTTP browse error: %s", exc)

        return results

    def check_connectivity(self) -> bool:
        """Quick connectivity check — returns True if the HTTP server is reachable."""
        try:
            client = _get_client(timeout=5)
            resp = client.head(self.base_url, timeout=5)
            return resp.status_code < 500
        except Exception:
            return False

    # ------------------------------------------------------------------
    # HTTP directory listing parser
    # ------------------------------------------------------------------

    def _list_directory(self, directory: str) -> List[Tuple[str, str, str]]:
        """
        Fetch and parse an Apache-style HTML directory listing.

        Returns list of (name, date_string, size_string) tuples.
        Uses a per-search cache to avoid re-fetching.
        """
        if directory in self._dir_cache:
            return self._dir_cache[directory]

        url = f"{self.base_url}{directory}/"
        # Normalize double slashes
        url = url.replace("//", "/").replace("http:/", "http://")

        client = _get_client(timeout=self.timeout)
        resp = client.get(url)
        resp.raise_for_status()

        items = self._parse_apache_listing(resp.text, url)
        self._dir_cache[directory] = items
        return items

    def _parse_apache_listing(
        self, html: str, base_url: str
    ) -> List[Tuple[str, str, str]]:
        """
        Parse Apache mod_autoindex HTML.

        Handles both <pre>-based and <table>-based index formats.
        Returns list of (name, date, size) tuples.
        """
        items: List[Tuple[str, str, str]] = []
        soup = BeautifulSoup(html, "html.parser")

        # Strategy 1: <pre> block with <a> tags (most common for Apache FTP)
        pre = soup.find("pre")
        if pre:
            for a_tag in pre.find_all("a"):
                # IMPORTANT: Use href to get the full name — Apache truncates
                # long names in display text (shows "..>" at the end).
                href = a_tag.get("href", "")
                if not href or href.startswith("?") or href.startswith("#"):
                    continue
                # Decode the href to get the real folder/file name
                name = unquote(href.split("?")[0])
                # Strip leading path components — keep only the last segment
                name = name.rstrip("/").rsplit("/", 1)[-1]
                if not name:
                    continue
                # Re-add trailing slash if original href had it (= directory)
                if href.endswith("/"):
                    name += "/"

                if name in ("../", "..", ".", "/"):
                    continue

                # The text after the <a> tag contains date + size
                # Format: "DD-Mon-YYYY HH:MM    SIZE"
                next_text = a_tag.next_sibling
                date_str = ""
                size_str = ""
                if next_text and isinstance(next_text, str):
                    parts = next_text.strip().split()
                    if len(parts) >= 2:
                        date_str = f"{parts[0]} {parts[1]}"
                    if len(parts) >= 3:
                        size_str = parts[2]

                items.append((name, date_str, size_str))
            return items

        # Strategy 2: <table>-based (some Apache configs)
        table = soup.find("table")
        if table:
            for row in table.find_all("tr"):
                cells = row.find_all("td")
                if len(cells) < 3:
                    continue
                a_tag = cells[0].find("a")
                if not a_tag:
                    continue
                name = unquote(a_tag.get_text(strip=True))
                if not name or name in ("Name", "Parent Directory", "../"):
                    continue
                date_str = cells[1].get_text(strip=True)
                size_str = cells[2].get_text(strip=True)
                items.append((name, date_str, size_str))
            return items

        # Strategy 3: Just find all <a> tags as fallback
        for a_tag in soup.find_all("a", href=True):
            href = a_tag["href"]
            name = unquote(a_tag.get_text(strip=True))
            if not name or name in ("../", "..", "Parent Directory"):
                continue
            if href.startswith("?") or href.startswith("#"):
                continue
            items.append((name, "", ""))

        return items

    # ------------------------------------------------------------------
    # Internal helpers  (unchanged from original)
    # ------------------------------------------------------------------

    def _matches(self, query: str, folder_name: str) -> bool:
        """
        Improved matching: strips year from query, supports partial word
        matching, and uses a 70 % threshold instead of requiring every word.

        Examples that now work:
        - "A Knight 2026"  →  "A Knight of the Seven Kingdoms"
        - "Inception 2010" →  "Inception.2010.1080p.BluRay"
        - "baby john"      →  "Baby John (2024) Hindi"
        """
        query_lower = query.lower()
        folder_lower = folder_name.lower()

        # Clean special characters for comparison
        folder_clean = re.sub(r"[._\-\[\]\(\)]", " ", folder_lower)
        folder_clean = re.sub(r"\[ddn\]|\(ddn\)", "", folder_clean)
        query_clean = re.sub(r"[._\-\[\]\(\)]", " ", query_lower)

        # Remove year from query (the main fix — FTP folders often lack year)
        query_no_year = re.sub(r"\b(20\d{2}|19\d{2})\b", "", query_clean).strip()
        query_no_year = re.sub(r"\s+", " ", query_no_year)

        # MATCH 1: Direct substring
        if query_lower in folder_lower:
            return True

        # MATCH 2: Query without year matches folder
        if query_no_year and query_no_year in folder_clean:
            logger.info("[FTP] ✅ MATCH (no-year): '%s' → '%s'", query, folder_name)
            return True

        # MATCH 3: Word-based — at least 70 % of query words must appear
        query_words = [w for w in query_no_year.split() if len(w) > 2]
        if not query_words:
            return query_lower in folder_lower

        folder_words = [w for w in folder_clean.split() if len(w) > 1]
        hits = sum(
            1 for qw in query_words
            if any(qw == fw or qw in fw or (len(fw) > 2 and fw in qw) for fw in folder_words)
        )
        pct = hits / len(query_words)
        if pct >= 0.7:
            logger.info(
                "[FTP] ✅ MATCH (%.0f%%): '%s' → '%s'", pct * 100, query, folder_name
            )
            return True

        return False

    def _parse_folder(self, folder_name: str, directory: str) -> Optional[Dict]:
        """
        Parse a folder name into clean metadata.

        Removes [DDN] tags, extracts title/year/quality/language, and
        generates a stable ID from the path.
        """
        try:
            clean = folder_name.rstrip("/")
            clean = re.sub(r"\[DDN\]|\(DDN\)", "", clean).strip()

            # Extract title + year  (e.g. "Title.2024.1080p.BluRay")
            match = re.search(r"^(.+?)[.\s](\d{4})", clean)
            if match:
                title = match.group(1).replace(".", " ").replace("_", " ").strip()
                year = match.group(2)
            else:
                title = clean.split(".")[0].replace(".", " ").replace("_", " ").strip()
                year = ""

            quality = self._extract_quality(clean)

            # Language inference
            if "Hindi" in clean or "/Indian" in directory:
                language = "Hindi"
            elif "/English" in directory:
                language = "English"
            else:
                language = ""

            content_type = "series" if "/TV_Series" in directory else "movie"

            return {
                "id": self._generate_id(clean, directory),
                "title": title,
                "year": year,
                "quality": quality,
                "language": language,
                "type": content_type,
                # Internal data — used by get_playable_links(), never shown in app UI
                "_internal_folder": folder_name,
                "_internal_directory": directory,
                "_source": "ftp",
            }

        except Exception as exc:
            logger.debug("Parse error for '%s': %s", folder_name, exc)
            return None

    @staticmethod
    def _generate_id(name: str, directory: str) -> str:
        combined = f"{directory}/{name}"
        return hashlib.md5(combined.encode()).hexdigest()[:16]

    @staticmethod
    def _is_video(filename: str) -> bool:
        return any(
            filename.lower().endswith(ext)
            for ext in (".mp4", ".mkv", ".avi", ".mov", ".wmv", ".webm", ".m4v")
        )

    @staticmethod
    def _extract_quality(text: str) -> str:
        text_lower = text.lower()
        for label, pattern in [
            ("4K", "2160p"), ("4K", "4k"), ("4K", "uhd"),
            ("1080p", "1080p"), ("720p", "720p"), ("480p", "480p"),
        ]:
            if pattern in text_lower:
                return label
        return "HD"

    @staticmethod
    def _extract_episode_info(text: str) -> str:
        """Extract season/episode info from text. Returns e.g. 'S01E03' or ''."""
        if not text:
            return ""
        # S01E01 / S1E1 pattern
        m = re.search(r'S(\d{1,2})\s*E(\d{1,3})', text, re.IGNORECASE)
        if m:
            return f"S{int(m.group(1)):02d}E{int(m.group(2)):02d}"
        # Episode X / Ep X
        m = re.search(r'\b(?:Episode|Ep)\.?\s*(\d{1,3})\b', text, re.IGNORECASE)
        if m:
            return f"E{int(m.group(1)):02d}"
        # E01 standalone at word boundary
        m = re.search(r'\bE(\d{1,3})\b', text)
        if m:
            return f"E{int(m.group(1)):02d}"
        return ""

    @staticmethod
    def _clean_filename(filename: str) -> str:
        """Strip extension and common tags for a user-friendly label."""
        name = re.sub(r"\.[^.]+$", "", filename)          # remove extension
        name = re.sub(r"\[DDN\]|\(DDN\)", "", name)       # remove DDN tags
        name = name.replace(".", " ").replace("_", " ")
        return name.strip()

    @staticmethod
    def _parse_size_str(size_str: str) -> int:
        """Parse Apache-style size strings like '1.2G', '500M', '250K'."""
        if not size_str or size_str == "-":
            return 0
        try:
            size_str = size_str.strip().upper()
            multipliers = {"K": 1024, "M": 1024**2, "G": 1024**3, "T": 1024**4}
            if size_str[-1] in multipliers:
                return int(float(size_str[:-1]) * multipliers[size_str[-1]])
            return int(size_str)
        except (ValueError, IndexError):
            return 0

    def get_random_movies(self, limit: int = 20) -> list:
        """
        Get random movies from FTP server
        Returns list of movies with basic info (title, year, quality, ftp_path)
        """
        import random
        
        logger.info(f"[FTP] Getting {limit} random movies...")
        
        all_movies = []
        categories = [
            '/English',
            '/Indian/Hindi Movies',
            '/TV_Series',
        ]
        
        try:
            for category in categories:
                movies = self._get_movies_from_directory(category, limit=100)
                all_movies.extend(movies)
                
                if len(all_movies) >= limit * 2:
                    break
            
            # Shuffle and select
            random.shuffle(all_movies)
            selected = all_movies[:limit]
            
            logger.info(f"[FTP] Selected {len(selected)} random movies")
            return selected
            
        except Exception as e:
            logger.error(f"[FTP] Random movies error: {e}")
            return []


    def _get_movies_from_directory(self, directory: str, limit: int = 100) -> list:
        """
        Get movies from a specific FTP directory
        """
        import re
        
        movies = []
        
        try:
            # Fetch directory listing via HTTP
            url = f"{self.base_url}{directory}/"
            client = _get_client(timeout=self.timeout)
            response = client.get(url)
            
            if response.status_code != 200:
                logger.warning(f"[FTP] Failed to fetch {directory}: {response.status_code}")
                return []
            
            # Parse HTML to extract folder links
            folder_pattern = r'<a href="([^"]+)/">([^<]+)</a>'
            matches = re.findall(folder_pattern, response.text)
            
            for href, folder_name in matches[:limit]:
                # Skip parent directory
                if folder_name in ['..', '.']:
                    continue
                
                # Parse movie info
                movie = {
                    'title': self._clean_movie_name(folder_name),
                    'year': self._extract_year(folder_name),
                    'quality': self._extract_quality(folder_name),
                    'ftp_path': f"{directory}/{folder_name}",
                    'ftp_url': f"{self.base_url}{directory}/{folder_name}/",
                    'source': 'ftp',
                }
                
                movies.append(movie)
            
            logger.debug(f"[FTP] Found {len(movies)} movies in {directory}")
            return movies
            
        except Exception as e:
            logger.error(f"[FTP] Directory error {directory}: {e}")
            return []


    def _clean_movie_name(self, filename: str) -> str:
        """Clean movie name for TMDB search"""
        import re
        
        cleaned = unquote(filename)
        
        # Remove quality markers
        cleaned = re.sub(r'\b(720p|1080p|2160p|4K|480p)\b', '', cleaned, flags=re.IGNORECASE)
        
        # Remove format markers
        cleaned = re.sub(r'\b(WEBRip|BluRay|HDTS|HDRip|DVDRip|WEB-DL|BRRip)\b', '', cleaned, flags=re.IGNORECASE)
        
        # Remove codec markers
        cleaned = re.sub(r'\b(x264|x265|H264|H265|HEVC|10bit)\b', '', cleaned, flags=re.IGNORECASE)
        
        # Remove audio markers
        cleaned = re.sub(r'\b(AAC|DD5\.1|AC3|DTS|Atmos|ESub)\b', '', cleaned, flags=re.IGNORECASE)
        
        # Remove [DDN] tags
        cleaned = re.sub(r'\[DDN\]|\(DDN\)', '', cleaned, flags=re.IGNORECASE)
        
        # Remove year (will be extracted separately)
        cleaned = re.sub(r'\(?\d{4}\)?', '', cleaned)
        
        # Replace separators with spaces
        cleaned = cleaned.replace('.', ' ').replace('_', ' ').replace('-', ' ')
        
        # Clean multiple spaces
        cleaned = re.sub(r'\s+', ' ', cleaned).strip()
        
        return cleaned


    def _extract_year(self, filename: str) -> int:
        """Extract year from filename"""
        import re
        match = re.search(r'\b(19\d{2}|20\d{2})\b', filename)
        return int(match.group(1)) if match else 0



# ------------------------------------------------------------------
# Standalone helpers
# ------------------------------------------------------------------

def _format_size(size_bytes: int) -> str:
    """Convert bytes to a human-readable string."""
    for unit in ("B", "KB", "MB", "GB"):
        if size_bytes < 1024:
            return f"{size_bytes:.1f} {unit}"
        size_bytes /= 1024
    return f"{size_bytes:.1f} TB"
