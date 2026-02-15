import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../controllers/watchlist_controller.dart';
import '../models/watchlist_movie.dart';
import '../models/movie.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';
import 'details_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = const [
    Tab(text: 'Watchlist'),
    Tab(text: 'Watching'),
    Tab(text: 'Completed'),
    Tab(text: 'Favorites'),
  ];

  final _categories = const [
    WatchlistCategory.watchlist,
    WatchlistCategory.watching,
    WatchlistCategory.completed,
    WatchlistCategory.favorites,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WatchlistController>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Library',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 22),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: colorScheme.primary,
          indicatorWeight: 3,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurface.withOpacity(0.38),
          labelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: _tabs,
        ),
      ),
      body: Obx(() {
        if (!controller.isInitialized.value) {
          return const SkeletonGrid(itemCount: 6);
        }

        return TabBarView(
          controller: _tabController,
          children: _categories.map((category) {
            final movies = controller.getByCategory(category);

            if (movies.isEmpty) {
              return _buildEmptyState(category, controller);
            }

            return RefreshIndicator(
              onRefresh: () async {
                // Watchlist is local — just trigger a UI refresh.
                await Future.delayed(const Duration(milliseconds: 300));
              },
              color: colorScheme.primary,
              backgroundColor: colorScheme.surface,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: movies.length,
                itemBuilder: (context, index) {
                  final movie = movies[index];
                  return Dismissible(
                    key: ValueKey(movie.tmdbId),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                        size: 28,
                      ),
                    ),
                    confirmDismiss: (_) async => true,
                    onDismissed: (_) {
                      controller.removeFromWatchlist(movie.tmdbId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('"${movie.title}" removed'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xFF323232),
                          margin: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          action: SnackBarAction(
                            label: 'Undo',
                            textColor: colorScheme.primary,
                            onPressed: () {
                              controller.addToWatchlist(
                                Movie(
                                  tmdbId: movie.tmdbId,
                                  title: movie.title,
                                  plot: movie.plot ?? '',
                                  tmdbPoster: movie.posterUrl ?? '',
                                  releaseDate: movie.releaseDate ?? 'N/A',
                                  rating: movie.rating,
                                  sources: [],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                    child: _buildMovieCard(movie, controller),
                  );
                },
              ),
            );
          }).toList(),
        );
      }),
    );
  }

  Widget _buildMovieCard(WatchlistMovie movie, WatchlistController controller) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        // Convert WatchlistMovie back to Movie for navigation
        final movieObj = Movie(
          tmdbId: movie.tmdbId,
          title: movie.title,
          plot: movie.plot ?? '',
          tmdbPoster: movie.posterUrl ?? '',
          releaseDate: movie.releaseDate ?? 'N/A',
          rating: movie.rating,
          sources: [],
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailsScreen(movie: movieObj),
          ),
        );
      },
      onLongPress: () => _showOptionsSheet(movie, controller),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (movie.posterUrl != null && movie.posterUrl!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: movie.posterUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: 300,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: const Color(0xFF1E1E3A),
                          highlightColor: const Color(0xFF2A2A4A),
                          child: Container(color: Colors.black),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[900],
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white24,
                            size: 40,
                          ),
                        ),
                      )
                    else
                      Container(
                        color: Colors.grey[900],
                        child: const Icon(
                          Icons.movie_outlined,
                          color: Colors.white24,
                          size: 40,
                        ),
                      ),
                    // Rating badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 12,
                            ),
                            const SizedBox(width: 3),
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
                    // Favorite icon
                    if (movie.favorite)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.redAccent,
                            size: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Text(
                    movie.title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptionsSheet(WatchlistMovie movie, WatchlistController controller) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.24),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              movie.title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            // Move to category
            ListTile(
              leading: Icon(Icons.swap_horiz, color: colorScheme.primary),
              title: Text('Move to...', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(context);
                _showCategoryPicker(movie, controller);
              },
            ),
            // Toggle favorite
            ListTile(
              leading: Icon(
                movie.favorite ? Icons.favorite : Icons.favorite_border,
                color: Colors.redAccent,
              ),
              title: Text(
                movie.favorite ? 'Remove from Favorites' : 'Add to Favorites',
                style: GoogleFonts.inter(),
              ),
              onTap: () {
                controller.toggleFavorite(movie.tmdbId);
                Navigator.pop(context);
              },
            ),
            // Remove
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
              ),
              title: Text(
                'Remove',
                style: GoogleFonts.inter(color: Colors.redAccent),
              ),
              onTap: () {
                controller.removeFromWatchlist(movie.tmdbId);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker(
    WatchlistMovie movie,
    WatchlistController controller,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Move to',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...WatchlistCategory.values.map((cat) {
              final isSelected = movie.category == cat;
              final label = _categoryLabel(cat);
              final icon = _categoryIcon(cat);
              return ListTile(
                leading: Icon(
                  icon,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withOpacity(0.38),
                ),
                title: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: isSelected ? colorScheme.primary : null,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check, color: colorScheme.primary)
                    : null,
                onTap: () {
                  controller.updateCategory(movie.tmdbId, cat);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    WatchlistCategory category,
    WatchlistController controller,
  ) {
    String title;
    String message;
    IconData icon;

    switch (category) {
      case WatchlistCategory.watchlist:
        title = 'Watchlist is Empty';
        message = 'Add movies to watch them later';
        icon = Icons.bookmark_border;
        break;
      case WatchlistCategory.watching:
        title = 'Nothing Playing';
        message = 'Movies you\'re currently watching appear here';
        icon = Icons.play_circle_outline;
        break;
      case WatchlistCategory.completed:
        title = 'No Completed Movies';
        message = 'Finished watching a movie? Move it here!';
        icon = Icons.check_circle_outline;
        break;
      case WatchlistCategory.favorites:
        title = 'No Favorites Yet';
        message = 'Heart a movie to add it to favorites';
        icon = Icons.favorite_border;
        break;
    }

    return EmptyState(icon: icon, title: title, message: message);
  }

  String _categoryLabel(WatchlistCategory cat) {
    switch (cat) {
      case WatchlistCategory.watchlist:
        return 'Watchlist';
      case WatchlistCategory.watching:
        return 'Watching';
      case WatchlistCategory.completed:
        return 'Completed';
      case WatchlistCategory.favorites:
        return 'Favorites';
    }
  }

  IconData _categoryIcon(WatchlistCategory cat) {
    switch (cat) {
      case WatchlistCategory.watchlist:
        return Icons.bookmark;
      case WatchlistCategory.watching:
        return Icons.play_circle;
      case WatchlistCategory.completed:
        return Icons.check_circle;
      case WatchlistCategory.favorites:
        return Icons.favorite;
    }
  }
}
