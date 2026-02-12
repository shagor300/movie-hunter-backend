"""
HubDrive Deep Link Resolver
Automates extraction of direct download links from file hosting sites.
Shares the Playwright browser instance from MovieScraper to stay within
Render's memory limits.
"""

import asyncio
import re
import logging
import time
from typing import Optional, Dict, Any
from playwright.async_api import Browser, Page, TimeoutError as PlaywrightTimeout

logger = logging.getLogger(__name__)


class DownloadLinkResolver:
    """
    Resolves intermediate download links (HubDrive, GoFile, Pixeldrain, GDrive)
    to final direct file URLs that flutter_downloader can handle.
    """

    def __init__(self, max_concurrent: int = 2):
        self.browser: Optional[Browser] = None
        self.semaphore = asyncio.Semaphore(max_concurrent)

        # Timeout configurations (milliseconds)
        self.navigation_timeout = 30_000
        self.button_wait_timeout = 15_000
        self.countdown_max_wait = 60  # seconds

    def set_browser(self, browser: Browser) -> None:
        """Attach the shared browser from MovieScraper."""
        self.browser = browser
        logger.info("DownloadLinkResolver: browser attached")

    # ------------------------------------------------------------------
    # Public entry point
    # ------------------------------------------------------------------
    async def resolve_download_link(self, url: str) -> Dict[str, Any]:
        """
        Resolve any supported download link to a direct file URL.

        Returns dict with keys: success, direct_url, filename, filesize, error
        """
        if not self.browser:
            return {"success": False, "error": "Browser not initialized"}

        async with self.semaphore:
            try:
                if "hubdrive" in url or "hubcloud" in url:
                    return await self._resolve_hubdrive(url)
                elif "gofile" in url:
                    return await self._resolve_gofile(url)
                elif "pixeldrain" in url:
                    return await self._resolve_pixeldrain(url)
                elif "drive.google.com" in url:
                    return await self._resolve_google_drive(url)
                else:
                    return {"success": False, "error": f"Unsupported host: {url}"}
            except Exception as e:
                logger.error(f"Resolution failed for {url}: {e}")
                return {"success": False, "error": str(e)}

    # ------------------------------------------------------------------
    # HubDrive / HubCloud
    # ------------------------------------------------------------------
    async def _resolve_hubdrive(self, url: str) -> Dict[str, Any]:
        """
        Automate HubDrive page:
        1. Navigate to file page
        2. Click "Direct/Instant Download" button
        3. Wait for countdown timer
        4. Click "Download Here" button / extract href
        5. Return direct URL
        """
        user_agent = (
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
            "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        )
        context = await self.browser.new_context(user_agent=user_agent)
        page = await context.new_page()

        try:
            logger.info(f"Resolving HubDrive link: {url}")

            # Step 1: Navigate
            await page.goto(url, wait_until="domcontentloaded", timeout=self.navigation_timeout)
            await asyncio.sleep(2)

            # Step 2: Click "Direct / Instant Download" button
            button_selectors = [
                'button:has-text("Direct")',
                'button:has-text("Instant")',
                'a:has-text("Direct Download")',
                'button:has-text("Download")',
                '.download-button',
                '#direct-download',
            ]

            clicked = False
            for sel in button_selectors:
                try:
                    await page.wait_for_selector(sel, timeout=5000)
                    await page.click(sel)
                    logger.info(f"Clicked button: {sel}")
                    clicked = True
                    break
                except PlaywrightTimeout:
                    continue

            if not clicked:
                # JS fallback
                logger.warning("Standard selectors failed – trying JS click")
                await page.evaluate("""
                    () => {
                        const btns = Array.from(document.querySelectorAll('button, a'));
                        const btn = btns.find(b =>
                            b.textContent.toLowerCase().includes('direct') ||
                            b.textContent.toLowerCase().includes('instant') ||
                            b.textContent.toLowerCase().includes('download')
                        );
                        if (btn) btn.click();
                    }
                """)

            await asyncio.sleep(3)

            # Step 3: Wait for countdown
            logger.info("Waiting for countdown timer...")
            countdown_selectors = [
                '#countdown', '.countdown',
                'span:has-text("seconds")', 'div:has-text("wait")',
            ]
            countdown_found = False
            for sel in countdown_selectors:
                try:
                    await page.wait_for_selector(sel, timeout=5000)
                    countdown_found = True
                    logger.info(f"Countdown found: {sel}")
                    break
                except PlaywrightTimeout:
                    continue

            if countdown_found:
                for i in range(self.countdown_max_wait):
                    await asyncio.sleep(1)
                    try:
                        final_btn = await page.query_selector(
                            'button:has-text("Download Here"), a:has-text("Download Here")'
                        )
                        if final_btn:
                            logger.info(f"Countdown finished after {i + 1}s")
                            break
                    except Exception:
                        continue
            else:
                logger.info("No countdown detected, proceeding...")
                await asyncio.sleep(5)

            # Step 4: Extract final URL
            final_link = await self._extract_final_link(page)

            if not final_link:
                raise Exception("Could not extract final download URL")

            filename = self._extract_filename(final_link)
            filesize = await self._extract_filesize(page)

            logger.info(f"Successfully resolved: {filename}")
            return {
                "success": True,
                "direct_url": final_link,
                "filename": filename,
                "filesize": filesize,
                "original_url": url,
            }

        except Exception as e:
            logger.error(f"HubDrive resolution failed: {e}")
            return {"success": False, "error": str(e), "original_url": url}

        finally:
            await page.close()
            await context.close()

    # ------------------------------------------------------------------
    # GoFile
    # ------------------------------------------------------------------
    async def _resolve_gofile(self, url: str) -> Dict[str, Any]:
        context = await self.browser.new_context()
        page = await context.new_page()

        try:
            logger.info(f"Resolving GoFile link: {url}")
            await page.goto(url, wait_until="networkidle", timeout=self.navigation_timeout)
            await asyncio.sleep(3)

            await page.wait_for_selector('button:has-text("Download")', timeout=15000)
            download_btn = await page.query_selector('button:has-text("Download")')

            download_url_future: asyncio.Future[str] = asyncio.get_event_loop().create_future()

            async def _on_download(download):
                if not download_url_future.done():
                    download_url_future.set_result(download.url)

            page.on("download", _on_download)

            if download_btn:
                await download_btn.click()

            try:
                download_url = await asyncio.wait_for(download_url_future, timeout=10)
            except asyncio.TimeoutError:
                download_url = None

            if not download_url and download_btn:
                download_url = await download_btn.get_attribute("data-url")

            if not download_url:
                raise Exception("Could not extract GoFile download URL")

            return {
                "success": True,
                "direct_url": download_url,
                "filename": self._extract_filename(download_url),
                "original_url": url,
            }

        except Exception as e:
            logger.error(f"GoFile resolution failed: {e}")
            return {"success": False, "error": str(e), "original_url": url}

        finally:
            await page.close()
            await context.close()

    # ------------------------------------------------------------------
    # Pixeldrain (already direct)
    # ------------------------------------------------------------------
    async def _resolve_pixeldrain(self, url: str) -> Dict[str, Any]:
        file_id = url.rstrip("/").split("/")[-1]
        direct_url = f"https://pixeldrain.com/api/file/{file_id}"
        return {
            "success": True,
            "direct_url": direct_url,
            "filename": f"file_{file_id}",
            "original_url": url,
        }

    # ------------------------------------------------------------------
    # Google Drive
    # ------------------------------------------------------------------
    async def _resolve_google_drive(self, url: str) -> Dict[str, Any]:
        match = re.search(r"/d/([a-zA-Z0-9_-]+)", url)
        if not match:
            return {"success": False, "error": "Invalid Google Drive URL"}

        file_id = match.group(1)
        direct_url = f"https://drive.google.com/uc?export=download&id={file_id}"
        return {
            "success": True,
            "direct_url": direct_url,
            "filename": f"gdrive_{file_id}",
            "original_url": url,
        }

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------
    async def _extract_final_link(self, page: Page) -> Optional[str]:
        """Try multiple strategies to get the final direct download URL."""

        # Method 1: "Download Here" button href
        dl_here = await page.query_selector('a:has-text("Download Here")')
        if dl_here:
            href = await dl_here.get_attribute("href")
            if href:
                logger.info("Found via 'Download Here' button")
                return href

        # Method 2: Any link pointing to a video file
        all_links = await page.query_selector_all("a[href]")
        for link in all_links:
            href = await link.get_attribute("href")
            if href and re.search(r"\.(mkv|mp4|avi|m4v)(\?|$)", href, re.I):
                logger.info(f"Found direct file link: {href}")
                return href

        # Method 3: Intercept download event
        logger.info("Setting up download listener...")
        download_url_future: asyncio.Future[str] = asyncio.get_event_loop().create_future()

        async def _on_download(download):
            u = download.url
            if re.search(r"\.(mkv|mp4|avi|m4v)", u, re.I):
                if not download_url_future.done():
                    download_url_future.set_result(u)

        page.on("download", _on_download)
        try:
            await page.click(
                'button:has-text("Download Here"), a:has-text("Download")',
                timeout=5000,
            )
            return await asyncio.wait_for(download_url_future, timeout=10)
        except (asyncio.TimeoutError, PlaywrightTimeout):
            logger.warning("Download listener timeout")

        return None

    async def _extract_filesize(self, page: Page) -> Optional[str]:
        """Try to scrape file size text from the page."""
        try:
            el = await page.query_selector('text=/\\d+(\\.\\d+)?\\s*(GB|MB)/')
            if el:
                return (await el.inner_text()).strip()
        except Exception:
            pass
        return None

    @staticmethod
    def _extract_filename(url: str) -> str:
        """Extract or generate a filename from the URL."""
        filename = url.split("/")[-1].split("?")[0]
        if not re.search(r"\.(mkv|mp4|avi|m4v)$", filename, re.I):
            match = re.search(r"/([^/]+\.(mkv|mp4|avi|m4v))", url, re.I)
            if match:
                filename = match.group(1)
            else:
                filename = f"movie_{int(time.time())}.mp4"
        return filename
