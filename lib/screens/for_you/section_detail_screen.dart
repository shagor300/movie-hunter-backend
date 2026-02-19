import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/movie.dart';
import '../details_screen.dart';

/// Full-screen grid view showing all movies in a "For You" section.
class SectionDetailScreen extends StatelessWidget {
  final String sectionTitle;
  final List<Movie> movies;
  final IconData icon;

  const SectionDetailScreen({
    super.key,
    required this.sectionTitle,
    required this.movies,
    this.icon = Icons.movie_filter,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.onSurface),
          onPressed: () => Get.back(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: colorScheme.primary, size: 16),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                sectionTitle,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: movies.isEmpty
          ? Center(
              child: Text(
                'No movies found',
                style: GoogleFonts.inter(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 16,
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.62,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
              ),
              itemCount: movies.length,
              itemBuilder: (context, index) {
                return _buildMovieCard(movies[index], colorScheme, context);
              },
            ),
    );
  }

  Widget _buildMovieCard(
    Movie movie,
    ColorScheme colorScheme,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailsScreen(movie: movie)),
      ),
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
                          memCacheWidth: 360,
                          placeholder: (_, _) => Shimmer.fromColors(
                            baseColor: colorScheme.surface,
                            highlightColor: colorScheme.onSurface.withValues(
                              alpha: 0.05,
                            ),
                            child: Container(color: colorScheme.surface),
                          ),
                          errorWidget: (_, _, _) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.movie,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.2,
                              ),
                              size: 40,
                            ),
                          ),
                        )
                      : Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.movie,
                            color: colorScheme.onSurface.withValues(alpha: 0.2),
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
                          color: Colors.black.withValues(alpha: 0.75),
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
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
