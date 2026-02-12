import os
import asyncio
import re
import logging
from fastapi import FastAPI, HTTPException, Query, Path
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, HttpUrl
from typing import Optional, List
from contextlib import asynccontextmanager
from scraper import scraper_instance, tmdb_helper, DOMAINS
from hdhub4u_homepage_scraper import HDHub4uScraper
from hubdrive_resolver import DownloadLinkResolver
from embed_link_extractor import EmbedLinkExtractor
from multi_source_manager import MultiSourceManager
from config.sources import MovieSources
from bs4 import BeautifulSoup

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
        # Initialize multi-source scrapers (share browser)
        multi_source.init_scrapers(scraper_instance.browser)
        logger.info("HDHub4u scraper initialized (shared browser)")
        logger.info("Download link resolver initialized (shared browser)")
        logger.info("Multi-source manager initialized")
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
            })

        return {"query": query, "results": results}
    except Exception as e:
        logger.error(f"Search error: {e}")
        return {"query": query, "results": []}


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
    source: Optional[str] = Query(None, description="Source type: hdhub4u or skymovieshd"),
    skymovieshd_url: Optional[str] = Query(None, description="Direct SkyMoviesHD page URL"),
):
    """
    Generate download AND streaming links for a movie.
    Supports multiple sources: HDHub4u (default) and SkyMoviesHD.
    Returns both 'links' (download) and 'embed_links' (streaming).
    """
    try:
        if tmdb_id <= 0:
            logger.warning(f"Invalid TMDB ID received: {tmdb_id}")
            raise HTTPException(status_code=400, detail="Invalid TMDB ID")

        embed_links = []
        links = []

        # --- SkyMoviesHD source ---
        if source == 'skymovieshd' and skymovieshd_url:
            logger.info(f"Link request (SkyMoviesHD) - Title: '{title}', URL: {skymovieshd_url}")
            result = await multi_source.extract_links_from_source('skymovieshd', skymovieshd_url)
            links = result.get('links', [])
            embed_links = result.get('embed_links', [])

        # --- HDHub4u source (default) ---
        elif hdhub4u_url:
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
        else:
            logger.info(f"Link request (search) - Title: '{title}', TMDB ID: {tmdb_id}, Year: {year}")
            links = await scraper_instance.generate_download_links(tmdb_id, title, year)

        return {
            "url": f"tmdb_{tmdb_id}",
            "total_links": len(links),
            "links": links,
            "embed_links": embed_links,
            "total_embed": len(embed_links),
            "source": source or 'hdhub4u',
            "cached": False,
        }
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
    max_results: int = Query(50, ge=10, le=100)
):
    """Get latest movies from HDHub4u homepage with TMDB data."""
    try:
        logger.info(f"Scraping HDHub4u homepage (max_results={max_results})...")
        movies = await hdhub4u_scraper.scrape_homepage(max_movies=max_results)

        logger.info(f"Scraped {len(movies)} movies from HDHub4u")
        return {
            "source": "HDHub4u",
            "total": len(movies),
            "movies": movies,
        }
    except Exception as e:
        logger.error(f"Browse latest error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


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


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port, log_level="info", timeout_keep_alive=120)