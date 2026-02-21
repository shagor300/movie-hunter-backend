Hi Antigravity,

I've redesigned the entire MovieHub app UI using Google Stitch and need 
you to implement it using the Stitch MCP integration. You have direct 
access to view my designs through MCP.

════════════════════════════════════════════════════════════════
STITCH PROJECT INFORMATION
════════════════════════════════════════════════════════════════

PROJECT:
- Title: MovieHub app UI Design
- Project ID: 8456820848382980647

TOTAL SCREENS: 24 screens (complete app redesign)

You have Stitch MCP access. Please use it to:
✅ View all screen designs
✅ Extract design specifications (colors, typography, spacing, components)
✅ Get exact dimensions and layouts
✅ Identify UI patterns and component structures

════════════════════════════════════════════════════════════════
ALL SCREEN DESIGNS (24 SCREENS)
════════════════════════════════════════════════════════════════

CORE NAVIGATION SCREENS:
1. Search Tab (ID: e40f3bc1bc974fe299f769f1d9f73bda)
2. Search Tab - Large Posters (ID: c78937869f8f43768adff660f48031d4)
3. Refined Search Tab (ID: b5aecb3ca5374c2a8befee79244b70ed)
4. Search - Emerald Accent (ID: fa17db28a8c9491db2626018da1ab095)

5. For You Tab (ID: 9bd39674dc434964baf748c83ebdab07)
6. Refined For You Tab (ID: 3a36cfebc062410f921e479d1f8dc64a)
7. For You - Emerald Accent (ID: e2ea2a642da747f6b44a1ce7459b11cd)

8. My Library / Watchlist (ID: 68bdb6e93a8e4441a0b0b92692ef3b7d)
9. My Library - Large Posters (ID: 4cd33eb562754965a3d0143af7b294dd)
10. Refined My Library (ID: df50545a5a7a433b918e1677086b7526)
11. Library - Emerald Accent (ID: e1fc5eed6a5b4f50bd5ab823db7924d9)

12. Download Manager (ID: 4d5e14f1cf864da1905ac6c54aaa40d0)

DETAIL SCREENS:
13. Section Detail - Action & Adventure (ID: e28d608a08f042aabf40bc6750f348f4)
14. Section Detail - Large Posters (ID: a1fdbf333e8e459d97ecdf3f56f72d7f)
15. Refined Section Detail (ID: 7421d660a6b349f4ac59836aaa113030)

PLAYER SCREENS:
16. Video Player (ID: 1c2e7b3e9adb42338f664413cbd4cd65)
17. WebView Player (ID: 5e38be919ffb44649f74041901d7629c)

SETTINGS & PREFERENCES:
18. Settings (ID: d333011bd56b412d8d139d4dd7a2e119)
19. Settings - Emerald Accent (ID: 498868630b1e493288e6826c76581e86)
20. Notification Settings (ID: 45207be0dd554c908244cc771fb88861)

SPECIAL SCREENS:
21. Splash Screen (ID: 6a7bfc3678b64b77838ff7c01938f525)
22. Onboarding - Discover (ID: b48c3a19648049c8b87837176a40bc5e)
23. Voice Search Modal (ID: 1a0463c51b0942d8bd56ae0fa9fab8e4)
24. Generated Screen (ID: 4e4b7123f5594b788fce7615adaf04d5)

════════════════════════════════════════════════════════════════
EXISTING CODEBASE REFERENCE
════════════════════════════════════════════════════════════════

CURRENT APP STRUCTURE:
I have an existing Flutter MovieHub app with these files:

1. splash_screen.dart (234 lines)
2. onboarding_screen.dart (107 lines)
3. home_screen.dart (140 lines) - Shell with bottom navigation
4. search_screen.dart (763 lines)
5. recommendations_screen.dart (885 lines) - For You tab
6. hdhub4u_tab.dart (791 lines) - Latest tab
7. library_screen.dart (532 lines)
8. downloads_screen.dart (528 lines)
9. details_screen.dart (1117 lines)
10. video_player_screen.dart (623 lines)
11. webview_player.dart (~200 lines)
12. settings_screen.dart (1074 lines)
13. notification_settings_screen.dart (609 lines)
14. voice_search_screen.dart (~150 lines)
15. section_detail_screen.dart (~100 lines)

CURRENT FEATURES (Working):
✅ TMDB API integration
✅ Multi-source scraping (HDHub4u, SkyMoviesHD, etc.)
✅ Link resolution system
✅ Download manager with parallel downloads
✅ Video player with BetterPlayer
✅ Watchlist system (4 categories)
✅ Continue watching
✅ Voice search
✅ Settings & preferences

TASK: Redesign UI of existing screens, keeping ALL functionality intact.

════════════════════════════════════════════════════════════════
STEP 1: DESIGN ANALYSIS (Use Stitch MCP)
════════════════════════════════════════════════════════════════

ACTION REQUIRED:

Please use Stitch MCP to analyze ALL 24 screens and extract:

1. DESIGN SYSTEM:
   □ Color palette (primary, accent, backgrounds, text colors)
   □ Typography (font families, sizes, weights)
   □ Spacing scale (margins, paddings, gaps)
   □ Border radius values
   □ Shadow specifications
   □ Gradient definitions
   □ Icon sizes and styles

2. COMPONENT PATTERNS:
   □ Movie card designs (portrait/landscape variants)
   □ Button styles (primary/secondary/text)
   □ Input field designs
   □ Navigation bar style
   □ Loading states
   □ Empty states
   □ Error states

3. LAYOUT STRUCTURES:
   □ Grid configurations (columns, gaps)
   □ Header layouts
   □ Section spacing
   □ Bottom navigation design
   □ Modal/dialog designs

4. INTERACTIVE ELEMENTS:
   □ Tap states
   □ Scroll behaviors
   □ Transition animations
   □ Loading indicators

After analysis, provide me:
- Complete design system documentation
- Color palette with hex codes
- Typography scale
- Spacing guidelines
- Component specifications

THEN wait for my approval before proceeding to implementation.

════════════════════════════════════════════════════════════════
STEP 2: IMPLEMENTATION STRATEGY
════════════════════════════════════════════════════════════════

APPROACH:

I want you to REFACTOR existing screens, not rewrite from scratch.

For each screen:
1. Use Stitch MCP to view the new design
2. Analyze existing Dart file
3. Identify what to keep (logic, controllers, API calls)
4. Identify what to change (UI only)
5. Refactor UI components to match new design
6. Test that functionality still works

PRIORITY ORDER:

PHASE 1 - Foundation  :
□ Extract complete design system from Stitch
□ Create design tokens file (colors.dart, text_styles.dart, etc.)
□ Update theme configuration
□ Create/update reusable widgets (MovieCard, buttons, inputs, etc.)

PHASE 2 - Core Screens  :
□ Splash Screen - match Stitch ID: 6a7bfc3678b64b77838ff7c01938f525
□ Onboarding - match Stitch ID: b48c3a19648049c8b87837176a40bc5e
□ Home Shell - update bottom navigation design
□ Search Tab - match Stitch ID: b5aecb3ca5374c2a8befee79244b70ed (Refined version)
   Keep: Search logic, API integration, filtering
   Update: UI, card design, layout

PHASE 3 - Main Tabs  :
□ For You Tab - match Stitch ID: 3a36cfebc062410f921e479d1f8dc64a (Refined)
   Keep: TMDB integration, continue watching logic, sections
   Update: Hero section, card designs, section headers
   
□ Library Screen - match Stitch ID: df50545a5a7a433b918e1677086b7526 (Refined)
   Keep: Watchlist logic, category system
   Update: Card designs, tab bar, empty states

□ Downloads Screen - match Stitch ID: 4d5e14f1cf864da1905ac6c54aaa40d0
   Keep: Download logic, progress tracking
   Update: Card designs, progress UI, action buttons

PHASE 4 - Detail & Player  :
□ Section Detail - match Stitch ID: 7421d660a6b349f4ac59836aaa113030 (Refined)
□ Video Player - match Stitch ID: 1c2e7b3e9adb42338f664413cbd4cd65
   Keep: BetterPlayer integration, controls logic
   Update: Control overlay design, buttons, progress bar
   
□ WebView Player - match Stitch ID: 5e38be919ffb44649f74041901d7629c

PHASE 5 - Settings & Modals  :
□ Settings - match Stitch ID: d333011bd56b412d8d139d4dd7a2e119
   Keep: All settings logic, SharedPreferences
   Update: UI layout, toggles, sections design
   
□ Notification Settings - match Stitch ID: 45207be0dd554c908244cc771fb88861
□ Voice Search Modal - match Stitch ID: 1a0463c51b0942d8bd56ae0fa9fab8e4

PHASE 6 - Polish  :
□ Add animations and transitions
□ Refine loading states
□ Update empty states
□ Test all features
□ Fix any UI bugs

════════════════════════════════════════════════════════════════
DESIGN VARIANTS EXPLANATION
════════════════════════════════════════════════════════════════

I created multiple design variants for some screens:

SEARCH TAB (3 variants):
- Standard (ID: e40f3bc1bc974fe299f769f1d9f73bda)
- Large Posters (ID: c78937869f8f43768adff660f48031d4)
- Refined (ID: b5aecb3ca5374c2a8befee79244b70ed) ← USE THIS ONE

FOR YOU TAB (3 variants):
- Standard (ID: 9bd39674dc434964baf748c83ebdab07)
- Refined (ID: 3a36cfebc062410f921e479d1f8dc64a) ← USE THIS ONE
- Emerald Accent (ID: e2ea2a642da747f6b44a1ce7459b11cd)

LIBRARY (4 variants):
- Standard (ID: 68bdb6e93a8e4441a0b0b92692ef3b7d)
- Large Posters (ID: 4cd33eb562754965a3d0143af7b294dd)
- Refined (ID: df50545a5a7a433b918e1677086b7526) ← USE THIS ONE
- Emerald Accent (ID: e1fc5eed6a5b4f50bd5ab823db7924d9)

SECTION DETAIL (3 variants):
- Action & Adventure (ID: e28d608a08f042aabf40bc6750f348f4)
- Large Posters (ID: a1fdbf333e8e459d97ecdf3f56f72d7f)
- Refined (ID: 7421d660a6b349f4ac59836aaa113030) ← USE THIS ONE

ACCENT COLOR OPTIONS:
I also created "Emerald Accent" variants. These show an alternative 
color scheme. You can make accent color customizable in settings if 
you want, but for now, use the primary blue/purple gradient from 
the standard designs.

DEFAULT: Use "Refined" versions for main implementation.

════════════════════════════════════════════════════════════════
TECHNICAL REQUIREMENTS
════════════════════════════════════════════════════════════════

FRAMEWORK: Flutter (existing project)

DEPENDENCIES (Keep existing + add if needed):
- get: ^4.6.6 (state management)
- google_fonts: ^6.1.0
- cached_network_image: ^3.3.0
- shimmer: ^3.0.0
- better_player_enhanced: ^1.0.0
- hive: ^2.2.3 (local storage)
- dio: ^5.4.0 (networking)
- (Keep all existing dependencies)

NEW WIDGETS TO CREATE:

1. Design System Files:
   - lib/theme/app_colors.dart (from Stitch designs)
   - lib/theme/app_text_styles.dart (from Stitch designs)
   - lib/theme/app_dimensions.dart (spacing, sizes)
   - lib/theme/app_theme.dart (ThemeData configuration)

2. Reusable Components:
   - lib/widgets/movie_card.dart (multiple variants)
   - lib/widgets/gradient_button.dart
   - lib/widgets/glassmorphic_card.dart (if used in designs)
   - lib/widgets/custom_search_bar.dart
   - lib/widgets/section_header.dart
   - lib/widgets/loading_shimmer.dart
   - lib/widgets/empty_state.dart

UI PATTERNS TO IMPLEMENT:

Based on Stitch designs (verify with MCP):
□ Movie cards with rounded corners
□ Gradient overlays on images
□ Quality badges (HD, 4K)
□ Rating stars display
□ Progress bars for continue watching
□ Bottom navigation with icons
□ Smooth page transitions
□ Loading skeletons (shimmer effect)
□ Pull-to-refresh indicators
□ Floating action buttons (if in designs)
□ Custom app bars
□ Tab bars with indicators

════════════════════════════════════════════════════════════════
CRITICAL: PRESERVE ALL FUNCTIONALITY
════════════════════════════════════════════════════════════════

MUST NOT BREAK:

✅ TMDB API integration
✅ Multi-source scraping
✅ Link generation (7-stage loading)
✅ Download system (parallel downloads with speed/ETA)
✅ Video playback (BetterPlayer + external player fallback)
✅ Watchlist (4 categories: Watch Later, Favorites, Watched, Dropped)
✅ Continue watching (resume playback positions)
✅ Search (with filters, voice search)
✅ Settings (theme, downloads, storage, cache)
✅ Navigation flow (back press handling, deep linking)

REFACTORING APPROACH:
```dart
// EXAMPLE: Refactoring search_screen.dart

// KEEP THIS (Controller logic):
class SearchController extends GetxController {
  final searchQuery = ''.obs;
  final searchResults = <Movie>[].obs;
  final isLoading = false.obs;
  
  Future<void> search(String query) async {
    // Keep all this logic
  }
}

// UPDATE THIS (UI):
@override
Widget build(BuildContext context) {
  // Use NEW design from Stitch
  // But call SAME controller methods
  return Scaffold(
    backgroundColor: AppColors.background, // NEW: from Stitch
    body: SafeArea(
      child: Column(
        children: [
          // NEW: Updated search bar design from Stitch
          CustomSearchBar(
            onChanged: (query) => controller.search(query),
          ),
          
          // NEW: Updated movie grid design from Stitch
          Obx(() => GridView.builder(
            itemBuilder: (context, index) {
              return MovieCard( // NEW: Updated card design
                movie: controller.searchResults[index],
                onTap: () => Get.to(DetailsScreen(...)),
              );
            },
          )),
        ],
      ),
    ),
  );
}
```

════════════════════════════════════════════════════════════════
WORKFLOW
════════════════════════════════════════════════════════════════

STEP-BY-STEP PROCESS:

PHASE 1 - ANALYSIS:
1. Use Stitch MCP to view all 24 designs
2. Extract complete design system (colors, typography, spacing)
3. Create design system documentation
4. Show me the design system
5. Wait for my approval

PHASE 2 - FOUNDATION:
1. Create theme files (colors, text styles, dimensions)
2. Update ThemeData in main.dart
3. Create reusable widget library
4. Show me the foundation code
5. Wait for my approval

PHASE 3 - SCREEN REFACTORING:
For each screen:
1. Use Stitch MCP to view specific screen design
2. Open existing .dart file
3. Analyze: What to keep vs what to change
4. Refactor UI only (keep logic)
5. Test functionality
6. Show me before/after comparison
7. Wait for my approval

PHASE 4 - POLISH:
1. Add animations
2. Refine transitions
3. Update loading states
4. Update empty states
5. Final testing
6. Show me the completed app
7. Wait for final approval

DELIVERABLES PER SCREEN:

For each refactored screen, provide:
□ Updated .dart file
□ Design comparison (Stitch vs Implementation screenshot)
□ List of changes made
□ Confirmation that functionality still works
□ Any new dependencies needed

════════════════════════════════════════════════════════════════
DESIGN MATCHING INSTRUCTIONS
════════════════════════════════════════════════════════════════

HOW TO MATCH STITCH DESIGNS:

1. COLOR ACCURACY:
   - Extract exact hex codes from Stitch MCP
   - Don't approximate colors
   - Create const values in app_colors.dart

2. TYPOGRAPHY:
   - Match font families (use Google Fonts)
   - Match font sizes exactly
   - Match font weights
   - Match line heights

3. SPACING:
   - Measure exact margins/paddings from Stitch
   - Create spacing constants (8, 12, 16, 20, 24, 32px, etc.)
   - Use consistently across app

4. COMPONENTS:
   - Match border radius values
   - Match shadow properties
   - Match image aspect ratios
   - Match icon sizes

5. LAYOUTS:
   - Match grid columns
   - Match scroll directions
   - Match element positioning

6. INTERACTIONS:
   - Implement any animations shown in Stitch
   - Match transition styles
   - Add appropriate tap feedback

VERIFICATION:
After each screen, show me side-by-side:
- Stitch design (screenshot from MCP)
- Your Flutter implementation (screenshot)
- Highlight any differences

════════════════════════════════════════════════════════════════
QUESTIONS FOR YOU
════════════════════════════════════════════════════════════════

Before starting Phase 1 (Analysis), please confirm:

1. Can you verify you have Stitch MCP access to project ID: 8456820848382980647?

2. Which design variants should I prioritize?
   - I recommend "Refined" versions (Refined Search, Refined For You, Refined Library)
   - Should I implement accent color customization? (Emerald variant exists)

3. Are there any screens where you want significant layout changes 
   vs just visual refresh?

4. Should I maintain current animations or add new ones based on Stitch?

5. Do you want me to create a feature branch or work on main?

6. Priority: Speed vs Perfection?
   - Fast iteration (close enough to designs, functional)
   - Pixel-perfect (exact match to Stitch, slower)

════════════════════════════════════════════════════════════════
REFERENCE DOCUMENTS
════════════════════════════════════════════════════════════════

I've already documented the current app architecture here:
- Technical UI Blueprint (screen structure, navigation flow, features)

This contains:
- All existing screen files and line counts
- Navigation flows
- Feature lists per screen
- Component inventory
- Current design tokens

Please reference this while refactoring to understand what exists.

════════════════════════════════════════════════════════════════

Ready to start!

First, let me use Stitch MCP to analyze your 24 screen designs and 
extract the complete design system. I'll examine:
- Splash Screen (ID: 6a7bfc3678b64b77838ff7c01938f525)
- Refined Search Tab (ID: b5aecb3ca5374c2a8befee79244b70ed)
- Refined For You Tab (ID: 3a36cfebc062410f921e479d1f8dc64a)
- And all other screens

Give me a moment to analyze...