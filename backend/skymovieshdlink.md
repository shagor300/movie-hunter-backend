================================================================================
  SKYMOVIESHD → GOOGLE DRIVE LINK EXTRACTION WORKFLOW
  Advanced Plaintext Structure & Implementation Guide
================================================================================

VERSION: 3.0
AUTHOR: MovieHunter Team
DATE: 2026-02-13
TARGET: Extract Google Drive direct links from SkyMoviesHD

================================================================================
  TABLE OF CONTENTS
================================================================================

1. OVERVIEW
2. WORKFLOW DIAGRAM
3. STEP-BY-STEP PROCESS
4. DATA STRUCTURES
5. ALGORITHM DETAILS
6. ERROR HANDLING
7. EXAMPLE EXECUTION
8. PERFORMANCE METRICS

================================================================================
  1. OVERVIEW
================================================================================

PURPOSE:
    Extract direct Google Drive download links from SkyMoviesHD by navigating
    through intermediate file hosting pages (HubDrive, HubCloud, GDFlix, etc.)

INPUT:
    - Movie Name: String (e.g., "Inception")
    - Year: Integer (optional, e.g., 2010)

OUTPUT:
    - List of Google Drive URLs with metadata:
        * Google Drive direct link
        * Quality (1080p, 720p, etc.)
        * Source host (hubdrive, hubcloud, gdflix)

CHALLENGE:
    SkyMoviesHD doesn't directly expose Google Drive links. Instead:
    1. Movie page contains intermediate host links
    2. Each intermediate page requires button clicking + timer waiting
    3. Final Google Drive link is hidden behind these intermediates

SOLUTION:
    Automated browser automation using Playwright to:
    - Search movie
    - Extract intermediate links
    - Visit each intermediate page
    - Extract final Google Drive URLs

================================================================================
  2. WORKFLOW DIAGRAM
================================================================================

┌─────────────────────────────────────────────────────────────────────────┐
│  START: extract_google_drive_links(movie_name, year)                    │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │   STEP 1: SEARCH        │
                    │   skymovieshd.mba/?s=   │
                    └────────────┬────────────┘
                                 │
                      ┌──────────▼──────────┐
                      │  Found movie page?  │
                      └──────────┬──────────┘
                                 │
                        ┌────────▼────────┐
                        │  YES  │   NO    │
                        │       │    │    │
                        │       │    └────┼──> ERROR: Movie not found
                        │       │         │
                    ┌───▼───────▼───┐     │
                    │  STEP 2: OPEN │     │
                    │  Movie Page   │     │
                    └───────┬───────┘     │
                            │             │
                ┌───────────▼───────────┐ │
                │  STEP 3: EXTRACT      │ │
                │  Intermediate Links   │ │
                │  (HubDrive, HubCloud, │ │
                │   GDFlix, etc.)       │ │
                └───────┬───────────────┘ │
                        │                 │
              ┌─────────▼─────────┐       │
              │  Found any links? │       │
              └─────────┬─────────┘       │
                        │                 │
               ┌────────▼────────┐        │
               │  YES  │   NO    │        │
               │       │    │    │        │
               │       │    └────┼────────┼──> ERROR: No links found
               │       │         │        │
    ┌──────────▼───────▼──────┐  │        │
    │  STEP 4: LOOP THROUGH   │  │        │
    │  Each Intermediate Link │  │        │
    └──────────┬──────────────┘  │        │
               │                 │        │
    ┌──────────▼──────────────┐  │        │
    │  For each link:         │  │        │
    │  1. Identify host type  │  │        │
    │  2. Visit page          │  │        │
    │  3. Extract GDrive URL  │  │        │
    └──────────┬──────────────┘  │        │
               │                 │        │
    ┌──────────▼──────────────┐  │        │
    │  STEP 5: COLLECT        │  │        │
    │  All Google Drive URLs  │  │        │
    └──────────┬──────────────┘  │        │
               │                 │        │
    ┌──────────▼──────────────┐  │        │
    │  OUTPUT: Return list of │  │        │
    │  Google Drive links     │  │        │
    └─────────────────────────┘  │        │
                                 │        │
                                 ▼        ▼
                            ┌─────────────────┐
                            │   END RESULT    │
                            └─────────────────┘

================================================================================
  3. STEP-BY-STEP PROCESS
================================================================================

┌─────────────────────────────────────────────────────────────────────────┐
│  STEP 1: SEARCH MOVIE ON SKYMOVIESHD                                    │
└─────────────────────────────────────────────────────────────────────────┘

    INPUT:
        - movie_name: "Inception"
        - year: 2010

    PROCESS:
        1.1. Build search URL:
             URL = "https://skymovieshd.mba/?s=Inception"
        
        1.2. Navigate to search page
             TIMEOUT: 30 seconds
             WAIT_UNTIL: domcontentloaded
        
        1.3. Extract search results:
             SELECTOR: "article, .post, .movie-item"
             FOR EACH result:
                 - Extract title from: ".entry-title, h2, h3, .title"
                 - Extract URL from: "a[href*='skymovieshd']"
        
        1.4. Match results with search query:
             ALGORITHM:
                 IF movie_name.lower() IN result.title.lower():
                     IF year PROVIDED:
                         IF str(year) IN result.title:
                             RETURN result.url
                     ELSE:
                         RETURN result.url
             
             FALLBACK:
                 IF no exact match:
                     RETURN first result
    
    OUTPUT:
        - movie_page_url: "https://skymovieshd.mba/inception-2010-..."
    
    ERROR CASES:
        - No results found → RETURN None
        - Network timeout → RETRY (max 3 attempts)
        - HTTP error (4xx, 5xx) → RETURN None

┌─────────────────────────────────────────────────────────────────────────┐
│  STEP 2: NAVIGATE TO MOVIE DETAIL PAGE                                  │
└─────────────────────────────────────────────────────────────────────────┘

    INPUT:
        - movie_page_url: "https://skymovieshd.mba/inception-2010-..."
    
    PROCESS:
        2.1. Navigate to movie page:
             METHOD: page.goto(url)
             TIMEOUT: 30 seconds
             WAIT_UNTIL: domcontentloaded
        
        2.2. Wait for page to stabilize:
             WAIT: 2 seconds
        
        2.3. Verify page loaded successfully:
             CHECK: response.status < 400
    
    OUTPUT:
        - success: True/False
    
    ERROR CASES:
        - HTTP error → RETURN False
        - Timeout → RETURN False

┌─────────────────────────────────────────────────────────────────────────┐
│  STEP 3: EXTRACT INTERMEDIATE HOST LINKS                                │
└─────────────────────────────────────────────────────────────────────────┘

    INPUT:
        - Current page: Movie detail page
    
    PROCESS:
        3.1. Scan all links on page:
             SELECTOR: "a[href]"
             EXTRACT:
                 - href
                 - text content
                 - CSS classes
        
        3.2. Filter intermediate host links:
             FOR EACH link:
                 domain = extract_domain(link.href)
                 
                 IF domain IN INTERMEDIATE_HOSTS:
                     host_type = identify_host(domain)
                     quality = extract_quality(link.text)
                     
                     ADD TO intermediate_links:
                         - url: link.href
                         - host_type: "hubdrive"|"hubcloud"|"gdflix"
                         - quality: "1080p"|"720p"|"480p"|"HD"
                         - text: link.text
        
        3.3. Deduplicate links:
             ALGORITHM:
                 seen_urls = SET()
                 unique_links = LIST()
                 
                 FOR EACH link IN intermediate_links:
                     IF link.url NOT IN seen_urls:
                         seen_urls.add(link.url)
                         unique_links.add(link)
                 
                 RETURN unique_links
    
    INTERMEDIATE_HOSTS = {
        'hubdrive': ['hubdrive.space', 'hubdrive.dad'],
        'hubcloud': ['hubcloud.foo'],
        'gdflix': ['gdflix.dev', 'new1.gdflix.app'],
        'dgdrive': ['dgdrive.site'],
        'filepress': ['filepress.wiki', 'new1.filepress.wiki'],
    }
    
    OUTPUT:
        - intermediate_links: [
            {
                url: "https://hubdrive.space/file/123",
                host_type: "hubdrive",
                quality: "1080p",
                text: "HubDrive 1080p"
            },
            {
                url: "https://gdflix.dev/file/456",
                host_type: "gdflix",
                quality: "720p",
                text: "GDFlix 720p"
            },
            ...
          ]
    
    ERROR CASES:
        - No links found → RETURN empty list
        - JavaScript error → LOG and continue

┌─────────────────────────────────────────────────────────────────────────┐
│  STEP 4: EXTRACT GOOGLE DRIVE LINKS FROM INTERMEDIATE HOSTS             │
└─────────────────────────────────────────────────────────────────────────┘

    INPUT:
        - intermediate_links: List of intermediate host URLs
    
    PROCESS:
        4.1. FOR EACH intermediate_link IN intermediate_links:
        
            4.1.1. Create new browser page:
                   page = browser.new_page()
                   page.set_default_timeout(20000)
            
            4.1.2. Navigate to intermediate page:
                   page.goto(intermediate_link.url)
                   WAIT: 2 seconds
            
            4.1.3. Extract Google Drive URL using MULTI-METHOD APPROACH:
            
                   ┌──────────────────────────────────────┐
                   │  METHOD 1: Direct Links             │
                   └──────────────────────────────────────┘
                   
                   SELECTOR: 'a[href*="drive.google.com"]'
                   ACTION: Extract href attribute
                   
                   IF found:
                       RETURN google_drive_url
                   
                   ┌──────────────────────────────────────┐
                   │  METHOD 2: Click Download Button    │
                   └──────────────────────────────────────┘
                   
                   SELECTORS (try in order):
                       - 'a:has-text("Download")'
                       - 'button:has-text("Download")'
                       - 'a:has-text("Get Link")'
                       - 'a.btn-download'
                       - '.download-btn'
                       - '#download-button'
                   
                   FOR EACH selector:
                       TRY:
                           button = find_element(selector)
                           IF button exists:
                               button.click()
                               WAIT: 5 seconds
                               
                               IF current_url contains "drive.google.com":
                                   RETURN current_url
                               
                               ELSE:
                                   links = find_all('a[href*="drive.google.com"]')
                                   IF links found:
                                       RETURN links[0]
                   
                   ┌──────────────────────────────────────┐
                   │  METHOD 3: Check Iframes             │
                   └──────────────────────────────────────┘
                   
                   SELECTOR: 'iframe[src*="drive.google.com"]'
                   ACTION: Extract src attribute
                   
                   IF found:
                       RETURN iframe_src
                   
                   ┌──────────────────────────────────────┐
                   │  METHOD 4: Parse Page Content        │
                   └──────────────────────────────────────┘
                   
                   content = page.content()
                   REGEX: 'https://drive\.google\.com/[^\s"\'\)]+'
                   matches = find_all_regex_matches(content)
                   
                   IF matches found:
                       RETURN matches[0]
            
            4.1.4. Store result:
                   IF google_drive_url found:
                       ADD TO results:
                           - url: google_drive_url
                           - quality: intermediate_link.quality
                           - source_host: intermediate_link.host_type
                           - original_url: intermediate_link.url
            
            4.1.5. Cleanup:
                   page.close()
        
        4.2. RETURN all collected Google Drive URLs
    
    OUTPUT:
        - google_drive_links: [
            {
                url: "https://drive.google.com/file/d/ABC123/view",
                quality: "1080p",
                source_host: "hubdrive",
                original_url: "https://hubdrive.space/file/123"
            },
            {
                url: "https://drive.google.com/file/d/XYZ789/view",
                quality: "720p",
                source_host: "gdflix",
                original_url: "https://gdflix.dev/file/456"
            },
            ...
          ]
    
    ERROR CASES:
        - No Google Drive link found on page → LOG and continue to next
        - Page load timeout → LOG and continue to next
        - Button click fails → Try next method

┌─────────────────────────────────────────────────────────────────────────┐
│  STEP 5: FORMAT AND RETURN RESULTS                                      │
└─────────────────────────────────────────────────────────────────────────┘

    INPUT:
        - google_drive_links: List of extracted Google Drive URLs
    
    PROCESS:
        5.1. Format final response:
             response = {
                 success: True,
                 movie_name: "Inception",
                 google_drive_links: [
                     {
                         url: "https://drive.google.com/file/d/...",
                         quality: "1080p",
                         source_host: "hubdrive",
                         original_url: "https://hubdrive.space/..."
                     },
                     ...
                 ],
                 total_links: 5,
                 intermediate_links: [...],  // For debugging
             }
        
        5.2. RETURN response
    
    OUTPUT:
        - Final response dictionary

================================================================================
  4. DATA STRUCTURES
================================================================================

┌─────────────────────────────────────────────────────────────────────────┐
│  INPUT DATA STRUCTURE                                                    │
└─────────────────────────────────────────────────────────────────────────┘

    {
        "movie_name": String,      // Required, e.g., "Inception"
        "year": Integer | None,    // Optional, e.g., 2010
    }

┌─────────────────────────────────────────────────────────────────────────┐
│  INTERMEDIATE LINK STRUCTURE                                             │
└─────────────────────────────────────────────────────────────────────────┘

    {
        "url": String,             // Full URL to intermediate host
        "host_type": String,       // "hubdrive"|"hubcloud"|"gdflix"|etc.
        "quality": String,         // "1080p"|"720p"|"480p"|"HD"|"4K"
        "text": String,            // Link text from page
    }
    
    EXAMPLE:
    {
        "url": "https://hubdrive.space/file/1819627699",
        "host_type": "hubdrive",
        "quality": "1080p",
        "text": "HubDrive 1080p Download"
    }

┌─────────────────────────────────────────────────────────────────────────┐
│  GOOGLE DRIVE LINK STRUCTURE                                             │
└─────────────────────────────────────────────────────────────────────────┘

    {
        "url": String,             // Google Drive URL
        "quality": String,         // Inherited from intermediate link
        "source_host": String,     // Which intermediate host provided this
        "original_url": String,    // Original intermediate URL
    }
    
    EXAMPLE:
    {
        "url": "https://drive.google.com/file/d/1a2b3c4d5e6f/view",
        "quality": "1080p",
        "source_host": "hubdrive",
        "original_url": "https://hubdrive.space/file/1819627699"
    }

┌─────────────────────────────────────────────────────────────────────────┐
│  FINAL OUTPUT STRUCTURE                                                  │
└─────────────────────────────────────────────────────────────────────────┘

    {
        "success": Boolean,                    // True if any links found
        "movie_name": String,                  // Original query
        "google_drive_links": Array<Object>,   // List of Google Drive URLs
        "total_links": Integer,                // Count of links found
        "intermediate_links": Array<Object>,   // For debugging
        "error": String | None,                // Error message if failed
    }
    
    SUCCESS EXAMPLE:
    {
        "success": true,
        "movie_name": "Inception",
        "google_drive_links": [
            {
                "url": "https://drive.google.com/file/d/ABC/view",
                "quality": "1080p",
                "source_host": "hubdrive",
                "original_url": "https://hubdrive.space/file/123"
            },
            {
                "url": "https://drive.google.com/file/d/XYZ/view",
                "quality": "720p",
                "source_host": "gdflix",
                "original_url": "https://gdflix.dev/file/456"
            }
        ],
        "total_links": 2,
        "intermediate_links": [...]
    }
    
    FAILURE EXAMPLE:
    {
        "success": false,
        "movie_name": "NonexistentMovie",
        "google_drive_links": [],
        "total_links": 0,
        "error": "Movie not found on SkyMoviesHD"
    }

================================================================================
  5. ALGORITHM DETAILS
================================================================================

┌─────────────────────────────────────────────────────────────────────────┐
│  HOST IDENTIFICATION ALGORITHM                                           │
└─────────────────────────────────────────────────────────────────────────┘

    FUNCTION identify_intermediate_host(url: String) -> String | None:
        
        parsed = parse_url(url)
        domain = parsed.netloc.lower()
        
        FOR EACH (host_type, domains) IN INTERMEDIATE_HOSTS:
            FOR EACH host_domain IN domains:
                IF host_domain IN domain:
                    RETURN host_type
        
        RETURN None
    
    TIME COMPLEXITY: O(n * m)
        where n = number of host types
              m = average domains per host type
    
    SPACE COMPLEXITY: O(1)

┌─────────────────────────────────────────────────────────────────────────┐
│  QUALITY EXTRACTION ALGORITHM                                            │
└─────────────────────────────────────────────────────────────────────────┘

    FUNCTION extract_quality(text: String) -> String:
        
        text_lower = text.to_lower()
        
        IF '4k' IN text_lower OR '2160p' IN text_lower:
            RETURN '4K'
        ELSE IF '1080p' IN text_lower:
            RETURN '1080p'
        ELSE IF '720p' IN text_lower:
            RETURN '720p'
        ELSE IF '480p' IN text_lower:
            RETURN '480p'
        ELSE:
            RETURN 'HD'
    
    TIME COMPLEXITY: O(n)
        where n = length of text
    
    SPACE COMPLEXITY: O(1)

┌─────────────────────────────────────────────────────────────────────────┐
│  DEDUPLICATION ALGORITHM                                                 │
└─────────────────────────────────────────────────────────────────────────┘

    FUNCTION deduplicate_links(links: List<Dict>) -> List<Dict>:
        
        seen_urls = SET()
        unique_links = LIST()
        
        FOR EACH link IN links:
            IF link.url NOT IN seen_urls:
                seen_urls.add(link.url)
                unique_links.append(link)
        
        RETURN unique_links
    
    TIME COMPLEXITY: O(n)
        where n = number of links
    
    SPACE COMPLEXITY: O(n)
        for storing seen URLs

┌─────────────────────────────────────────────────────────────────────────┐
│  MULTI-METHOD EXTRACTION ALGORITHM                                       │
└─────────────────────────────────────────────────────────────────────────┘

    FUNCTION extract_gdrive_from_page(page: Page, url: String) -> String | None:
        
        // Method 1: Direct links
        direct_links = page.query_all('a[href*="drive.google.com"]')
        IF direct_links.length > 0:
            RETURN direct_links[0].href
        
        // Method 2: Button clicking
        SELECTORS = [
            'a:has-text("Download")',
            'button:has-text("Download")',
            'a.btn-download',
            ...
        ]
        
        FOR EACH selector IN SELECTORS:
            TRY:
                button = page.wait_for_selector(selector, timeout=3s)
                IF button EXISTS:
                    button.click()
                    WAIT 5 seconds
                    
                    IF 'drive.google.com' IN page.url:
                        RETURN page.url
                    
                    new_links = page.query_all('a[href*="drive.google.com"]')
                    IF new_links.length > 0:
                        RETURN new_links[0].href
                    
                    BREAK
            CATCH timeout:
                CONTINUE
        
        // Method 3: Iframes
        iframes = page.query_all('iframe[src*="drive.google.com"]')
        IF iframes.length > 0:
            RETURN iframes[0].src
        
        // Method 4: Regex search
        content = page.content()
        matches = REGEX_FIND_ALL(content, 'https://drive\.google\.com/[^\s"\'\)]+')
        IF matches.length > 0:
            RETURN matches[0]
        
        RETURN None
    
    TIME COMPLEXITY: O(n + m + k)
        where n = time to load page
              m = time to try selectors
              k = time to parse content
    
    SPACE COMPLEXITY: O(p)
        where p = size of page content

================================================================================
  6. ERROR HANDLING
================================================================================

┌─────────────────────────────────────────────────────────────────────────┐
│  ERROR TYPES AND RECOVERY STRATEGIES                                     │
└─────────────────────────────────────────────────────────────────────────┘

    ERROR TYPE: Network Timeout
    LOCATION: Any network request
    STRATEGY:
        - RETRY 3 times with exponential backoff
        - IF still fails: LOG and continue to next step
        - RETURN partial results if any
    
    ERROR TYPE: Movie Not Found
    LOCATION: Step 1 (Search)
    STRATEGY:
        - RETURN error response immediately
        - error: "Movie not found on SkyMoviesHD"
        - success: False
    
    ERROR TYPE: No Intermediate Links
    LOCATION: Step 3 (Extract intermediate links)
    STRATEGY:
        - LOG warning
        - RETURN error response
        - error: "No intermediate host links found"
    
    ERROR TYPE: Intermediate Page Load Failure
    LOCATION: Step 4 (Visit intermediate pages)
    STRATEGY:
        - LOG error for this specific link
        - CONTINUE to next intermediate link
        - DO NOT fail entire extraction
    
    ERROR TYPE: Google Drive Link Not Found
    LOCATION: Step 4 (Extract from intermediate page)
    STRATEGY:
        - TRY all 4 methods
        - IF all fail: LOG and continue to next link
        - DO NOT fail entire extraction
    
    ERROR TYPE: Browser Crash
    LOCATION: Any step
    STRATEGY:
        - CATCH exception
        - CLOSE all pages
        - RETURN error response
        - error: "Browser error: [details]"

┌─────────────────────────────────────────────────────────────────────────┐
│  TIMEOUT CONFIGURATION                                                   │
└─────────────────────────────────────────────────────────────────────────┘

    OPERATION                           TIMEOUT     RETRY
    ─────────────────────────────────  ─────────   ─────
    Search page navigation              30s         Yes (3x)
    Movie page navigation               30s         Yes (3x)
    Intermediate page navigation        20s         No
    Element wait (button, link)         3-5s        No
    Button click wait                   5s          N/A
    Page content extraction             N/A         N/A

================================================================================
  7. EXAMPLE EXECUTION
================================================================================

┌─────────────────────────────────────────────────────────────────────────┐
│  EXAMPLE: Extract links for "Inception (2010)"                          │
└─────────────────────────────────────────────────────────────────────────┘

INPUT:
    movie_name = "Inception"
    year = 2010

EXECUTION LOG:

    [00:00.000] 🎬 Starting extraction for: Inception (2010)
    [00:00.050] 📍 Step 1: Searching movie on SkyMoviesHD...
    [00:00.100] GET https://skymovieshd.mba/?s=Inception
    [00:02.150] ✅ Found 5 search results
    [00:02.200] 🎯 Matched: "Inception (2010) Multi Audio [Hindi+English]"
    [00:02.250] ✅ Movie page URL: https://skymovieshd.mba/inception-2010-...
    
    [00:02.300] 📍 Step 2: Opening movie detail page...
    [00:02.350] GET https://skymovieshd.mba/inception-2010-...
    [00:04.400] ✅ Movie page loaded successfully
    
    [00:04.450] 📍 Step 3: Extracting intermediate links...
    [00:04.500] Found 247 total links on page
    [00:04.600] 🔍 Filtering intermediate host links...
    [00:04.650] ✅ Found hubdrive link: 1080p
    [00:04.700] ✅ Found hubdrive link: 720p
    [00:04.750] ✅ Found hubcloud link: 1080p
    [00:04.800] ✅ Found gdflix link: 720p
    [00:04.850] ✅ Found 6 unique intermediate links
    
    [00:04.900] 📍 Step 4: Extracting Google Drive URLs...
    
    [00:04.950] [1/6] Processing hubdrive: https://hubdrive.space/file/123...
    [00:05.000] GET https://hubdrive.space/file/123
    [00:07.050] 🖱️  Found download button
    [00:07.100] 🖱️  Clicking button...
    [00:12.150] ✅ Found Google Drive link after click
    [00:12.200] ✅ Extracted: https://drive.google.com/file/d/ABC.../view
    
    [00:12.250] [2/6] Processing hubdrive: https://hubdrive.space/file/456...
    [00:12.300] GET https://hubdrive.space/file/456
    [00:14.350] 🖱️  Found download button
    [00:14.400] 🖱️  Clicking button...
    [00:19.450] ✅ Found Google Drive link after click
    [00:19.500] ✅ Extracted: https://drive.google.com/file/d/DEF.../view
    
    [00:19.550] [3/6] Processing hubcloud: https://hubcloud.foo/drive/789...
    [00:19.600] GET https://hubcloud.foo/drive/789
    [00:21.650] 🖱️  Found download button
    [00:21.700] 🖱️  Clicking button...
    [00:26.750] ✅ Found Google Drive link after click
    [00:26.800] ✅ Extracted: https://drive.google.com/file/d/GHI.../view
    
    [00:26.850] [4/6] Processing gdflix: https://gdflix.dev/file/xyz...
    [00:26.900] GET https://gdflix.dev/file/xyz
    [00:28.950] 🖱️  Found download button
    [00:29.000] 🖱️  Clicking button...
    [00:34.050] ✅ Found Google Drive link after click
    [00:34.100] ✅ Extracted: https://drive.google.com/file/d/JKL.../view
    
    [00:34.150] [5/6] Processing gdflix: https://gdflix.dev/file/abc...
    [00:34.200] GET https://gdflix.dev/file/abc
    [00:36.250] 🖱️  Found download button
    [00:36.300] 🖱️  Clicking button...
    [00:41.350] ✅ Found Google Drive link after click
    [00:41.400] ✅ Extracted: https://drive.google.com/file/d/MNO.../view
    
    [00:41.450] [6/6] Processing filepress: https://filepress.wiki/file/def...
    [00:41.500] GET https://filepress.wiki/file/def
    [00:43.550] ❌ No Google Drive link found
    [00:43.600] ⚠️  Skipping this link
    
    [00:43.650] ✅ Extraction complete!
    [00:43.700] 📊 Found 5 Google Drive links from 6 intermediate links

OUTPUT:

    {
        "success": true,
        "movie_name": "Inception",
        "google_drive_links": [
            {
                "url": "https://drive.google.com/file/d/ABC123/view",
                "quality": "1080p",
                "source_host": "hubdrive",
                "original_url": "https://hubdrive.space/file/123"
            },
            {
                "url": "https://drive.google.com/file/d/DEF456/view",
                "quality": "720p",
                "source_host": "hubdrive",
                "original_url": "https://hubdrive.space/file/456"
            },
            {
                "url": "https://drive.google.com/file/d/GHI789/view",
                "quality": "1080p",
                "source_host": "hubcloud",
                "original_url": "https://hubcloud.foo/drive/789"
            },
            {
                "url": "https://drive.google.com/file/d/JKL012/view",
                "quality": "720p",
                "source_host": "gdflix",
                "original_url": "https://gdflix.dev/file/xyz"
            },
            {
                "url": "https://drive.google.com/file/d/MNO345/view",
                "quality": "480p",
                "source_host": "gdflix",
                "original_url": "https://gdflix.dev/file/abc"
            }
        ],
        "total_links": 5,
        "intermediate_links": [...]
    }

PERFORMANCE METRICS:

    Total Execution Time:  43.7 seconds
    Search Time:           2.2 seconds
    Movie Page Load:       2.1 seconds
    Link Extraction:       0.4 seconds
    GDrive Extraction:     38.7 seconds (6 links)
    Average per Link:      6.5 seconds
    Success Rate:          83% (5/6 links)

================================================================================
  8. PERFORMANCE METRICS
================================================================================

┌─────────────────────────────────────────────────────────────────────────┐
│  EXPECTED PERFORMANCE                                                    │
└─────────────────────────────────────────────────────────────────────────┘

    METRIC                              TYPICAL     WORST CASE
    ─────────────────────────────────  ──────────  ────────────
    Search Time                         2-3 sec     10 sec
    Movie Page Load                     2-3 sec     10 sec
    Intermediate Link Extraction        0.5 sec     2 sec
    Per Intermediate Page:              6-8 sec     20 sec
    Total (5 intermediate links):       35-45 sec   120 sec

┌─────────────────────────────────────────────────────────────────────────┐
│  OPTIMIZATION OPPORTUNITIES                                              │
└─────────────────────────────────────────────────────────────────────────┘

    1. PARALLEL PROCESSING:
       - Process multiple intermediate links simultaneously
       - Potential speedup: 3-5x
       - Trade-off: Higher memory usage
    
    2. CACHING:
       - Cache Google Drive URLs by intermediate URL
       - Cache duration: 24 hours
       - Reduces: Repeated intermediate page visits
    
    3. SMART SELECTOR ORDERING:
       - Order selectors by success rate
       - Track which selectors work most often
       - Skip failing selectors faster
    
    4. EARLY TERMINATION:
       - Stop after finding N links (e.g., 3)
       - Good for quick previews
       - Trade-off: Miss some quality options

================================================================================
  END OF DOCUMENT
================================================================================

For implementation code, see:
    - skymovieshd_gdrive_extractor.py

For API integration:
    - Add to main.py as endpoint: /api/extract-skymovieshd-gdrive

For testing:
    - Run test_extractor() function
    - Try with popular movies first

Last Updated: 2026-02-13
Version: 3.0