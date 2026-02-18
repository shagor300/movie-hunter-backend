Hi Antigravity,

Please implement a NEW scraper for Cinefreak.net with the following specifications:

TARGET: https://cinefreak.net/

WORKFLOW:
1. Search for movie (e.g., "O'Romeo")
2. Click on correct movie post (match by title + year)
3. Scroll to "Download Links" section
4. Extract 3 quality links:
   - 480p: Under "Download Links" header
   - 720p: Next to "Watch Online"
   - 1080p: Next to "Watch Online"

TECHNICAL REQUIREMENTS:
- Use shared Playwright browser (memory efficient)
- Set 40s timeout for Cloudflare bypass
- Extract cinecloud.site URLs (format: https://new5.cinecloud.site/f/xxxxx)
- Return as: [{quality: '480p', url: '...', source: 'Cinefreak'}]

INTEGRATION:
- Add to MultiSourceManager
- Follow same pattern as HDHub4u/SkyMoviesHD scrapers
- Ensure links work with existing DownloadLinkResolver

OUTPUT FORMAT:
[
  {
    "quality": "480p SD",
    "size": "580 MB",
    "url": "https://new5.cinecloud.site/f/87fc11f8",
    "source": "Cinefreak",
    "type": "download"
  },
  {
    "quality": "720p HD", 
    "size": "1.3 GB",
    "url": "https://new5.cinecloud.site/f/202686dc",
    "source": "Cinefreak",
    "type": "download"
  },
  {
    "quality": "1080p HD",
    "size": "2.8 GB", 
    "url": "https://new5.cinecloud.site/f/c34cf250",
    "source": "Cinefreak",
    "type": "download"
  }
]

This scraper will add a third source to our multi-source system (HDHub4u, SkyMoviesHD, Cinefreak).

Please implement following the existing scraper patterns.

Thank you!






: CINEFREAK MOVIE LINK EXTRACTOR

├── [STEP 1] TARGET WEBSITE:
│   └── URL: https://cinefreak.net/
│
├── [STEP 2] ACTION: SEARCH
│   └── Query: "O'Romeo"
│   └── Process: Enter text in search bar -> Click Search Icon
│
├── [STEP 3] ACTION: NAVIGATION
│   └── Target: Open the "O'Romeo (2026)" movie poster/post
│   └── Position: Scroll down to the "Download Links" section
│
├── [STEP 4] DATA EXTRACTION (MAIN GOAL):
│   ├── Target 1: [480p SD - 580 MB]
│   │   └── Find Link: Beneath "Download Links" text
│   │   └── URL Format: https://new5.cinecloud.site/f/87fc11f8
│   │
│   ├── Target 2: [720p HD - 1.3 GB]
│   │   └── Find Link: Next to "Watch Online" text
│   │   └── URL Format: https://new5.cinecloud.site/f/202686dc
│   │
│   └── Target 3: [1080p HD - 2.8 GB]
│       └── Find Link: Next to "Watch Online" text
│       └── URL Format: https://new5.cinecloud.site/f/c34cf250
│
└── [STEP 5] FINAL OUTPUT FORMAT:
    └── Result: Show only the "cinecloud.site" final URLs for each quality.