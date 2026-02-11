import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../models/movie.dart';
import '../controllers/link_controller.dart';
import '../controllers/watchlist_controller.dart';
import '../controllers/download_controller.dart';
import 'video_player_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Premium Header with Background Image
              SliverAppBar(
                expandedHeight: 450,
                pinned: true,
                backgroundColor: const Color(0xFF0F0F1E),
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  // Watchlist toggle
                  Obx(() {
                    final isIn = _watchlistController.isInWatchlist(
                      widget.movie.tmdbId,
                    );
                    return IconButton(
                      icon: Icon(
                        isIn ? Icons.bookmark : Icons.bookmark_border,
                        color: Colors.amber,
                      ),
                      onPressed: () =>
                          _watchlistController.toggleWatchlist(widget.movie),
                    );
                  }),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
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
                              const Color(0xFF0F0F1E).withOpacity(0.5),
                              const Color(0xFF0F0F1E),
                            ],
                          ),
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
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildChip(widget.movie.year, Colors.blueAccent),
                          const SizedBox(width: 8),
                          _buildChip("HD 4K", Colors.green),
                          const SizedBox(width: 8),
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            widget.movie.rating.toStringAsFixed(1),
                            style: GoogleFonts.inter(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      // Glass Button for Links
                      _buildGetLinksButton(),
                      const SizedBox(height: 30),
                      // Storyline Section
                      Text(
                        "Storyline",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.movie.plot,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.white70,
                          height: 1.6,
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
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
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
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildGetLinksButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Colors.blueAccent, Colors.purpleAccent],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.3),
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
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        color: Colors.black.withOpacity(0.8),
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_linkController.isLoading.value) ...[
              const SpinKitCubeGrid(color: Colors.blueAccent, size: 70),
              const SizedBox(height: 40),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Obx(
                  () => Text(
                    _linkController.progressText.value,
                    key: ValueKey(_linkController.progressText.value),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: Obx(
                  () => LinearProgressIndicator(
                    value: _linkController.currentProgress.value,
                    backgroundColor: Colors.white12,
                    color: Colors.blueAccent,
                    minHeight: 4,
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
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _linkController.errorMessage.value,
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
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
                      style: GoogleFonts.inter(color: Colors.white60),
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
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
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
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_download, color: Colors.blueAccent),
          ),
          title: Text(
            link['name'] ?? "Source ${index + 1}",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            "Quality: ${link['quality']}",
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Stream/Play button
              IconButton(
                icon: const Icon(
                  Icons.play_circle_outline,
                  color: Colors.greenAccent,
                  size: 22,
                ),
                tooltip: 'Stream',
                onPressed: () {
                  final url = link['url'] ?? '';
                  if (url.isEmpty) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VideoPlayerScreen(
                        videoUrl: url,
                        tmdbId: widget.movie.tmdbId,
                        movieTitle: widget.movie.title,
                        posterUrl: widget.movie.fullPosterPath,
                      ),
                    ),
                  );
                },
              ),
              // Download button
              IconButton(
                icon: const Icon(
                  Icons.download_rounded,
                  color: Colors.blueAccent,
                  size: 22,
                ),
                tooltip: 'Download',
                onPressed: () {
                  final url = link['url'] ?? '';
                  if (url.isEmpty) return;

                  _downloadController.startDownload(
                    url: url,
                    filename:
                        '${widget.movie.title}_${link['quality'] ?? 'HD'}.mp4',
                    tmdbId: widget.movie.tmdbId,
                    quality: link['quality'],
                    movieTitle: widget.movie.title,
                  );

                  Get.snackbar(
                    "Download Started",
                    "Check the Downloads tab for progress",
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green.withOpacity(0.8),
                    colorText: Colors.white,
                    margin: const EdgeInsets.all(20),
                    duration: const Duration(seconds: 2),
                    icon: const Icon(Icons.download_done, color: Colors.white),
                  );
                },
              ),
              // Copy button
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.white24, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: link['url'] ?? ""));
                  Get.snackbar(
                    "Link Copied",
                    "Ready to paste in your browser",
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.blueAccent.withOpacity(0.8),
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
}
