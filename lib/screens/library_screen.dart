import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/watchlist_controller.dart';
import '../theme/theme_controller.dart';
import '../models/watchlist_movie.dart';
import '../models/movie.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/movie_card.dart';
import 'details_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = const [Tab(text: 'Watchlist'), Tab(text: 'Favorites')];

  final _categories = const [
    WatchlistCategory.watchlist,
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
          style: AppTextStyles.headingLarge.copyWith(fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: AppColors.backgroundDark,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
          unselectedLabelStyle: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
          dividerColor: Colors.transparent,
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
              child: Obx(() {
                final tc = Get.find<ThemeController>();
                final cols = tc.gridColumnCount;
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
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
                );
              }),
            );
          }).toList(),
        );
      }),
    );
  }

  Widget _buildMovieCard(WatchlistMovie movie, WatchlistController controller) {
    final movieObj = Movie(
      tmdbId: movie.tmdbId,
      title: movie.title,
      plot: movie.plot ?? '',
      tmdbPoster: movie.posterUrl ?? '',
      releaseDate: movie.releaseDate ?? 'N/A',
      rating: movie.rating,
      sources: [],
    );

    return GestureDetector(
      onLongPress: () => _showOptionsSheet(movie, controller),
      child: Stack(
        children: [
          MovieCard(
            movie: movieObj,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailsScreen(movie: movieObj),
              ),
            ),
          ),
          if (movie.favorite)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
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
                color: colorScheme.onSurface.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              movie.title,
              style: AppTextStyles.headingLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
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
      case WatchlistCategory.favorites:
        title = 'No Favorites Yet';
        message = 'Heart a movie to add it to favorites';
        icon = Icons.favorite_border;
        break;
      default:
        title = 'Empty';
        message = '';
        icon = Icons.inbox;
        break;
    }

    return EmptyState(icon: icon, title: title, message: message);
  }
}
