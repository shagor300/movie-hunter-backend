import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/movie.dart';
import '../models/watchlist_movie.dart';
import '../services/recommendation_service.dart';
import '../services/tmdb_service.dart';
import '../controllers/watchlist_controller.dart';
import '../widgets/continue_watching_section.dart';
import 'details_screen.dart';
import 'customization_screen.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final RecommendationService _recService = RecommendationService();
  final TmdbService _tmdbService = TmdbService();

  List<_RecommendationSection> _sections = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final sections = <_RecommendationSection>[];

    // Trending Now — always first
    try {
      final trending = await _tmdbService.getTrendingMovies();
      if (trending.isNotEmpty) {
        sections.add(
          _RecommendationSection(
            title: '🔥 Trending Now',
            movies: trending.take(15).toList(),
          ),
        );
      }
    } catch (_) {}

    // Personalized "Because You Watched" from watchlist completed/favorites
    try {
      final watchlistController = Get.find<WatchlistController>();
      final completed = watchlistController.getByCategory(
        WatchlistCategory.completed,
      );
      final favorites = watchlistController.favorites;

      // Build unique list of movies to base recommendations on
      final baseTmdbIds = <int>{};
      for (final m in [...favorites, ...completed]) {
        if (m.tmdbId > 0) baseTmdbIds.add(m.tmdbId);
      }

      // Fetch "similar" for up to 3 watchlist movies
      for (final tmdbId in baseTmdbIds.take(3)) {
        final similar = await _recService.getSimilarMovies(tmdbId);
        if (similar.isNotEmpty) {
          // Find the source movie title
          final source = [
            ...favorites,
            ...completed,
          ].firstWhereOrNull((m) => m.tmdbId == tmdbId);
          final title = source != null
              ? '✨ Because you liked "${source.title}"'
              : '✨ Recommended For You';
          sections.add(_RecommendationSection(title: title, movies: similar));
        }
      }
    } catch (_) {}

    // Genre sections — fetch in parallel
    final genreSections = await Future.wait([
      _fetchGenreSection('💥 Top Action', 28),
      _fetchGenreSection('🎭 Drama Masterpieces', 18),
      _fetchGenreSection('💎 Hidden Gems', null, hiddenGems: true),
      _fetchGenreSection('🚀 Science Fiction', 878),
      _fetchGenreSection('😂 Comedy Picks', 35),
      _fetchGenreSection('🔪 Thrilling Suspense', 53),
      _fetchGenreSection('😱 Horror Nights', 27),
      _fetchGenreSection('💕 Romance', 10749),
      _fetchGenreSection('🏰 Fantasy Worlds', 14),
    ]);

    for (final section in genreSections) {
      if (section != null) sections.add(section);
    }

    setState(() {
      _sections = sections;
      _isLoading = false;
      _hasError = sections.isEmpty;
    });
  }

  Future<_RecommendationSection?> _fetchGenreSection(
    String title,
    int? genreId, {
    bool hiddenGems = false,
  }) async {
    try {
      final movies = hiddenGems
          ? await _recService.getHiddenGems()
          : await _recService.discoverByGenre(genreId!);
      if (movies.isNotEmpty) {
        return _RecommendationSection(title: title, movies: movies);
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'For You',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 22),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Customization',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CustomizationScreen()),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoading()
          : _sections.isEmpty
          ? RefreshIndicator(
              onRefresh: _loadRecommendations,
              color: Colors.blueAccent,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  _buildEmpty(),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadRecommendations,
              color: Colors.blueAccent,
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 20),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                // +1 for Continue Watching section at top
                itemCount: _sections.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const ContinueWatchingSection();
                  }
                  return _buildSection(_sections[index - 1]);
                },
              ),
            ),
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.white10,
                highlightColor: Colors.white24,
                child: Container(
                  width: 180,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  itemBuilder: (context, i) {
                    return Shimmer.fromColors(
                      baseColor: Colors.white10,
                      highlightColor: Colors.white24,
                      child: Container(
                        width: 130,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _hasError ? Icons.wifi_off_rounded : Icons.movie_filter,
            size: 80,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Text(
            _hasError ? 'Something went wrong' : 'No recommendations yet',
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            _hasError
                ? 'Check your internet connection'
                : 'Watch some movies first!',
            style: GoogleFonts.inter(color: Colors.white24, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadRecommendations,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(_RecommendationSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Text(
            section.title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: section.movies.length,
            itemBuilder: (context, index) {
              return _buildMovieCard(section.movies[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMovieCard(Movie movie) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailsScreen(movie: movie)),
      ),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    movie.tmdbPoster.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: movie.fullPosterPath,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            memCacheWidth: 280,
                            placeholder: (_, __) => Shimmer.fromColors(
                              baseColor: const Color(0xFF1E1E3A),
                              highlightColor: const Color(0xFF2A2A4A),
                              child: Container(color: Colors.black),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey[900],
                              child: const Icon(
                                Icons.movie,
                                color: Colors.white24,
                                size: 40,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[900],
                            child: const Icon(
                              Icons.movie,
                              color: Colors.white24,
                              size: 40,
                            ),
                          ),
                    // Rating badge
                    if (movie.rating > 0)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 10,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                movie.rating.toStringAsFixed(1),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              movie.title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              movie.year,
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationSection {
  final String title;
  final List<Movie> movies;

  _RecommendationSection({required this.title, required this.movies});
}
