import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tmdb_service.dart';
import '../services/api_service.dart';
import '../models/movie.dart';
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

  /// Apply all active filters to a list of movies.
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

  // TMDB genre name → ID mapping for client-side filtering
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'MOVIEHUNTER',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          // Filter button
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.tune, color: colorScheme.primary),
                onPressed: _showFilterSheet,
              ),
              if (_hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          // Settings button
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: isDark ? Colors.white54 : Colors.black38,
            ),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withOpacity(0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: const SizedBox.shrink(),
              ),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 100),
              // Glassmorphism Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colorScheme.onSurface.withOpacity(0.1),
                          width: 1.5,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.inter(color: colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Search movies, sources...',
                          hintStyle: GoogleFonts.inter(
                            color: colorScheme.onSurface.withOpacity(0.38),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: colorScheme.primary,
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Voice search mic button
                              IconButton(
                                icon: Icon(
                                  Icons.mic,
                                  color: colorScheme.primary,
                                ),
                                tooltip: 'Voice Search',
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
                              // Clear button (only when text is present)
                              if (_searchController.text.isNotEmpty)
                                IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.3,
                                    ),
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
                            vertical: 15,
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
                ),
              ),

              // Active filter chips
              if (_hasActiveFilters) _buildActiveFilters(),

              // Content
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
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchTrending,
                    color: colorScheme.primary,
                    backgroundColor: colorScheme.surface,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
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
                                builder: (context) =>
                                    DetailsScreen(movie: movie),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ..._selectedGenres.map(
            (genre) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(
                  genre,
                  style: GoogleFonts.inter(
                    color: colorScheme.onSurface,
                    fontSize: 12,
                  ),
                ),
                backgroundColor: colorScheme.primary.withOpacity(0.2),
                deleteIconColor: colorScheme.onSurface.withOpacity(0.54),
                side: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
                onDeleted: () {
                  setState(() => _selectedGenres.remove(genre));
                  if (_searchController.text.isNotEmpty) {
                    _onSearch(_searchController.text);
                  }
                },
              ),
            ),
          ),
          if (_selectedYear != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(
                  _selectedYear!,
                  style: GoogleFonts.inter(
                    color: colorScheme.onSurface,
                    fontSize: 12,
                  ),
                ),
                backgroundColor: Colors.purpleAccent.withOpacity(0.2),
                deleteIconColor: colorScheme.onSurface.withOpacity(0.54),
                side: BorderSide(color: Colors.purpleAccent.withOpacity(0.3)),
                onDeleted: () {
                  setState(() => _selectedYear = null);
                  if (_searchController.text.isNotEmpty) {
                    _onSearch(_searchController.text);
                  }
                },
              ),
            ),
          if (_minRating > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(
                  '${_minRating.toInt()}+ ⭐',
                  style: GoogleFonts.inter(
                    color: colorScheme.onSurface,
                    fontSize: 12,
                  ),
                ),
                backgroundColor: Colors.amber.withOpacity(0.2),
                deleteIconColor: colorScheme.onSurface.withOpacity(0.54),
                side: BorderSide(color: Colors.amber.withOpacity(0.3)),
                onDeleted: () {
                  setState(() => _minRating = 0);
                  if (_searchController.text.isNotEmpty) {
                    _onSearch(_searchController.text);
                  }
                },
              ),
            ),
          if (_selectedLanguage != null)
            Chip(
              label: Text(
                _selectedLanguage!,
                style: GoogleFonts.inter(
                  color: colorScheme.onSurface,
                  fontSize: 12,
                ),
              ),
              backgroundColor: Colors.greenAccent.withOpacity(0.2),
              deleteIconColor: colorScheme.onSurface.withOpacity(0.54),
              side: BorderSide(color: Colors.greenAccent.withOpacity(0.3)),
              onDeleted: () {
                setState(() => _selectedLanguage = null);
                if (_searchController.text.isNotEmpty) {
                  _onSearch(_searchController.text);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Searches',
                  style: GoogleFonts.poppins(
                    color: colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: _clearRecentSearches,
                  child: Text(
                    'Clear',
                    style: GoogleFonts.inter(
                      color: colorScheme.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _recentSearches.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final search = _recentSearches[index];
                  return ListTile(
                    leading: Icon(
                      Icons.history,
                      color: colorScheme.onSurface.withOpacity(0.24),
                    ),
                    title: Text(
                      search,
                      style: GoogleFonts.inter(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    trailing: Icon(
                      Icons.north_west,
                      color: colorScheme.onSurface.withOpacity(0.12),
                      size: 16,
                    ),
                    onTap: () {
                      _searchController.text = search;
                      _onSearch(search);
                    },
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
