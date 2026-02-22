import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tmdb_service.dart';
import '../services/api_service.dart';
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
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 20,
            left: 20,
            right: 20,
            bottom: 20,
          ),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark.withValues(alpha: 0.8),
            border: const Border(
              bottom: BorderSide(color: AppColors.glassBorder, width: 1),
            ),
          ),
          child: Column(
            children: [
              // Search bar row
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
                      onFilterTap: _showFilterSheet,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Mic / Voice Search
                  GestureDetector(
                    onTap: () {
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
                    child: Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mic_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Settings
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    child: Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: const Icon(
                        Icons.settings_outlined,
                        color: AppColors.textSecondary,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Quick filter chips
              SizedBox(
                height: 36,
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
                              ? AppColors.primary
                              : AppColors.surfaceLight,
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
        color: AppColors.primary,
        backgroundColor: AppColors.backgroundDark,
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
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
        ),
      ),
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
                Text('RECENT SEARCHES', style: AppTextStyles.labelSmall),
                GestureDetector(
                  onTap: _clearRecentSearches,
                  child: Text(
                    'Clear All',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 12,
              children: _recentSearches.take(6).map((search) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = search;
                    _onSearch(search);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.history,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(search, style: AppTextStyles.bodyMedium),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() => _recentSearches.remove(search));
                          },
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: AppColors.textMuted,
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
