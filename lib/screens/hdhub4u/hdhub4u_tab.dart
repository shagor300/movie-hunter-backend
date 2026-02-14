import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../controllers/hdhub4u_controller.dart';
import '../details_screen.dart';

class HDHub4uTab extends StatelessWidget {
  const HDHub4uTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HDHub4uController());
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Latest',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'LIVE',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Subtle sync indicator (background incremental sync)
          Obx(() {
            if (controller.isSyncing.value && controller.movies.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          Obx(() {
            if (controller.isLoading.value) {
              return const Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            return IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => controller.refresh(),
            );
          }),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        color: colorScheme.primary,
        child: Obx(() {
          // Loading state — animated movie icon + pulsing text
          if (controller.isLoading.value && controller.movies.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOut,
                    builder: (_, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            colorScheme.primary.withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                          radius: 0.8,
                        ),
                      ),
                      child: Icon(
                        Icons.movie_filter,
                        color: colorScheme.primary,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Fetching latest movies…',
                    style: GoogleFonts.poppins(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait',
                    style: GoogleFonts.inter(
                      color: colorScheme.onSurface.withOpacity(0.38),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 120,
                    child: LinearProgressIndicator(
                      backgroundColor: colorScheme.onSurface.withOpacity(0.1),
                      color: colorScheme.primary,
                      minHeight: 3,
                    ),
                  ),
                ],
              ),
            );
          }

          // Error state — context-aware messages
          if (controller.hasError.value && controller.movies.isEmpty) {
            final error = controller.errorMessage.value.toLowerCase();
            final bool isNetworkError =
                error.contains('connection') ||
                error.contains('socket') ||
                error.contains('network') ||
                error.contains('unreachable');
            final bool isDeploying =
                error.contains('deploying') ||
                error.contains('server') ||
                error.contains('timeout') ||
                error.contains('502') ||
                error.contains('503');

            final IconData errorIcon = isNetworkError
                ? Icons.wifi_off_rounded
                : isDeploying
                ? Icons.cloud_off_rounded
                : Icons.error_outline;
            final Color errorColor = isNetworkError
                ? Colors.orangeAccent
                : isDeploying
                ? Colors.amber
                : Colors.redAccent;
            final String errorTitle = isNetworkError
                ? 'No Internet Connection'
                : isDeploying
                ? 'Server Starting Up'
                : 'Failed to Load Movies';
            final String errorHint = isNetworkError
                ? 'Check your internet connection and try again.'
                : isDeploying
                ? 'The backend may still be deploying.\nUsually takes 1-2 minutes.'
                : 'Something went wrong. Please try again.';

            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: errorColor.withValues(alpha: 0.1),
                      ),
                      child: Icon(errorIcon, size: 40, color: errorColor),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      errorTitle,
                      style: GoogleFonts.poppins(
                        color: colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      errorHint,
                      style: GoogleFonts.inter(
                        color: colorScheme.onSurface.withOpacity(0.54),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (!isNetworkError) ...[
                      const SizedBox(height: 12),
                      // Info box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: colorScheme.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                controller.errorMessage.value,
                                style: GoogleFonts.inter(
                                  color: colorScheme.onSurface.withOpacity(
                                    0.38,
                                  ),
                                  fontSize: 11,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => controller.refresh(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                      ),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(
                        'Try Again',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Empty state
          if (controller.movies.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.onSurface.withValues(alpha: 0.05),
                    ),
                    child: Icon(
                      Icons.movie_outlined,
                      color: colorScheme.onSurface.withOpacity(0.38),
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Movies Yet',
                    style: GoogleFonts.poppins(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for new releases!',
                    style: GoogleFonts.inter(
                      color: colorScheme.onSurface.withOpacity(0.38),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: () => controller.refresh(),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: Text(
                      'Refresh',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          }

          // Content grid
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.62,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: controller.movies.length,
            itemBuilder: (context, index) {
              final movie = controller.movies[index];
              return _buildMovieCard(context, movie, colorScheme);
            },
          );
        }),
      ),
    );
  }

  Widget _buildMovieCard(BuildContext context, movie, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailsScreen(movie: movie)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: colorScheme.onSurface.withOpacity(0.05),
          border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'poster-${movie.title}',
                    child: CachedNetworkImage(
                      imageUrl: movie.fullPosterPath,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: Colors.grey[900],
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onSurface.withOpacity(0.24),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[900],
                        child: Icon(
                          Icons.movie,
                          size: 50,
                          color: colorScheme.onSurface.withOpacity(0.24),
                        ),
                      ),
                    ),
                  ),

                  // NEW badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.redAccent, Colors.deepOrange],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withOpacity(0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Text(
                        'NEW',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),

                  // Rating chip
                  if (movie.rating > 0)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              movie.rating.toStringAsFixed(1),
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Title & Year
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  if (movie.releaseDate != 'N/A')
                    Text(
                      movie.year,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: colorScheme.onSurface.withOpacity(0.38),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
