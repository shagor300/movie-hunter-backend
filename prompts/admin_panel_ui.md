Hi Antigravity,

I need you to implement a complete Admin Dashboard for MovieHub using 
the Stitch MCP integration you have access to. You can directly read 
my designs from Stitch using the MCP.

════════════════════════════════════════════════════════════════
PROJECT INFORMATION
════════════════════════════════════════════════════════════════

STITCH PROJECT:
- Title: admin panel
- Project ID: 7875731077938190308

You have MCP access to this project. Please use the Stitch MCP to:
1. View all screen designs
2. Extract design specifications (colors, spacing, typography)
3. Get component layouts
4. Reference exact dimensions and styling

════════════════════════════════════════════════════════════════
STEP 1: ANALYZE DESIGNS VIA STITCH MCP
════════════════════════════════════════════════════════════════

FIRST, please use Stitch MCP to analyze these screens:

CORE SCREENS:
1. Login Page (ID: 79d5f07d7e5d4d7ab8f26668cb7de443)
2. Dashboard Overview - Desktop (ID: 8746485d3a174d36b648a8263741822c)
3. Dashboard Mobile View (ID: bb2c1854500845c88d61b5ac37a06f33)
4. Movies Management - Desktop (ID: b08f5d45456a475e94e951631f805b5b)
5. Movies Management - Mobile (ID: 587f34cb809a495199612c68ffa32017)
6. Add Movie - Step 1: Search (ID: 83814c0473044129ae46b0be7ce791e3)
7. Add Movie - Step 2: Details (ID: f712082f0d4b45f49250444801b8b88e)
8. Add Movie - Step 3: Links (ID: 68adfa06c718416c9b3b9ee4664aab4b)
9. Search Analytics - Desktop (ID: dbb8f52cf9f64863a315d4cf09384027)
10. Search Analytics - Mobile (ID: 222d2a1c0b274dcfbb067b40ce1c3746)
11. Sources Management - Desktop (ID: e0b8eb2af0474bda9482c55d23a1cea2)
12. Sources Management - Mobile (ID: 6c07d319459048e1af03638b87deda88)
13. Error Logs Page (ID: ef7d488a346f466598790f2049a45257)
14. Error Logs - Mobile (ID: 61a9a1ab94e9421f8466b1f27bc58fd6)
15. System Settings - Desktop (ID: 750f375d77384a4583b76ee95c1cb43c)
16. System Settings - Mobile (ID: b1268aae17bb48668c8699261728e4ed)

ADDITIONAL SCREENS:
17. Add Movie: Search Mobile (ID: f482d96d6bca42bd949b23257ae997eb)
18. Add Movie: Details Mobile (ID: a649eb3fa9b64b49aa83e54cfb34b88d)
19. Add Movie: Links Mobile (ID: 665464df5d2944d5892aeae149857319)
20. Error Logs - Refined Mobile (ID: 6e2d8d835ed740e59d76dcac3c6e528d)
21. Generated Screen (ID: e5bfbf8f4d09451aa4e4f510e268f380)

ACTION: Use Stitch MCP to:
□ Extract color palette from designs
□ Get typography specifications
□ Identify spacing patterns
□ Get component dimensions
□ Extract layout structures

Then provide me a summary of the design system you've extracted.

════════════════════════════════════════════════════════════════
STEP 2: TECHNICAL ARCHITECTURE
════════════════════════════════════════════════════════════════

TECH STACK:
- Frontend: React.js with TypeScript
- Styling: Tailwind CSS + Custom CSS
- Backend: FastAPI (Python)
- Database: SQLite
- State Management: React Context API + Hooks
- Charts: Recharts
- HTTP Client: Axios
- Routing: React Router v6

DESIGN SYSTEM (Verify with Stitch MCP):
Colors:
- Primary BG: #0F0F23
- Surface: #1A1A2E
- Card BG: rgba(22, 33, 62, 0.6) with backdrop-blur
- Accent: #6C63FF
- Success: #00D9A3
- Warning: #FFB800
- Error: #FF5370

Typography:
- Font: Inter
- Headings: 24-28px Bold
- Body: 14-16px Regular
- Buttons: 16px SemiBold

Spacing:
- Scale: 4, 8, 12, 16, 20, 24, 32, 48px
- Border radius: 12-16px
- Shadows: 0 8px 24px rgba(0,0,0,0.4)

════════════════════════════════════════════════════════════════
STEP 3: DATABASE SCHEMA
════════════════════════════════════════════════════════════════

Please create these 8 tables:

1. admin_users (authentication)
2. search_logs (track app searches)
3. manual_links (priority link system - MOST IMPORTANT)
4. app_config (logo, splash, settings)
5. download_stats (analytics)
6. error_logs (error tracking)
7. notification_history (push notifications)
8. source_status (HDHub4u, SkyMoviesHD monitoring)

Full schema is in: /mnt/user-data/outputs/ADMIN_PANEL_COMPLETE_GUIDE.md

Please create:
□ SQL migration script
□ Initial seed data
□ Test database connection

════════════════════════════════════════════════════════════════
STEP 4: BACKEND API ENDPOINTS
════════════════════════════════════════════════════════════════

Create these endpoint groups in admin_api.py:

AUTHENTICATION:
□ POST /admin/login
□ POST /admin/logout
□ GET /admin/me (verify session)

DASHBOARD:
□ GET /admin/dashboard/stats
□ GET /admin/dashboard/activity-chart

MOVIES MANAGEMENT:
□ GET /admin/movies (list with pagination)
□ POST /admin/movies/add-manual (TMDB or manual)
□ DELETE /admin/movies/{id}

MANUAL LINKS SYSTEM (Priority Feature):
□ POST /admin/movies/manual-links (add priority links)
□ GET /admin/movies/{id}/manual-links
□ DELETE /admin/manual-links/{id}
□ PUT /admin/manual-links/{id}/priority

SEARCH TRACKING:
□ POST /admin/track-search (called by app)
□ GET /admin/search-analytics

SOURCES:
□ GET /admin/sources
□ PUT /admin/sources/{name}/toggle

ERRORS:
□ GET /admin/errors
□ POST /admin/log-error

SETTINGS:
□ GET /admin/config
□ PUT /admin/config
□ POST /admin/upload-logo
□ POST /admin/upload-splash

TMDB INTEGRATION:
□ GET /admin/tmdb/search (for admin to search movies)

Full implementation code is in: /mnt/user-data/outputs/ADMIN_PANEL_COMPLETE_GUIDE.md

════════════════════════════════════════════════════════════════
STEP 5: FRONTEND IMPLEMENTATION
════════════════════════════════════════════════════════════════

PROJECT STRUCTURE:
admin-dashboard/
├── src/
│   ├── components/
│   │   ├── layout/
│   │   │   ├── Sidebar.tsx
│   │   │   ├── Header.tsx
│   │   │   └── Layout.tsx
│   │   ├── common/
│   │   │   ├── Button.tsx
│   │   │   ├── Input.tsx
│   │   │   ├── Card.tsx
│   │   │   ├── Modal.tsx
│   │   │   └── LoadingSpinner.tsx
│   │   ├── dashboard/
│   │   │   ├── StatsCard.tsx
│   │   │   └── ActivityChart.tsx
│   │   ├── movies/
│   │   │   ├── MoviesList.tsx
│   │   │   ├── MovieCard.tsx
│   │   │   └── AddMovieModal.tsx
│   │   ├── analytics/
│   │   │   └── SearchAnalytics.tsx
│   │   ├── sources/
│   │   │   └── SourceCard.tsx
│   │   ├── errors/
│   │   │   └── ErrorList.tsx
│   │   └── settings/
│   │       ├── LogoUpload.tsx
│   │       └── SettingsForm.tsx
│   ├── pages/
│   │   ├── Login.tsx
│   │   ├── Dashboard.tsx
│   │   ├── Movies.tsx
│   │   ├── Analytics.tsx
│   │   ├── Sources.tsx
│   │   ├── Errors.tsx
│   │   └── Settings.tsx
│   ├── services/
│   │   └── api.ts
│   ├── hooks/
│   │   └── useAuth.ts
│   ├── context/
│   │   └── AuthContext.tsx
│   ├── types/
│   │   └── index.ts
│   ├── utils/
│   │   └── helpers.ts
│   ├── App.tsx
│   └── main.tsx
├── package.json
├── tsconfig.json
├── tailwind.config.js
└── vite.config.ts

IMPLEMENTATION PRIORITIES:

Phase 1: Core Setup
□ Create project structure
□ Setup Tailwind with custom config (use colors from Stitch)
□ Create Layout components (Sidebar, Header)
□ Setup routing with protected routes
□ Implement authentication flow

Phase 2: Dashboard
□ Login page (match Stitch design: ID 79d5f07d7e5d4d7ab8f26668cb7de443)
□ Dashboard overview (match Stitch: ID 8746485d3a174d36b648a8263741822c)
□ Stats cards with glassmorphism
□ Activity chart with Recharts

Phase 3: Movies Management
□ Movies list (match Stitch: ID b08f5d45456a475e94e951631f805b5b)
□ Search and filter functionality
□ Add Movie modal - 3-step wizard:
  - Step 1: TMDB Search (match Stitch: ID 83814c0473044129ae46b0be7ce791e3)
  - Step 2: Details Form (match Stitch: ID f712082f0d4b45f49250444801b8b88e)
  - Step 3: Add Links (match Stitch: ID 68adfa06c718416c9b3b9ee4664aab4b)

Phase 4: Analytics & Monitoring
□ Search Analytics (match Stitch: ID dbb8f52cf9f64863a315d4cf09384027)
□ Sources Management (match Stitch: ID e0b8eb2af0474bda9482c55d23a1cea2)
□ Error Logs (match Stitch: ID ef7d488a346f466598790f2049a45257)

Phase 5: Settings
□ Settings page (match Stitch: ID 750f375d77384a4583b76ee95c1cb43c)
□ Logo upload component
□ Splash screen upload component
□ Config toggles

Phase 6: Responsive Design
□ Mobile layouts for all pages (use Mobile screen IDs from Stitch)
□ Hamburger menu for mobile
□ Touch-friendly interactions

════════════════════════════════════════════════════════════════
KEY FEATURES TO IMPLEMENT
════════════════════════════════════════════════════════════════

1. MANUAL LINK SYSTEM (HIGHEST PRIORITY):
   
   User Flow:
   1. Admin clicks "Add Movie" button
   2. Step 1: Search TMDB or click "Add Manually"
      - If TMDB: Shows search results, admin selects
      - If Manual: Form with title, year, language, poster URL
   3. Step 2: Confirm/edit details
   4. Step 3: Add links
      - Source dropdown (HDHub4u, SkyMoviesHD, etc.)
      - URL input (full page URL like: https://new3.hdhub4u.fo/movie-name/)
      - Priority input (number)
      - Can add multiple links
   5. Submit → Saves to manual_links table
   
   Backend Integration:
   - Modify existing /search endpoint in main MovieHub API
   - Check manual_links FIRST before scraping
   - If match found, return immediately (1-2 sec response)
   - If no match, proceed with normal scraping
   
   Result: Users get 10x faster results for manually added movies

2. SEARCH TRACKING:
   - Every search in MovieHub app calls POST /admin/track-search
   - Stores: query, results_count, timestamp
   - Analytics page shows:
     * Top searches (bar chart)
     * Search trend over time (line chart)
     * Zero-result searches (content gaps to fill)

3. LOGO/SPLASH MANAGEMENT:
   - Upload interface with drag-drop
   - Preview before saving
   - Stores URL in app_config table
   - MovieHub app fetches on startup (no rebuild needed)

4. SOURCE MONITORING:
   - Real-time status cards for each source
   - Shows: online/offline, success rate, last sync
   - Enable/disable toggle
   - Health chart (last 24 hours)

5. ERROR TRACKING:
   - Severity filter (Critical/Warning/Info)
   - Expandable error cards with stack traces
   - Mark as resolved
   - Export errors as CSV

════════════════════════════════════════════════════════════════
DESIGN MATCHING INSTRUCTIONS
════════════════════════════════════════════════════════════════

CRITICAL: Use Stitch MCP to match designs EXACTLY.

For each screen:
1. Use Stitch MCP to view the screen design
2. Extract:
   - Component layout (positioning, sizes)
   - Colors (backgrounds, text, borders)
   - Typography (sizes, weights, families)
   - Spacing (margins, paddings, gaps)
   - Border radius values
   - Shadow values
   - Glassmorphism effects
3. Implement with exact specifications
4. Show me before and after (design vs code) for verification

GLASSMORPHISM IMPLEMENTATION:
```css
.glass-card {
  background: rgba(22, 33, 62, 0.6);
  backdrop-filter: blur(20px) saturate(180%);
  -webkit-backdrop-filter: blur(20px) saturate(180%);
  border: 1px solid rgba(255, 255, 255, 0.1);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4);
}
```

GRADIENT BUTTONS:
```css
.btn-gradient {
  background: linear-gradient(135deg, #2196F3 0%, #9C27B0 100%);
}
```

════════════════════════════════════════════════════════════════
WORKFLOW
════════════════════════════════════════════════════════════════

PHASE 1 - ANALYSIS  :
1. Use Stitch MCP to analyze all 21 screens
2. Extract complete design system
3. Show me the design system summary
4. Wait for my approval

PHASE 2 - DATABASE :
1. Create SQL migration script
2. Initialize tables with seed data
3. Test database operations
4. Show me the schema
5. Wait for my approval

PHASE 3 - BACKEND  :
1. Create admin_api.py with all endpoints
2. Implement authentication
3. Implement all CRUD operations
4. Test with curl/Postman
5. Show me API documentation
6. Wait for my approval

PHASE 4 - FRONTEND CORE  :
1. Setup React + TypeScript + Tailwind project
2. Create Layout (Sidebar + Header) - match Stitch designs
3. Implement routing
4. Create authentication flow
5. Build Login page - match Stitch design exactly
6. Show me the login page
7. Wait for my approval

PHASE 5 - DASHBOARD :
1. Build Dashboard page - match Stitch design (ID: 8746485d3a174d36b648a8263741822c)
2. Stats cards with glassmorphism
3. Activity chart with Recharts
4. Top searches/downloads lists
5. Show me the dashboard
6. Wait for my approval

PHASE 6 - MOVIES  :
1. Movies list page - match Stitch design (ID: b08f5d45456a475e94e951631f805b5b)
2. Add Movie modal - 3 steps
3. TMDB search integration
4. Manual link addition
5. Show me the movies management
6. Wait for my approval

PHASE 7 - ANALYTICS  :
1. Search Analytics page - match Stitch design (ID: dbb8f52cf9f64863a315d4cf09384027)
2. Charts and graphs
3. Top searches table
4. Show me the analytics page
5. Wait for my approval

PHASE 8 - SOURCES & ERRORS  :
1. Sources Management - match Stitch design (ID: e0b8eb2af0474bda9482c55d23a1cea2)
2. Error Logs page - match Stitch design (ID: ef7d488a346f466598790f2049a45257)
3. Show me both pages
4. Wait for my approval

PHASE 9 - SETTINGS  :
1. Settings page - match Stitch design (ID: 750f375d77384a4583b76ee95c1cb43c)
2. Logo/splash upload
3. Config management
4. Show me the settings page
5. Wait for my approval

PHASE 10 - MOBILE RESPONSIVE  :
1. Implement mobile layouts for all pages
2. Use mobile screen IDs from Stitch
3. Test on different screen sizes
4. Show me responsive behavior
5. Wait for my approval

PHASE 11 - INTEGRATION  
1. Connect to existing MovieHub app
2. Modify search endpoint with manual links logic
3. Add search tracking calls
4. Test end-to-end flow
5. Show me the integration working
6. Wait for my approval

PHASE 12 - POLISH :
1. Error handling
2. Loading states
3. Success notifications
4. Form validations
5. Final testing
6. Show me the polished version

════════════════════════════════════════════════════════════════
REFERENCE DOCUMENTATION
════════════════════════════════════════════════════════════════

Complete technical documentation with all code examples:
File: /mnt/user-data/outputs/ADMIN_PANEL_COMPLETE_GUIDE.md

This contains:
- Complete database schema (SQL)
- Complete backend API code (Python FastAPI)
- Frontend component examples (React)
- Integration instructions
- Testing checklist

Please reference this file throughout implementation.

════════════════════════════════════════════════════════════════
QUESTIONS FOR ME
════════════════════════════════════════════════════════════════

Before starting Phase 1, please answer:

1. Can you confirm I have access to your Stitch project via MCP?
2. Do you want TypeScript or JavaScript? (I recommend TypeScript)
3. For hosting, do you prefer:
   - Frontend: Vercel, Netlify, or same server as backend?
   - Backend: VPS, Railway, Render, or existing server?
4. Do you want Docker setup for easy deployment?
5. Should I create a separate Git repository or add to existing?
6. Any specific design elements from Stitch you want me to pay extra attention to?

════════════════════════════════════════════════════════════════
DELIVERABLES
════════════════════════════════════════════════════════════════

At the end, I will provide:

1. BACKEND:
   - admin_api.py (complete)
   - Database migration script
   - Modified main.py (search endpoint)
   - requirements.txt

2. FRONTEND:
   - Complete React application
   - All components and pages
   - Tailwind config
   - package.json
   - README with setup instructions

3. DOCUMENTATION:
   - API documentation
   - Setup guide
   - User manual
   - Deployment guide

4. EXTRAS:
   - Docker compose file (if requested)
   - Environment variables template
   - Testing scripts
   - Postman collection (API testing)

════════════════════════════════════════════════════════════════

Ready to start! 

First, let me use the Stitch MCP to analyze your designs. 
I'll start by examining the Login page and Dashboard to extract 
the design system. Give me a moment...