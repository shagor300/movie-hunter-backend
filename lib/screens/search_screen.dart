import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tmdb_service.dart';
import '../services/api_service.dart';
import '../models/movie.dart';
import '../widgets/movie_card.dart';
import '../widgets/filter_sheet.dart';
import 'details_screen.dart';

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
      _searchResults = results;
      _isLoading = false;
      _showRecent = false;
    });
  }

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

    // Apply client-side filters
    if (_minRating > 0) {
      movies = movies.where((m) => m.rating >= _minRating).toList();
    }
    if (_selectedYear != null) {
      movies = movies.where((m) => m.year == _selectedYear).toList();
    }

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
              }
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'MOVIEHUNTER',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          // Filter button
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.tune, color: Colors.blueAccent),
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
                color: Colors.blueAccent.withValues(alpha: 0.15),
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
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1.5,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.inter(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search movies, sources...',
                          hintStyle: GoogleFonts.inter(color: Colors.white38),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.blueAccent,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.white30,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _fetchTrending();
                            },
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
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    itemCount: _searchResults.length,
                    physics: const BouncingScrollPhysics(),
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
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
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                ),
                backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
                deleteIconColor: Colors.white54,
                side: BorderSide(color: Colors.blueAccent.withValues(alpha: 0.3)),
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
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                ),
                backgroundColor: Colors.purpleAccent.withValues(alpha: 0.2),
                deleteIconColor: Colors.white54,
                side: BorderSide(color: Colors.purpleAccent.withValues(alpha: 0.3)),
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
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                ),
                backgroundColor: Colors.amber.withValues(alpha: 0.2),
                deleteIconColor: Colors.white54,
                side: BorderSide(color: Colors.amber.withValues(alpha: 0.3)),
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
                style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
              ),
              backgroundColor: Colors.greenAccent.withValues(alpha: 0.2),
              deleteIconColor: Colors.white54,
              side: BorderSide(color: Colors.greenAccent.withValues(alpha: 0.3)),
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
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: _clearRecentSearches,
                  child: Text(
                    'Clear',
                    style: GoogleFonts.inter(
                      color: Colors.blueAccent,
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
                    leading: const Icon(Icons.history, color: Colors.white24),
                    title: Text(
                      search,
                      style: GoogleFonts.inter(color: Colors.white70),
                    ),
                    trailing: const Icon(
                      Icons.north_west,
                      color: Colors.white12,
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
