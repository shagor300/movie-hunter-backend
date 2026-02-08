"Act as a Senior Reverse-Engineering Architect. I am scrapping the previous codebase. We are starting fresh with a new app named 'MovieHunter'.

The Problem with previous builds: They were just UI shells using TMDB. They could not download anything. The Goal: Build a 'Universal Link Resolver System'. The app must fetch metadata from TMDB, but for downloading, it must use a custom Python backend to Scrape & Extract direct links from external movie sites.

CORE ARCHITECTURE (Strictly Follow This):

1. THE BACKEND ENGINE (Python FastAPI + Playwright)

Role: This is the brain. It runs on a server (or PC for testing).

Technology: FastAPI (for API), Playwright (Headless Browser), BeautifulSoup (Parsing).

Key Function extract_links(movie_name):

Step 1: Receive movie name from Flutter app.

Step 2: Launch Headless Chromium. Navigate to a target movie repository (Design the logic for sites like 'HubCloud' or 'PixelDrain' structures).

Step 3 (Ad-Blocker): Intercept all network requests. Abort/Block any URL containing words like 'popads', 'adsterra', 'tracker'.

Step 4 (The Bypass): If a 'Click to Generate Link' button appears, automate the click. Wait for the timer.

Step 5: Extract the final .mkv or .mp4 URL from the video tag or download button.

Step 6: Return JSON: {"status": "success", "links": [{"quality": "1080p", "url": "http://real-file.mkv"}]}.

2. THE FRONTEND (Flutter - Functional UI)

Search Screen: Shows TMDB results.

Details Screen: Must have a 'Get Download Links' button.

Integration Logic:

When 'Get Download Links' is clicked -> Call Python API (POST /resolve).

Show a 'Hacking/Searching...' animation.

Display the list of links returned by Python.

Clicking a link starts the Flutter Downloader Manager.

3. DATABASE (Room & Settings)

Save 'Watchlist' and 'Download History' locally.

EXECUTION ORDER: First, write the backend/scraper.py code using Playwright that demonstrates how to bypass a generic 'Click to Continue' page and extract a link. Second, write the main.py (FastAPI) to expose this scraper. Third, provide the Flutter ResolverService.dart to connect the app to this backend.

Start by coding the Python Scraper Engine first. This is the most critical part."