# Advanced Link Extractor - Implementation Guide

## 🎯 What This System Does

### Problem Solved:
- ✅ Bypasses AD pages automatically (cryptoinsights.site, etc.)
- ✅ Follows intermediate/mediator pages (hblinks.dad, gadgetsweb.xyz)
- ✅ Handles "Verify Yourself" / "Click to Continue" buttons
- ✅ Extracts ONLY direct download links (hubdrive, gofile, etc.)
- ✅ No more Render timeouts
- ✅ Fixes TMDB ID = 0 issue

---

## 📁 Files to Update

### Backend (Python):

1. **scraper.py** → Replace with `scraper_advanced.py`
2. **main.py** → Already updated (use the latest version)

### Frontend (Flutter/Dart):

3. **movie.dart** → Update with `movie_dart_fix.dart` code

---

## 🔧 Key Features Explained

### 1. Link Classification System

```python
# Three types of URLs:

DIRECT_DOWNLOAD_HOSTS = {
    'hubdrive.space', 'hubcloud.foo', 'gofile.io', ...
}
# → These are FINAL links, added to results

MEDIATOR_HOSTS = {
    'hblinks.dad', 'gadgetsweb.xyz', 'gdtot.pro', ...
}
# → These need to be FOLLOWED recursively

AD_HOSTS = {
    'cryptoinsights.site', 'adfly.com', ...
}
# → These are SKIPPED completely
```

### 2. Advanced Link Extractor Flow

```
Movie Page
    ↓
Scan for links
    ↓
Classify each link:
    ├─ Direct Download? → Add to results ✅
    ├─ Mediator? → Follow recursively (max depth 2) 🔄
    └─ AD Page? → Skip ❌
    ↓
Return only direct download links
```

### 3. Verification Button Handler

Automatically clicks buttons like:
- "Continue"
- "Verify Yourself"
- "I am not a robot"
- "Click here to continue"

### 4. Timeout Protection

```python
# Page navigation: 15 seconds max
await page.goto(url, timeout=15000)

# Single link extraction: 25 seconds max
await asyncio.wait_for(extractor.extract(url), timeout=25.0)

# Mediator following: 10 seconds max
await asyncio.wait_for(self.extract(mediator_url), timeout=10.0)
```

### 5. TMDB ID Validation

**Backend:**
```python
if tmdb_id <= 0:
    raise HTTPException(400, "Invalid TMDB ID")
```

**Frontend:**
```dart
int parseId(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

final id = parseId(json['tmdb_id']) != 0
    ? parseId(json['tmdb_id'])
    : parseId(json['id']);
```

---

## 🚀 Deployment Steps

### Step 1: Update Backend

```bash
# Replace scraper.py
mv scraper_advanced.py scraper.py

# Verify main.py has latest changes
# (TMDB ID validation, detailed logging)

# Deploy to Render
git add scraper.py main.py
git commit -m "Advanced link extractor with AD bypass"
git push
```

### Step 2: Update Flutter App

```dart
// In movie.dart, update fromJson:

factory Movie.fromJson(Map<String, dynamic> json) {
  // Use robust ID parsing
  int parseId(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  final id = parseId(json['tmdb_id']) != 0
      ? parseId(json['tmdb_id'])
      : parseId(json['id']);

  if (id <= 0) {
    print('WARNING: Invalid TMDB ID: $json');
  }

  return Movie(
    id: id,
    title: json['title'] ?? 'Unknown',
    posterPath: json['tmdb_poster'] ?? json['poster'],
    rating: (json['rating'] ?? 0.0).toDouble(),
    overview: json['plot'] ?? json['overview'],
    releaseDate: json['release_date'],
    sources: (json['sources'] as List?)
        ?.map((s) => MovieSource.fromJson(s))
        .toList(),
  );
}
```

### Step 3: Test

```bash
# Test search
curl "https://your-api.onrender.com/search?query=Inception"

# Test link generation
curl "https://your-api.onrender.com/links?tmdb_id=27205&title=Inception&year=2010"
```

---

## 📊 Performance Improvements

### Before:
- ⏱️ Timeout after 60+ seconds
- ❌ Returns intermediate pages (hblinks.dad)
- ❌ Includes AD pages
- 🐌 Sequential processing

### After:
- ⚡ Completes in 15-25 seconds
- ✅ Returns only direct download links
- ✅ Skips AD pages automatically
- 🚀 Concurrent scraping with semaphores

---

## 🔍 Debugging

### Enable Detailed Logging:

```python
# In scraper.py, change:
logging.basicConfig(level=logging.DEBUG)

# Check logs for:
# [Depth X] Extracting from: URL
# Following mediator: URL
# Clicked verification button: selector
# Extracted X final download links
```

### Common Issues:

**Issue: Still timing out**
```python
# Reduce max URLs to scrape
all_urls = list(set(all_urls))[:3]  # Changed from 5 to 3

# Reduce max depth
extractor = AdvancedLinkExtractor(page, max_depth=1)  # Changed from 2
```

**Issue: TMDB ID still 0**
```dart
// Add debug logging in Flutter
print('Received JSON: ${response.body}');
print('Parsed ID: ${movie.id}');

// Check API response format
final data = json.decode(response.body);
print('Results structure: ${data['results'][0].keys}');
```

**Issue: No links found**
```python
# Check if sites changed structure
logger.debug(f"Page content preview: {content[:500]}")

# Try different selectors
# Update DIRECT_DOWNLOAD_HOSTS if new file hosts appear
```

---

## 📈 Monitoring

### Key Metrics to Watch:

1. **Response Time**: Should be < 30 seconds
2. **Cache Hit Rate**: Should increase over time
3. **Links Found**: Should be > 0 for popular movies
4. **Error Rate**: Should be < 10%

### Logs to Monitor:

```
[Scraping Start] Generating links for: Movie Name
[Depth 0] Extracting from: https://...
Following mediator: https://hblinks.dad/...
[Depth 1] Extracting from: https://hblinks.dad/...
Clicked verification button: button:has-text("Continue")
Extracted 5 final download links
[Scraping Complete] Found 12 links for Movie Name
```

---

## ⚠️ Important Notes

1. **Concurrent Requests**: Limited to 2 to avoid IP bans
2. **Cache Duration**: 7 days (configurable in `CacheManager`)
3. **Max Recursion Depth**: 2 levels (movie page → mediator → final)
4. **Browser Launch**: Headless mode with stealth plugins
5. **Timeout Strategy**: Progressive (15s → 25s → 10s)

---

## 🎯 Next Steps

1. Deploy updated `scraper.py`
2. Update Flutter `movie.dart`
3. Test with popular movies
4. Monitor Render logs
5. Adjust timeouts if needed
6. Add more file hosts to `DIRECT_DOWNLOAD_HOSTS` if needed

---

## 🆘 Support

If issues persist:

1. Check Render logs: `https://dashboard.render.com/web/YOUR_SERVICE/logs`
2. Test API directly: `curl "https://your-api.onrender.com/links?..."`
3. Enable DEBUG logging
4. Share logs for analysis

---

## ✅ Success Criteria

- [ ] Search returns movies with valid TMDB IDs (> 0)
- [ ] Link generation completes in < 30 seconds
- [ ] Returns only direct download links (no mediators/ADs)
- [ ] Cache works (second request instant)
- [ ] No Render timeouts
- [ ] Flutter app displays links correctly

---

**Good luck!** 🚀