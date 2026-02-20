Hi Google Antigravity,

The notification system you implemented has TWO CRITICAL ISSUES:

ISSUE 1: TEST NOTIFICATIONS (Not Production-Ready)
Currently showing test notifications like:
"🖊️ Test Notification - This is a test for newMoviesDaily notifications"

This is NOT what we need. We need REAL, PRODUCTION notifications:

REQUIRED:
- "New Movies Daily" should show: "5 new movies added today" with actual movie count
- "Download Complete" should show: "Inception (1080p) - 2.5 GB ready to watch"
- "Trending This Week" should show actual trending movie names
- "Watchlist Available" should show actual movie title from watchlist

REMOVE all "test" notifications. Implement REAL notifications that:
1. Fetch actual data from backend/database
2. Show real movie names, counts, file sizes
3. Have working action buttons that actually do something
4. Are production-ready, not debug/test notifications


ISSUE 2: NO APP ICON IN NOTIFICATIONS

Current notification shows:
- Generic pen icon (🖊️)
- No app logo
- Looks unprofessional

REQUIRED:
Notifications MUST show proper app icon like WhatsApp, Instagram, Netflix do.

Implementation needed:

A) Create notification icons:
   File: android/app/src/main/res/drawable/ic_notification.xml
```xml
   <vector xmlns:android="http://schemas.android.com/apk/res/android"
       android:width="24dp"
       android:height="24dp"
       android:viewportWidth="24"
       android:viewportHeight="24">
       <path
           android:fillColor="#FFFFFFFF"
           android:pathData="M18,4l2,4h-3l-2,-4h-2l2,4h-3l-2,-4H8l2,4H7L5,4H4c-1.1,0 -1.99,0.9 -1.99,2L2,18c0,1.1 0.9,2 2,2h16c1.1,0 2,-0.9 2,-2V4h-4z"/>
   </vector>
```
   
   This creates a movie/film icon in white color.

B) Update notification channel setup:
   
   In your notification service, SET THE ICON:
```dart
   final androidDetails = AndroidNotificationDetails(
     'channel_id',
     'Channel Name',
     channelDescription: 'Description',
     importance: Importance.high,
     priority: Priority.high,
     icon: 'ic_notification',  // THIS IS CRITICAL
     largeIcon: DrawableResourceAndroidBitmap('ic_launcher'),  // App icon
     color: Color(0xFF6200EE),  // Purple accent
   );
```

C) Ensure proper icon files exist:
   
   You need these icon files:
   - android/app/src/main/res/drawable/ic_notification.xml (white monochrome)
   - android/app/src/main/res/mipmap-hdpi/ic_launcher.png
   - android/app/src/main/res/mipmap-mdpi/ic_launcher.png
   - android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
   - android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
   - android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png


EXAMPLES OF PROPER NOTIFICATIONS:

1. New Movies Daily (9 AM):
[🎬] MovieHub
5 new movies added today
Including: Inception, Interstellar, The Dark Knight
[Browse Now]

2. Download Complete:
[🎬] MovieHub
Download Complete
Inception (1080p) • 2.5 GB
[▶️ Play Now]  [Share]

3. Trending This Week:
[🎬] MovieHub
Top 5 Trending Movies

Oppenheimer
Barbie
The Batman
[See All]


4. Watchlist Available:
[🎬] MovieHub
Watchlist Update
"Avatar 2" is now available in 1080p
[Download Now]


CRITICAL REQUIREMENTS:

1. NO TEST NOTIFICATIONS
   - Remove all "This is a test for..." messages
   - Implement real data fetching
   - Show actual movie information

2. PROPER APP ICON
   - Small icon: ic_notification.xml (white, transparent background)
   - Large icon: ic_launcher (app logo)
   - Color: Purple (#6200EE)

3. ACTION BUTTONS MUST WORK
   - "Play Now" → Opens video player
   - "Browse Now" → Opens latest movies
   - "Download Now" → Starts download
   - NOT just test buttons

4. PRODUCTION DATA
   - Fetch real movie count from database
   - Get actual file sizes from downloads
   - Show real trending movies from backend
   - Display actual watchlist items

Please fix both issues and provide PRODUCTION-READY notifications with proper icons and real data.

Thank you!