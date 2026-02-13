import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../controllers/hdhub4u_controller.dart';
import '../details_screen.dart';

class HDHub4uTab extends StatelessWidget {
  const HDHub4uTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HDHub4uController());

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1E),
        elevation: 0,
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
              return const Padding(
                padding: EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.blueAccent),
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
        color: Colors.blueAccent,
        child: Obx(() {
          // Loading state
          if (controller.isLoading.value && controller.movies.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SpinKitCubeGrid(color: Colors.blueAccent, size: 50),
                  const SizedBox(height: 24),
                  Text(
                    'Loading latest movies...',
                    style: GoogleFonts.inter(
                      color: Colors.white60,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          // Error state
          if (controller.hasError.value && controller.movies.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.redAccent.withOpacity(0.7),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Failed to load movies',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      controller.errorMessage.value,
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => controller.refresh(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
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
              child: Text(
                'No movies found',
                style: GoogleFonts.inter(color: Colors.white54),
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
              return _buildMovieCard(context, movie);
            },
          );
        }),
      ),
    );
  }

  Widget _buildMovieCard(BuildContext context, movie) {
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
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white10),
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
                        child: const Center(
                          child: SpinKitPulse(color: Colors.white24, size: 30),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[900],
                        child: const Icon(
                          Icons.movie,
                          size: 50,
                          color: Colors.white24,
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
                      color: Colors.white,
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
                        color: Colors.white38,
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
