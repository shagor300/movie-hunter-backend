"""
Admin Panel API — FastAPI Router
All admin endpoints under /admin prefix.
"""

import secrets
import json
import logging
from datetime import datetime, timedelta
from typing import Optional
from fastapi import APIRouter, HTTPException, Header
from pydantic import BaseModel, Field
import bcrypt as _bcrypt

from admin_db import admin_db
from config.sources import MovieSources

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/admin", tags=["admin"])


def _hash_password(password: str) -> str:
    return _bcrypt.hashpw(password.encode(), _bcrypt.gensalt()).decode()


def _verify_password(password: str, hashed: str) -> bool:
    return _bcrypt.checkpw(password.encode(), hashed.encode())

# In-memory session store (sufficient for single-instance deploy on Render)
_sessions: dict = {}

TMDB_API_KEY = MovieSources.TMDB_API_KEY


# ─── Pydantic Models ────────────────────────────────────────────────────

class LoginRequest(BaseModel):
    username: str
    password: str

class ManualLinkInput(BaseModel):
    source_name: str
    source_url: str
    priority: int = 1

class AddManualLinksRequest(BaseModel):
    tmdb_id: Optional[int] = None
    movie_title: str
    year: Optional[int] = None
    language: Optional[str] = None
    poster_url: Optional[str] = None
    links: list[ManualLinkInput]

class ConfigUpdateRequest(BaseModel):
    updates: dict

class LogErrorRequest(BaseModel):
    severity: str = "info"
    source: str = "unknown"
    error_type: str = ""
    message: str
    stack_trace: str = ""
    metadata: dict = {}

class SendNotificationRequest(BaseModel):
    title: str
    message: str
    target: str = "all"

class TrackSearchRequest(BaseModel):
    query: str
    results_count: int = 0
    ip_address: Optional[str] = None


# ─── Auth Helpers ────────────────────────────────────────────────────────

def _create_session(admin_id: int, username: str, role: str) -> str:
    token = secrets.token_urlsafe(32)
    _sessions[token] = {
        "admin_id": admin_id,
        "username": username,
        "role": role,
        "expires": datetime.now() + timedelta(hours=24),
    }
    return token


def _verify_token(token: str) -> dict:
    session = _sessions.get(token)
    if not session or session["expires"] < datetime.now():
        _sessions.pop(token, None)
        raise HTTPException(status_code=401, detail="Unauthorized or expired session")
    return session


async def _require_auth(authorization: str = Header(None)) -> dict:
    """Extract and verify Bearer token from Authorization header."""
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing Authorization header")
    token = authorization.replace("Bearer ", "")
    return _verify_token(token)


# ─── Setup: create default admin if none exists ─────────────────────────

async def ensure_default_admin():
    """Create a default admin user if the table is empty."""
    count = await admin_db.fetch_scalar("SELECT COUNT(*) FROM admin_users")
    if count == 0:
        hashed = _hash_password("admin123")
        await admin_db.insert(
            "INSERT INTO admin_users (username, email, password_hash, role) VALUES (?, ?, ?, ?)",
            ("admin", "admin@moviehub.app", hashed, "super_admin"),
        )
        logger.info("Created default admin user: admin / admin123")


# ════════════════════════════════════════════════════════════════════════
# AUTHENTICATION
# ════════════════════════════════════════════════════════════════════════

@router.post("/login")
async def admin_login(req: LoginRequest):
    """Authenticate admin and return session token."""
    user = await admin_db.fetch_one(
        "SELECT * FROM admin_users WHERE username = ? AND is_active = 1",
        (req.username,),
    )
    if not user or not _verify_password(req.password, user["password_hash"]):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    await admin_db.execute(
        "UPDATE admin_users SET last_login = ? WHERE id = ?",
        (datetime.now().isoformat(), user["id"]),
    )

    token = _create_session(user["id"], user["username"], user["role"])
    return {
        "success": True,
        "token": token,
        "username": user["username"],
        "role": user["role"],
    }


@router.post("/logout")
async def admin_logout(authorization: str = Header(None)):
    """Invalidate session."""
    if authorization and authorization.startswith("Bearer "):
        token = authorization.replace("Bearer ", "")
        _sessions.pop(token, None)
    return {"success": True}


# ════════════════════════════════════════════════════════════════════════
# DASHBOARD STATISTICS
# ════════════════════════════════════════════════════════════════════════

@router.get("/dashboard/stats")
async def get_dashboard_stats(authorization: str = Header(None)):
    """Overview stats for the dashboard."""
    _verify_token((authorization or "").replace("Bearer ", ""))

    today = datetime.now().strftime("%Y-%m-%d")

    today_searches = await admin_db.fetch_scalar(
        "SELECT COUNT(*) FROM search_logs WHERE DATE(search_timestamp) = ?", (today,)
    )
    today_downloads = await admin_db.fetch_scalar(
        "SELECT COUNT(*) FROM download_stats WHERE DATE(download_timestamp) = ?", (today,)
    )
    total_manual_links = await admin_db.fetch_scalar(
        "SELECT COUNT(*) FROM manual_links WHERE is_active = 1"
    )
    unresolved_errors = await admin_db.fetch_scalar(
        "SELECT COUNT(*) FROM error_logs WHERE resolved = 0"
    )

    top_searches = await admin_db.fetch_all("""
        SELECT query, COUNT(*) as count
        FROM search_logs
        WHERE search_timestamp >= datetime('now', '-7 days')
        GROUP BY query ORDER BY count DESC LIMIT 10
    """)

    top_downloads = await admin_db.fetch_all("""
        SELECT movie_title, COUNT(*) as count
        FROM download_stats
        WHERE download_timestamp >= datetime('now', '-7 days')
        GROUP BY movie_title ORDER BY count DESC LIMIT 10
    """)

    sources = await admin_db.fetch_all(
        "SELECT * FROM source_status ORDER BY source_name"
    )

    recent_errors = await admin_db.fetch_all("""
        SELECT * FROM error_logs
        WHERE created_at >= datetime('now', '-1 day') AND resolved = 0
        ORDER BY created_at DESC LIMIT 10
    """)

    return {
        "today_searches": today_searches or 0,
        "today_downloads": today_downloads or 0,
        "total_manual_links": total_manual_links or 0,
        "unresolved_errors": unresolved_errors or 0,
        "top_searches": top_searches,
        "top_downloads": top_downloads,
        "sources": sources,
        "recent_errors": recent_errors,
    }


@router.get("/dashboard/activity-chart")
async def get_activity_chart(days: int = 7, authorization: str = Header(None)):
    """Daily activity data for charts."""
    _verify_token((authorization or "").replace("Bearer ", ""))

    searches = await admin_db.fetch_all("""
        SELECT DATE(search_timestamp) as date, COUNT(*) as count
        FROM search_logs
        WHERE search_timestamp >= datetime('now', '-' || ? || ' days')
        GROUP BY DATE(search_timestamp) ORDER BY date
    """, (days,))

    downloads = await admin_db.fetch_all("""
        SELECT DATE(download_timestamp) as date, COUNT(*) as count
        FROM download_stats
        WHERE download_timestamp >= datetime('now', '-' || ? || ' days')
        GROUP BY DATE(download_timestamp) ORDER BY date
    """, (days,))

    return {"searches": searches, "downloads": downloads}


# ════════════════════════════════════════════════════════════════════════
# SEARCH TRACKING & ANALYTICS
# ════════════════════════════════════════════════════════════════════════

@router.post("/track-search")
async def track_search(req: TrackSearchRequest):
    """Track a search query (called by the app's /search endpoint)."""
    await admin_db.insert(
        "INSERT INTO search_logs (query, results_count, ip_address) VALUES (?, ?, ?)",
        (req.query, req.results_count, req.ip_address),
    )
    return {"success": True}


@router.get("/search-analytics")
async def get_search_analytics(days: int = 30, authorization: str = Header(None)):
    """Search analytics for admin."""
    _verify_token((authorization or "").replace("Bearer ", ""))

    top_queries = await admin_db.fetch_all("""
        SELECT query, COUNT(*) as count FROM search_logs
        WHERE search_timestamp >= datetime('now', '-' || ? || ' days')
        GROUP BY query ORDER BY count DESC LIMIT 50
    """, (days,))

    daily = await admin_db.fetch_all("""
        SELECT DATE(search_timestamp) as date, COUNT(*) as count FROM search_logs
        WHERE search_timestamp >= datetime('now', '-' || ? || ' days')
        GROUP BY DATE(search_timestamp) ORDER BY date
    """, (days,))

    zero_results = await admin_db.fetch_all("""
        SELECT query, COUNT(*) as count FROM search_logs
        WHERE results_count = 0
        AND search_timestamp >= datetime('now', '-' || ? || ' days')
        GROUP BY query ORDER BY count DESC LIMIT 20
    """, (days,))

    return {
        "top_queries": top_queries,
        "daily_searches": daily,
        "zero_results": zero_results,
    }


# ════════════════════════════════════════════════════════════════════════
# MANUAL LINKS (Priority System)
# ════════════════════════════════════════════════════════════════════════

@router.get("/manual-links")
async def get_all_manual_links(
    page: int = 1, limit: int = 50, search: str = "",
    authorization: str = Header(None),
):
    """List all manual links with optional search."""
    _verify_token((authorization or "").replace("Bearer ", ""))

    offset = (page - 1) * limit
    if search:
        links = await admin_db.fetch_all("""
            SELECT * FROM manual_links WHERE movie_title LIKE ?
            ORDER BY priority DESC, created_at DESC LIMIT ? OFFSET ?
        """, (f"%{search}%", limit, offset))
        total = await admin_db.fetch_scalar(
            "SELECT COUNT(*) FROM manual_links WHERE movie_title LIKE ?",
            (f"%{search}%",),
        )
    else:
        links = await admin_db.fetch_all("""
            SELECT * FROM manual_links
            ORDER BY priority DESC, created_at DESC LIMIT ? OFFSET ?
        """, (limit, offset))
        total = await admin_db.fetch_scalar("SELECT COUNT(*) FROM manual_links")

    return {"links": links, "total": total or 0, "page": page}


@router.post("/manual-links")
async def add_manual_links(req: AddManualLinksRequest, authorization: str = Header(None)):
    """Add manual priority links for a movie."""
    session = _verify_token((authorization or "").replace("Bearer ", ""))

    added = 0
    for link in req.links:
        await admin_db.insert("""
            INSERT INTO manual_links
                (tmdb_id, movie_title, movie_year, movie_language,
                 movie_poster_url, source_name, source_url, priority, added_by)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            req.tmdb_id, req.movie_title, req.year, req.language,
            req.poster_url, link.source_name, link.source_url,
            link.priority, session["admin_id"],
        ))
        added += 1

    return {"success": True, "added_count": added}


@router.delete("/manual-links/{link_id}")
async def delete_manual_link(link_id: int, authorization: str = Header(None)):
    """Delete a manual link."""
    _verify_token((authorization or "").replace("Bearer ", ""))
    await admin_db.execute("DELETE FROM manual_links WHERE id = ?", (link_id,))
    return {"success": True}


@router.put("/manual-links/{link_id}/priority")
async def update_link_priority(
    link_id: int, priority: int, authorization: str = Header(None)
):
    """Update link priority."""
    _verify_token((authorization or "").replace("Bearer ", ""))
    await admin_db.execute(
        "UPDATE manual_links SET priority = ? WHERE id = ?", (priority, link_id)
    )
    return {"success": True}


# ════════════════════════════════════════════════════════════════════════
# APP CONFIGURATION
# ════════════════════════════════════════════════════════════════════════

@router.get("/config")
async def get_config(authorization: str = Header(None)):
    """Get all app configuration."""
    _verify_token((authorization or "").replace("Bearer ", ""))
    rows = await admin_db.fetch_all("SELECT key, value, description FROM app_config")
    return {r["key"]: {"value": r["value"], "description": r["description"]} for r in rows}


@router.put("/config")
async def update_config(req: ConfigUpdateRequest, authorization: str = Header(None)):
    """Update configuration values."""
    session = _verify_token((authorization or "").replace("Bearer ", ""))
    for key, value in req.updates.items():
        await admin_db.execute(
            "UPDATE app_config SET value = ?, updated_at = ?, updated_by = ? WHERE key = ?",
            (str(value), datetime.now().isoformat(), session["admin_id"], key),
        )
    return {"success": True}


# ════════════════════════════════════════════════════════════════════════
# SOURCE MANAGEMENT
# ════════════════════════════════════════════════════════════════════════

@router.get("/sources")
async def get_sources(authorization: str = Header(None)):
    """Get all sources status."""
    _verify_token((authorization or "").replace("Bearer ", ""))
    return await admin_db.fetch_all("SELECT * FROM source_status ORDER BY source_name")


@router.put("/sources/{source_name}/toggle")
async def toggle_source(source_name: str, enabled: bool, authorization: str = Header(None)):
    """Enable/disable a source."""
    _verify_token((authorization or "").replace("Bearer ", ""))
    await admin_db.execute(
        "UPDATE source_status SET is_enabled = ? WHERE source_name = ?",
        (1 if enabled else 0, source_name),
    )
    return {"success": True}


# ════════════════════════════════════════════════════════════════════════
# ERROR LOGS
# ════════════════════════════════════════════════════════════════════════

@router.get("/errors")
async def get_errors(
    severity: Optional[str] = None, limit: int = 100,
    authorization: str = Header(None),
):
    """Get error logs."""
    _verify_token((authorization or "").replace("Bearer ", ""))
    if severity:
        return await admin_db.fetch_all(
            "SELECT * FROM error_logs WHERE severity = ? ORDER BY created_at DESC LIMIT ?",
            (severity, limit),
        )
    return await admin_db.fetch_all(
        "SELECT * FROM error_logs ORDER BY created_at DESC LIMIT ?", (limit,)
    )


@router.post("/log-error")
async def log_error(req: LogErrorRequest):
    """Log an error (called by scrapers/app)."""
    await admin_db.insert("""
        INSERT INTO error_logs (severity, source, error_type, message, stack_trace, metadata)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (
        req.severity, req.source, req.error_type,
        req.message, req.stack_trace, json.dumps(req.metadata),
    ))
    return {"success": True}


@router.put("/errors/{error_id}/resolve")
async def resolve_error(error_id: int, authorization: str = Header(None)):
    """Mark an error as resolved."""
    session = _verify_token((authorization or "").replace("Bearer ", ""))
    await admin_db.execute(
        "UPDATE error_logs SET resolved = 1, resolved_at = ?, resolved_by = ? WHERE id = ?",
        (datetime.now().isoformat(), session["admin_id"], error_id),
    )
    return {"success": True}


# ════════════════════════════════════════════════════════════════════════
# PUSH NOTIFICATIONS
# ════════════════════════════════════════════════════════════════════════

@router.post("/notifications/send")
async def send_notification(req: SendNotificationRequest, authorization: str = Header(None)):
    """Log a notification (actual push delivery is a future integration)."""
    session = _verify_token((authorization or "").replace("Bearer ", ""))
    await admin_db.insert("""
        INSERT INTO notification_history (title, message, target_type, sent_by)
        VALUES (?, ?, ?, ?)
    """, (req.title, req.message, req.target, session["admin_id"]))
    return {"success": True, "message": "Notification logged"}


@router.get("/notifications")
async def get_notifications(limit: int = 50, authorization: str = Header(None)):
    """Get notification history."""
    _verify_token((authorization or "").replace("Bearer ", ""))
    return await admin_db.fetch_all(
        "SELECT * FROM notification_history ORDER BY sent_at DESC LIMIT ?", (limit,)
    )


# ════════════════════════════════════════════════════════════════════════
# TMDB SEARCH (for admin panel movie lookup)
# ════════════════════════════════════════════════════════════════════════

@router.get("/tmdb/search")
async def search_tmdb(query: str, authorization: str = Header(None)):
    """Search TMDB for movies."""
    _verify_token((authorization or "").replace("Bearer ", ""))

    import httpx
    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.get(
            "https://api.themoviedb.org/3/search/movie",
            params={"api_key": TMDB_API_KEY, "query": query, "include_adult": "false"},
        )
        if resp.status_code == 200:
            data = resp.json()
            return {"success": True, "results": data.get("results", [])}
        return {"success": False, "error": "TMDB API error"}


# ════════════════════════════════════════════════════════════════════════
# DOWNLOAD TRACKING (called by app)
# ════════════════════════════════════════════════════════════════════════

@router.post("/track-download")
async def track_download(data: dict):
    """Track a download event."""
    await admin_db.insert(
        "INSERT INTO download_stats (tmdb_id, movie_title, quality, ip_address) VALUES (?, ?, ?, ?)",
        (data.get("tmdb_id"), data.get("movie_title"), data.get("quality"), data.get("ip_address")),
    )
    return {"success": True}


# ════════════════════════════════════════════════════════════════════════
# REMOTE CONFIG — IN-APP UPDATE CONTROL
# ════════════════════════════════════════════════════════════════════════

_RC_KEYS = ["current_version", "update_url", "is_force_update", "whats_new"]


class RemoteConfigRequest(BaseModel):
    current_version: str
    update_url: str = ""
    is_force_update: bool = False
    whats_new: str = ""


@router.get("/remote-config")
async def get_remote_config(authorization: str = Header(None)):
    """Get current Remote Config values for in-app updates."""
    _verify_token((authorization or "").replace("Bearer ", ""))

    config = {}
    for key in _RC_KEYS:
        row = await admin_db.fetch_one(
            "SELECT value FROM app_config WHERE key = ?", (f"rc_{key}",)
        )
        config[key] = row["value"] if row else ""

    # Load publish history
    history = await admin_db.fetch_all("""
        SELECT * FROM update_publish_history
        ORDER BY published_at DESC LIMIT 10
    """)

    return {**config, "history": history or []}


@router.post("/remote-config")
async def publish_remote_config(req: RemoteConfigRequest, authorization: str = Header(None)):
    """Publish Remote Config values (saves to DB + tries Firebase)."""
    session = _verify_token((authorization or "").replace("Bearer ", ""))

    # Save to local DB
    values = {
        "current_version": req.current_version,
        "update_url": req.update_url,
        "is_force_update": str(req.is_force_update).lower(),
        "whats_new": req.whats_new,
    }

    for key, value in values.items():
        db_key = f"rc_{key}"
        exists = await admin_db.fetch_one(
            "SELECT key FROM app_config WHERE key = ?", (db_key,)
        )
        if exists:
            await admin_db.execute(
                "UPDATE app_config SET value = ?, updated_at = ?, updated_by = ? WHERE key = ?",
                (value, datetime.now().isoformat(), session["admin_id"], db_key),
            )
        else:
            await admin_db.insert(
                "INSERT INTO app_config (key, value, description, updated_by) VALUES (?, ?, ?, ?)",
                (db_key, value, f"Remote Config: {key}", session["admin_id"]),
            )

    # Record in publish history
    try:
        await admin_db.insert("""
            INSERT INTO update_publish_history
                (version, update_url, is_force_update, whats_new, published_by)
            VALUES (?, ?, ?, ?, ?)
        """, (
            req.current_version, req.update_url,
            1 if req.is_force_update else 0,
            req.whats_new, session["username"],
        ))
    except Exception:
        # Table might not exist on first run — create it
        await admin_db.execute("""
            CREATE TABLE IF NOT EXISTS update_publish_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                version TEXT NOT NULL,
                update_url TEXT,
                is_force_update INTEGER DEFAULT 0,
                whats_new TEXT,
                published_by TEXT,
                published_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        """)
        await admin_db.insert("""
            INSERT INTO update_publish_history
                (version, update_url, is_force_update, whats_new, published_by)
            VALUES (?, ?, ?, ?, ?)
        """, (
            req.current_version, req.update_url,
            1 if req.is_force_update else 0,
            req.whats_new, session["username"],
        ))

    # Try to publish to Firebase Remote Config via firebase-admin SDK
    firebase_status = "skipped"
    try:
        import firebase_admin
        from firebase_admin import credentials, remote_config as fb_rc
        import os

        sa_path = os.path.join(os.path.dirname(__file__), "service-account.json")
        if os.path.exists(sa_path):
            if not firebase_admin._apps:
                cred = credentials.Certificate(sa_path)
                firebase_admin.initialize_app(cred)

            # Build the Remote Config template
            template = fb_rc.get_server_template()
            server_config = template.evaluate()

            # Update via REST API instead (firebase_admin remote_config is limited)
            # For now, the local DB is the source of truth
            firebase_status = "service_account_found"
            logger.info("Firebase service account found — values saved to DB")
        else:
            firebase_status = "no_service_account"
            logger.info("No service-account.json found — values saved to DB only")
    except ImportError:
        firebase_status = "sdk_not_installed"
        logger.info("firebase-admin not installed — values saved to DB only")
    except Exception as e:
        firebase_status = f"error: {str(e)}"
        logger.warning(f"Firebase publish failed: {e}")

    return {
        "success": True,
        "message": "Update configuration published!",
        "firebase_status": firebase_status,
        "config": values,
    }


# ════════════════════════════════════════════════════════════════════════
# MOVIE REQUESTS (from app users)
# ════════════════════════════════════════════════════════════════════════

_MOVIE_REQUESTS_TABLE = """
    CREATE TABLE IF NOT EXISTS movie_requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        movie_name TEXT NOT NULL,
        year TEXT,
        language TEXT,
        quality TEXT,
        note TEXT,
        status TEXT DEFAULT 'pending',
        device_id TEXT,
        requested_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME
    )
"""


class MovieRequestInput(BaseModel):
    movie_name: str
    year: Optional[str] = None
    language: Optional[str] = None
    quality: Optional[str] = None
    note: Optional[str] = None
    device_id: Optional[str] = None


class UpdateStatusInput(BaseModel):
    status: str


async def _ensure_requests_table():
    """Create movie_requests table if it doesn't exist."""
    try:
        await admin_db.execute(_MOVIE_REQUESTS_TABLE)
    except Exception:
        pass


@router.post("/movie-requests")
async def submit_movie_request(req: MovieRequestInput):
    """Submit a movie request (called by the app — no auth required)."""
    await _ensure_requests_table()
    await admin_db.insert("""
        INSERT INTO movie_requests (movie_name, year, language, quality, note, device_id)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (req.movie_name, req.year, req.language, req.quality, req.note, req.device_id))
    return {"success": True, "message": "Request submitted"}


@router.get("/movie-requests")
async def get_movie_requests(
    status: Optional[str] = None,
    search: Optional[str] = None,
    limit: int = 100,
    authorization: str = Header(None),
):
    """Get all movie requests (admin only)."""
    _verify_token((authorization or "").replace("Bearer ", ""))
    await _ensure_requests_table()

    if status and search:
        rows = await admin_db.fetch_all(
            "SELECT * FROM movie_requests WHERE status = ? AND movie_name LIKE ? ORDER BY requested_at DESC LIMIT ?",
            (status, f"%{search}%", limit),
        )
    elif status:
        rows = await admin_db.fetch_all(
            "SELECT * FROM movie_requests WHERE status = ? ORDER BY requested_at DESC LIMIT ?",
            (status, limit),
        )
    elif search:
        rows = await admin_db.fetch_all(
            "SELECT * FROM movie_requests WHERE movie_name LIKE ? ORDER BY requested_at DESC LIMIT ?",
            (f"%{search}%", limit),
        )
    else:
        rows = await admin_db.fetch_all(
            "SELECT * FROM movie_requests ORDER BY requested_at DESC LIMIT ?", (limit,)
        )

    return {"requests": rows, "total": len(rows)}


@router.put("/movie-requests/{request_id}/status")
async def update_request_status(
    request_id: int,
    body: UpdateStatusInput,
    authorization: str = Header(None),
):
    """Update a movie request's status (admin only)."""
    _verify_token((authorization or "").replace("Bearer ", ""))
    await admin_db.execute(
        "UPDATE movie_requests SET status = ?, updated_at = ? WHERE id = ?",
        (body.status, datetime.now().isoformat(), request_id),
    )
    return {"success": True}


@router.delete("/movie-requests/{request_id}")
async def delete_movie_request(request_id: int, authorization: str = Header(None)):
    """Delete a movie request (admin only)."""
    _verify_token((authorization or "").replace("Bearer ", ""))
    await admin_db.execute("DELETE FROM movie_requests WHERE id = ?", (request_id,))
    return {"success": True}


# ════════════════════════════════════════════════════════════════════════
# PUSH NOTIFICATIONS — COMPOSE + HISTORY
# ════════════════════════════════════════════════════════════════════════

_NOTIFICATIONS_TABLE = """
    CREATE TABLE IF NOT EXISTS notification_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        target_type TEXT DEFAULT 'all',
        sent_by TEXT,
        sent_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
"""


class NotificationInput(BaseModel):
    title: str
    message: str
    target: str = "all"


async def _ensure_notifications_table():
    try:
        await admin_db.execute(_NOTIFICATIONS_TABLE)
    except Exception:
        pass


@router.post("/notifications/send")
async def send_notification(body: NotificationInput, authorization: str = Header(None)):
    """Send a push notification (admin only). Logs to DB + attempts FCM."""
    session = _verify_token((authorization or "").replace("Bearer ", ""))
    await _ensure_notifications_table()

    # Log to DB
    await admin_db.insert("""
        INSERT INTO notification_history (title, message, target_type, sent_by)
        VALUES (?, ?, ?, ?)
    """, (body.title, body.message, body.target, session["username"]))

    # Try sending via Firebase Cloud Messaging
    fcm_status = "logged_only"
    try:
        import firebase_admin
        from firebase_admin import messaging
        import os

        sa_path = os.path.join(os.path.dirname(__file__), "service-account.json")
        if os.path.exists(sa_path):
            if not firebase_admin._apps:
                from firebase_admin import credentials
                cred = credentials.Certificate(sa_path)
                firebase_admin.initialize_app(cred)

            # Send to topic 'all' by default
            topic = body.target if body.target != "all" else "all"
            msg = messaging.Message(
                notification=messaging.Notification(
                    title=body.title,
                    body=body.message,
                ),
                topic=topic,
            )
            response = messaging.send(msg)
            fcm_status = f"sent:{response}"
            logger.info(f"FCM sent: {response}")
        else:
            fcm_status = "no_service_account"
    except ImportError:
        fcm_status = "firebase_not_installed"
    except Exception as e:
        fcm_status = f"error:{str(e)}"
        logger.warning(f"FCM send failed: {e}")

    return {"success": True, "fcm_status": fcm_status, "message": "Notification sent!"}


@router.get("/notifications")
async def get_notifications(authorization: str = Header(None)):
    """Get notification history (admin only)."""
    _verify_token((authorization or "").replace("Bearer ", ""))
    await _ensure_notifications_table()
    rows = await admin_db.fetch_all(
        "SELECT * FROM notification_history ORDER BY sent_at DESC LIMIT 50"
    )
    return {"notifications": rows or []}

