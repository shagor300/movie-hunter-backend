Role: You are a Senior Python Developer specializing in Web Scraping and API Optimization.

Goal: Upgrade my current scraper.py and main.py by integrating professional-grade features to fix issues like wrong movie links, duplicate results, and slow performance.

Please add the following 5 features into the code:

Fuzzy Title Matching: Integrate thefuzz library to compare the search query with scraped titles. If the match score is below 75%, discard that result to avoid wrong movies like "The Watchers" appearing for "Shelter".

Result De-duplication: Implement a logic to merge results from different sources (YoMovies, HDHub4u,KatmovieHD,SkymoviesHD, CTGMovies). If multiple sites have the same movie, show it once but collect all available links inside it.

TMDB Metadata Integration: Use the TMDB API to fetch high-quality posters, ratings, and plot summaries based on the movie title found by the scraper.

Smart Domain Handler: Update the DOMAINS dictionary with the latest working links:

YoMovies: https://yomovies.top

HDHub4u: https://hdhub4u.tv

4khdhub: https://hdhub4u.cx

CTGMovies: http://ctgmovies.com

SkymoviesHD : https://skymovieshd.mba

KatmovieHD : https://new.katmoviehd.cymru

Caching Layer: Add a simple SQLite-based caching system to store search results for 24 hours. If a user searches for the same movie again, return the cached data instantly without re-scraping.

Technical Requirements:

Use asyncio.gather for parallel scraping.

Ensure the scraper_instance is correctly exported to avoid ImportError.

Add thefuzz and requests to the requirements/dependencies.

Please provide the full updated code for scraper.py and any necessary changes for main.py.