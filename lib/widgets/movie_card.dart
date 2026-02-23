import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/movie.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_dimensions.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;

  const MovieCard({super.key, required this.movie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster Section (2:3 Aspect Ratio)
          AspectRatio(
            aspectRatio: AppDimensions.posterAspectRatio,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: AppColors.glassBorder),
                color: AppColors.surface, // Fallback bg
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image
                    Hero(
                      tag: 'poster-${movie.title}',
                      child: movie.fullPosterPath.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: movie.fullPosterPath,
                              fit: BoxFit.cover,
                              memCacheWidth: 300,
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: AppColors.surface,
                                highlightColor: AppColors.surfaceLight,
                                child: Container(color: Colors.black),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Center(
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      color: AppColors.textMuted,
                                      size: 40,
                                    ),
                                  ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.movie_outlined,
                                color: AppColors.textMuted,
                                size: 40,
                              ),
                            ),
                    ),

                    // Bottom Gradient (for rating text visibility)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 60,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Top Right Quality Badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _buildGlassBadge(
                        child: Text(
                          "HD",
                          style: AppTextStyles.labelSmall.copyWith(fontSize: 9),
                        ),
                      ),
                    ),

                    // Bottom Left Rating Badge
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: _buildGlassBadge(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              color: AppColors.starGold,
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              movie.rating.toStringAsFixed(1),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.white,
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

          const SizedBox(height: AppDimensions.spacingSm),

          // Title
          Text(
            movie.title,
            style: AppTextStyles.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Subtitle (Year & Sources)
          const SizedBox(height: 2),
          Text(
            "${movie.year} • ${movie.sources.length} Sources",
            style: AppTextStyles.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildGlassBadge({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.glassBackground.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: AppColors.glassBorder.withValues(alpha: 0.2)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}
