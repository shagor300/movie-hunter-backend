# 🎛️ Advanced Admin Panel - Complete Implementation Guide

**For Google Antigravity**

---

## 🎯 OVERVIEW

Complete web-based admin dashboard for MovieHub with:
- 📊 Real-time statistics & analytics
- 🎬 Movies management (TMDB + Manual)
- ⚡ Manual link addition system (Priority links)
- 🔍 Search tracking & analytics
- 🎨 App logo & splash screen management
- 🌐 Multi-source monitoring
- 🚨 Error tracking
- 📢 Push notifications
- ⚙️ Settings & configuration

---

## 🗄️ PART 1: DATABASE SCHEMA

### **New Tables to Add:**

```sql
-- 1. Admin Users
CREATE TABLE admin_users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT DEFAULT 'admin',  -- super_admin, admin, content_manager
    is_active BOOLEAN DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

-- 2. Search Tracking
CREATE TABLE search_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    query TEXT NOT NULL,
    results_count INTEGER DEFAULT 0,
    search_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_id TEXT,  -- Optional: if you add user accounts
    ip_address TEXT
);

-- 3. Manual Links (Priority Links)
CREATE TABLE manual_links (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    movie_id INTEGER,  -- Can be NULL for non-TMDB movies
    tmdb_id INTEGER,   -- NULL if movie not in TMDB
    movie_title TEXT NOT NULL,
    movie_year INTEGER,
    movie_language TEXT,
    movie_poster_url TEXT,
    movie_description TEXT,
    source_name TEXT NOT NULL,  -- hdhub4u, skymovieshd, etc.
    source_url TEXT NOT NULL,   -- The page URL to scrape
    priority INTEGER DEFAULT 1, -- Higher = checked first
    is_active BOOLEAN DEFAULT 1,
    added_by INTEGER REFERENCES admin_users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_checked TIMESTAMP,
    status TEXT DEFAULT 'active'  -- active, broken, expired
);

-- 4. App Configuration
CREATE TABLE app_config (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    key TEXT UNIQUE NOT NULL,
    value TEXT,
    description TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by INTEGER REFERENCES admin_users(id)
);

-- Initial config values
INSERT INTO app_config (key, value, description) VALUES
('app_logo_url', '', 'URL to app logo image'),
('splash_screen_url', '', 'URL to splash screen image'),
('app_version', '1.0.0', 'Current app version'),
('force_update', 'false', 'Force users to update'),
('maintenance_mode', 'false', 'Enable maintenance mode'),
('featured_movie_ids', '[]', 'JSON array of featured movie TMDB IDs'),
('sync_interval_hours', '6', 'Auto-sync interval'),
('max_concurrent_scrapers', '3', 'Max parallel scrapers');

-- 5. Download Statistics
CREATE TABLE download_stats (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    movie_id INTEGER,
    tmdb_id INTEGER,
    movie_title TEXT,
    quality TEXT,
    download_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_id TEXT,
    ip_address TEXT
);

-- 6. Error Logs
CREATE TABLE error_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    severity TEXT NOT NULL,  -- critical, warning, info
    source TEXT NOT NULL,    -- scraper, api, player, etc.
    error_type TEXT,         -- timeout, 404, crash, etc.
    message TEXT NOT NULL,
    stack_trace TEXT,
    metadata TEXT,           -- JSON with additional info
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved BOOLEAN DEFAULT 0,
    resolved_at TIMESTAMP,
    resolved_by INTEGER REFERENCES admin_users(id)
);

-- 7. Push Notifications History
CREATE TABLE notification_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    target_type TEXT,        -- all, active, inactive
    sent_count INTEGER DEFAULT 0,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sent_by INTEGER REFERENCES admin_users(id)
);

-- 8. Source Status (for monitoring)
CREATE TABLE source_status (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    source_name TEXT UNIQUE NOT NULL,
    is_enabled BOOLEAN DEFAULT 1,
    is_online BOOLEAN DEFAULT 1,
    last_check TIMESTAMP,
    last_sync TIMESTAMP,
    total_movies INTEGER DEFAULT 0,
    success_rate REAL DEFAULT 0.0,
    avg_response_time_ms INTEGER DEFAULT 0,
    consecutive_failures INTEGER DEFAULT 0
);

-- Initial sources
INSERT INTO source_status (source_name) VALUES
('hdhub4u'),
('skymovieshd'),
('cinefreak'),
('katmoviehd');
```

---

## 🔧 PART 2: BACKEND API ENDPOINTS

### **File:** `admin_api.py` (New file)

```python
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBasic, HTTPBasicCredentials
from passlib.context import CryptContext
from datetime import datetime, timedelta
from typing import Optional, List
import secrets
import sqlite3
import json

router = APIRouter(prefix="/admin", tags=["admin"])
security = HTTPBasic()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Simple session storage (use Redis in production)
active_sessions = {}

def get_db():
    conn = sqlite3.connect('moviehub.db')
    conn.row_factory = sqlite3.Row
    return conn

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def hash_password(password):
    return pwd_context.hash(password)

def create_session(admin_id: int, username: str) -> str:
    token = secrets.token_urlsafe(32)
    active_sessions[token] = {
        'admin_id': admin_id,
        'username': username,
        'expires': datetime.now() + timedelta(hours=24)
    }
    return token

def verify_session(token: str) -> Optional[dict]:
    session = active_sessions.get(token)
    if session and session['expires'] > datetime.now():
        return session
    return None

# ════════════════════════════════════════
# AUTHENTICATION
# ════════════════════════════════════════

@router.post("/login")
async def admin_login(credentials: HTTPBasicCredentials = Depends(security)):
    """Admin login endpoint"""
    db = get_db()
    cursor = db.cursor()
    
    # Get admin user
    admin = cursor.execute(
        "SELECT * FROM admin_users WHERE username = ? AND is_active = 1",
        (credentials.username,)
    ).fetchone()
    
    if not admin or not verify_password(credentials.password, admin['password_hash']):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials"
        )
    
    # Update last login
    cursor.execute(
        "UPDATE admin_users SET last_login = ? WHERE id = ?",
        (datetime.now(), admin['id'])
    )
    db.commit()
    db.close()
    
    # Create session
    token = create_session(admin['id'], admin['username'])
    
    return {
        'success': True,
        'token': token,
        'username': admin['username'],
        'role': admin['role']
    }

@router.post("/logout")
async def admin_logout(token: str):
    """Logout and invalidate session"""
    if token in active_sessions:
        del active_sessions[token]
    return {'success': True}

def require_auth(token: str):
    """Dependency for protected routes"""
    session = verify_session(token)
    if not session:
        raise HTTPException(status_code=401, detail="Unauthorized")
    return session

# ════════════════════════════════════════
# DASHBOARD STATISTICS
# ════════════════════════════════════════

@router.get("/dashboard/stats")
async def get_dashboard_stats(token: str = Depends(require_auth)):
    """Get overview statistics"""
    db = get_db()
    cursor = db.cursor()
    
    # Today's stats
    today = datetime.now().strftime('%Y-%m-%d')
    
    total_movies = cursor.execute(
        "SELECT COUNT(*) FROM homepage_movies"
    ).fetchone()[0]
    
    today_searches = cursor.execute(
        "SELECT COUNT(*) FROM search_logs WHERE DATE(search_timestamp) = ?",
        (today,)
    ).fetchone()[0]
    
    today_downloads = cursor.execute(
        "SELECT COUNT(*) FROM download_stats WHERE DATE(download_timestamp) = ?",
        (today,)
    ).fetchone()[0]
    
    # Top searches (last 7 days)
    top_searches = cursor.execute("""
        SELECT query, COUNT(*) as count
        FROM search_logs
        WHERE search_timestamp >= datetime('now', '-7 days')
        GROUP BY query
        ORDER BY count DESC
        LIMIT 10
    """).fetchall()
    
    # Top downloads (last 7 days)
    top_downloads = cursor.execute("""
        SELECT movie_title, COUNT(*) as count
        FROM download_stats
        WHERE download_timestamp >= datetime('now', '-7 days')
        GROUP BY movie_title
        ORDER BY count DESC
        LIMIT 10
    """).fetchall()
    
    # Source status
    sources = cursor.execute(
        "SELECT * FROM source_status ORDER BY source_name"
    ).fetchall()
    
    # Recent errors (last 24 hours)
    recent_errors = cursor.execute("""
        SELECT * FROM error_logs
        WHERE created_at >= datetime('now', '-1 day')
        AND resolved = 0
        ORDER BY created_at DESC
        LIMIT 10
    """).fetchall()
    
    db.close()
    
    return {
        'total_movies': total_movies,
        'today_searches': today_searches,
        'today_downloads': today_downloads,
        'top_searches': [dict(row) for row in top_searches],
        'top_downloads': [dict(row) for row in top_downloads],
        'sources': [dict(row) for row in sources],
        'recent_errors': [dict(row) for row in recent_errors]
    }

@router.get("/dashboard/activity-chart")
async def get_activity_chart(
    days: int = 7,
    token: str = Depends(require_auth)
):
    """Get activity data for charts"""
    db = get_db()
    cursor = db.cursor()
    
    # Daily searches
    searches = cursor.execute("""
        SELECT DATE(search_timestamp) as date, COUNT(*) as count
        FROM search_logs
        WHERE search_timestamp >= datetime('now', '-' || ? || ' days')
        GROUP BY DATE(search_timestamp)
        ORDER BY date
    """, (days,)).fetchall()
    
    # Daily downloads
    downloads = cursor.execute("""
        SELECT DATE(download_timestamp) as date, COUNT(*) as count
        FROM download_stats
        WHERE download_timestamp >= datetime('now', '-' || ? || ' days')
        GROUP BY DATE(download_timestamp)
        ORDER BY date
    """, (days,)).fetchall()
    
    db.close()
    
    return {
        'searches': [dict(row) for row in searches],
        'downloads': [dict(row) for row in downloads]
    }

# ════════════════════════════════════════
# SEARCH TRACKING
# ════════════════════════════════════════

@router.post("/track-search")
async def track_search(data: dict):
    """Track search query (called by app)"""
    db = get_db()
    cursor = db.cursor()
    
    cursor.execute("""
        INSERT INTO search_logs (query, results_count, user_id, ip_address)
        VALUES (?, ?, ?, ?)
    """, (
        data.get('query', ''),
        data.get('results_count', 0),
        data.get('user_id'),
        data.get('ip_address')
    ))
    
    db.commit()
    db.close()
    
    return {'success': True}

@router.get("/search-analytics")
async def get_search_analytics(
    days: int = 30,
    token: str = Depends(require_auth)
):
    """Get search analytics"""
    db = get_db()
    cursor = db.cursor()
    
    # Top searches
    top_queries = cursor.execute("""
        SELECT query, COUNT(*) as count
        FROM search_logs
        WHERE search_timestamp >= datetime('now', '-' || ? || ' days')
        GROUP BY query
        ORDER BY count DESC
        LIMIT 50
    """, (days,)).fetchall()
    
    # Search trend over time
    daily_searches = cursor.execute("""
        SELECT DATE(search_timestamp) as date, COUNT(*) as count
        FROM search_logs
        WHERE search_timestamp >= datetime('now', '-' || ? || ' days')
        GROUP BY DATE(search_timestamp)
        ORDER BY date
    """, (days,)).fetchall()
    
    # Zero-result searches (users not finding content)
    zero_results = cursor.execute("""
        SELECT query, COUNT(*) as count
        FROM search_logs
        WHERE results_count = 0
        AND search_timestamp >= datetime('now', '-' || ? || ' days')
        GROUP BY query
        ORDER BY count DESC
        LIMIT 20
    """, (days,)).fetchall()
    
    db.close()
    
    return {
        'top_queries': [dict(row) for row in top_queries],
        'daily_searches': [dict(row) for row in daily_searches],
        'zero_results': [dict(row) for row in zero_results]
    }

# ════════════════════════════════════════
# MOVIES MANAGEMENT
# ════════════════════════════════════════

@router.get("/movies")
async def get_movies(
    page: int = 1,
    limit: int = 50,
    search: str = "",
    token: str = Depends(require_auth)
):
    """Get paginated movies list"""
    db = get_db()
    cursor = db.cursor()
    
    offset = (page - 1) * limit
    
    if search:
        movies = cursor.execute("""
            SELECT * FROM homepage_movies
            WHERE title LIKE ? OR tmdb_id = ?
            ORDER BY created_at DESC
            LIMIT ? OFFSET ?
        """, (f'%{search}%', search, limit, offset)).fetchall()
        
        total = cursor.execute("""
            SELECT COUNT(*) FROM homepage_movies
            WHERE title LIKE ? OR tmdb_id = ?
        """, (f'%{search}%', search)).fetchone()[0]
    else:
        movies = cursor.execute("""
            SELECT * FROM homepage_movies
            ORDER BY created_at DESC
            LIMIT ? OFFSET ?
        """, (limit, offset)).fetchall()
        
        total = cursor.execute("SELECT COUNT(*) FROM homepage_movies").fetchone()[0]
    
    # Get manual links count for each movie
    movies_with_links = []
    for movie in movies:
        manual_links_count = cursor.execute("""
            SELECT COUNT(*) FROM manual_links
            WHERE tmdb_id = ? AND is_active = 1
        """, (movie['tmdb_id'],)).fetchone()[0]
        
        movie_dict = dict(movie)
        movie_dict['manual_links_count'] = manual_links_count
        movies_with_links.append(movie_dict)
    
    db.close()
    
    return {
        'movies': movies_with_links,
        'total': total,
        'page': page,
        'pages': (total + limit - 1) // limit
    }

@router.delete("/movies/{tmdb_id}")
async def delete_movie(tmdb_id: int, token: str = Depends(require_auth)):
    """Delete a movie"""
    db = get_db()
    cursor = db.cursor()
    
    cursor.execute("DELETE FROM homepage_movies WHERE tmdb_id = ?", (tmdb_id,))
    cursor.execute("DELETE FROM manual_links WHERE tmdb_id = ?", (tmdb_id,))
    
    db.commit()
    db.close()
    
    return {'success': True}

# ════════════════════════════════════════
# MANUAL LINKS (Priority System)
# ════════════════════════════════════════

@router.post("/movies/add-manual")
async def add_manual_movie(data: dict, session: dict = Depends(require_auth)):
    """Add movie manually (with or without TMDB)"""
    db = get_db()
    cursor = db.cursor()
    
    # Check if TMDB movie or manual
    if data.get('tmdb_id'):
        # TMDB movie - may already exist
        existing = cursor.execute(
            "SELECT * FROM homepage_movies WHERE tmdb_id = ?",
            (data['tmdb_id'],)
        ).fetchone()
        
        if not existing:
            # Add to homepage_movies
            cursor.execute("""
                INSERT INTO homepage_movies (
                    tmdb_id, title, original_title, poster_path,
                    backdrop_path, overview, release_date, vote_average,
                    vote_count, popularity, created_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                data['tmdb_id'],
                data['title'],
                data.get('original_title', data['title']),
                data.get('poster_path', ''),
                data.get('backdrop_path', ''),
                data.get('overview', ''),
                data.get('release_date', ''),
                data.get('vote_average', 0.0),
                data.get('vote_count', 0),
                data.get('popularity', 0.0),
                datetime.now()
            ))
    else:
        # Fully manual movie (not in TMDB)
        # Add to homepage_movies with tmdb_id = NULL or 0
        cursor.execute("""
            INSERT INTO homepage_movies (
                tmdb_id, title, original_title, poster_path,
                overview, release_date, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (
            0,  # or NULL
            data['title'],
            data['title'],
            data.get('poster_url', ''),
            data.get('description', ''),
            f"{data.get('year', '')}-01-01",
            datetime.now()
        ))
    
    db.commit()
    movie_id = cursor.lastrowid
    db.close()
    
    return {
        'success': True,
        'movie_id': movie_id,
        'tmdb_id': data.get('tmdb_id', 0)
    }

@router.post("/movies/manual-links")
async def add_manual_links(data: dict, session: dict = Depends(require_auth)):
    """Add manual priority links for a movie"""
    db = get_db()
    cursor = db.cursor()
    
    tmdb_id = data.get('tmdb_id', 0)
    movie_title = data['movie_title']
    links = data['links']  # List of {source_name, source_url, priority}
    
    added_count = 0
    for link in links:
        cursor.execute("""
            INSERT INTO manual_links (
                tmdb_id, movie_title, movie_year, movie_language,
                movie_poster_url, source_name, source_url,
                priority, added_by, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            tmdb_id if tmdb_id > 0 else None,
            movie_title,
            data.get('year'),
            data.get('language'),
            data.get('poster_url'),
            link['source_name'],
            link['source_url'],
            link.get('priority', 1),
            session['admin_id'],
            datetime.now()
        ))
        added_count += 1
    
    db.commit()
    db.close()
    
    return {
        'success': True,
        'added_count': added_count
    }

@router.get("/movies/{identifier}/manual-links")
async def get_manual_links(
    identifier: str,  # Can be tmdb_id or movie_title
    token: str = Depends(require_auth)
):
    """Get manual links for a movie"""
    db = get_db()
    cursor = db.cursor()
    
    # Try as tmdb_id first
    if identifier.isdigit():
        links = cursor.execute("""
            SELECT * FROM manual_links
            WHERE tmdb_id = ?
            ORDER BY priority DESC, created_at DESC
        """, (int(identifier),)).fetchall()
    else:
        # Search by title
        links = cursor.execute("""
            SELECT * FROM manual_links
            WHERE movie_title LIKE ?
            ORDER BY priority DESC, created_at DESC
        """, (f'%{identifier}%',)).fetchall()
    
    db.close()
    
    return {
        'links': [dict(row) for row in links]
    }

@router.delete("/manual-links/{link_id}")
async def delete_manual_link(link_id: int, token: str = Depends(require_auth)):
    """Delete a manual link"""
    db = get_db()
    cursor = db.cursor()
    
    cursor.execute("DELETE FROM manual_links WHERE id = ?", (link_id,))
    db.commit()
    db.close()
    
    return {'success': True}

@router.put("/manual-links/{link_id}/priority")
async def update_link_priority(
    link_id: int,
    priority: int,
    token: str = Depends(require_auth)
):
    """Update link priority"""
    db = get_db()
    cursor = db.cursor()
    
    cursor.execute(
        "UPDATE manual_links SET priority = ? WHERE id = ?",
        (priority, link_id)
    )
    db.commit()
    db.close()
    
    return {'success': True}

# ════════════════════════════════════════
# APP CONFIGURATION
# ════════════════════════════════════════

@router.get("/config")
async def get_config(token: str = Depends(require_auth)):
    """Get all app configuration"""
    db = get_db()
    cursor = db.cursor()
    
    config = cursor.execute("SELECT * FROM app_config").fetchall()
    db.close()
    
    config_dict = {row['key']: row['value'] for row in config}
    return config_dict

@router.put("/config")
async def update_config(
    data: dict,
    session: dict = Depends(require_auth)
):
    """Update app configuration"""
    db = get_db()
    cursor = db.cursor()
    
    for key, value in data.items():
        cursor.execute("""
            UPDATE app_config
            SET value = ?, updated_at = ?, updated_by = ?
            WHERE key = ?
        """, (str(value), datetime.now(), session['admin_id'], key))
    
    db.commit()
    db.close()
    
    return {'success': True}

# ════════════════════════════════════════
# LOGO & SPLASH SCREEN
# ════════════════════════════════════════

@router.post("/upload-logo")
async def upload_logo(file: UploadFile, token: str = Depends(require_auth)):
    """Upload app logo"""
    # Save file
    file_path = f"static/logos/{file.filename}"
    with open(file_path, "wb") as f:
        f.write(await file.read())
    
    # Update config
    db = get_db()
    cursor = db.cursor()
    cursor.execute(
        "UPDATE app_config SET value = ? WHERE key = 'app_logo_url'",
        (f"/static/logos/{file.filename}",)
    )
    db.commit()
    db.close()
    
    return {'success': True, 'url': f"/static/logos/{file.filename}"}

@router.post("/upload-splash")
async def upload_splash(file: UploadFile, token: str = Depends(require_auth)):
    """Upload splash screen"""
    file_path = f"static/splash/{file.filename}"
    with open(file_path, "wb") as f:
        f.write(await file.read())
    
    db = get_db()
    cursor = db.cursor()
    cursor.execute(
        "UPDATE app_config SET value = ? WHERE key = 'splash_screen_url'",
        (f"/static/splash/{file.filename}",)
    )
    db.commit()
    db.close()
    
    return {'success': True, 'url': f"/static/splash/{file.filename}"}

# ════════════════════════════════════════
# SOURCE MANAGEMENT
# ════════════════════════════════════════

@router.get("/sources")
async def get_sources(token: str = Depends(require_auth)):
    """Get all sources status"""
    db = get_db()
    cursor = db.cursor()
    
    sources = cursor.execute(
        "SELECT * FROM source_status ORDER BY source_name"
    ).fetchall()
    db.close()
    
    return [dict(row) for row in sources]

@router.put("/sources/{source_name}/toggle")
async def toggle_source(
    source_name: str,
    enabled: bool,
    token: str = Depends(require_auth)
):
    """Enable/disable a source"""
    db = get_db()
    cursor = db.cursor()
    
    cursor.execute(
        "UPDATE source_status SET is_enabled = ? WHERE source_name = ?",
        (enabled, source_name)
    )
    db.commit()
    db.close()
    
    return {'success': True}

@router.post("/sources/{source_name}/sync")
async def force_sync_source(
    source_name: str,
    token: str = Depends(require_auth)
):
    """Force manual sync for a source"""
    # Trigger scraper
    # Implementation depends on your scraper architecture
    return {'success': True, 'message': 'Sync started in background'}

# ════════════════════════════════════════
# ERROR LOGS
# ════════════════════════════════════════

@router.get("/errors")
async def get_errors(
    severity: str = None,
    limit: int = 100,
    token: str = Depends(require_auth)
):
    """Get error logs"""
    db = get_db()
    cursor = db.cursor()
    
    if severity:
        errors = cursor.execute("""
            SELECT * FROM error_logs
            WHERE severity = ?
            ORDER BY created_at DESC
            LIMIT ?
        """, (severity, limit)).fetchall()
    else:
        errors = cursor.execute("""
            SELECT * FROM error_logs
            ORDER BY created_at DESC
            LIMIT ?
        """, (limit,)).fetchall()
    
    db.close()
    
    return [dict(row) for row in errors]

@router.post("/log-error")
async def log_error(data: dict):
    """Log an error (called by app/scrapers)"""
    db = get_db()
    cursor = db.cursor()
    
    cursor.execute("""
        INSERT INTO error_logs (
            severity, source, error_type, message,
            stack_trace, metadata, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
    """, (
        data.get('severity', 'info'),
        data.get('source', 'unknown'),
        data.get('error_type', ''),
        data.get('message', ''),
        data.get('stack_trace', ''),
        json.dumps(data.get('metadata', {})),
        datetime.now()
    ))
    
    db.commit()
    db.close()
    
    return {'success': True}

# ════════════════════════════════════════
# PUSH NOTIFICATIONS
# ════════════════════════════════════════

@router.post("/notifications/send")
async def send_push_notification(
    data: dict,
    session: dict = Depends(require_auth)
):
    """Send push notification to users"""
    # Integration with FCM (Firebase Cloud Messaging)
    # Implementation depends on your notification setup
    
    # Log notification
    db = get_db()
    cursor = db.cursor()
    
    cursor.execute("""
        INSERT INTO notification_history (
            title, message, target_type, sent_count, sent_by
        ) VALUES (?, ?, ?, ?, ?)
    """, (
        data['title'],
        data['message'],
        data.get('target', 'all'),
        data.get('sent_count', 0),
        session['admin_id']
    ))
    
    db.commit()
    db.close()
    
    return {
        'success': True,
        'message': 'Notification sent'
    }

# ════════════════════════════════════════
# TMDB SEARCH (for admin panel)
# ════════════════════════════════════════

import httpx

TMDB_API_KEY = "7efd8424c17ff5b3e8dc9cebf4a33f73"  # Your key

@router.get("/tmdb/search")
async def search_tmdb(
    query: str,
    token: str = Depends(require_auth)
):
    """Search TMDB for movies (for admin to add)"""
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"https://api.themoviedb.org/3/search/movie",
            params={
                'api_key': TMDB_API_KEY,
                'query': query,
                'include_adult': False
            }
        )
        
        if response.status_code == 200:
            data = response.json()
            return {
                'success': True,
                'results': data.get('results', [])
            }
        else:
            return {
                'success': False,
                'error': 'TMDB API error'
            }
```

---

## 🎨 PART 3: FRONTEND (React Dashboard)

### **Project Structure:**

```
admin-dashboard/
├── package.json
├── src/
│   ├── App.jsx
│   ├── components/
│   │   ├── Dashboard/
│   │   │   ├── Overview.jsx
│   │   │   ├── StatsCards.jsx
│   │   │   └── ActivityChart.jsx
│   │   ├── Movies/
│   │   │   ├── MoviesList.jsx
│   │   │   ├── MovieCard.jsx
│   │   │   ├── AddMovieModal.jsx
│   │   │   └── ManualLinksModal.jsx
│   │   ├── Analytics/
│   │   │   ├── SearchAnalytics.jsx
│   │   │   └── DownloadAnalytics.jsx
│   │   ├── Sources/
│   │   │   └── SourcesManager.jsx
│   │   ├── Settings/
│   │   │   ├── AppSettings.jsx
│   │   │   ├── LogoUpload.jsx
│   │   │   └── SplashUpload.jsx
│   │   ├── Errors/
│   │   │   └── ErrorLogs.jsx
│   │   └── Common/
│   │       ├── Sidebar.jsx
│   │       ├── Header.jsx
│   │       └── LoadingSpinner.jsx
│   ├── services/
│   │   └── api.js
│   ├── utils/
│   │   └── auth.js
│   └── styles/
│       └── global.css
```

### **Key Components:**

**File:** `src/components/Dashboard/Overview.jsx`

```jsx
import React, { useState, useEffect } from 'react';
import { Line } from 'react-chartjs-2';
import StatsCards from './StatsCards';
import api from '../../services/api';

export default function Overview() {
  const [stats, setStats] = useState(null);
  const [activityData, setActivityData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    try {
      const [statsRes, activityRes] = await Promise.all([
        api.get('/admin/dashboard/stats'),
        api.get('/admin/dashboard/activity-chart?days=7')
      ]);
      
      setStats(statsRes.data);
      setActivityData(activityRes.data);
    } catch (error) {
      console.error('Failed to fetch dashboard data:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <LoadingSpinner />;

  return (
    <div className="dashboard-overview">
      <h1>Dashboard</h1>
      
      {/* Stats Cards */}
      <StatsCards
        totalMovies={stats.total_movies}
        todaySearches={stats.today_searches}
        todayDownloads={stats.today_downloads}
      />

      {/* Activity Chart */}
      <div className="chart-container">
        <h2>Last 7 Days Activity</h2>
        <Line
          data={{
            labels: activityData.searches.map(d => d.date),
            datasets: [
              {
                label: 'Searches',
                data: activityData.searches.map(d => d.count),
                borderColor: 'rgb(75, 192, 192)',
              },
              {
                label: 'Downloads',
                data: activityData.downloads.map(d => d.count),
                borderColor: 'rgb(255, 99, 132)',
              },
            ],
          }}
        />
      </div>

      {/* Top Movies */}
      <div className="top-movies">
        <h2>🔥 Top Downloads (Last 7 Days)</h2>
        <ul>
          {stats.top_downloads.map((item, idx) => (
            <li key={idx}>
              {idx + 1}. {item.movie_title} - {item.count} downloads
            </li>
          ))}
        </ul>
      </div>

      {/* Top Searches */}
      <div className="top-searches">
        <h2>🔍 Top Searches (Last 7 Days)</h2>
        <ul>
          {stats.top_searches.map((item, idx) => (
            <li key={idx}>
              {idx + 1}. "{item.query}" - {item.count} searches
            </li>
          ))}
        </ul>
      </div>

      {/* Recent Errors */}
      {stats.recent_errors.length > 0 && (
        <div className="recent-errors">
          <h2>⚠️ Recent Errors</h2>
          <ul>
            {stats.recent_errors.map((error, idx) => (
              <li key={idx} className={`error-${error.severity}`}>
                [{error.severity.toUpperCase()}] {error.message}
                <span className="error-time">
                  {new Date(error.created_at).toLocaleTimeString()}
                </span>
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}
```

**File:** `src/components/Movies/AddMovieModal.jsx`

```jsx
import React, { useState } from 'react';
import api from '../../services/api';

export default function AddMovieModal({ onClose, onSuccess }) {
  const [step, setStep] = useState(1); // 1: Search, 2: Select, 3: Add Links
  const [searchQuery, setSearchQuery] = useState('');
  const [tmdbResults, setTmdbResults] = useState([]);
  const [selectedMovie, setSelectedMovie] = useState(null);
  const [manualMode, setManualMode] = useState(false);
  const [manualData, setManualData] = useState({
    title: '',
    year: '',
    language: '',
    poster_url: '',
    description: ''
  });
  const [links, setLinks] = useState([
    { source_name: '', source_url: '', priority: 1 }
  ]);

  // Step 1: Search TMDB or switch to manual
  const searchTMDB = async () => {
    try {
      const res = await api.get(`/admin/tmdb/search?query=${searchQuery}`);
      if (res.data.success) {
        setTmdbResults(res.data.results);
      }
    } catch (error) {
      console.error('TMDB search failed:', error);
    }
  };

  // Step 2: Select movie from TMDB or manual entry
  const selectMovie = (movie) => {
    setSelectedMovie(movie);
    setStep(3);
  };

  const useManualEntry = () => {
    setManualMode(true);
    setStep(2);
  };

  const addLink = () => {
    setLinks([...links, { source_name: '', source_url: '', priority: 1 }]);
  };

  const updateLink = (index, field, value) => {
    const newLinks = [...links];
    newLinks[index][field] = value;
    setLinks(newLinks);
  };

  const removeLink = (index) => {
    setLinks(links.filter((_, i) => i !== index));
  };

  // Step 3: Submit movie + links
  const submitMovie = async () => {
    try {
      // First add movie
      const movieData = manualMode ? {
        title: manualData.title,
        year: manualData.year,
        language: manualData.language,
        poster_url: manualData.poster_url,
        description: manualData.description
      } : {
        tmdb_id: selectedMovie.id,
        title: selectedMovie.title,
        original_title: selectedMovie.original_title,
        poster_path: selectedMovie.poster_path,
        overview: selectedMovie.overview,
        release_date: selectedMovie.release_date,
        vote_average: selectedMovie.vote_average,
        vote_count: selectedMovie.vote_count,
        popularity: selectedMovie.popularity
      };

      const addRes = await api.post('/admin/movies/add-manual', movieData);

      // Then add manual links
      if (links.some(l => l.source_url)) {
        await api.post('/admin/movies/manual-links', {
          tmdb_id: addRes.data.tmdb_id,
          movie_title: movieData.title,
          year: manualData.year || selectedMovie?.release_date?.split('-')[0],
          language: manualData.language,
          poster_url: manualData.poster_url || selectedMovie?.poster_path,
          links: links.filter(l => l.source_url)
        });
      }

      onSuccess();
      onClose();
    } catch (error) {
      console.error('Failed to add movie:', error);
      alert('Failed to add movie');
    }
  };

  return (
    <div className="modal-overlay">
      <div className="modal-content add-movie-modal">
        <button className="close-btn" onClick={onClose}>×</button>
        
        {/* Step 1: Search or Manual */}
        {step === 1 && (
          <div>
            <h2>Add Movie</h2>
            <div className="search-section">
              <input
                type="text"
                placeholder="Search movie name..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                onKeyPress={(e) => e.key === 'Enter' && searchTMDB()}
              />
              <button onClick={searchTMDB}>Search TMDB</button>
            </div>

            {tmdbResults.length > 0 && (
              <div className="results-list">
                <h3>TMDB Results</h3>
                {tmdbResults.map(movie => (
                  <div key={movie.id} className="movie-result" onClick={() => selectMovie(movie)}>
                    <img 
                      src={`https://image.tmdb.org/t/p/w92${movie.poster_path}`}
                      alt={movie.title}
                    />
                    <div>
                      <strong>{movie.title}</strong>
                      <span>{movie.release_date?.split('-')[0]}</span>
                      <p>{movie.overview?.substring(0, 100)}...</p>
                    </div>
                  </div>
                ))}
              </div>
            )}

            <div className="manual-option">
              <p>Movie not in TMDB?</p>
              <button onClick={useManualEntry}>Add Manually</button>
            </div>
          </div>
        )}

        {/* Step 2: Manual Entry */}
        {step === 2 && manualMode && (
          <div>
            <h2>Manual Entry</h2>
            <input
              placeholder="Movie Title *"
              value={manualData.title}
              onChange={(e) => setManualData({...manualData, title: e.target.value})}
            />
            <input
              placeholder="Year (e.g., 2025)"
              value={manualData.year}
              onChange={(e) => setManualData({...manualData, year: e.target.value})}
            />
            <input
              placeholder="Language (e.g., Bangla)"
              value={manualData.language}
              onChange={(e) => setManualData({...manualData, language: e.target.value})}
            />
            <input
              placeholder="Poster URL"
              value={manualData.poster_url}
              onChange={(e) => setManualData({...manualData, poster_url: e.target.value})}
            />
            <textarea
              placeholder="Description (optional)"
              value={manualData.description}
              onChange={(e) => setManualData({...manualData, description: e.target.value})}
            />
            <button onClick={() => setStep(3)}>Next: Add Links</button>
          </div>
        )}

        {/* Step 3: Add Manual Links */}
        {step === 3 && (
          <div>
            <h2>Add Priority Links</h2>
            <p>Movie: <strong>{selectedMovie?.title || manualData.title}</strong></p>
            
            {links.map((link, idx) => (
              <div key={idx} className="link-input-group">
                <select
                  value={link.source_name}
                  onChange={(e) => updateLink(idx, 'source_name', e.target.value)}
                >
                  <option value="">Select Source</option>
                  <option value="hdhub4u">HDHub4u</option>
                  <option value="skymovieshd">SkyMoviesHD</option>
                  <option value="cinefreak">CinemaFreak</option>
                  <option value="katmoviehd">KatMovieHD</option>
                </select>
                <input
                  placeholder="Page URL (e.g., https://new3.hdhub4u.fo/...)"
                  value={link.source_url}
                  onChange={(e) => updateLink(idx, 'source_url', e.target.value)}
                />
                <input
                  type="number"
                  placeholder="Priority"
                  value={link.priority}
                  onChange={(e) => updateLink(idx, 'priority', parseInt(e.target.value))}
                  style={{width: '80px'}}
                />
                <button onClick={() => removeLink(idx)}>Remove</button>
              </div>
            ))}

            <button onClick={addLink}>+ Add Another Link</button>
            
            <div className="modal-actions">
              <button onClick={() => setStep(manualMode ? 2 : 1)}>Back</button>
              <button onClick={submitMovie} className="primary">Submit Movie</button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
```

---

## 🔧 PART 4: INTEGRATION WITH APP

### **Modify Search Endpoint** (Flutter calls this)

**File:** `main.py` (Existing)

```python
@app.get("/search")
async def search_movies(query: str):
    """
    Search movies - check manual links first, then auto-scrape
    """
    # Log search
    db = get_db()
    cursor = db.cursor()
    cursor.execute(
        "INSERT INTO search_logs (query, search_timestamp) VALUES (?, ?)",
        (query, datetime.now())
    )
    db.commit()
    
    # 1. Check if we have manual links for this movie
    manual_movies = cursor.execute("""
        SELECT DISTINCT ml.*, hm.tmdb_id, hm.title, hm.poster_path
        FROM manual_links ml
        LEFT JOIN homepage_movies hm ON ml.tmdb_id = hm.tmdb_id
        WHERE ml.is_active = 1
        AND (ml.movie_title LIKE ? OR hm.title LIKE ?)
        ORDER BY ml.priority DESC
    """, (f'%{query}%', f'%{query}%')).fetchall()
    
    if manual_movies:
        print(f"✅ Found {len(manual_movies)} manual links for '{query}'")
        # Return these immediately (fast response)
        results = []
        for movie in manual_movies:
            results.append({
                'tmdb_id': movie['tmdb_id'] or 0,
                'title': movie['movie_title'],
                'poster_path': movie['movie_poster_url'],
                'has_manual_links': True,
                'manual_link_url': movie['source_url'],
                'source': movie['source_name']
            })
        
        cursor.execute(
            "UPDATE search_logs SET results_count = ? WHERE query = ? ORDER BY search_timestamp DESC LIMIT 1",
            (len(results), query)
        )
        db.commit()
        db.close()
        
        return results
    
    # 2. No manual links - proceed with normal TMDB + scraping
    db.close()
    return await normal_search_flow(query)  # Your existing logic
```

---

## ✅ PART 5: DEPLOYMENT CHECKLIST

### **Backend:**
- [ ] Install dependencies: `pip install passlib[bcrypt] python-multipart`
- [ ] Run database migrations (create new tables)
- [ ] Create admin user: `INSERT INTO admin_users ...`
- [ ] Update main.py to include admin_api router
- [ ] Create static folders: `static/logos/`, `static/splash/`
- [ ] Set up CORS for admin dashboard domain

### **Frontend:**
- [ ] `npm install` (React, Chart.js, Axios)
- [ ] Update API base URL in `services/api.js`
- [ ] Build: `npm run build`
- [ ] Deploy to hosting (Vercel, Netlify, or same server)
- [ ] Configure authentication

### **Testing:**
- [ ] Login works
- [ ] Dashboard loads statistics
- [ ] Search tracking captured
- [ ] Add manual movie (TMDB + Manual)
- [ ] Add manual links
- [ ] Logo/splash upload works
- [ ] Sources toggle works
- [ ] Error logs visible
- [ ] App uses manual links first

---

## 📊 EXPECTED RESULTS

**Before:**
```
User searches "Saba 2025" → Scrapes HDHub4u → 10-15 seconds
User searches "Inception" → Scrapes HDHub4u → 10-15 seconds
Admin has no visibility into app usage
```

**After:**
```
User searches "Saba 2025" → Finds manual link → 1-2 seconds ⚡
User searches "Inception" → Finds manual link → 1-2 seconds ⚡
Admin sees:
  - 245 searches today
  - "Inception" searched 23 times
  - HDHub4u online, 94% success rate
  - 2 critical errors need attention
```

---

## 🎯 PRIORITY IMPLEMENTATION ORDER

### ** 1: Core Features**
1. Database schema
2. Authentication
3. Dashboard overview
4. Movies list

### **2: Manual Links System**
5. Add manual movie (TMDB + Manual)
6. Add/manage manual links
7. Priority system in search

### **3: Analytics & Management**
8. Search tracking analytics
9. Source management
10. Error logs

### **4: Polish**
11. Logo/splash upload
12. Push notifications
13. Settings
14. UI improvements

---

**complete admin panel** 🚀

END OF ADMIN PANEL GUIDE