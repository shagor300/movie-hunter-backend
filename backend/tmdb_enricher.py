import asyncio
import aiohttp
import logging
from typing import List, Dict, Optional

logger = logging.getLogger(__name__)

class TMDBEnricher:
    """Enrich FTP movies with TMDB metadata"""
    
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.base_url = "https://api.themoviedb.org/3"
        self.image_base = "https://image.tmdb.org/t/p"
    
    async def enrich_movies(self, ftp_movies: List[Dict]) -> List[Dict]:
        """
        Enrich list of FTP movies with TMDB data
        Returns merged data: FTP info + TMDB metadata
        """
        if not ftp_movies:
            return []
        
        logger.info(f"[TMDB] Enriching {len(ftp_movies)} movies...")
        
        async with aiohttp.ClientSession() as session:
            tasks = [
                self._enrich_single_movie(session, movie)
                for movie in ftp_movies
            ]
            
            enriched = await asyncio.gather(*tasks, return_exceptions=True)
            
            # Filter out errors
            valid = [m for m in enriched if isinstance(m, dict)]
            
            logger.info(f"[TMDB] Successfully enriched {len(valid)}/{len(ftp_movies)} movies")
            return valid
    
    async def _enrich_single_movie(
        self, 
        session: aiohttp.ClientSession, 
        ftp_movie: Dict
    ) -> Dict:
        """Enrich single FTP movie with TMDB data"""
        
        try:
            # Search TMDB for this movie
            tmdb_data = await self._search_tmdb(
                session,
                ftp_movie['title'],
                ftp_movie.get('year')
            )
            
            if tmdb_data:
                # Merge FTP + TMDB data
                return {
                    # TMDB metadata (for display)
                    'id': tmdb_data.get('id'),
                    'title': tmdb_data.get('title', ftp_movie['title']),
                    'original_title': tmdb_data.get('original_title'),
                    'year': tmdb_data.get('release_date', '')[:4] if tmdb_data.get('release_date') else str(ftp_movie.get('year', '')),
                    'poster_path': tmdb_data.get('poster_path'),
                    'backdrop_path': tmdb_data.get('backdrop_path'),
                    'overview': tmdb_data.get('overview', ''),
                    'vote_average': tmdb_data.get('vote_average', 0),
                    'vote_count': tmdb_data.get('vote_count', 0),
                    'popularity': tmdb_data.get('popularity', 0),
                    'genre_ids': tmdb_data.get('genre_ids', []),
                    
                    # FTP data (for links)
                    'ftp_path': ftp_movie['ftp_path'],
                    'ftp_url': ftp_movie['ftp_url'],
                    'quality': ftp_movie['quality'],
                    'source': 'hybrid',  # Indicates FTP + TMDB
                    'has_links': True,   # Always true for FTP movies
                }
            else:
                # TMDB not found - use FTP data only
                logger.warning(f"[TMDB] Not found: {ftp_movie['title']}")
                return {
                    'id': hash(ftp_movie['title']),  # Generate fake ID
                    'title': ftp_movie['title'],
                    'year': str(ftp_movie.get('year', '')),
                    'poster_path': None,
                    'backdrop_path': None,
                    'overview': f"Available in {ftp_movie['quality']}",
                    'vote_average': 0,
                    'vote_count': 0,
                    'popularity': 0,
                    'genre_ids': [],
                    'ftp_path': ftp_movie['ftp_path'],
                    'ftp_url': ftp_movie['ftp_url'],
                    'quality': ftp_movie['quality'],
                    'source': 'ftp_only',
                    'has_links': True,
                }
        
        except Exception as e:
            logger.error(f"[TMDB] Enrich error for '{ftp_movie.get('title')}': {e}")
            # Return FTP-only data on error
            return {
                'id': hash(ftp_movie['title']),
                'title': ftp_movie['title'],
                'year': str(ftp_movie.get('year', '')),
                'poster_path': None,
                'overview': '',
                'ftp_path': ftp_movie['ftp_path'],
                'ftp_url': ftp_movie['ftp_url'],
                'quality': ftp_movie['quality'],
                'source': 'ftp_only',
                'has_links': True,
            }
    
    async def _search_tmdb(
        self,
        session: aiohttp.ClientSession,
        title: str,
        year: Optional[int] = None
    ) -> Optional[Dict]:
        """Search TMDB for a movie"""
        
        try:
            params = {
                'api_key': self.api_key,
                'query': title,
                'language': 'en-US',
            }
            
            if year and year != '' and int(year) > 1900:
                params['year'] = year
            
            url = f"{self.base_url}/search/movie"
            
            async with session.get(url, params=params, timeout=5) as response:
                if response.status == 200:
                    data = await response.json()
                    
                    if data.get('results') and len(data['results']) > 0:
                        # Return first match
                        return data['results'][0]
            
            return None
        
        except asyncio.TimeoutError:
            logger.warning(f"[TMDB] Timeout for: {title}")
            return None
        except Exception as e:
            logger.warning(f"[TMDB] Search error for '{title}': {e}")
            return None
