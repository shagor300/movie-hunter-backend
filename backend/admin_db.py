"""
Admin Database Manager
Async SQLite database for the MovieHub admin panel.
Uses a separate 'admin.db' to avoid conflicts with scraper_cache.db.
"""

import asyncio
import aiosqlite
import logging
from typing import Optional, Dict, Any, List
from datetime import datetime

logger = logging.getLogger(__name__)

DB_PATH = "admin.db"


class AdminDB:
    """Async SQLite manager for admin panel tables."""

    def __init__(self, db_path: str = DB_PATH):
        self.db_path = db_path
        self._lock = asyncio.Lock()

    # ─── Schema ──────────────────────────────────────────────────────────

    async def init_db(self) -> None:
        """Create all admin tables if they don't exist."""
        async with self._lock:
            try:
                async with aiosqlite.connect(self.db_path) as db:
                    # 1. Admin Users
                    await db.execute("""
                        CREATE TABLE IF NOT EXISTS admin_users (
                            id INTEGER PRIMARY KEY AUTOINCREMENT,
                            username TEXT UNIQUE NOT NULL,
                            email TEXT UNIQUE NOT NULL,
                            password_hash TEXT NOT NULL,
                            role TEXT DEFAULT 'admin',
                            is_active INTEGER DEFAULT 1,
                            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                            last_login TEXT
                        )
                    """)

                    # 2. Search Logs
                    await db.execute("""
                        CREATE TABLE IF NOT EXISTS search_logs (
                            id INTEGER PRIMARY KEY AUTOINCREMENT,
                            query TEXT NOT NULL,
                            results_count INTEGER DEFAULT 0,
                            search_timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
                            ip_address TEXT
                        )
                    """)

                    # 3. Manual Links (Priority Links)
                    await db.execute("""
                        CREATE TABLE IF NOT EXISTS manual_links (
                            id INTEGER PRIMARY KEY AUTOINCREMENT,
                            tmdb_id INTEGER,
                            movie_title TEXT NOT NULL,
                            movie_year INTEGER,
                            movie_language TEXT,
                            movie_poster_url TEXT,
                            movie_description TEXT,
                            source_name TEXT NOT NULL,
                            source_url TEXT NOT NULL,
                            priority INTEGER DEFAULT 1,
                            is_active INTEGER DEFAULT 1,
                            added_by INTEGER,
                            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                            last_checked TEXT,
                            status TEXT DEFAULT 'active'
                        )
                    """)

                    # 4. App Configuration
                    await db.execute("""
                        CREATE TABLE IF NOT EXISTS app_config (
                            id INTEGER PRIMARY KEY AUTOINCREMENT,
                            key TEXT UNIQUE NOT NULL,
                            value TEXT,
                            description TEXT,
                            updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
                            updated_by INTEGER
                        )
                    """)

                    # 5. Error Logs
                    await db.execute("""
                        CREATE TABLE IF NOT EXISTS error_logs (
                            id INTEGER PRIMARY KEY AUTOINCREMENT,
                            severity TEXT NOT NULL,
                            source TEXT NOT NULL,
                            error_type TEXT,
                            message TEXT NOT NULL,
                            stack_trace TEXT,
                            metadata TEXT,
                            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                            resolved INTEGER DEFAULT 0,
                            resolved_at TEXT,
                            resolved_by INTEGER
                        )
                    """)

                    # 6. Notification History
                    await db.execute("""
                        CREATE TABLE IF NOT EXISTS notification_history (
                            id INTEGER PRIMARY KEY AUTOINCREMENT,
                            title TEXT NOT NULL,
                            message TEXT NOT NULL,
                            target_type TEXT,
                            sent_count INTEGER DEFAULT 0,
                            sent_at TEXT DEFAULT CURRENT_TIMESTAMP,
                            sent_by INTEGER
                        )
                    """)

                    # 7. Source Status
                    await db.execute("""
                        CREATE TABLE IF NOT EXISTS source_status (
                            id INTEGER PRIMARY KEY AUTOINCREMENT,
                            source_name TEXT UNIQUE NOT NULL,
                            is_enabled INTEGER DEFAULT 1,
                            is_online INTEGER DEFAULT 1,
                            last_check TEXT,
                            last_sync TEXT,
                            total_movies INTEGER DEFAULT 0,
                            success_rate REAL DEFAULT 0.0,
                            avg_response_time_ms INTEGER DEFAULT 0,
                            consecutive_failures INTEGER DEFAULT 0
                        )
                    """)

                    # 8. Download Stats
                    await db.execute("""
                        CREATE TABLE IF NOT EXISTS download_stats (
                            id INTEGER PRIMARY KEY AUTOINCREMENT,
                            tmdb_id INTEGER,
                            movie_title TEXT,
                            quality TEXT,
                            download_timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
                            ip_address TEXT
                        )
                    """)

                    # ── Seed default config ──
                    defaults = [
                        ('app_version', '1.1.0', 'Current app version'),
                        ('force_update', 'false', 'Force users to update'),
                        ('maintenance_mode', 'false', 'Enable maintenance mode'),
                        ('sync_interval_hours', '6', 'Auto-sync interval'),
                        ('max_concurrent_scrapers', '3', 'Max parallel scrapers'),
                    ]
                    for key, value, desc in defaults:
                        await db.execute("""
                            INSERT OR IGNORE INTO app_config (key, value, description)
                            VALUES (?, ?, ?)
                        """, (key, value, desc))

                    # ── Seed initial sources ──
                    for src in ('hdhub4u', 'skymovieshd', 'cinefreak', 'katmoviehd'):
                        await db.execute("""
                            INSERT OR IGNORE INTO source_status (source_name)
                            VALUES (?)
                        """, (src,))

                    await db.commit()
                    logger.info("Admin database initialized successfully")
            except Exception as e:
                logger.error(f"Admin DB init error: {e}")

    # ─── Helpers ─────────────────────────────────────────────────────────

    async def execute(self, sql: str, params: tuple = ()) -> None:
        """Execute a write query."""
        async with aiosqlite.connect(self.db_path) as db:
            await db.execute(sql, params)
            await db.commit()

    async def fetch_one(self, sql: str, params: tuple = ()) -> Optional[Dict]:
        """Fetch a single row as dict."""
        async with aiosqlite.connect(self.db_path) as db:
            db.row_factory = aiosqlite.Row
            cursor = await db.execute(sql, params)
            row = await cursor.fetchone()
            return dict(row) if row else None

    async def fetch_all(self, sql: str, params: tuple = ()) -> List[Dict]:
        """Fetch all rows as list of dicts."""
        async with aiosqlite.connect(self.db_path) as db:
            db.row_factory = aiosqlite.Row
            cursor = await db.execute(sql, params)
            rows = await cursor.fetchall()
            return [dict(r) for r in rows]

    async def fetch_scalar(self, sql: str, params: tuple = ()) -> Any:
        """Fetch a single scalar value."""
        async with aiosqlite.connect(self.db_path) as db:
            cursor = await db.execute(sql, params)
            row = await cursor.fetchone()
            return row[0] if row else None

    async def insert(self, sql: str, params: tuple = ()) -> int:
        """Execute an INSERT and return lastrowid."""
        async with aiosqlite.connect(self.db_path) as db:
            cursor = await db.execute(sql, params)
            await db.commit()
            return cursor.lastrowid


# Singleton
admin_db = AdminDB()
