 BEFORE STARTING
bash# Backup files first
cd /path/to/backend
cp backend/ftp_handler.py backend/ftp_handler.py.backup
cp backend/multi_source_manager.py backend/multi_source_manager.py.backup

📝 FIX 1: FTP Matching
File: backend/ftp_handler.py
Find line ~150-170 containing:
pythondef _matches(self, query: str, folder_name: str) -> bool:
DELETE entire method and REPLACE with:
pythondef _matches(self, query: str, folder_name: str) -> bool:
    """Smart matching with year/char handling"""
    import re
    
    query_lower = query.lower()
    folder_lower = folder_name.lower()
    
    # Clean special chars
    query_clean = re.sub(r'[._\-\[\]\(\)]', ' ', query_lower)
    folder_clean = re.sub(r'[._\-\[\]\(\)]', ' ', folder_lower)
    
    # Remove [DDN]
    folder_clean = re.sub(r'\[ddn\]|\(ddn\)', '', folder_clean)
    folder_clean = re.sub(r'\s+', ' ', folder_clean).strip()
    
    # Remove year from query
    query_no_year = re.sub(r'\b(20\d{2}|19\d{2})\b', '', query_clean)
    query_no_year = re.sub(r'\s+', ' ', query_no_year).strip()
    
    # Match 1: Direct
    if query_lower in folder_lower:
        logger.debug(f"[FTP] ✓ Direct match: '{query}' → '{folder_name}'")
        return True
    
    # Match 2: No year
    if query_no_year and len(query_no_year) > 2:
        if query_no_year in folder_clean:
            logger.info(f"[FTP] ✅ MATCH: '{query}' → '{folder_name}'")
            return True
    
    # Match 3: Word-based
    query_words = [w for w in query_no_year.split() if len(w) > 2]
    
    if not query_words:
        return query_lower in folder_lower
    
    folder_words = folder_clean.split()
    matches = 0
    
    for qw in query_words:
        for fw in folder_words:
            if qw == fw or qw in fw or fw in qw:
                matches += 1
                break
    
    match_pct = matches / len(query_words)
    is_match = match_pct >= 0.7
    
    if is_match:
        logger.info(f"[FTP] ✅ MATCH ({match_pct*100:.0f}%): '{query}' → '{folder_name}'")
    
    return is_match
Verify imports at TOP of file:
pythonimport re
import logging

logger = logging.getLogger(__name__)

📝 FIX 2: Priority Single-Source
File: backend/multi_source_manager.py
Find method (line ~50-150):
pythonasync def search(self, query: str, limit: int = 20):
DELETE entire method and REPLACE with:
pythonasync def search(self, query: str, limit: int = 20):
    """Priority: FTP → HDHub4u → SkyMovies → Cinefreak. Stop at first success."""
    import asyncio
    import time
    
    logger.info(f"[MultiSource] 🔍 Priority search: '{query}'")
    start = time.time()
    
    # PRIORITY 1: FTP
    logger.info("[MultiSource] [P1] Checking FTP...")
    try:
        ftp_results = self.ftp_handler.search(query, limit=limit)
        if ftp_results and len(ftp_results) > 0:
            elapsed = time.time() - start
            logger.info(f"[MultiSource] ✅ FTP SUCCESS: {len(ftp_results)} in {elapsed:.1f}s")
            logger.info("[MultiSource] 🛑 STOPPING (FTP found)")
            return {
                'source': 'ftp',
                'source_name': 'Premium Server',
                'results': ftp_results,
                'count': len(ftp_results),
                'time': elapsed
            }
        logger.info("[MultiSource] FTP empty, trying scrapers...")
    except Exception as e:
        logger.error(f"[MultiSource] FTP error: {e}")
    
    # PRIORITY 2: HDHub4u
    if self.hdhub4u_scraper:
        logger.info("[MultiSource] [P2] Checking HDHub4u...")
        try:
            results = await asyncio.wait_for(self.hdhub4u_scraper.search(query), timeout=30)
            if results and len(results) > 0:
                validated = self._validate_results(query, results)
                if validated:
                    elapsed = time.time() - start
                    logger.info(f"[MultiSource] ✅ HDHub4u SUCCESS: {len(validated)} in {elapsed:.1f}s")
                    logger.info("[MultiSource] 🛑 STOPPING (HDHub4u found)")
                    return {
                        'source': 'hdhub4u',
                        'source_name': 'HDHub4u',
                        'results': validated[:limit],
                        'count': len(validated),
                        'time': elapsed
                    }
        except asyncio.TimeoutError:
            logger.warning("[MultiSource] HDHub4u timeout")
        except Exception as e:
            logger.error(f"[MultiSource] HDHub4u error: {e}")
    
    # PRIORITY 3: SkyMoviesHD
    if self.skymovieshd_scraper:
        logger.info("[MultiSource] [P3] Checking SkyMoviesHD...")
        try:
            results = await asyncio.wait_for(self.skymovieshd_scraper.search(query), timeout=30)
            if results and len(results) > 0:
                validated = self._validate_results(query, results)
                if validated:
                    elapsed = time.time() - start
                    logger.info(f"[MultiSource] ✅ SkyMoviesHD SUCCESS: {len(validated)} in {elapsed:.1f}s")
                    logger.info("[MultiSource] 🛑 STOPPING (SkyMoviesHD found)")
                    return {
                        'source': 'skymovieshd',
                        'source_name': 'SkyMoviesHD',
                        'results': validated[:limit],
                        'count': len(validated),
                        'time': elapsed
                    }
        except asyncio.TimeoutError:
            logger.warning("[MultiSource] SkyMoviesHD timeout")
        except Exception as e:
            logger.error(f"[MultiSource] SkyMoviesHD error: {e}")
    
    # PRIORITY 4: Cinefreak
    if self.cinefreak_scraper:
        logger.info("[MultiSource] [P4] Checking Cinefreak...")
        try:
            results = await asyncio.wait_for(self.cinefreak_scraper.search(query), timeout=30)
            if results and len(results) > 0:
                validated = self._validate_results(query, results)
                if validated:
                    elapsed = time.time() - start
                    logger.info(f"[MultiSource] ✅ Cinefreak SUCCESS: {len(validated)} in {elapsed:.1f}s")
                    logger.info("[MultiSource] 🛑 STOPPING (Cinefreak found)")
                    return {
                        'source': 'cinefreak',
                        'source_name': 'Cinefreak',
                        'results': validated[:limit],
                        'count': len(validated),
                        'time': elapsed
                    }
        except asyncio.TimeoutError:
            logger.warning("[MultiSource] Cinefreak timeout")
        except Exception as e:
            logger.error(f"[MultiSource] Cinefreak error: {e}")
    
    # Nothing found
    elapsed = time.time() - start
    logger.warning(f"[MultiSource] ❌ NO RESULTS for '{query}' ({elapsed:.1f}s)")
    return {
        'source': 'none',
        'source_name': 'Not Found',
        'results': [],
        'count': 0,
        'time': elapsed
    }
Now ADD this NEW method RIGHT AFTER (same file):
pythondef _validate_results(self, query: str, results: list) -> list:
    """Validate scraper results match query (prevent wrong movies)"""
    import re
    from difflib import SequenceMatcher
    
    if not results:
        return []
    
    query_clean = re.sub(r'[._\-\[\]\(\)0-9]', ' ', query.lower()).strip()
    query_clean = re.sub(r'\s+', ' ', query_clean)
    query_words = set(query_clean.split())
    
    validated = []
    
    for result in results:
        title = result.get('title', '').lower()
        if not title:
            continue
        
        title_clean = re.sub(r'[._\-\[\]\(\)0-9]', ' ', title).strip()
        title_clean = re.sub(r'\s+', ' ', title_clean)
        title_words = set(title_clean.split())
        
        common = query_words & title_words
        similarity = SequenceMatcher(None, query_clean, title_clean).ratio()
        
        if len(common) >= 2 or similarity >= 0.7:
            logger.debug(f"[MultiSource] ✓ Valid: '{query}' → '{result.get('title')}'")
            validated.append(result)
        else:
            logger.warning(f"[MultiSource] ✗ Reject: '{query}' ≠ '{result.get('title')}'")
    
    return validated
Verify imports at TOP:
pythonimport time
import asyncio
import logging

logger = logging.getLogger(__name__)

💾 SAVE & RESTART
bash# Save both files

# Restart backend
python main.py

# Or
uvicorn main:app --reload --host 0.0.0.0 --port 8000

🧪 TEST
bash# Test 1: FTP search
curl "http://localhost:8000/search?query=A Knight of the Seven Kingdoms"
# Should find instantly, show "Premium Server"

# Test 2: Check logs
# Should see:
# [FTP] ✅ MATCH: 'a knight...' → 'A Knight...'
# [MultiSource] 🛑 STOPPING (FTP found)

# Test 3: Scraper fallback
curl "http://localhost:8000/search?query=Random Movie XYZ"
# Should check FTP first, then scrapers

# Test 4: Flutter app
# Search "Young Sherlock" → should show correct movie (not O Romeo)
# Search "A Knight" → should find on FTP
# No duplicate links from multiple sources
```

---

## ✅ SUCCESS CRITERIA
```
After fix, you should see:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ FTP finds movies with year differences
✅ Logs show "✅ MATCH" messages
✅ Logs show "🛑 STOPPING" after finding content
✅ Only ONE source shown per search
✅ No duplicate links
✅ Correct movie shown (Young Sherlock = Young Sherlock)
✅ Response time: 1-2s (FTP), 8-15s (scrapers)

🚨 IF NOT WORKING
Problem: FTP still not finding
bash# Check if _matches method replaced
grep -n "Smart matching" backend/ftp_handler.py
# Should show line number

# If not found, re-paste the code
Problem: Still getting duplicates
bash# Check if search method replaced
grep -n "Priority: FTP" backend/multi_source_manager.py
# Should show line number

# Check logs for "🛑 STOPPING"
# If not there, old code still running
Problem: Wrong movie still showing
bash# Check if _validate_results exists
grep -n "_validate_results" backend/multi_source_manager.py
# Should show method

# Check logs for "✓ Valid" or "✗ Reject"
# If missing, method not called

📤 DEPLOY
bash# Commit
git add backend/ftp_handler.py backend/multi_source_manager.py
git commit -m "Fix FTP matching + priority single-source"
git push origin main

# Render auto-deploys (2-3 min)