import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../controllers/watchlist_controller.dart';
import '../models/watchlist_movie.dart';
import '../models/movie.dart';
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

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Library',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.blueAccent,
          indicatorWeight: 3,
          labelColor: Colors.blueAccent,
          unselectedLabelColor: Colors.white38,
          labelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: _tabs,
        ),
      ),
      body: Obx(() {
        if (!controller.isInitialized.value) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.blueAccent),
          );
        }

        return TabBarView(
          controller: _tabController,
          children: _categories.map((category) {
            final movies = controller.getByCategory(category);

            if (movies.isEmpty) {
              return _buildEmptyState(category);
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: movies.length,
              itemBuilder: (context, index) {
                return _buildMovieCard(movies[index], controller);
              },
            );
          }).toList(),
        );
      }),
    );
  }

  Widget _buildMovieCard(WatchlistMovie movie, WatchlistController controller) {
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
          color: const Color(0xFF1E1E3A).withOpacity(0.8),
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
                      color: Colors.white,
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
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E3A),
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
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              movie.title,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            // Move to category
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: Colors.blueAccent),
              title: Text(
                'Move to...',
                style: GoogleFonts.inter(color: Colors.white),
              ),
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
                style: GoogleFonts.inter(color: Colors.white),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E3A),
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
                color: Colors.white,
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
                  color: isSelected ? Colors.blueAccent : Colors.white38,
                ),
                title: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: isSelected ? Colors.blueAccent : Colors.white,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.blueAccent)
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

  Widget _buildEmptyState(WatchlistCategory category) {
    String message;
    IconData icon;

    switch (category) {
      case WatchlistCategory.watchlist:
        message = 'No movies in your watchlist';
        icon = Icons.bookmark_border;
        break;
      case WatchlistCategory.watching:
        message = 'Not watching anything right now';
        icon = Icons.play_circle_outline;
        break;
      case WatchlistCategory.completed:
        message = 'No completed movies yet';
        icon = Icons.check_circle_outline;
        break;
      case WatchlistCategory.favorites:
        message = 'No favorites yet';
        icon = Icons.favorite_border;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 16),
          ),
        ],
      ),
    );
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
