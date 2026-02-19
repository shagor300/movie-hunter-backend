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
import httpx

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
        self.navigation_timeout = 45_000
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
        1. Set up network interception to catch direct file URLs
        2. Navigate to file page
        3. Click through buttons (Direct/Instant/Generate Link)
        4. Wait for timer / network request with file URL
        5. Extract direct URL from intercepted requests or page links
        """
        user_agent = (
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
            "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        )
        context = await self.browser.new_context(user_agent=user_agent)
        page = await context.new_page()

        # Network interception — catch direct file URLs before they redirect
        intercepted_urls = []

        def _on_request(request):
            req_url = request.url.lower()
            if re.search(r'\.(mp4|mkv|avi|m4v|mov|webm)(\?|$)', req_url, re.I):
                intercepted_urls.append(request.url)
                logger.info(f"Intercepted file URL: {request.url[:100]}")

        def _on_response(response):
            resp_url = response.url.lower()
            # Catch redirects to file hosting CDNs
            if re.search(r'\.(mp4|mkv|avi|m4v|mov|webm)(\?|$)', resp_url, re.I):
                if response.url not in intercepted_urls:
                    intercepted_urls.append(response.url)
                    logger.info(f"Intercepted file response: {response.url[:100]}")

        page.on("request", _on_request)
        page.on("response", _on_response)

        try:
            logger.info(f"Resolving HubDrive link: {url}")

            # Step 1: Navigate (increased timeout for slow hosts)
            await page.goto(url, wait_until="domcontentloaded", timeout=self.navigation_timeout)
            await asyncio.sleep(2)

            # Step 2: Click through buttons — try multiple rounds
            button_selectors = [
                'button:has-text("Direct")',
                'button:has-text("Instant")',
                'a:has-text("Direct Download")',
                'a:has-text("Instant Download")',
                'button:has-text("Generate")',
                'a:has-text("Generate Link")',
                'a:has-text("Get Link")',
                'button:has-text("Download")',
                'a:has-text("Download")',
                '.download-button',
                '#direct-download',
                '#generate',
                '.btn-success',
                '.btn-primary',
            ]

            for attempt in range(2):  # Two rounds of clicking
                clicked = False
                for sel in button_selectors:
                    try:
                        btn = await page.query_selector(sel)
                        if btn and await btn.is_visible():
                            await btn.click()
                            logger.info(f"Clicked button: {sel} (attempt {attempt + 1})")
                            clicked = True
                            await asyncio.sleep(2)
                            break
                    except Exception:
                        continue

                if not clicked and attempt == 0:
                    # JS fallback on first attempt
                    logger.warning("Standard selectors failed – trying JS click")
                    await page.evaluate("""
                        () => {
                            const btns = Array.from(document.querySelectorAll('button, a'));
                            const btn = btns.find(b =>
                                b.textContent.toLowerCase().includes('direct') ||
                                b.textContent.toLowerCase().includes('instant') ||
                                b.textContent.toLowerCase().includes('generate') ||
                                b.textContent.toLowerCase().includes('download')
                            );
                            if (btn) btn.click();
                        }
                    """)
                    await asyncio.sleep(2)

                # Check if we already intercepted a file URL
                if intercepted_urls:
                    logger.info(f"Got file URL from network interception!")
                    break

                await asyncio.sleep(2)

            # Step 3: Wait for countdown / file URL (max 60s)
            logger.info("Waiting for download link (network + page polling)...")
            for i in range(self.countdown_max_wait):
                # Check intercepted URLs first
                if intercepted_urls:
                    logger.info(f"File URL intercepted after {i}s")
                    break

                await asyncio.sleep(1)

                # Try clicking any newly appeared download button
                try:
                    for final_sel in [
                        'a:has-text("Download Here")',
                        'a:has-text("Download Now")',
                        'a:has-text("Click Here")',
                        '#download-link',
                        'a.btn-success:has-text("Download")',
                    ]:
                        final_btn = await page.query_selector(final_sel)
                        if final_btn and await final_btn.is_visible():
                            href = await final_btn.get_attribute("href")
                            if href and re.search(r'\.(mp4|mkv|avi|m4v)', href, re.I):
                                intercepted_urls.append(href)
                                logger.info(f"Found direct file href: {href[:100]}")
                                break
                            elif href and href.startswith("http"):
                                intercepted_urls.append(href)
                                logger.info(f"Found download href: {href[:100]}")
                                break
                except Exception:
                    continue

                # Every 10s, also check page links
                if i > 0 and i % 10 == 0:
                    link = await self._extract_final_link(page)
                    if link:
                        intercepted_urls.append(link)
                        break

            # Step 4: Return best URL
            final_link = None
            if intercepted_urls:
                final_link = intercepted_urls[0]
            else:
                # Last resort: scan all page links
                final_link = await self._extract_final_link(page)

            if not final_link:
                # Try page source regex for any video URL
                content = await page.content()
                video_match = re.search(
                    r'https?://[^\s"\'<>\]]+\.(mp4|mkv|avi|m4v)(\?[^\s"\'<>\]]*)?',
                    content, re.I
                )
                if video_match:
                    final_link = video_match.group(0)
                    logger.info(f"Found video URL in page source: {final_link[:100]}")

            if not final_link:
                raise Exception("Could not extract final download URL after all strategies")

            filename = self._extract_filename(final_link)
            filesize = await self._extract_filesize(page)

            # Capture authentication data for streaming
            cookies_list = await context.cookies()
            cookies_string = '; '.join(
                f"{c['name']}={c['value']}" for c in cookies_list
            )
            actual_ua = await page.evaluate('navigator.userAgent')

            logger.info(f"Successfully resolved: {filename}")
            return {
                "success": True,
                "direct_url": final_link,
                "filename": filename,
                "filesize": filesize,
                "original_url": url,
                "cookies": cookies_string,
                "user_agent": actual_ua,
                "referer": url,
                "requires_headers": True,
            }

        except Exception as e:
            logger.error(f"HubDrive resolution failed: {e}")
            return {"success": False, "error": str(e), "original_url": url}

        finally:
            page.remove_listener("request", _on_request)
            page.remove_listener("response", _on_response)
            await page.close()
            await context.close()

    # ------------------------------------------------------------------
    # GoFile
    # ------------------------------------------------------------------
    async def _resolve_gofile(self, url: str) -> Dict[str, Any]:
        """
        Resolve GoFile link using their API (the web UI is a React SPA
        that doesn't expose buttons to Playwright).
        """
        try:
            logger.info(f"Resolving GoFile link: {url}")

            # Extract content ID from URL: https://gofile.io/d/XXXX
            content_id = url.rstrip('/').split('/')[-1]
            if not content_id or len(content_id) < 4:
                return {"success": False, "error": "Invalid GoFile URL", "original_url": url}

            async with httpx.AsyncClient(timeout=15.0) as client:
                # Step 1: Create a guest account to get a token
                token = None
                try:
                    acc_resp = await client.post("https://api.gofile.io/accounts")
                    if acc_resp.status_code == 200:
                        acc_data = acc_resp.json()
                        if acc_data.get('status') == 'ok':
                            token = acc_data['data']['token']
                except Exception as e:
                    logger.warning(f"GoFile account creation failed: {e}")

                # Step 2: Fetch content info
                headers = {}
                if token:
                    headers['Authorization'] = f'Bearer {token}'

                content_url = f"https://api.gofile.io/contents/{content_id}?wt=4fd6sg89d7s6"
                resp = await client.get(content_url, headers=headers)

                if resp.status_code == 200:
                    data = resp.json()
                    if data.get('status') == 'ok':
                        contents = data.get('data', {}).get('children', {})
                        # Find the first file with a download link
                        for file_id, file_info in contents.items():
                            if file_info.get('type') == 'file':
                                direct_url = file_info.get('link')
                                filename = file_info.get('name', f'gofile_{content_id}')
                                filesize = file_info.get('size')
                                if direct_url:
                                    logger.info(f"GoFile resolved via API: {filename}")
                                    return {
                                        "success": True,
                                        "direct_url": direct_url,
                                        "filename": filename,
                                        "filesize": f"{filesize / (1024*1024*1024):.1f} GB" if filesize else None,
                                        "original_url": url,
                                        "cookies": f"accountToken={token}" if token else "",
                                        "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0",
                                        "referer": url,
                                        "requires_headers": True,
                                    }

            # Fallback: construct a direct download URL
            fallback_url = f"https://store1.gofile.io/download/direct/{content_id}"
            return {
                "success": True,
                "direct_url": fallback_url,
                "filename": f"gofile_{content_id}",
                "original_url": url,
                "cookies": "",
                "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0",
                "referer": url,
                "requires_headers": True,
            }

        except Exception as e:
            logger.error(f"GoFile resolution failed: {e}")
            return {"success": False, "error": str(e), "original_url": url}

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
            "cookies": "",
            "user_agent": "",
            "referer": url,
            "requires_headers": False,
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
            "cookies": "",
            "user_agent": "",
            "referer": "",
            "requires_headers": False,
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
