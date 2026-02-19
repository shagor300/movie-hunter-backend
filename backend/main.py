import os
import asyncio
import re
import logging
from pathlib import Path as FilePath
from fastapi import FastAPI, HTTPException, Query, Path
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field, HttpUrl
from typing import Optional, List
from contextlib import asynccontextmanager
from scraper import scraper_instance, tmdb_helper, DOMAINS
from hdhub4u_homepage_scraper import HDHub4uScraper
from hubdrive_resolver import DownloadLinkResolver
from homepage_state import homepage_state
from embed_link_extractor import EmbedLinkExtractor
from multi_source_manager import MultiSourceManager
from config.sources import MovieSources
from bs4 import BeautifulSoup
from admin_db import admin_db
from admin_api import router as admin_router, ensure_default_admin

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


# --- Lifespan ---

# HDHub4u homepage scraper (shares browser with scraper_instance)
hdhub4u_scraper = HDHub4uScraper(scraper_instance)

# Download link resolver (shares browser with scraper_instance)
download_resolver = DownloadLinkResolver(max_concurrent=2)

# Embed link extractor (lightweight, no browser needed)
embed_extractor = EmbedLinkExtractor()

# Multi-source manager (SkyMoviesHD + future sources)
multi_source = MultiSourceManager()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan: start browser on startup, close on shutdown."""
    logger.info("Starting up application...")
    try:
        await scraper_instance.startup()
        # Share the browser with the download resolver
        download_resolver.set_browser(scraper_instance.browser)
        # Initialize multi-source scrapers (share browser + HDHub4u scraper + resolver)
        multi_source.init_scrapers(
            scraper_instance.browser,
            hdhub4u_scraper=scraper_instance,
            download_resolver=download_resolver
        )
        logger.info("HDHub4u scraper initialized (shared browser)")
        logger.info("Download link resolver initialized (shared browser)")
        logger.info("Multi-source manager initialized")
        # Initialize admin panel database
        await admin_db.init_db()
        await ensure_default_admin()
        logger.info("Admin panel database initialized")
        logger.info("Application startup complete")
        yield
    finally:
        logger.info("Shutting down application...")
        await tmdb_helper.close()
        await scraper_instance.shutdown()
        logger.info("Application shutdown complete")


app = FastAPI(
    title="MovieHub API v2",
    description="Advanced movie API with TMDB integration and on-demand link generation",
    version="2.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register admin panel router
app.include_router(admin_router)

# Serve admin dashboard (built React app)
_admin_dist = FilePath(__file__).parent / "admin-dashboard" / "dist"
if _admin_dist.is_dir():
    app.mount("/admin-panel", StaticFiles(directory=str(_admin_dist), html=True), name="admin-panel")
    logger.info(f"Admin dashboard mounted at /admin-panel from {_admin_dist}")
else:
    logger.warning(f"Admin dashboard not built yet. Run 'npm run build' in admin-dashboard/")


# --- Pydantic Models ---

class MovieMetadata(BaseModel):
    tmdb_id: int = Field(..., description="TMDB movie ID")
    title: str = Field(..., description="Movie title")
    original_title: Optional[str] = Field(None, description="Original title")
    poster: Optional[str] = Field(None, description="Poster URL")
    backdrop: Optional[str] = Field(None, description="Backdrop URL")
    rating: Optional[float] = Field(None, description="TMDB rating")
    release_date: Optional[str] = Field(None, description="Release date")
    overview: Optional[str] = Field(None, description="Movie overview")
    popularity: Optional[float] = Field(None, description="Popularity score")


class MovieDetails(MovieMetadata):
    runtime: Optional[int] = Field(None, description="Runtime in minutes")
    genres: Optional[List[str]] = Field(None, description="Genre list")
    tagline: Optional[str] = Field(None, description="Movie tagline")
    imdb_id: Optional[str] = Field(None, description="IMDB ID")


class DownloadLink(BaseModel):
    quality: str = Field(..., description="Video quality (480p, 720p, 1080p, etc)")
    url: str = Field(..., description="Download URL")
    name: str = Field(..., description="Link description")
    type: str = Field(..., description="Link type (Hindi, English, Dual Audio)")
    source: str = Field(..., description="Source website")


class HealthResponse(BaseModel):
    status: str
    message: str
    tmdb_enabled: bool
    scraper_sources: int


class ResolveDownloadRequest(BaseModel):
    """Request model for download link resolution."""
    url: str = Field(..., description="Intermediate download URL (HubDrive, GoFile, etc.)")
    quality: str = Field("1080p", description="Requested quality (for logging)")


# --- Helper ---

def _build_search_sources(title: str) -> List[dict]:
    """Build deterministic search URLs for each domain (no scraping needed)."""
    sources = [{"site": name, "url": f"{url}/?s={title}"} for name, url in DOMAINS.items()]
    # Add SkyMoviesHD source
    if MovieSources.SKYMOVIESHD_ENABLED:
        sources.append({
            "site": "SkyMoviesHD",
            "url": f"{MovieSources.SKYMOVIESHD_BASE_URL}/?s={title}"
        })
    # Add Cinefreak source
    if MovieSources.CINEFREAK_ENABLED:
        sources.append({
            "site": "Cinefreak",
            "url": f"{MovieSources.CINEFREAK_BASE_URL}/?s={title}"
        })
    return sources


# --- API Endpoints ---

@app.get("/", response_model=HealthResponse)
async def root():
    """Health check endpoint."""
    return {
        "status": "online",
        "message": "MovieHub API v2 is running",
        "tmdb_enabled": True,
        "scraper_sources": len(DOMAINS),
    }


@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Detailed health check."""
    return {
        "status": "healthy",
        "message": "All systems operational",
        "tmdb_enabled": True,
        "scraper_sources": len(DOMAINS),
    }


@app.get("/trending")
async def get_trending():
    """Get trending movies from TMDB."""
    try:
        logger.info("Fetching trending movies")
        movies = await tmdb_helper.get_trending_movies()

        results = []
        for movie in movies:
            results.append({
                **movie,
                "sources": [{"site": name, "url": f"tmdb_{movie['tmdb_id']}"} for name in DOMAINS],
            })

        return {"total_results": len(results), "results": results}
    except Exception as e:
        logger.error(f"Trending error: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch trending movies: {e}")


@app.get("/search")
async def search_movies(
    query: str = Query(..., description="Movie title to search", min_length=2, max_length=100)
):
    """
    Search movies via TMDB. Returns metadata + deterministic source URLs.
    No inline scraping — keeps response fast (~1s instead of ~10s).
    """
    results_count = 0
    try:
        logger.info(f"Search request: {query}")
        movies = await tmdb_helper.search_movie(query)

        results = []
        for movie in movies:
            results.append({
                "title": movie['title'],
                "sources": _build_search_sources(movie['title']),
                "tmdb_poster": movie.get('poster'),
                "rating": movie.get('rating'),
                "plot": movie.get('overview', 'No plot available'),
                "release_date": movie.get('release_date'),
                "tmdb_id": movie.get('tmdb_id'),
                "genre_ids": movie.get('genre_ids', []),
                "original_language": movie.get('original_language'),
            })

        results_count = len(results)
        return {"query": query, "results": results}
    except Exception as e:
        logger.error(f"Search error: {e}")
        return {"query": query, "results": []}
    finally:
        # Track search for admin analytics (fire-and-forget)
        try:
            await admin_db.insert(
                "INSERT INTO search_logs (query, results_count) VALUES (?, ?)",
                (query, results_count),
            )
        except Exception:
            pass


@app.get("/movie/{tmdb_id}", response_model=MovieDetails)
async def get_movie_details(
    tmdb_id: int = Path(..., description="TMDB movie ID")
):
    """Get detailed movie information from TMDB."""
    try:
        logger.info(f"Fetching details for TMDB ID: {tmdb_id}")
        movie = await tmdb_helper.get_movie_details(tmdb_id)

        if not movie:
            raise HTTPException(status_code=404, detail="Movie not found")

        return movie
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Movie details error: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch movie details: {e}")


@app.get("/links")
async def generate_download_links(
    tmdb_id: int = Query(..., description="TMDB movie ID"),
    title: str = Query(..., description="Movie title for searching"),
    year: Optional[str] = Query(None, description="Release year (optional)"),
    hdhub4u_url: Optional[str] = Query(None, description="Direct HDHub4u page URL (skips search)"),
    source: Optional[str] = Query(None, description="Source type: hdhub4u, skymovieshd, cinefreak, or all"),
    skymovieshd_url: Optional[str] = Query(None, description="Direct SkyMoviesHD page URL"),
    cinefreak_url: Optional[str] = Query(None, description="Direct Cinefreak page URL"),
):
    """
    Generate download AND streaming links for a movie.
    Searches HDHub4u + SkyMoviesHD in parallel and combines results.
    Returns both 'links' (download) and 'embed_links' (streaming).
    """
    try:
        if tmdb_id <= 0:
            logger.warning(f"Invalid TMDB ID received: {tmdb_id}")
            raise HTTPException(status_code=400, detail="Invalid TMDB ID")

        embed_links = []
        links = []
        used_source = 'multi'

        # Check for manual priority links first
        manual = await admin_db.fetch_all(
            "SELECT * FROM manual_links WHERE movie_title LIKE ? AND is_active = 1 ORDER BY priority DESC",
            (f"%{title}%",),
        )
        manual_links = [
            {
                "text": f"[PRIORITY] {m['source_name']} — {m['movie_title']}",
                "url": m['source_url'],
                "source": m['source_name'],
                "priority": True,
            }
            for m in manual
        ]

        # --- Case 1: SkyMoviesHD direct URL provided ---
        if source == 'skymovieshd' and skymovieshd_url:
            logger.info(f"Link request (SkyMoviesHD direct) - Title: '{title}', URL: {skymovieshd_url}")
            result = await multi_source.extract_links_from_source('skymovieshd', skymovieshd_url)
            links = result.get('links', [])
            embed_links = result.get('embed_links', [])
            used_source = 'skymovieshd'

        # --- Case 1b: Cinefreak direct URL provided ---
        elif source == 'cinefreak' and cinefreak_url:
            logger.info(f"Link request (Cinefreak direct) - Title: '{title}', URL: {cinefreak_url}")
            result = await multi_source.extract_links_from_source('cinefreak', cinefreak_url)
            links = result.get('links', [])
            embed_links = result.get('embed_links', [])
            used_source = 'cinefreak'

        # --- Case 2: HDHub4u direct URL provided ---
        elif source == 'hdhub4u' and hdhub4u_url:
            logger.info(f"Link request (HDHub4u direct) - Title: '{title}', URL: {hdhub4u_url}")
            links = await scraper_instance.extract_links_from_url(hdhub4u_url)
            # Also extract embed links from the same page
            try:
                context, page = await scraper_instance._new_stealth_page()
                try:
                    await page.goto(hdhub4u_url, wait_until='domcontentloaded', timeout=20000)
                    embed_links = await embed_extractor.extract_from_page(page, hdhub4u_url)
                finally:
                    await page.close()
                    await context.close()
            except Exception as e:
                logger.warning(f"Embed extraction failed (non-critical): {e}")
            used_source = 'hdhub4u'

        # --- Case 3: HDHub4u URL provided without explicit source ---
        elif hdhub4u_url:
            logger.info(f"Link request (HDHub4u direct, no source) - Title: '{title}', URL: {hdhub4u_url}")
            links = await scraper_instance.extract_links_from_url(hdhub4u_url)
            try:
                context, page = await scraper_instance._new_stealth_page()
                try:
                    await page.goto(hdhub4u_url, wait_until='domcontentloaded', timeout=20000)
                    embed_links = await embed_extractor.extract_from_page(page, hdhub4u_url)
                finally:
                    await page.close()
                    await context.close()
            except Exception as e:
                logger.warning(f"Embed extraction failed (non-critical): {e}")
            used_source = 'hdhub4u'

        # --- Case 4: No URL — search ALL sources in parallel ---
        else:
            logger.info(
                f"Link request (MULTI-SOURCE) - Title: '{title}', "
                f"TMDB ID: {tmdb_id}, Year: {year}"
            )
            result = await multi_source.extract_links_all_sources(
                title=title, year=year, tmdb_id=tmdb_id
            )
            links = result.get('links', [])
            embed_links = result.get('embed_links', [])
            used_source = 'multi'

        return {
            "url": f"tmdb_{tmdb_id}",
            "total_links": len(manual_links) + len(links),
            "links": manual_links + links,
            "embed_links": embed_links,
            "total_embed": len(embed_links),
            "source": used_source,
            "cached": False,
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Link generation failed for '{title}': {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/sources")
async def get_sources():
    """Get list of all available scraping sources (enabled via config)."""
    enabled = MovieSources.get_enabled_sources()
    return {
        "sources": enabled,
        "total": len(enabled),
    }


@app.delete("/cache/{tmdb_id}")
async def clear_cache(
    tmdb_id: int = Path(..., description="TMDB movie ID to clear from cache")
):
    """Clear cached links for a specific movie (forces fresh generation)."""
    try:
        await scraper_instance.cache.delete(f"tmdb_{tmdb_id}")
        logger.info(f"Cache cleared for TMDB ID: {tmdb_id}")
        return {"message": f"Cache cleared for movie {tmdb_id}"}
    except Exception as e:
        logger.error(f"Cache clear error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/browse/latest")
async def get_latest_from_hdhub4u(
    max_results: int = Query(50, ge=10, le=100),
    incremental: bool = Query(False, description="Only return new movies since last sync"),
):
    """Get latest movies from HDHub4u homepage with TMDB data.

    When `incremental=true`, only movies newer than the last sync are returned.
    First call (or after reset) always does a full sync.
    """
    try:
        logger.info(f"Scraping HDHub4u homepage (max={max_results}, incremental={incremental})")
        result = await hdhub4u_scraper.scrape_homepage(
            max_movies=max_results, incremental=incremental
        )

        logger.info(f"Scraped {result['total_new']} movies (mode={result['sync_mode']})")
        return {
            "source": "HDHub4u",
            "sync_mode": result["sync_mode"],
            "is_incremental": result["is_incremental"],
            "total": result["total_new"],
            "movies": result["movies"],
        }
    except Exception as e:
        logger.error(f"Browse latest error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/browse/latest/state")
async def get_sync_state():
    """Check the current incremental sync state."""
    return {
        "hdhub4u": homepage_state.get_info("hdhub4u"),
    }


@app.post("/browse/latest/reset")
async def reset_sync_state(
    source: str = Query("hdhub4u", description="Source to reset"),
):
    """Reset sync state to force a full sync on next call."""
    homepage_state.reset(source)
    return {"status": "ok", "message": f"{source} state reset — next call will be full sync"}


@app.get("/browse/{site}")
async def browse_latest_movies(
    site: str = Path(..., description="Site name: hdhub4u or katmoviehd"),
    page: int = Query(1, description="Page number", ge=1, le=10)
):
    """Browse latest movies from a specific site."""
    site_map = {"hdhub4u": "HDHub4u", "katmoviehd": "KatmovieHD"}

    site_name = site_map.get(site.lower())
    if not site_name or site_name not in DOMAINS:
        raise HTTPException(status_code=404, detail=f"Site '{site}' not found. Use 'hdhub4u' or 'katmoviehd'")

    try:
        base_url = DOMAINS[site_name]
        browse_url = f"{base_url}/page/{page}/" if page > 1 else base_url

        # Browser is already initialized via lifespan — no need to call startup()
        context = await scraper_instance.browser.new_context(
            user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        )
        page_obj = await context.new_page()

        try:
            logger.info(f"Browsing {site_name} - Page {page}")
            await page_obj.goto(browse_url, wait_until="domcontentloaded", timeout=20000)
            await asyncio.sleep(2)

            content = await page_obj.content()
            soup = BeautifulSoup(content, 'html.parser')

            movies = []
            for article in soup.find_all(['article', 'div'], class_=re.compile(r'post|item|movie')):
                title_elem = article.find(['h2', 'h3', 'a'])
                link_elem = article.find('a', href=True)

                if title_elem and link_elem:
                    title = title_elem.get_text(strip=True)
                    url = link_elem['href']

                    img = article.find('img')
                    thumbnail = (img.get('src') or img.get('data-src')) if img else None

                    if title and url and len(title) > 3:
                        movies.append({
                            "title": title,
                            "url": url,
                            "thumbnail": thumbnail,
                            "site": site_name,
                        })

            logger.info(f"Found {len(movies)} movies from {site_name} page {page}")
            return {"site": site_name, "page": page, "total": len(movies), "movies": movies}

        finally:
            await page_obj.close()
            await context.close()

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Browse error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# --- Download Link Resolution ---

@app.post("/api/resolve-download-link")
async def resolve_download_link(request: ResolveDownloadRequest):
    """
    Resolve an intermediate download link to a final direct file URL.

    Automates the manual browser steps:
    1. Navigate to file host page
    2. Click "Direct/Instant Download" button
    3. Wait for countdown timer
    4. Extract final download URL
    """
    try:
        logger.info(f"Resolving download link: {request.url}")
        result = await download_resolver.resolve_download_link(str(request.url))

        if result["success"]:
            logger.info(f"Successfully resolved: {result.get('filename')}")
            return {
                "status": "success",
                "direct_url": result["direct_url"],
                "filename": result.get("filename"),
                "filesize": result.get("filesize"),
                "original_url": str(request.url),
                "headers": {
                    "Cookie": result.get("cookies", ""),
                    "User-Agent": result.get("user_agent", ""),
                    "Referer": result.get("referer", ""),
                },
                "requires_headers": result.get("requires_headers", False),
            }
        else:
            logger.error(f"Resolution failed: {result.get('error')}")
            raise HTTPException(
                status_code=400,
                detail={
                    "status": "failed",
                    "error": result.get("error", "Unknown error"),
                    "original_url": str(request.url),
                },
            )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected resolution error: {e}")
        raise HTTPException(
            status_code=500,
            detail={"status": "error", "error": str(e), "original_url": str(request.url)},
        )


@app.get("/api/test-resolver")
async def test_resolver():
    """Debug: test the download resolver with a sample HubDrive link."""
    test_url = "https://hubdrive.space/file/5220296218"
    result = await download_resolver.resolve_download_link(test_url)
    return {"test_url": test_url, "result": result}


@app.get("/test/skymovieshd")
async def test_skymovieshd(
    movie_url: Optional[str] = Query(None, description="Direct SkyMoviesHD movie page URL"),
    search: Optional[str] = Query(None, description="Search query (alternative to URL)"),
):
    """
    🧪 Debug endpoint: test SkyMoviesHD extraction with full logging.
    
    Usage:
      /test/skymovieshd?movie_url=https://skymovieshd.mba/movie/...
      /test/skymovieshd?search=Tagar+2025
    """
    import time
    import traceback

    start = time.time()

    try:
        if not multi_source.sky_scraper:
            return {"error": "SkyMoviesHD scraper not initialized"}

        sky = multi_source.sky_scraper

        # Step 1: Search or use direct URL
        if search:
            logger.info(f"🧪 [TEST] Searching SkyMoviesHD for: {search}")
            results = await sky.search_movies(search, max_results=5)
            if not results:
                return {
                    "error": "No search results",
                    "query": search,
                    "elapsed": f"{time.time() - start:.1f}s",
                }
            movie_url = results[0].get('url')
            search_results = [
                {"title": r.get("title"), "url": r.get("url"), "quality": r.get("quality")}
                for r in results
            ]
        else:
            search_results = None

        if not movie_url:
            return {"error": "Provide movie_url or search parameter"}

        # Step 2: Extract links
        logger.info(f"🧪 [TEST] Extracting from: {movie_url}")
        extraction = await sky.extract_links(movie_url)

        elapsed = time.time() - start

        return {
            "status": "success",
            "movie_url": movie_url,
            "elapsed": f"{elapsed:.1f}s",
            "search_results": search_results,
            "links": extraction.get('links', []),
            "embed_links": extraction.get('embed_links', []),
            "intermediate_links": extraction.get('intermediate_links', []),
            "total_links": len(extraction.get('links', [])),
            "total_embeds": len(extraction.get('embed_links', [])),
            "total_intermediates": len(extraction.get('intermediate_links', [])),
        }

    except Exception as e:
        return {
            "error": str(e),
            "traceback": traceback.format_exc(),
            "elapsed": f"{time.time() - start:.1f}s",
        }


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port, log_level="info", timeout_keep_alive=120)