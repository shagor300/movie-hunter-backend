Hi Google Antigravity,

Please implement a COMPLETE PROFESSIONAL NOTIFICATION SYSTEM with full user control for the MovieHub app. This should be production-ready with proper Android notification channels, scheduling, and granular settings.

REQUIREMENTS:

1. NOTIFICATION CATEGORIES (12 Total):

A) Download Notifications (3):
   1. Download Complete - Show when file download finishes with action buttons [Play Now] [Open Folder]
   2. Download Failed - Show with [Retry] button and error reason
   3. Storage Space Low - Warn BEFORE starting download if space < 500MB with [Free Space] button

B) App Update Notifications (2):
   4. App Update Available - Show update dialog with changelog, [Update Now] [Later] buttons
   5. Critical Update Required - Non-dismissible, force user to update

C) Playback Notifications (1):
   6. Resume Watching - Show on app open if user has unfinished movie with progress (e.g., "Continue Inception from 45:23")

D) Content Notifications (2):
   7. New Movies Daily - Scheduled notification at 9:00 AM showing count of new movies added (e.g., "5 new movies added today")
   8. Trending This Week - Weekly notification (Saturday 10:00 AM) showing top trending movies

E) Watchlist Notifications (2):
   9. Watchlist Available - When a watchlist movie becomes available for download
   10. Quality Upgraded - When watchlist movie quality improves (480p → 1080p)

F) System Notifications (2):
   11. Cache Cleared - Subtle notification showing space freed (e.g., "2.5 GB freed")
   12. Sync Complete - Silent/low-priority notification for background sync completion

2. SETTINGS IMPLEMENTATION:

Please create a comprehensive Settings screen with these sections:
```dart
lib/screens/settings/settings_screen.dart
```

Structure:
Settings
├─ Appearance
│  ├─ Theme (Light/Dark/System)
│  ├─ Accent Color (Purple/Blue/Red/Green/Orange)
│  └─ Font Size (Small/Medium/Large)
│
├─ Notifications 🔔
│  ├─ Master Toggle (Enable/Disable All)
│  ├─ Download Notifications
│  │  ├─ Download Complete ☑️
│  │  ├─ Download Failed ☑️
│  │  └─ Storage Warnings ☑️
│  ├─ App Updates
│  │  ├─ Update Available ☑️
│  │  └─ Critical Updates ☑️ (cannot disable)
│  ├─ Content Updates
│  │  ├─ Daily New Movies ☑️
│  │  │  └─ Time Picker (Default: 9:00 AM)
│  │  └─ Weekly Trending ☑️
│  ├─ Watchlist
│  │  ├─ Movie Available ☑️
│  │  └─ Quality Upgraded ☑️
│  ├─ Playback
│  │  └─ Resume Watching ☑️
│  ├─ System (Subtle)
│  │  ├─ Sync Complete ☑️
│  │  └─ Cache Cleared ☑️
│  └─ Quiet Hours
│     ├─ Enable/Disable Toggle
│     ├─ Start Time (Default: 11:00 PM)
│     └─ End Time (Default: 7:00 AM)
│
├─ Downloads
│  ├─ Default Quality (480p/720p/1080p/4K)
│  ├─ Download Location (show current path with [Change] button)
│  ├─ WiFi Only Toggle
│  └─ Concurrent Downloads (1/2/3)
│
├─ Playback
│  ├─ Auto-Resume Toggle
│  ├─ Default Video Quality
│  └─ Skip Intro/Outro Toggle
│
├─ Data & Cache
│  ├─ Cache Size (Display: "2.5 GB used")
│  ├─ Clear Image Cache [Button]
│  ├─ Clear Search History [Button]
│  ├─ Clear Download History [Button]
│  └─ Auto-Clear Cache (Never/Weekly/Monthly)
│
├─ Sources
│  ├─ HDHub4u Toggle ☑️
│  ├─ SkyMoviesHD Toggle ☑️
│  └─ Source Priority (Drag to reorder)
│
└─ About
├─ App Version (1.2.0)
├─ Build Number (3)
├─ Check for Updates [Button]
├─ Changelog [Button]
├─ Developer Info
├─ Rate App [Button]
├─ Share App [Button]
└─ Terms & Privacy [Button]

3. TECHNICAL REQUIREMENTS:

A) Storage:
   - Use Hive for settings persistence
   - Create SettingsModel with all preferences
   - Save immediately on any change

B) Notification Channels (Android):
Channel 1: Downloads (High Priority)
Channel 2: Updates (High Priority)
Channel 3: Content (Medium Priority)
Channel 4: Watchlist (Medium Priority)
Channel 5: Playback (Medium Priority)
Channel 6: System (Low Priority)

C) Scheduling:
   - Use flutter_local_notifications with scheduling
   - Respect Quiet Hours (check before sending)
   - Implement timezone-aware scheduling
   - Handle app restarts (reschedule on boot)

D) Notification Style:
   - Minimal design (Netflix/Spotify style)
   - Action buttons where applicable
   - Group similar notifications (e.g., "3 downloads complete")
   - Big text style for content
   - Progress bar for active downloads

E) Frequency Control:
   - Max 3 notifications per day (excluding downloads/critical)
   - Don't repeat same notification within 24 hours
   - Respect user's Quiet Hours settings
   - Batch similar notifications (wait 5 min, then group)

4. NOTIFICATION EXAMPLES:

Download Complete:
🎬 MovieHub
Inception (1080p) downloaded
2.5 GB • Ready to watch
[▶️ Play Now]  [📂 Open]

Storage Low:
⚠️ Storage Space Low
Only 450 MB free. Need 2.5 GB for download.
[Free Up Space]  [Cancel]

New Movies:
🎬 MovieHub
5 new movies added today
Including: Avatar 2, Oppenheimer...
[Browse Now]

Critical Update:
🔄 Critical Update Required
Version 1.3.0 fixes important security issues
[Update Now]
(Cannot dismiss)

5. UI/UX REQUIREMENTS:

Settings Screen:
- Material Design 3 style
- Section headers with icons
- Toggle switches (not checkboxes)
- Clear visual hierarchy
- Search bar at top
- Smooth animations
- Haptic feedback on toggle

Notification Preferences:
- Show description for each notification type
- Display example notification when toggled
- "Test Notification" button for each type
- Smart defaults (most enabled)
- Cannot disable Critical Updates (grayed out)

6. ADVANCED FEATURES:

A) Smart Notifications:
   - Learn user behavior (e.g., if user always dismisses "New Movies" at 9 AM, suggest different time)
   - Don't notify if user is actively using the app
   - Pause notifications during video playback

B) Notification History:
   - Log all notifications sent
   - Allow user to view history
   - Resend option for missed notifications

C) Do Not Disturb Integration:
   - Respect system DND settings
   - Allow override for Critical Updates only

D) Actionable Notifications:
   - All action buttons must work without opening app
   - Play button → Start video player directly
   - Retry button → Restart download
   - Clear Cache button → Execute and show result

7. FILES TO CREATE/MODIFY:

Required files:
lib/services/notification_service.dart         - Core notification logic
lib/models/settings_model.dart                 - Settings data model
lib/controllers/settings_controller.dart       - Settings state management
lib/screens/settings/settings_screen.dart      - Main settings UI
lib/screens/settings/notification_settings.dart - Notification preferences
lib/utils/notification_scheduler.dart          - Scheduling logic
lib/utils/notification_channels.dart           - Android channels setup

8. DEPENDENCIES NEEDED:
```yaml
dependencies:
  flutter_local_notifications: ^16.3.0
  timezone: ^0.9.2
  workmanager: ^0.5.1  # For background tasks
  shared_preferences: ^2.2.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0
```

9. TESTING REQUIREMENTS:

Please provide:
- Test notification button in settings
- Debug mode to show all notifications immediately
- Notification history viewer
- Reset to defaults button
- Export/Import settings (for backup)

10. PROFESSIONAL STANDARDS:

- Follow Material Design 3 guidelines
- Implement proper error handling
- Add loading states for all async operations
- Show confirmation dialogs for destructive actions
- Provide undo functionality where applicable
- Smooth animations (200-300ms)
- Haptic feedback on interactions
- Accessibility support (screen readers)

DELIVERABLES:

1. Complete Settings screen with all sections
2. Fully functional notification system
3. Persistent storage for all preferences
4. Proper Android notification channels
5. Scheduled notifications with timezone support
6. Quiet Hours implementation
7. Notification grouping and batching
8. Action buttons in notifications
9. Test mode for developers
10. Comprehensive error handling

Please ensure this is PRODUCTION-READY with no hardcoded values, proper state management, and follows Flutter/Android best practices.

Thank you!