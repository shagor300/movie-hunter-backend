import asyncio
import re
import random
import json
import aiosqlite
import requests
from datetime import datetime, timedelta
from typing import List, Dict, Optional
from playwright.async_api import async_playwright
from playwright_stealth import stealth_async
from bs4 import BeautifulSoup
from urllib.parse import urljoin, quote
from thefuzz import fuzz, process

# --- Configuration & Domains ---
DOMAINS = {
    "YoMovies": "https://yomovies.top",
    "HDHub4u": "https://hdhub4u.tv",
    "4khdhub": "https://hdhub4u.cx",
    "CTGMovies": "http://ctgmovies.com",
    "SkymoviesHD": "https://skymovieshd.mba",
    "KatmovieHD": "https://new.katmoviehd.cymru"
}

TMDB_API_KEY = "eb8907379766e4a60156d812d4d8fc39"
AD_KEYWORDS = [
    'popads', 'adsterra', 'tracker', 'google-analytics', 'doubleclick', 
    'adnxs', 'amazon-adsystem', 'facebook.com/tr', 'googletagmanager',
    'ads', 'analytics', 'telemetry', 'mgid', 'click', 'shutterstock',
    'pro-ads', 'ad-shield', 'yandex', 'mail.ru', 'coinhive', 'crypto-loot'
]

# --- Cache Manager (Async) ---
class CacheManager:
    def __init__(self, db_path="scraper_cache.db"):
        self.db_path = db_path

    async def init_db(self):
        async with aiosqlite.connect(self.db_path) as db:
            await db.execute("""
                CREATE TABLE IF NOT EXISTS cache (
                    query TEXT PRIMARY KEY,
                    data TEXT,
                    timestamp DATETIME
                )
            """)
            await db.commit()

    async def get(self, query: str) -> Optional[List[Dict]]:
        try:
            async with aiosqlite.connect(self.db_path) as db:
                async with db.execute("SELECT data, timestamp FROM cache WHERE query = ?", (query.lower(),)) as cursor:
                    row = await cursor.fetchone()
                    if row:
                        data, timestamp = row
                        ts = datetime.strptime(timestamp, "%Y-%m-%d %H:%M:%S")
                        if datetime.now() - ts < timedelta(hours=24):
                            return json.loads(data)
        except Exception as e:
            print(f"Cache Get Error: {e}")
        return None

    async def set(self, query: str, data: List[Dict]):
        try:
            async with aiosqlite.connect(self.db_path) as db:
                await db.execute(
                    "INSERT OR REPLACE INTO cache (query, data, timestamp) VALUES (?, ?, ?)",
                    (query.lower(), json.dumps(data), datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
                )
                await db.commit()
        except Exception as e:
            print(f"Cache Set Error: {e}")

# --- Scraper Logic ---
class MovieScraper:
    def __init__(self):
        self.user_agents = [
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36"
        ]
        self.cache = CacheManager()
        self.playwright = None
        self.browser = None
        self.semaphore = asyncio.Semaphore(2)  # Limit to 2 concurrent scrapes for RAM safety

    async def startup(self):
        """Initialize shared browser instance."""
        if not self.browser:
            self.playwright = await async_playwright().start()
            self.browser = await self.playwright.chromium.launch(headless=True, args=["--headless=new"])
            await self.cache.init_db()

    async def shutdown(self):
        """Cleanup shared browser."""
        if self.browser:
            await self.browser.close()
        if self.playwright:
            await self.playwright.stop()

    async def _intercept_request(self, route):
        url = route.request.url.lower()
        if any(keyword in url for keyword in AD_KEYWORDS) or route.request.resource_type in ["image", "media", "font"]:
            await route.abort()
        else:
            await route.continue_()

    async def _get_context(self):
        context = await self.browser.new_context(user_agent=random.choice(self.user_agents))
        return context

    async def fetch_tmdb_metadata(self, title: str) -> Dict:
        """Fetch enrichment data from TMDB (non-Playwright)."""
        try:
            clean_title = re.sub(r'\(?\d{4}\)?', '', title).strip()
            url = f"https://api.themoviedb.org/3/search/movie?api_key={TMDB_API_KEY}&query={quote(clean_title)}"
            response = requests.get(url, timeout=5)
            if response.status_code == 200:
                results = response.json().get('results', [])
                if results:
                    best_match = results[0]
                    return {
                        "tmdb_poster": f"https://image.tmdb.org/t/p/w500{best_match.get('poster_path')}" if best_match.get('poster_path') else None,
                        "rating": best_match.get('vote_average'),
                        "plot": best_match.get('overview'),
                        "release_date": best_match.get('release_date')
                    }
        except Exception: pass
        return {}

    async def search_site(self, site_name: str, query: str) -> List[Dict]:
        """Scrape a single site with concurrency control and strict timeouts."""
        async with self.semaphore:
            results = []
            base_url = DOMAINS.get(site_name)
            if not base_url: return []

            context = await self._get_context()
            page = await context.new_page()
            await stealth_async(page)
            await page.route("**/*", self._intercept_request)

            try:
                search_url = f"{base_url}/?s={quote(query)}"
                # 15s timeout per search as requested
                await page.goto(search_url, wait_until="domcontentloaded", timeout=15000)
                content = await page.content()
                soup = BeautifulSoup(content, 'html.parser')
                
                items = soup.select('.ml-item, article, .post-item, .hub-video')
                for item in items[:8]:
                    title_elem = item.select_one('a[title], h2 a, .post-title a, .hub-video a') or item.find('a')
                    if title_elem:
                        title = title_elem.get('title') or title_elem.get_text(strip=True)
                        link = title_elem.get('href')
                        if not link.startswith('http'): link = urljoin(base_url, link)
                        
                        score = fuzz.token_sort_ratio(query.lower(), title.lower())
                        if score < 70: continue

                        results.append({"title": title, "url": link, "source": site_name})
            except Exception as e:
                print(f"{site_name} Error: {e}")
            finally:
                await page.close()
                await context.close()
            return results

    async def global_search(self, query: str) -> List[Dict]:
        """Perform search across all domains with caching and merging."""
        await self.startup()
        
        cached_data = await self.cache.get(query)
        if cached_data: return cached_data

        tasks = [self.search_site(site, query) for site in DOMAINS.keys()]
        all_site_results = await asyncio.gather(*tasks)
        
        merged_results = {}
        for site_results in all_site_results:
            for item in site_results:
                title = item['title'].lower()
                match = process.extractOne(title, merged_results.keys(), scorer=fuzz.token_sort_ratio)
                
                if match and match[1] > 92:
                    existing_title = match[0]
                    if item['url'] not in [s['url'] for s in merged_results[existing_title]['sources']]:
                        merged_results[existing_title]['sources'].append({"site": item['source'], "url": item['url']})
                else:
                    merged_results[title] = {
                        "title": item['title'],
                        "sources": [{"site": item['source'], "url": item['url']}]
                    }

        final_results = list(merged_results.values())[:15]
        metadata_tasks = [self.fetch_tmdb_metadata(res['title']) for res in final_results]
        metadata_list = await asyncio.gather(*metadata_tasks)
        
        for i, metadata in enumerate(metadata_list):
            final_results[i].update(metadata)

        if final_results:
            await self.cache.set(query, final_results)

        return final_results

    async def extract_links(self, url: str) -> List[Dict]:
        """Extract links using shared browser instance."""
        await self.startup()
        links = []
        context = await self._get_context()
        page = await context.new_page()
        await page.route("**/*", self._intercept_request)

        try:
            await page.goto(url, wait_until="domcontentloaded", timeout=30000)
            
            for _ in range(2):
                content = await page.content()
                soup = BeautifulSoup(content, 'html.parser')
                
                for a in soup.find_all('a', href=True):
                    href = a['href']
                    text = a.get_text().lower()
                    
                    if any(ext in href.lower() for ext in ['.mkv', '.mp4', '.avi']) or \
                       any(domain in href for domain in ['drive.google', 'hubcloud', 'pixeldrain', 'gdtot', 'sharer']):
                        
                        quality = "720p"
                        if any(q in text for q in ["2160", "4k"]): quality = "4K"
                        elif "1080" in text: quality = "1080p"
                        elif "480" in text: quality = "480p"
                        
                        links.append({"quality": quality, "url": href, "name": text.strip() or "Stream/Download"})

                if links: break
                
                selectors = ["text='Direct Download'", "text='Download Now'", ".btn-download"]
                for selector in selectors:
                    if await page.is_visible(selector, timeout=2000):
                        await page.click(selector)
                        await page.wait_for_timeout(3000)
                        break

        except Exception as e:
            print(f"Link Error: {e}")
        finally:
            await page.close()
            await context.close()
        
        return list({l['url']: l for l in links}.values())

scraper_instance = MovieScraper()
