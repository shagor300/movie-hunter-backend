import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tmdb_service.dart';
import '../models/movie.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/movie_card.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';
import 'details_screen.dart';
import 'settings_screen.dart';
import 'voice_search/voice_search_screen.dart';
import '../widgets/premium_transitions.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TmdbService _tmdbService = TmdbService();
  List<Movie> _searchResults = [];
  bool _isLoading = false;

  // Filters
  List<String> _selectedGenres = [];
  String? _selectedYear;
  double _minRating = 0;
  String? _selectedLanguage;

  // Recent searches
  List<String> _recentSearches = [];
  bool _showRecent = false;

  // Quick filter chips
  final _quickFilters = [
    'All',
    'Movies',
    'Series',
    'Action',
    'Comedy',
    'Sci-Fi',
    'Romance',
  ];
  String _activeQuickFilter = 'All';

  /// Whether search has active text or results (for back-press handling)
  bool get hasActiveSearch => _searchController.text.isNotEmpty;

  /// Clear search and go back to trending
  void clearSearch() {
    _searchController.clear();
    _fetchTrending();
  }

  @override
  void initState() {
    super.initState();
    _fetchTrending();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> _saveRecentSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.sublist(0, 10);
    }
    await prefs.setStringList('recent_searches', _recentSearches);
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    setState(() => _recentSearches.clear());
  }

  Future<void> _fetchTrending() async {
    setState(() => _isLoading = true);
    final results = await _tmdbService.getTrendingMovies();
    setState(() {
      _searchResults = _applyFilters(results);
      _isLoading = false;
      _showRecent = false;
    });
  }

  List<Movie> _applyFilters(List<Movie> movies) {
    List<Movie> filtered = List.from(movies);

    if (_minRating > 0) {
      filtered = filtered.where((m) => m.rating >= _minRating).toList();
    }
    if (_selectedYear != null) {
      filtered = filtered.where((m) => m.year == _selectedYear).toList();
    }
    if (_selectedGenres.isNotEmpty) {
      final selectedIds = _selectedGenres
          .map((name) => _genreNameToId[name])
          .whereType<int>()
          .toSet();
      filtered = filtered
          .where((m) => m.genreIds.any((id) => selectedIds.contains(id)))
          .toList();
    }
    if (_selectedLanguage != null) {
      if (_selectedLanguage == 'Hindi') {
        filtered = filtered.where((m) => m.originalLanguage == 'hi').toList();
      } else if (_selectedLanguage == 'English') {
        filtered = filtered.where((m) => m.originalLanguage == 'en').toList();
      } else if (_selectedLanguage == 'Dual Audio') {
        filtered = filtered
            .where(
              (m) =>
                  m.title.toLowerCase().contains('dual audio') ||
                  m.originalLanguage == 'hi' ||
                  m.originalLanguage == 'en',
            )
            .toList();
      }
    }
    if (_activeQuickFilter == 'Movies') {
      filtered = filtered.where((m) => m.mediaType == 'movie').toList();
    } else if (_activeQuickFilter == 'Series') {
      filtered = filtered.where((m) => m.mediaType == 'tv').toList();
    }

    return filtered;
  }

  static const Map<String, int> _genreNameToId = {
    'Action': 28,
    'Adventure': 12,
    'Animation': 16,
    'Comedy': 35,
    'Crime': 80,
    'Documentary': 99,
    'Drama': 18,
    'Family': 10751,
    'Fantasy': 14,
    'History': 36,
    'Horror': 27,
    'Music': 10402,
    'Mystery': 9648,
    'Romance': 10749,
    'Science Fiction': 878,
    'Thriller': 53,
    'War': 10752,
    'Western': 37,
  };

  Future<void> _onSearch(String query) async {
    if (query.isEmpty) {
      _fetchTrending();
      return;
    }

    _saveRecentSearch(query);
    setState(() {
      _isLoading = true;
      _showRecent = false;
    });

    // Search TMDB directly from app — instant results, no backend needed
    final results = await _tmdbService.searchMovies(query);

    setState(() {
      _searchResults = _applyFilters(results);
      _isLoading = false;
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return FilterSheet(
            selectedGenres: _selectedGenres,
            selectedYear: _selectedYear,
            minRating: _minRating,
            selectedLanguage: _selectedLanguage,
            onApply: (genres, year, rating, language) {
              setState(() {
                _selectedGenres = genres;
                _selectedYear = year;
                _minRating = rating;
                _selectedLanguage = language;
              });
              Navigator.pop(context);
              if (_searchController.text.isNotEmpty) {
                _onSearch(_searchController.text);
              } else {
                _fetchTrending();
              }
            },
          );
        },
      ),
    );
  }

  /// Genre name → TMDB genre ID mapping for discover API
  static const Map<String, int> _quickFilterGenreId = {
    'Action': 28,
    'Comedy': 35,
    'Sci-Fi': 878,
    'Romance': 10749,
  };

  void _onQuickFilter(String filter) async {
    setState(() {
      _activeQuickFilter = filter;
      _isLoading = true;
      _showRecent = false;
    });

    List<Movie> results;

    if (filter == 'All') {
      // Trending — default
      results = await _tmdbService.getTrendingMovies();
    } else if (filter == 'Movies') {
      // Discover movies only
      results = await _tmdbService.discoverMovies();
    } else if (filter == 'Series') {
      // Discover TV shows only
      results = await _tmdbService.discoverTvShows();
    } else if (_quickFilterGenreId.containsKey(filter)) {
      // Genre-specific discover
      results = await _tmdbService.discoverByGenre(
        _quickFilterGenreId[filter]!,
      );
    } else {
      // Fallback — trending filtered locally
      results = await _tmdbService.getTrendingMovies();
    }

    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          // ── Sticky Glassmorphism Header ──
          _buildGlassHeader(isDark),

          // ── Content ──
          if (_showRecent && _recentSearches.isNotEmpty)
            _buildRecentSearches()
          else if (_isLoading)
            const Expanded(child: SkeletonGrid(itemCount: 6))
          else if (_searchResults.isEmpty)
            const Expanded(
              child: EmptyState(
                icon: Icons.search_off_rounded,
                title: 'No Results Found',
                message: 'Try different keywords or browse trending movies',
              ),
            )
          else
            _buildResultsGrid(),
        ],
      ),
    );
  }

  Widget _buildGlassHeader(bool isDark) {
    final tc = Get.find<ThemeController>();
    return Obx(() {
      final accent = tc.accentColor;
      return ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).scaffoldBackgroundColor.withValues(alpha: 0.8),
              border: const Border(
                bottom: BorderSide(color: AppColors.glassBorder, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Search bar row — clean: searchbar + settings icon
                Row(
                  children: [
                    Expanded(
                      child: CustomSearchBar(
                        controller: _searchController,
                        onChanged: (value) {
                          if (value.isEmpty && _recentSearches.isNotEmpty) {
                            setState(() => _showRecent = true);
                          } else {
                            setState(() => _showRecent = false);
                          }
                        },
                        onSubmitted: () {
                          if (_searchController.text.isNotEmpty) {
                            _onSearch(_searchController.text);
                          }
                        },
                        onFilterTap: _showFilterSheet,
                        onVoiceTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VoiceSearchScreen(
                                onSearchResult: (query) {
                                  _searchController.text = query;
                                  _onSearch(query);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Settings — small circle
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      ),
                      child: Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).cardColor.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: const Icon(
                          Icons.settings_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Quick filter chips + tag filter button
                Row(
                  children: [
                    // Quick filter genre chips
                    Expanded(
                      child: SizedBox(
                        height: 34,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _quickFilters.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final filter = _quickFilters[index];
                            final isActive = _activeQuickFilter == filter;
                            return GestureDetector(
                              onTap: () => _onQuickFilter(filter),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? accent
                                      : Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(9999),
                                  border: isActive
                                      ? null
                                      : Border.all(
                                          color: AppColors.glassBorder,
                                          width: 1,
                                        ),
                                ),
                                child: Text(
                                  filter,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    fontSize: 12,
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: isActive
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildResultsGrid() {
    final tc = Get.find<ThemeController>();
    final hasQuery = _searchController.text.isNotEmpty;

    return Expanded(
      child: RefreshIndicator(
        onRefresh: _fetchTrending,
        color: tc.accentColor,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // ── Results count header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    Icon(
                      hasQuery
                          ? Icons.search_rounded
                          : Icons.trending_up_rounded,
                      color: AppColors.textMuted,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hasQuery
                          ? '${_searchResults.length} results found'
                          : 'Trending Now',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    if (hasQuery)
                      Obx(
                        () => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: tc.accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _searchController.text,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: tc.accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // ── Grid ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
              sliver: Obx(() {
                final tc = Get.find<ThemeController>();
                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: tc.gridColumnCount,
                    childAspectRatio: 0.58,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 20,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final movie = _searchResults[index];
                    return MovieCard(
                      movie: movie,
                      onTap: () {
                        Navigator.push(
                          context,
                          PremiumPageRoute(page: DetailsScreen(movie: movie)),
                        );
                      },
                    );
                  }, childCount: _searchResults.length),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    final tc = Get.find<ThemeController>();
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 16,
                      color: tc.accentColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'RECENT SEARCHES',
                      style: AppTextStyles.labelSmall.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _clearRecentSearches,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Clear All',
                      style: AppTextStyles.labelSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.redAccent,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...List.generate(_recentSearches.take(8).length, (i) {
              final search = _recentSearches[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _searchController.text = search;
                      _onSearch(search);
                    },
                    borderRadius: BorderRadius.circular(12),
                    splashColor: tc.accentColor.withValues(alpha: 0.08),
                    highlightColor: tc.accentColor.withValues(alpha: 0.04),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.glassBorder.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).cardColor.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.history_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              search,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() => _recentSearches.remove(search));
                            },
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).cardColor.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.north_west_rounded,
                            size: 14,
                            color: AppColors.textMuted.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
