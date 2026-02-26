import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/movie.dart';
import '../controllers/link_controller.dart';
import '../controllers/watchlist_controller.dart';
import '../controllers/download_controller.dart';
import '../services/api_service.dart';
import '../services/trailer_service.dart';
import '../services/watch_history_service.dart';
import '../services/user_rating_service.dart';
import '../services/movie_collection_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_controller.dart';
import '../widgets/shareable_movie_card.dart';
import '../widgets/star_rating_widget.dart';
import 'webview_player.dart';
import 'video_player_screen.dart';
import 'trailer_player_screen.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DetailsScreen extends StatefulWidget {
  final Movie movie;
  const DetailsScreen({super.key, required this.movie});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final LinkController _linkController = Get.put(LinkController());
  final WatchlistController _watchlistController =
      Get.find<WatchlistController>();
  final DownloadController _downloadController = Get.find<DownloadController>();

  // Trailer state
  String? _trailerKey;
  bool _trailerLoading = true;

  // Similar movies state
  List<Movie> _similarMovies = [];
  bool _similarLoading = true;

  // User rating state
  double? _userRating;
  bool _showBookmarkHeart = false;

  @override
  void initState() {
    super.initState();
    // Clear old links so a new movie starts fresh
    _linkController.clearData();
    // Fetch trailer
    _loadTrailer();
    // Record view in watch history
    _recordView();
    // Load user rating
    _loadUserRating();
  }

  void _recordView() {
    final m = widget.movie;
    WatchHistoryService.recordView(
      tmdbId: m.tmdbId ?? 0,
      title: m.title,
      posterUrl: m.fullPosterPath,
      rating: m.rating,
    );
  }

  Future<void> _loadUserRating() async {
    if (widget.movie.tmdbId == null) return;
    final rating = await UserRatingService.getRating(widget.movie.tmdbId!);
    if (mounted) setState(() => _userRating = rating);
  }

  Future<void> _loadTrailer() async {
    final tmdbId = widget.movie.tmdbId;
    if (tmdbId == null || tmdbId <= 0) {
      setState(() => _trailerLoading = false);
      return;
    }
    final key = await TrailerService.getTrailerKey(tmdbId);
    if (mounted) {
      setState(() {
        _trailerKey = key;
        _trailerLoading = false;
      });
    }
    // Also load similar movies
    _loadSimilarMovies(tmdbId);
  }

  Future<void> _loadSimilarMovies(int tmdbId) async {
    try {
      final results = await TrailerService.getSimilarMovies(tmdbId);
      if (mounted) {
        setState(() {
          _similarMovies = results
              .where((m) => m['poster_path'] != null)
              .take(15)
              .map((m) => Movie.fromJson(m))
              .toList();
          _similarLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _similarLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDarker,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Premium Header with Background Image
              SliverAppBar(
                expandedHeight: 450,
                pinned: true,
                stretch: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                actions: [
                  // Favorite toggle
                  Obx(() {
                    final isIn = _watchlistController.isInWatchlist(
                      widget.movie.tmdbId,
                    );
                    final isFav = _watchlistController.isFavorite(
                      widget.movie.tmdbId,
                    );
                    return Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? Colors.redAccent : Colors.white,
                              size: 22,
                            ),
                            tooltip: isFav
                                ? 'Remove from Favorites'
                                : 'Add to Favorites',
                            onPressed: () {
                              // ONLY toggle favorite — completely independent
                              _watchlistController.toggleFavoriteIndependent(
                                widget.movie,
                              );
                            },
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              isIn ? Icons.bookmark : Icons.bookmark_border,
                              color: isIn ? Colors.amber : Colors.white,
                              size: 22,
                            ),
                            tooltip: isIn
                                ? 'Remove from Watchlist'
                                : 'Add to Watchlist',
                            onPressed: () => _watchlistController
                                .toggleWatchlist(widget.movie),
                          ),
                        ),
                      ],
                    );
                  }),
                  // Share button
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.share_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                      tooltip: 'Share',
                      onPressed: () => _shareMovieCard(),
                    ),
                  ),
                  // Add to collection button
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.playlist_add,
                        color: Colors.white,
                        size: 22,
                      ),
                      tooltip: 'Add to Collection',
                      onPressed: _showAddToCollectionDialog,
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      GestureDetector(
                        onDoubleTap: _onDoubleTapBookmark,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Hero(
                              tag: 'poster-${widget.movie.title}',
                              child: CachedNetworkImage(
                                imageUrl: widget.movie.fullPosterPath,
                                fit: BoxFit.cover,
                              ),
                            ),
                            // Gradient Overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    AppColors.backgroundDarker.withValues(
                                      alpha: 0.5,
                                    ),
                                    AppColors.backgroundDarker,
                                  ],
                                ),
                              ),
                            ),
                            // Double-tap heart animation
                            if (_showBookmarkHeart)
                              Center(
                                child: AnimatedOpacity(
                                  opacity: _showBookmarkHeart ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 300),
                                  child: Icon(
                                    _watchlistController.isInWatchlist(
                                          widget.movie.tmdbId,
                                        )
                                        ? Icons.bookmark
                                        : Icons.bookmark_remove,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    size: 80,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Metadata
                      Text(
                        widget.movie.title,
                        style: AppTextStyles.displayMedium.copyWith(
                          fontSize: 28,
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          _buildChip(
                            widget.movie.year,
                            Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          _buildChip("HD 4K", AppColors.primaryDark),
                          const SizedBox(width: 8),
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            widget.movie.rating.toStringAsFixed(1),
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Trailer Button
                      _buildTrailerButton(),
                      const SizedBox(height: 16),
                      // Glass Button for Links
                      _buildGetLinksButton(),
                      const SizedBox(height: 30),
                      // Storyline Section
                      Text(
                        "Storyline",
                        style: AppTextStyles.headingLarge.copyWith(
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.movie.plot,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Links List Container
                      Obx(() {
                        if (_linkController.links.isNotEmpty) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Available Links",
                                style: AppTextStyles.headingLarge.copyWith(
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // --- Embed/Streaming Links ---
                              if (_linkController.embedLinks.isNotEmpty) ...[
                                Row(
                                  children: [
                                    Icon(
                                      Icons.play_circle_fill,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Stream Online',
                                      style: AppTextStyles.titleMedium.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ..._linkController.embedLinks
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                      return _buildEmbedLinkItem(
                                        entry.value,
                                        entry.key,
                                      );
                                    }),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.cloud_download,
                                      color: AppColors.primaryDark,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Download',
                                      style: AppTextStyles.titleMedium.copyWith(
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                              ],
                              // --- Download Links ---
                              ..._linkController.links.asMap().entries.map((
                                entry,
                              ) {
                                return _buildLinkItem(entry.value, entry.key);
                              }),
                            ],
                          );
                        }
                        return const SizedBox();
                      }),
                      // User Rating Section
                      _buildUserRating(),
                      // Similar Movies Section
                      _buildSimilarMovies(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Loading & Error Overlay
          Obx(() {
            if (_linkController.isLoading.value ||
                _linkController.hasError.value) {
              return _buildLoadingOverlay();
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTrailerButton() {
    // Still loading — show subtle placeholder
    if (_trailerLoading) {
      return Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white30,
            ),
          ),
        ),
      );
    }

    // No trailer available — hide button
    if (_trailerKey == null) return const SizedBox.shrink();

    // Trailer available — show premium button
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF0000), Color(0xFFCC0000)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF0000).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TrailerPlayerScreen(
                  videoKey: _trailerKey!,
                  movieTitle: widget.movie.title,
                ),
              ),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.play_circle_filled,
                color: Colors.white,
                size: 26,
              ),
              const SizedBox(width: 10),
              Text(
                'Watch Trailer',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareMovieCard() async {
    final cardKey = GlobalKey();
    final tc = Get.find<ThemeController>();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // Build card off-screen via Overlay
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -1200,
        top: -2400,
        child: ShareableMovieCard(
          movie: widget.movie,
          accentColor: tc.accentColor,
          cardKey: cardKey,
        ),
      ),
    );
    overlay.insert(entry);

    // Wait for render
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      final imageBytes = await ShareableMovieCard.captureCard(cardKey);
      entry.remove();

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (imageBytes != null) {
        // Save to temp and share
        final dir = await getTemporaryDirectory();
        final file = File(
          '${dir.path}/moviehub_${widget.movie.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.png',
        );
        await file.writeAsBytes(imageBytes);

        final m = widget.movie;
        final text =
            '🎬 ${m.title}'
            '${m.year != "N/A" ? " (${m.year})" : ""}\n'
            '${m.rating > 0 ? "⭐ ${m.rating.toStringAsFixed(1)}/10\n" : ""}'
            '\nShared via MovieHub';

        await Share.shareXFiles([XFile(file.path)], text: text);
      } else {
        // Fallback: text only share
        _shareAsText();
      }
    } catch (e) {
      entry.remove();
      if (mounted) Navigator.pop(context);
      _shareAsText();
    }
  }

  void _shareAsText() {
    final m = widget.movie;
    final text =
        '🎬 ${m.title}'
        '${m.year != "N/A" ? " (${m.year})" : ""}\n'
        '${m.rating > 0 ? "⭐ ${m.rating.toStringAsFixed(1)}/10\n" : ""}'
        '\nShared via MovieHub';
    Share.share(text);
  }

  Widget _buildUserRating() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Rating',
              style: AppTextStyles.headingLarge.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Center(
              child: StarRatingWidget(
                rating: _userRating ?? 0,
                size: 36,
                onRatingChanged: (newRating) {
                  setState(() => _userRating = newRating);
                  if (widget.movie.tmdbId != null) {
                    UserRatingService.rateMovie(
                      tmdbId: widget.movie.tmdbId!,
                      rating: newRating,
                      title: widget.movie.title,
                    );
                    Get.snackbar(
                      '⭐ Rated ${newRating.toStringAsFixed(1)}/5',
                      widget.movie.title,
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.amber.withValues(alpha: 0.9),
                      colorText: Colors.black,
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 2),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onDoubleTapBookmark() {
    _watchlistController.toggleWatchlist(widget.movie);
    // Show animated bookmark
    setState(() => _showBookmarkHeart = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showBookmarkHeart = false);
    });
    HapticFeedback.mediumImpact();
  }

  void _showAddToCollectionDialog() async {
    final collections = await MovieCollectionService.getCollections();
    final movie = widget.movie;
    final tc = Get.find<ThemeController>();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDarker,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Add to Collection', style: AppTextStyles.titleLarge),
            const SizedBox(height: 16),
            if (collections.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No collections yet.\nCreate one from Settings → My Collections.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                ),
              )
            else
              ...collections.map(
                (col) => ListTile(
                  leading: Text(
                    col['emoji'] ?? '🎬',
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    col['name'] ?? 'Untitled',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    '${(col['movies'] as List?)?.length ?? 0} movies',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Icon(
                    Icons.add_circle_outline,
                    color: tc.accentColor,
                  ),
                  onTap: () async {
                    await MovieCollectionService.addToCollection(
                      collectionId: col['id'],
                      tmdbId: movie.tmdbId ?? 0,
                      title: movie.title,
                      posterUrl: movie.fullPosterPath,
                      rating: movie.rating,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    Get.snackbar(
                      '✅ Added to ${col['name']}',
                      movie.title,
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppColors.success.withValues(alpha: 0.9),
                      colorText: Colors.white,
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 2),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSimilarMovies() {
    // Hide if still loading or no results
    if (_similarLoading) {
      return Padding(
        padding: const EdgeInsets.only(top: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You May Also Like',
              style: AppTextStyles.headingLarge.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (_, _) => Container(
                  width: 130,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_similarMovies.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You May Also Like',
            style: AppTextStyles.headingLarge.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _similarMovies.length,
              itemBuilder: (context, index) {
                final movie = _similarMovies[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailsScreen(movie: movie),
                      ),
                    );
                  },
                  child: Container(
                    width: 130,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Poster
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: movie.fullPosterPath,
                                    fit: BoxFit.cover,
                                    placeholder: (_, _) => Container(
                                      color: Colors.white.withValues(
                                        alpha: 0.05,
                                      ),
                                    ),
                                  ),
                                  // Rating badge
                                  if (movie.rating > 0)
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.7,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                              size: 12,
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              movie.rating.toStringAsFixed(1),
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
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
                        ),
                        const SizedBox(height: 8),
                        // Title
                        Text(
                          movie.title,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGetLinksButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _linkController.fetchLinks(
          tmdbId: widget.movie.tmdbId ?? 0,
          title: widget.movie.title,
          year: widget.movie.year != 'N/A' ? widget.movie.year : null,
          hdhub4uUrl: widget.movie.hdhub4uUrl,
          source: widget.movie.sourceType,
          skyMoviesHDUrl: widget.movie.skyMoviesHDUrl,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.play_circle_fill, size: 28),
        label: Text(
          "Generate Links",
          style: AppTextStyles.headingLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        color: Colors.black.withValues(alpha: 0.85),
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_linkController.isSuccess.value) ...[
              // ── Success Animation ──
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (_, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.success, width: 2),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.success,
                    size: 54,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 400),
                child: Text(
                  "Links Generated Successfully!",
                  style: AppTextStyles.headingLarge.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ] else if (_linkController.isLoading.value) ...[
              // ── Continuous Searching Animation ──
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.1),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeInOutSine,
                    builder: (_, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.15),
                      ),
                      child: Icon(
                        Icons.satellite_alt_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Stage Message ──
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: Obx(
                  () => Text(
                    _linkController.progressText.value,
                    key: ValueKey(_linkController.progressText.value),
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontSize: 17,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Indeterminate Pulse Line ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ] else if (_linkController.hasError.value) ...[
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                "Search Failed",
                style: AppTextStyles.headingLarge.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _linkController.errorMessage.value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => _linkController.hasError.value = false,
                    child: Text(
                      "Dismiss",
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () => _linkController.retryFetch(
                      tmdbId: widget.movie.tmdbId ?? 0,
                      title: widget.movie.title,
                      year: widget.movie.year != 'N/A'
                          ? widget.movie.year
                          : null,
                      hdhub4uUrl: widget.movie.hdhub4uUrl,
                      source: widget.movie.sourceType,
                      skyMoviesHDUrl: widget.movie.skyMoviesHDUrl,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Retry Search"),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Handle play button press: resolve intermediate URL → open VideoPlayerScreen
  Future<void> _handlePlayLink(Map<String, String> link) async {
    final url = link['url'] ?? '';
    if (url.isEmpty || !url.startsWith('http')) {
      Get.snackbar(
        'Invalid Link',
        'This link cannot be played.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
        colorText: Colors.white,
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
      return;
    }

    // Check if URL is already a direct video link (e.g. cinecloud .mp4/.mkv)
    final lowerUrl = url.toLowerCase();
    final isDirectVideo =
        lowerUrl.endsWith('.mp4') ||
        lowerUrl.endsWith('.mkv') ||
        lowerUrl.endsWith('.webm') ||
        lowerUrl.endsWith('.avi');

    if (isDirectVideo) {
      // Play directly — no resolution needed
      _openVideoPlayer(url, link['quality'] ?? 'HD');
      return;
    }

    // Show resolving dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(40),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Preparing Video...',
                  style: AppTextStyles.headingLarge.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Resolving stream link, please wait',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final apiService = ApiService();
      final result = await apiService.resolveDownloadLink(
        url: url,
        quality: link['quality'] ?? '1080p',
      );

      // Close the loading dialog
      if (mounted) Navigator.of(context).pop();

      if (result['success'] == true && result['directUrl'] != null) {
        // Extract headers if available
        Map<String, String>? headers;
        if (result['headers'] != null && result['headers'] is Map) {
          headers = Map<String, String>.from(result['headers']);
        }
        _openVideoPlayer(
          result['directUrl'],
          link['quality'] ?? 'HD',
          headers: headers,
        );
      } else {
        final error = result['error'] ?? 'Could not resolve video link';
        Get.snackbar(
          'Cannot Play',
          error,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
          colorText: Colors.white,
          margin: const EdgeInsets.all(20),
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.error_outline, color: Colors.white),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      Get.snackbar(
        'Play Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
        colorText: Colors.white,
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Navigate to the in-app video player
  void _openVideoPlayer(
    String videoUrl,
    String quality, {
    Map<String, String>? headers,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          videoUrl: videoUrl,
          quality: quality,
          headers: headers,
          tmdbId: widget.movie.tmdbId,
          movieTitle: widget.movie.title,
          posterUrl: widget.movie.fullPosterPath,
        ),
      ),
    );
  }

  Widget _buildLinkItem(Map<String, String> link, int index) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.glassBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_download,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          title: Text(
            link['name'] ?? "Source ${index + 1}",
            style: AppTextStyles.titleMedium,
          ),
          subtitle: Text(
            "Quality: ${link['quality']}",
            style: AppTextStyles.bodySmall,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Stream/Play button — resolves link and opens in-app player
              IconButton(
                icon: Icon(
                  Icons.play_circle_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
                tooltip: 'Play Video',
                onPressed: () => _handlePlayLink(link),
              ),
              // Download button
              IconButton(
                icon: const Icon(
                  Icons.download_rounded,
                  color: AppColors.primaryDark,
                  size: 22,
                ),
                tooltip: 'Download',
                onPressed: () async {
                  final url = link['url'] ?? '';
                  if (url.isEmpty) return;

                  await _downloadController.startDownload(
                    url: url,
                    filename:
                        '${widget.movie.title}_${link['quality'] ?? 'HD'}.mp4',
                    tmdbId: widget.movie.tmdbId,
                    quality: link['quality'],
                    movieTitle: widget.movie.title,
                    posterUrl: widget.movie.fullPosterPath,
                  );
                },
              ),
              // Copy button
              IconButton(
                icon: const Icon(
                  Icons.copy,
                  color: AppColors.textMuted,
                  size: 18,
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: link['url'] ?? ""));
                  Get.snackbar(
                    "Link Copied",
                    "Ready to paste in your browser",
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.8),
                    colorText: Colors.white,
                    margin: const EdgeInsets.all(20),
                    duration: const Duration(seconds: 2),
                  );
                },
              ),
            ],
          ),
          onTap: () async {
            final url = Uri.parse(link['url'] ?? "");
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          },
        ),
      ),
    );
  }

  Widget _buildEmbedLinkItem(Map<String, String> link, int index) {
    // Gradient colors based on player priority
    final gradients = <List<Color>>[
      [
        Theme.of(context).colorScheme.primary,
        AppColors.primaryDark,
      ], // Emerald - Recommended
      [const Color(0xFF2563EB), const Color(0xFF3B82F6)], // Blue - High Speed
      [const Color(0xFF059669), const Color(0xFF10B981)], // Green - Standard
      [const Color(0xFFD97706), const Color(0xFFF59E0B)], // Orange - Backup
      [const Color(0xFF4B5563), const Color(0xFF6B7280)], // Gray - Extra
    ];
    final colors = index < gradients.length ? gradients[index] : gradients.last;

    // Beautiful name from backend, fallback to generated
    final beautifulNames = [
      '⚡ Instant Play (Recommended)',
      '🚀 High Speed Player',
      '📺 Standard Player',
      '🔄 Backup Player',
      '⭐ Premium Player',
    ];
    final displayName =
        link['name'] ??
        (index < beautifulNames.length
            ? beautifulNames[index]
            : 'Player ${index + 1}');

    final quality = link['quality'] ?? 'HD';
    final isRecommended = index == 0;

    // Speed indicator
    final speedIcons = [
      Icons.bolt,
      Icons.speed,
      Icons.network_check,
      Icons.backup,
    ];
    final speedTexts = ['Lightning Fast', 'Fast', 'Stable', 'Backup'];
    final speedIcon = index < speedIcons.length
        ? speedIcons[index]
        : Icons.backup;
    final speedText = index < speedTexts.length ? speedTexts[index] : 'Backup';

    // Quality badge color
    Color qualityColor;
    if (quality.contains('4K') || quality.contains('2160')) {
      qualityColor = Colors.purple;
    } else if (quality.contains('1080')) {
      qualityColor = Colors.blue;
    } else if (quality.contains('720')) {
      qualityColor = Colors.green;
    } else {
      qualityColor = Colors.orange;
    }

    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () {
            final url = link['url'] ?? '';
            if (url.isEmpty || !url.startsWith('http')) {
              Get.snackbar(
                'Invalid Link',
                'This link cannot be streamed.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
                colorText: Colors.white,
                margin: const EdgeInsets.all(20),
                duration: const Duration(seconds: 2),
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WebViewPlayer(
                  videoUrl: url,
                  movieTitle: widget.movie.title,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Play icon circle
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Link info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // Quality badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: qualityColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                quality,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Speed indicator
                            Icon(speedIcon, size: 13, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(
                              speedText,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        // Recommended badge
                        if (isRecommended)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.recommend,
                                  size: 13,
                                  color: Colors.amberAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Best Quality & Speed',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.amberAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Chevron
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
