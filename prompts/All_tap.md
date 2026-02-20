Hi Antigravity,

TWO TASKS needed for "For You" tab:

═══════════════════════════════════
TASK 1: FIX SECTION TAP (Critical Bug)
═══════════════════════════════════

CURRENT PROBLEM:
When user taps on any section header or ">" arrow 
in For You tab, nothing happens.

Sections affected:
- "Trending Now" > tap → Nothing ❌
- "Because you liked Fight Club" > tap → Nothing ❌
- "Top Action" > tap → Nothing ❌
- "Drama Masterpieces" > tap → Nothing ❌
- "Hidden Gems" > tap → Nothing ❌
- ALL other sections > tap → Nothing ❌

EXPECTED BEHAVIOR:
When user taps section header or ">" arrow:
→ Open a new screen showing ALL movies in that section
→ Title of screen = Section name
→ Show movies in grid (2 columns)
→ Back button returns to For You

IMPLEMENTATION:

Create new screen:
File: lib/screens/for_you/section_detail_screen.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SectionDetailScreen extends StatelessWidget {
  final String sectionTitle;
  final List<dynamic> movies;
  
  const SectionDetailScreen({
    Key? key,
    required this.sectionTitle,
    required this.movies,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(sectionTitle),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          return MovieCard(movie: movies[index]);
        },
      ),
    );
  }
}
```

Fix section header tap in For You screen:
```dart
// In for_you_screen.dart
// Find where section headers are built
// Add onTap to each section

GestureDetector(
  onTap: () {
    // Navigate to section detail
    Get.to(
      () => SectionDetailScreen(
        sectionTitle: section.title,
        movies: section.movies,
      ),
      transition: Transition.rightToLeft,
    );
  },
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(section.title),
      Icon(Icons.chevron_right), // The ">" arrow
    ],
  ),
)
```

═══════════════════════════════════
TASK 2: ADD NEW SECTIONS
═══════════════════════════════════

Add these NEW sections to For You tab:

LANGUAGE SECTIONS:
```dart
// 1. Hindi Blockbusters
ForYouSection(
  id: 'hindi_blockbusters',
  title: '🎬 Hindi Blockbusters',
  icon: '🎬',
  tmdbParams: {
    'with_original_language': 'hi',
    'sort_by': 'popularity.desc',
    'vote_average.gte': 6.0,
  },
)

// 2. Bengali Cinema
ForYouSection(
  id: 'bengali_cinema',
  title: '🎭 Bengali Cinema',
  icon: '🎭',
  tmdbParams: {
    'with_original_language': 'bn',
    'sort_by': 'popularity.desc',
  },
)

// 3. South Indian Hits
ForYouSection(
  id: 'south_hits',
  title: '🌟 South Indian Hits',
  icon: '🌟',
  tmdbParams: {
    'with_original_language': 'ta,te',
    'sort_by': 'popularity.desc',
    'vote_average.gte': 6.5,
  },
)

// 4. Hollywood Classics
ForYouSection(
  id: 'hollywood_classics',
  title: '🎥 Hollywood Classics',
  icon: '🎥',
  tmdbParams: {
    'with_original_language': 'en',
    'sort_by': 'vote_average.desc',
    'vote_count.gte': 5000,
  },
)
```

MOOD SECTIONS:
```dart
// 5. Love Stories
ForYouSection(
  id: 'love_stories',
  title: '💕 Love Stories',
  icon: '💕',
  tmdbParams: {
    'with_genres': '10749', // Romance genre
    'sort_by': 'vote_average.desc',
    'vote_average.gte': 7.0,
  },
)

// 6. Family Watch
ForYouSection(
  id: 'family_watch',
  title: '👨‍👩‍👧 Family Watch',
  icon: '👨‍👩‍👧',
  tmdbParams: {
    'with_genres': '10751', // Family genre
    'sort_by': 'popularity.desc',
  },
)

// 7. Mass Entertainers
ForYouSection(
  id: 'mass_entertainers',
  title: '🔥 Mass Entertainers',
  icon: '🔥',
  tmdbParams: {
    'with_genres': '28,12', // Action + Adventure
    'with_original_language': 'hi,ta,te',
    'sort_by': 'revenue.desc',
  },
)
```

ERA SECTIONS:
```dart
// 8. 90s Nostalgia
ForYouSection(
  id: '90s_nostalgia',
  title: '🕰️ 90s Nostalgia',
  icon: '🕰️',
  tmdbParams: {
    'primary_release_date.gte': '1990-01-01',
    'primary_release_date.lte': '1999-12-31',
    'sort_by': 'vote_average.desc',
    'vote_count.gte': 1000,
  },
)

// 9. 2000s Classics
ForYouSection(
  id: '2000s_classics',
  title: '💎 2000s Classics',
  icon: '💎',
  tmdbParams: {
    'primary_release_date.gte': '2000-01-01',
    'primary_release_date.lte': '2009-12-31',
    'sort_by': 'vote_average.desc',
    'vote_count.gte': 1000,
  },
)

// 10. New Releases 2025
ForYouSection(
  id: 'new_2025',
  title: '🚀 New in 2025',
  icon: '🚀',
  tmdbParams: {
    'primary_release_date.gte': '2025-01-01',
    'sort_by': 'popularity.desc',
  },
)

// 11. Award Winners
ForYouSection(
  id: 'award_winners',
  title: '🏆 Award Winners',
  icon: '🏆',
  tmdbParams: {
    'sort_by': 'vote_average.desc',
    'vote_count.gte': 10000,
    'vote_average.gte': 8.0,
  },
)
```

STAR SECTIONS:
```dart
// 12. Shah Rukh Khan
ForYouSection(
  id: 'srk_movies',
  title: '👑 Shah Rukh Khan',
  icon: '👑',
  tmdbParams: {
    'with_cast': '35742', // SRK TMDB ID
    'sort_by': 'popularity.desc',
  },
)

// 13. Salman Khan
ForYouSection(
  id: 'salman_movies',
  title: '💪 Salman Khan',
  icon: '💪',
  tmdbParams: {
    'with_cast': '99751', // Salman TMDB ID
    'sort_by': 'popularity.desc',
  },
)

// 14. Prabhas
ForYouSection(
  id: 'prabhas_movies',
  title: '⚡ Prabhas Movies',
  icon: '⚡',
  tmdbParams: {
    'with_cast': '1372346', // Prabhas TMDB ID
    'sort_by': 'popularity.desc',
  },
)

// 15. Aamir Khan
ForYouSection(
  id: 'aamir_movies',
  title: '🎭 Aamir Khan',
  icon: '🎭',
  tmdbParams: {
    'with_cast': '31263', // Aamir TMDB ID
    'sort_by': 'vote_average.desc',
  },
)
```

═══════════════════════════════════
COMPLETE FOR YOU SECTIONS ORDER:
═══════════════════════════════════

Final order of ALL sections:

1.  🔥 Trending Now (existing)
2.  🚀 New in 2025 (NEW)
3.  ⭐ Because you liked... (existing - personalized)
4.  🎬 Hindi Blockbusters (NEW)
5.  🎭 Bengali Cinema (NEW)
6.  🌟 South Indian Hits (NEW)
7.  🎥 Hollywood Classics (NEW)
8.  🏆 Top Action (existing)
9.  🎭 Drama Masterpieces (existing)
10. 💕 Love Stories (NEW)
11. 👨‍👩‍👧 Family Watch (NEW)
12. 🔥 Mass Entertainers (NEW)
13. 💎 Hidden Gems (existing)
14. 🧬 Science Fiction (existing)
15. 😂 Comedy Picks (existing)
16. 🕵️ Thrilling Suspense (existing)
17. 👻 Horror Nights (existing)
18. ❤️ Romance (existing)
19. 🧙 Fantasy Worlds (existing)
20. 🕰️ 90s Nostalgia (NEW)
21. 💎 2000s Classics (NEW)
22. 🏆 Award Winners (NEW)
23. 👑 Shah Rukh Khan (NEW)
24. 💪 Salman Khan (NEW)
25. ⚡ Prabhas Movies (NEW)
26. 🎭 Aamir Khan (NEW)

═══════════════════════════════════
TESTING CHECKLIST:
═══════════════════════════════════

Section Tap Fix:
[ ] Tap "Trending Now" → Opens full movie list
[ ] Tap ">" arrow → Same as header tap
[ ] Back button returns to For You
[ ] All existing sections work
[ ] Grid shows 2 columns
[ ] Movies clickable in section detail

New Sections:
[ ] Hindi Blockbusters shows Hindi movies
[ ] Bengali Cinema shows Bengali movies
[ ] South Indian shows Tamil/Telugu
[ ] Hollywood shows English movies
[ ] Love Stories shows romance genre
[ ] Family Watch shows family genre
[ ] 90s shows 1990-1999 movies
[ ] 2000s shows 2000-2009 movies
[ ] New 2025 shows current year
[ ] Award Winners shows 8.0+ rated
[ ] SRK section shows his movies
[ ] Salman section shows his movies
[ ] Prabhas section works
[ ] Aamir section works

PRIORITY:
- Task 1 (Fix tap): CRITICAL - Fix first
- Task 2 (New sections): HIGH - Add after fix

Thank you!