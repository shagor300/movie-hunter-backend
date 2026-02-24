import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:get/get.dart';
import '../models/movie.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_dimensions.dart';
import '../theme/theme_controller.dart';

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
                color: AppColors.surface,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image with Hero
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

                    // Bottom Gradient
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

                    // Top Right Quality Badge — accent colored
                    Positioned(top: 8, right: 8, child: _buildQualityBadge()),

                    // Bottom Left Rating Badge
                    Positioned(bottom: 8, left: 8, child: _buildRatingBadge()),
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

          // Subtitle
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

  Widget _buildQualityBadge() {
    final tc = Get.find<ThemeController>();
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: tc.accentColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: tc.accentColor.withValues(alpha: 0.3),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          "HD",
          style: AppTextStyles.labelSmall.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: tc.accentColor,
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: AppColors.starGold, size: 13),
          const SizedBox(width: 3),
          Text(
            movie.rating.toStringAsFixed(1),
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
