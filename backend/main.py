import os
import asyncio
from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel
from typing import Optional, List, Dict
from contextlib import asynccontextmanager
from scraper import scraper_instance

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Initialize shared browser
    await scraper_instance.startup()
    yield
    # Shutdown: Clean up shared browser
    await scraper_instance.shutdown()

app = FastAPI(
    title="MovieHub Scraper API",
    description="Professional Movie Scraper API with Fuzzy Matching, TMDB Enrichment, and De-duplication",
    lifespan=lifespan
)

# --- Models ---
class MovieSource(BaseModel):
    site: str
    url: str

class MovieResult(BaseModel):
    title: str
    sources: List[MovieSource]
    tmdb_poster: Optional[str] = None
    rating: Optional[float] = None
    plot: Optional[str] = None
    release_date: Optional[str] = None

class SearchResponse(BaseModel):
    query: str
    results: List[MovieResult]

class LinkResult(BaseModel):
    quality: str
    url: str
    name: str

class LinkResponse(BaseModel):
    url: str
    links: List[LinkResult]

# --- Endpoints ---
@app.get("/")
async def root():
    return {
        "status": "online", 
        "message": "MovieHub Scraper API is running professional mode",
        "features": ["Fuzzy Matching", "TMDB Enrichment", "SQLite Caching", "Parallel Scraping"]
    }

@app.get("/search", response_model=SearchResponse)
async def search(query: str = Query(..., description="The movie name to search for")):
    """
    Search multiple movie sites in parallel, merge results, and enrich with TMDB metadata.
    Uses SQLite caching for 24-hour persistence.
    """
    try:
        results = await scraper_instance.global_search(query)
        return SearchResponse(query=query, results=results)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Search failed: {str(e)}")

@app.get("/links", response_model=LinkResponse)
async def get_links(url: str = Query(..., description="The movie page URL to extract links from")):
    """
    Extract download/stream links from a specific movie page URL.
    """
    try:
        links = await scraper_instance.extract_links(url)
        if not links:
            raise HTTPException(status_code=404, detail="No links found for the given URL")
        return LinkResponse(url=url, links=links)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Link extraction failed: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
