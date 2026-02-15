Hi Google Antigravity,

Please implement a PROFESSIONAL DOUBLE-BACK-TO-EXIT feature to prevent accidental app exits. This is a standard feature in professional apps like WhatsApp, Instagram, YouTube, and Netflix.

REQUIREMENT:

Currently, pressing the back button once immediately exits the app, which is frustrating for users who accidentally tap back. We need to implement a double-tap back exit pattern with visual feedback.

EXPECTED BEHAVIOR:

1. First Back Press:
   - Show toast message: "Press back again to exit"
   - Start 2-second timer
   - Stay in app

2. Second Back Press (within 2 seconds):
   - Exit app immediately

3. Second Back Press (after 2 seconds):
   - Treat as first press again
   - Show toast message again
   - Reset timer

IMPLEMENTATION REQUIREMENTS:

1. APPLY ONLY TO MAIN/HOME SCREEN:
   - Only implement on the main screen with bottom navigation
   - DO NOT apply to:
     * Movie detail screens
     * Player screens
     * Settings screens
     * Search results
     * Any sub-screens
   - Reason: Users should be able to navigate back normally from sub-screens

2. SMART NAVIGATION:
   If user is on a different bottom navigation tab (e.g., Search, Latest, Library, Downloads):
   - First back press → Navigate to Home tab (index 0)
   - Second back press → Show "press back again" toast
   - Third back press → Exit app
   
   This matches YouTube/Instagram behavior.

3. TOAST MESSAGE DESIGN:

   Style: Material Design 3 SnackBar
SnackBar(
content: Row(
children: [
Icon(Icons.exit_to_app, color: Colors.white),
SizedBox(width: 12),
Text('Press back again to exit'),
],
),
duration: Duration(seconds: 2),
behavior: SnackBarBehavior.floating,
backgroundColor: Color(0xFF323232),
margin: EdgeInsets.all(16),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(8),
),
)

   Requirements:
   - Floating snackbar (not fixed at bottom)
   - Dark background (#323232)
   - Exit icon on left
   - Clean, minimal text
   - 16dp margin all sides
   - 8dp border radius
   - 2 second duration
   - Auto-dismiss previous toast before showing new one

4. TIMING:
   - Timeout: 2 seconds (standard across all major apps)
   - DO NOT make this configurable - keep it simple
   - Use DateTime to track last back press
   - Calculate difference between presses

5. IMPLEMENTATION LOCATION:

   File: lib/screens/main/main_screen.dart (or wherever your bottom navigation lives)

   Use WillPopScope widget:
```dart
   class _MainScreenState extends State<MainScreen> {
     DateTime? _lastBackPressed;
     int _currentIndex = 0;
     
     @override
     Widget build(BuildContext context) {
       return WillPopScope(
         onWillPop: _onWillPop,
         child: Scaffold(
           body: _screens[_currentIndex],
           bottomNavigationBar: BottomNavigationBar(
             currentIndex: _currentIndex,
             onTap: (index) => setState(() => _currentIndex = index),
             items: [...],
           ),
         ),
       );
     }
     
     Future<bool> _onWillPop() async {
       // Implementation here
     }
   }
```

6. LOGIC FLOW:
```dart
   Future<bool> _onWillPop() async {
     final now = DateTime.now();
     
     // Step 1: If not on home tab, navigate to home instead of exiting
     if (_currentIndex != 0) {
       setState(() => _currentIndex = 0);
       return false; // Don't exit
     }
     
     // Step 2: On home tab - check double back
     if (_lastBackPressed == null || 
         now.difference(_lastBackPressed!) > Duration(seconds: 2)) {
       
       // First press or timeout expired
       _lastBackPressed = now;
       
       // Remove any existing snackbar
       ScaffoldMessenger.of(context).removeCurrentSnackBar();
       
       // Show toast
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(...)
       );
       
       return false; // Don't exit
       
     } else {
       // Second press within 2 seconds
       return true; // Exit app
     }
   }
```

7. EDGE CASES TO HANDLE:

   A) User presses back, then switches to another tab, then presses back again:
      - Should reset timer
      - Should navigate to home tab first
   
   B) User presses back multiple times rapidly:
      - Should only count as 2 presses
      - Should exit after 2nd press
   
   C) App is backgrounded and resumed:
      - Should reset timer (consider previous press expired)
   
   D) User presses back, then interacts with app:
      - Timer continues (don't reset)
      - This is intentional - follows standard behavior

8. DO NOT IMPLEMENT:

   ❌ Configurable timeout in settings
   ❌ Dialog instead of toast
   ❌ Vibration feedback
   ❌ Sound effects
   ❌ Animation beyond standard SnackBar
   ❌ "Are you sure?" dialog
   ❌ Custom overlay
   
   Keep it SIMPLE and STANDARD.

9. TESTING REQUIREMENTS:

   Please verify:
   - Single back press shows toast and stays in app
   - Double back press within 2 seconds exits app
   - Double back press after 2 seconds shows toast again
   - Back press on non-home tab navigates to home tab first
   - Multiple rapid back presses work correctly
   - Toast auto-dismisses after 2 seconds
   - Previous toast is removed before showing new one
   - No memory leaks from DateTime tracking

10. ACCESSIBILITY:

    - Toast should be screen-reader accessible
    - Use semantic labels if needed
    - Ensure sufficient contrast for text

TECHNICAL NOTES:

- Use WillPopScope (not PopScope - avoid deprecated APIs)
- Track state at MainScreen level, not globally
- Don't persist lastBackPressed across app restarts
- Keep it stateful widget (need to track _lastBackPressed)
- Remove current snackbar before showing new one to avoid stacking
- Use SystemNavigator.pop() for clean exit (if needed)

EXPECTED RESULT:

User should experience smooth, professional back button behavior that:
1. Prevents accidental exits
2. Provides clear visual feedback
3. Matches behavior of popular apps (WhatsApp, Instagram, YouTube)
4. Feels natural and intuitive
5. Works consistently across all scenarios

This is a CRITICAL UX feature that significantly improves user experience by preventing frustration from accidental app exits.

Please implement this following Material Design guidelines and Flutter best practices.

Thank you!