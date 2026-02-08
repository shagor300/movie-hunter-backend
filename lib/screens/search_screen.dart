import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/tmdb_service.dart';
import '../services/api_service.dart';
import '../models/movie.dart';
import '../widgets/movie_card.dart';
import 'details_screen.dart';
import 'watchlist_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchTrending();
  }

  Future<void> _fetchTrending() async {
    setState(() => _isLoading = true);
    final results = await _tmdbService.getTrendingMovies();
    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  Future<void> _onSearch(String query) async {
    if (query.isEmpty) {
      _fetchTrending();
      return;
    }
    setState(() => _isLoading = true);

    final ApiService apiService = ApiService();
    final rawResults = await apiService.searchMovies(query);

    setState(() {
      _searchResults = rawResults.map((m) => Movie.fromJson(m)).toList();
      _isLoading = false;
    });
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
          IconButton(
            icon: const Icon(
              Icons.bookmarks_outlined,
              color: Colors.blueAccent,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WatchlistScreen(),
                ),
              );
            },
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
                color: Colors.blueAccent.withOpacity(0.15),
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
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
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
                      ),
                    ),
                  ),
                ),
              ),
              if (_isLoading)
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
}
