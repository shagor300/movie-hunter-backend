import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../controllers/video_player_controller.dart';
import '../models/playback_position.dart';
import '../screens/video_player_screen.dart';

class ContinueWatchingSection extends StatelessWidget {
  const ContinueWatchingSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VideoPlayerGetxController>();

    return Obx(() {
      if (!controller.isInitialized.value ||
          controller.continueWatching.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '▶ Continue Watching',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (controller.continueWatching.length > 3)
                  TextButton(
                    onPressed: () {}, // Could navigate to full list
                    child: Text(
                      'See All',
                      style: GoogleFonts.inter(
                        color: Colors.blueAccent,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              itemCount: controller.continueWatching.length.clamp(0, 10),
              itemBuilder: (context, index) {
                return _buildCard(context, controller.continueWatching[index]);
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildCard(BuildContext context, PlaybackPosition position) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(
              videoUrl: position.videoUrl ?? '',
              localFilePath: position.localFilePath,
              tmdbId: position.tmdbId,
              movieTitle: position.movieTitle,
              posterUrl: position.posterUrl,
            ),
          ),
        );
      },
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail with play overlay
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (position.posterUrl != null &&
                        position.posterUrl!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: position.posterUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: 440,
                        placeholder: (_, _) => Shimmer.fromColors(
                          baseColor: const Color(0xFF1E1E3A),
                          highlightColor: const Color(0xFF2A2A4A),
                          child: Container(color: Colors.black),
                        ),
                        errorWidget: (_, _, _) => Container(
                          color: Colors.grey[900],
                          child: const Icon(Icons.movie, color: Colors.white24),
                        ),
                      )
                    else
                      Container(
                        color: Colors.grey[900],
                        child: const Icon(
                          Icons.movie,
                          color: Colors.white24,
                          size: 30,
                        ),
                      ),
                    // Play button overlay
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    // Time remaining
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          position.remainingTime,
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Progress bar
              ClipRRect(
                child: LinearProgressIndicator(
                  value: position.progress,
                  backgroundColor: Colors.white10,
                  color: Colors.blueAccent,
                  minHeight: 3,
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  position.movieTitle,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
