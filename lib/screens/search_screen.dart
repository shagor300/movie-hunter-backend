import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../services/tmdb_service.dart';
import '../services/api_service.dart';
import '../models/movie.dart';
import '../controllers/theme_controller.dart';
import '../utils/stitch_design_system.dart';
import '../widgets/movie_card.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';
import 'details_screen.dart';
import 'settings_screen.dart';
import 'voice_search/voice_search_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
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
    'Action',
    'Comedy',
    'Sci-Fi',
    '2023',
    '2024',
    'Top Rated',
  ];
  String _activeQuickFilter = 'All';

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

    final ApiService apiService = ApiService();
    final rawResults = await apiService.searchMovies(query);

    List<Movie> movies = rawResults.map((m) => Movie.fromJson(m)).toList();
    movies = _applyFilters(movies);

    setState(() {
      _searchResults = movies;
      _isLoading = false;
    });
  }

  bool get _hasActiveFilters =>
      _selectedGenres.isNotEmpty ||
      _selectedYear != null ||
      _minRating > 0 ||
      _selectedLanguage != null;

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

  void _onQuickFilter(String filter) {
    setState(() => _activeQuickFilter = filter);

    if (filter == 'All') {
      _selectedGenres = [];
      _selectedYear = null;
      _minRating = 0;
    } else if (filter == 'Top Rated') {
      _selectedGenres = [];
      _selectedYear = null;
      _minRating = 7;
    } else if (filter == '2023' || filter == '2024') {
      _selectedGenres = [];
      _selectedYear = filter;
      _minRating = 0;
    } else {
      _selectedGenres = [filter];
      _selectedYear = null;
      _minRating = 0;
    }

    if (_searchController.text.isNotEmpty) {
      _onSearch(_searchController.text);
    } else {
      _fetchTrending();
    }
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
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            bottom: 8,
          ),
          decoration: BoxDecoration(
            color: StitchColors.glassHeader,
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // Search bar row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: StitchColors.slateChip.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: StitchColors.slateChipBorder.withValues(
                            alpha: 0.5,
                          ),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: StitchText.body(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search movies, actors, directors...',
                          hintStyle: StitchText.body(
                            fontSize: 14,
                            color: StitchColors.textTertiary,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: StitchColors.emerald,
                            size: 22,
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Voice search
                              IconButton(
                                icon: const Icon(
                                  Icons.mic_rounded,
                                  color: StitchColors.emerald,
                                  size: 20,
                                ),
                                onPressed: () {
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
                              if (_searchController.text.isNotEmpty)
                                IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: StitchColors.textTertiary,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    _fetchTrending();
                                  },
                                ),
                            ],
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 13,
                          ),
                        ),
                        onSubmitted: _onSearch,
                        onTap: () {
                          if (_searchController.text.isEmpty &&
                              _recentSearches.isNotEmpty) {
                            setState(() => _showRecent = true);
                          }
                        },
                        onChanged: (value) {
                          if (value.isEmpty && _recentSearches.isNotEmpty) {
                            setState(() => _showRecent = true);
                          } else {
                            setState(() => _showRecent = false);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Filter button
                  GestureDetector(
                    onTap: _showFilterSheet,
                    child: Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: StitchColors.emerald.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          const Icon(
                            Icons.tune,
                            color: StitchColors.emerald,
                            size: 22,
                          ),
                          if (_hasActiveFilters)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: StitchColors.redDanger,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Settings
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.settings_outlined,
                        color: StitchColors.textSecondary,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Quick filter chips
              SizedBox(
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
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isActive
                              ? StitchColors.emerald
                              : StitchColors.slateChip,
                          borderRadius: BorderRadius.circular(9999),
                          border: isActive
                              ? null
                              : Border.all(
                                  color: StitchColors.slateChipBorder,
                                  width: 1,
                                ),
                        ),
                        child: Text(
                          filter,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isActive
                                ? Colors.white
                                : StitchColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsGrid() {
    return Expanded(
      child: RefreshIndicator(
        onRefresh: _fetchTrending,
        color: StitchColors.emerald,
        backgroundColor: StitchColors.bgDark,
        child: Obx(() {
          final tc = Get.find<ThemeController>();
          final prefs = tc.preferences.value;
          if (prefs.useGridLayout) {
            return _buildStitchGrid();
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            itemCount: _searchResults.length,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            itemBuilder: (context, index) {
              final movie = _searchResults[index];
              return MovieCard(
                movie: movie,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailsScreen(movie: movie),
                    ),
                  );
                },
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildStitchGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.58,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
      ),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final movie = _searchResults[index];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailsScreen(movie: movie)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: movie.fullPosterPath,
                          fit: BoxFit.cover,
                          memCacheWidth: 300,
                          placeholder: (_, _) => Shimmer.fromColors(
                            baseColor: StitchColors.slateChip,
                            highlightColor: StitchColors.slateChipBorder,
                            child: Container(color: StitchColors.slateChip),
                          ),
                          errorWidget: (_, _, _) => Container(
                            color: StitchColors.slateChip,
                            child: const Icon(
                              Icons.movie_outlined,
                              color: StitchColors.textTertiary,
                              size: 40,
                            ),
                          ),
                        ),
                        // Quality badge
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              'HD',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        // Rating badge
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: RatingBadge(rating: movie.rating),
                        ),
                        // Bottom gradient
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: StitchGradients.posterFade,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Title
              Text(
                movie.title,
                style: StitchText.movieTitle(fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Subtitle
              Text(
                '${movie.year} • ${movie.rating.toStringAsFixed(1)} ⭐',
                style: StitchText.caption(fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentSearches() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('RECENT SEARCHES', style: StitchText.sectionLabel()),
                GestureDetector(
                  onTap: _clearRecentSearches,
                  child: Text(
                    'Clear All',
                    style: StitchText.caption(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: StitchColors.emerald,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Recent search tags (Stitch style)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.take(6).map((search) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = search;
                    _onSearch(search);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: StitchColors.slateChip.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: StitchColors.slateChipBorder.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history,
                          size: 14,
                          color: StitchColors.textTertiary,
                        ),
                        const SizedBox(width: 6),
                        Text(search, style: StitchText.caption(fontSize: 12)),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            setState(() => _recentSearches.remove(search));
                          },
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: StitchColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
