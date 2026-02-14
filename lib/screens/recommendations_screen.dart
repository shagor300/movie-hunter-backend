import 'dart:math';
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
import 'settings_screen.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen>
    with TickerProviderStateMixin {
  final RecommendationService _recService = RecommendationService();
  final TmdbService _tmdbService = TmdbService();

  List<_RecommendationSection> _sections = [];
  bool _isLoading = true;
  bool _hasError = false;
  Movie? _featuredMovie;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadRecommendations();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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
        // Pick a random trending movie as featured hero
        _featuredMovie = trending[Random().nextInt(min(trending.length, 5))];
        sections.add(
          _RecommendationSection(
            title: '🔥 Trending Now',
            movies: trending.take(15).toList(),
            icon: Icons.local_fire_department,
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

      final baseTmdbIds = <int>{};
      for (final m in [...favorites, ...completed]) {
        if (m.tmdbId > 0) baseTmdbIds.add(m.tmdbId);
      }

      for (final tmdbId in baseTmdbIds.take(3)) {
        final similar = await _recService.getSimilarMovies(tmdbId);
        if (similar.isNotEmpty) {
          final source = [
            ...favorites,
            ...completed,
          ].firstWhereOrNull((m) => m.tmdbId == tmdbId);
          final title = source != null
              ? 'Because you liked "${source.title}"'
              : 'Recommended For You';
          sections.add(
            _RecommendationSection(
              title: title,
              movies: similar,
              icon: Icons.auto_awesome,
            ),
          );
        }
      }
    } catch (_) {}

    // Genre sections — fetch in parallel
    final genreSections = await Future.wait([
      _fetchGenreSection('Top Action', 28, Icons.sports_mma),
      _fetchGenreSection('Drama Masterpieces', 18, Icons.theater_comedy),
      _fetchGenreSection(
        'Hidden Gems',
        null,
        Icons.diamond_outlined,
        hiddenGems: true,
      ),
      _fetchGenreSection('Science Fiction', 878, Icons.rocket_launch),
      _fetchGenreSection('Comedy Picks', 35, Icons.sentiment_very_satisfied),
      _fetchGenreSection('Thrilling Suspense', 53, Icons.psychology),
      _fetchGenreSection('Horror Nights', 27, Icons.nights_stay),
      _fetchGenreSection('Romance', 10749, Icons.favorite),
      _fetchGenreSection('Fantasy Worlds', 14, Icons.castle),
    ]);

    for (final section in genreSections) {
      if (section != null) sections.add(section);
    }

    setState(() {
      _sections = sections;
      _isLoading = false;
      _hasError = sections.isEmpty;
    });

    _fadeController.forward();
  }

  Future<_RecommendationSection?> _fetchGenreSection(
    String title,
    int? genreId,
    IconData icon, {
    bool hiddenGems = false,
  }) async {
    try {
      final movies = hiddenGems
          ? await _recService.getHiddenGems()
          : await _recService.discoverByGenre(genreId!);
      if (movies.isNotEmpty) {
        return _RecommendationSection(title: title, movies: movies, icon: icon);
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: _isLoading
          ? _buildLoading(colorScheme)
          : _sections.isEmpty
          ? RefreshIndicator(
              onRefresh: _loadRecommendations,
              color: colorScheme.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  _buildEmpty(colorScheme),
                ],
              ),
            )
          : FadeTransition(
              opacity: _fadeAnim,
              child: RefreshIndicator(
                onRefresh: _loadRecommendations,
                color: colorScheme.primary,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    // Hero banner + AppBar
                    _buildHeroSliver(colorScheme),

                    // Continue Watching
                    const SliverToBoxAdapter(child: ContinueWatchingSection()),

                    // Movie sections
                    ..._sections.map(
                      (s) => SliverToBoxAdapter(
                        child: _buildSection(s, colorScheme),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Hero Banner with SliverAppBar ──────────────────────────────────────

  Widget _buildHeroSliver(ColorScheme colorScheme) {
    if (_featuredMovie == null) {
      return SliverAppBar(
        floating: true,
        snap: true,
        backgroundColor: colorScheme.surface,
        title: Text(
          'For You',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 22),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      );
    }

    final movie = _featuredMovie!;

    return SliverAppBar(
      expandedHeight: 380,
      floating: false,
      pinned: true,
      backgroundColor: colorScheme.surface,
      title: Text(
        'For You',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 22),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailsScreen(movie: movie)),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Backdrop image
              if (movie.tmdbPoster.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: movie.fullPosterPath.replaceFirst(
                    '/w500/',
                    '/w780/',
                  ),
                  fit: BoxFit.cover,
                  memCacheWidth: 780,
                  placeholder: (_, __) => Container(color: colorScheme.surface),
                  errorWidget: (_, __, ___) =>
                      Container(color: colorScheme.surface),
                ),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.surface.withOpacity(0.3),
                      colorScheme.surface.withOpacity(0.1),
                      colorScheme.surface.withOpacity(0.7),
                      colorScheme.surface,
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
              ),

              // Movie info overlay
              Positioned(
                bottom: 48,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // "FEATURED" badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'FEATURED',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Title
                    Text(
                      movie.title,
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Meta row
                    Row(
                      children: [
                        if (movie.rating > 0) ...[
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            movie.rating.toStringAsFixed(1),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        if (movie.year.isNotEmpty) ...[
                          Icon(
                            Icons.calendar_today,
                            color: Colors.white60,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            movie.year,
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailsScreen(movie: movie),
                              ),
                            ),
                            icon: const Icon(Icons.play_arrow, size: 20),
                            label: Text(
                              'Watch Now',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.info_outline,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailsScreen(movie: movie),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Loading Shimmer ────────────────────────────────────────────────────

  Widget _buildLoading(ColorScheme colorScheme) {
    return SafeArea(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (context, index) {
          if (index == 0) {
            // Hero shimmer
            return Shimmer.fromColors(
              baseColor: colorScheme.surface,
              highlightColor: colorScheme.onSurface.withOpacity(0.05),
              child: Container(
                height: 280,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: colorScheme.surface,
                  highlightColor: colorScheme.onSurface.withOpacity(0.05),
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
                        baseColor: colorScheme.surface,
                        highlightColor: colorScheme.onSurface.withOpacity(0.05),
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
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────

  Widget _buildEmpty(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withOpacity(0.1),
            ),
            child: Icon(
              _hasError ? Icons.wifi_off_rounded : Icons.movie_filter,
              size: 56,
              color: colorScheme.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _hasError ? 'Something went wrong' : 'No recommendations yet',
            style: GoogleFonts.poppins(
              color: colorScheme.onSurface.withOpacity(0.7),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _hasError
                ? 'Check your internet connection'
                : 'Watch some movies first!',
            style: GoogleFonts.inter(
              color: colorScheme.onSurface.withOpacity(0.4),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadRecommendations,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(
              'Try Again',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section ────────────────────────────────────────────────────────────

  Widget _buildSection(
    _RecommendationSection section,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(section.icon, color: colorScheme.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  section.title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: colorScheme.onSurface.withOpacity(0.3),
                size: 14,
              ),
            ],
          ),
        ),
        // Horizontal movie list
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: section.movies.length,
            itemBuilder: (context, index) {
              return _buildMovieCard(section.movies[index], colorScheme);
            },
          ),
        ),
      ],
    );
  }

  // ── Movie Card ─────────────────────────────────────────────────────────

  Widget _buildMovieCard(Movie movie, ColorScheme colorScheme) {
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
                              baseColor: colorScheme.surface,
                              highlightColor: colorScheme.onSurface.withOpacity(
                                0.05,
                              ),
                              child: Container(color: colorScheme.surface),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.movie,
                                color: colorScheme.onSurface.withOpacity(0.2),
                                size: 40,
                              ),
                            ),
                          )
                        : Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.movie,
                              color: colorScheme.onSurface.withOpacity(0.2),
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
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 12,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                movie.rating.toStringAsFixed(1),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
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
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              movie.year,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: colorScheme.onSurface.withOpacity(0.4),
              ),
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
  final IconData icon;

  _RecommendationSection({
    required this.title,
    required this.movies,
    this.icon = Icons.movie_filter,
  });
}
