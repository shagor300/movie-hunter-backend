"""
FTP Handler — Lightweight FTP integration for ftp.ctgfun.com.

Connects anonymously to browse and search movie folders, then generates
direct HTTP links for streaming/downloading.  No heavy dependencies —
uses only Python's built-in `ftplib`.

Designed for Render free-tier: quick connect, fast search, minimal RAM.
"""

import ftplib
import hashlib
import logging
import re
from typing import Dict, List, Optional
from urllib.parse import quote

logger = logging.getLogger(__name__)


class FTPMovieHandler:
    """Search and browse movies on an FTP server."""

    def __init__(
        self,
        host: str = "ftp.ctgfun.com",
        user: str = "anonymous",
        password: str = "",
        timeout: int = 10,
    ):
        self.host = host
        self.user = user
        self.password = password
        self.timeout = timeout

        # Directories to search (order matters — searched first to last)
        self.search_dirs = [
            "/English",
            "/Indian/Hindi Movies",
            "/TV_Series",
        ]

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def search(self, query: str, limit: int = 20) -> List[Dict]:
        """
        Search for movies/series in the FTP server.

        Returns a list of dicts with clean metadata (no FTP paths exposed).
        """
        query = query.lower().strip()
        if not query:
            return []

        results: List[Dict] = []

        try:
            ftp = ftplib.FTP(self.host, timeout=self.timeout)
            ftp.login(self.user, self.password)

            for directory in self.search_dirs:
                try:
                    ftp.cwd(directory)
                    items: List[str] = []
                    ftp.retrlines("NLST", items.append)

                    for item in items:
                        if self._matches(query, item):
                            movie = self._parse_folder(item, directory)
                            if movie:
                                results.append(movie)
                            if len(results) >= limit:
                                break

                    if len(results) >= limit:
                        break
                except Exception as exc:
                    logger.warning("FTP search error in %s: %s", directory, exc)
                    continue

            ftp.quit()

        except Exception as exc:
            logger.error("FTP connection error: %s", exc)

        return results

    def get_playable_links(
        self,
        internal_folder: str,
        internal_directory: str,
    ) -> Dict:
        """
        Get video + subtitle links from a specific FTP folder.

        Returns direct HTTP links (``http://host/path/file.mp4``) that can
        be streamed or downloaded without any intermediate resolution.
        """
        try:
            ftp = ftplib.FTP(self.host, timeout=self.timeout)
            ftp.login(self.user, self.password)

            folder_path = f"{internal_directory}/{internal_folder}"
            ftp.cwd(folder_path)

            file_list: List[str] = []
            ftp.retrlines("LIST", file_list.append)

            videos: List[Dict] = []
            subtitles: List[Dict] = []

            for file_info in file_list:
                parts = file_info.split()
                if len(parts) < 9:
                    continue

                filename = " ".join(parts[8:])
                size = int(parts[4]) if parts[4].isdigit() else 0

                if self._is_video(filename):
                    quality = self._extract_quality(filename)
                    clean_name = self._clean_filename(filename)
                    url = f"http://{self.host}{folder_path}/{quote(filename)}"

                    videos.append({
                        "text": f"{clean_name} — {quality}",
                        "url": url,
                        "quality": quality,
                        "size": size,
                        "size_label": _format_size(size),
                        "source": "Premium",
                        "type": "direct",
                    })

                elif filename.lower().endswith(".srt"):
                    subtitles.append({
                        "filename": filename,
                        "url": f"http://{self.host}{folder_path}/{quote(filename)}",
                    })

            ftp.quit()

            return {
                "success": True,
                "links": videos,
                "subtitles": subtitles,
            }

        except Exception as exc:
            logger.error("FTP get_playable_links error: %s", exc)
            return {"success": False, "links": [], "subtitles": []}

    def browse_latest(self, directory: str = "/English", limit: int = 30) -> List[Dict]:
        """
        Browse the latest entries in a given FTP directory.

        Returns a list of parsed movie dicts (most recent first, if the
        server supports MLSD; otherwise alphabetical).
        """
        results: List[Dict] = []

        try:
            ftp = ftplib.FTP(self.host, timeout=self.timeout)
            ftp.login(self.user, self.password)
            ftp.cwd(directory)

            items: List[str] = []
            ftp.retrlines("NLST", items.append)

            # Reverse to approximate "latest first" (most FTP servers list
            # chronologically or alphabetically).
            for item in reversed(items):
                movie = self._parse_folder(item, directory)
                if movie:
                    results.append(movie)
                if len(results) >= limit:
                    break

            ftp.quit()

        except Exception as exc:
            logger.error("FTP browse error: %s", exc)

        return results

    def check_connectivity(self) -> bool:
        """Quick connectivity check — returns True if the FTP is reachable."""
        try:
            ftp = ftplib.FTP(self.host, timeout=5)
            ftp.login(self.user, self.password)
            ftp.quit()
            return True
        except Exception:
            return False

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _matches(self, query: str, folder_name: str) -> bool:
        """Check if *all* query words appear in the folder name."""
        folder_clean = re.sub(r"[._\-\[\]\(\)]", " ", folder_name.lower())
        query_words = [w for w in query.split() if len(w) > 1]
        return all(word in folder_clean for word in query_words)

    def _parse_folder(self, folder_name: str, directory: str) -> Optional[Dict]:
        """
        Parse an FTP folder name into clean metadata.

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
            logger.debug("FTP parse error for '%s': %s", folder_name, exc)
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
    def _clean_filename(filename: str) -> str:
        """Strip extension and common tags for a user-friendly label."""
        name = re.sub(r"\.[^.]+$", "", filename)          # remove extension
        name = re.sub(r"\[DDN\]|\(DDN\)", "", name)       # remove DDN tags
        name = name.replace(".", " ").replace("_", " ")
        return name.strip()


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
