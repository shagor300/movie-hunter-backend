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
import 'webview_player.dart';

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
  void initState() {
    super.initState();
    // Clear old links so a new movie starts fresh
    _linkController.clearData();
  }

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
                stretch: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                actions: [
                  // Favorite toggle
                  Obx(() {
                    final isIn = _watchlistController.isInWatchlist(
                      widget.movie.tmdbId,
                    );
                    final isFav = _watchlistController.isFavorite(
                      widget.movie.tmdbId,
                    );
                    return Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? Colors.redAccent : Colors.white,
                              size: 22,
                            ),
                            tooltip: isFav
                                ? 'Remove from Favorites'
                                : 'Add to Favorites',
                            onPressed: () {
                              // ONLY toggle favorite — completely independent
                              _watchlistController.toggleFavoriteIndependent(
                                widget.movie,
                              );
                            },
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              isIn ? Icons.bookmark : Icons.bookmark_border,
                              color: isIn ? Colors.amber : Colors.white,
                              size: 22,
                            ),
                            tooltip: isIn
                                ? 'Remove from Watchlist'
                                : 'Add to Watchlist',
                            onPressed: () => _watchlistController
                                .toggleWatchlist(widget.movie),
                          ),
                        ),
                      ],
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
                              // --- Embed/Streaming Links ---
                              if (_linkController.embedLinks.isNotEmpty) ...[
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.play_circle_fill,
                                      color: Colors.greenAccent,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Stream Online',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.greenAccent,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ..._linkController.embedLinks
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                      return _buildEmbedLinkItem(
                                        entry.value,
                                        entry.key,
                                      );
                                    }),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.cloud_download,
                                      color: Colors.blueAccent,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Download',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                              ],
                              // --- Download Links ---
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
          hdhub4uUrl: widget.movie.hdhub4uUrl,
          source: widget.movie.sourceType,
          skyMoviesHDUrl: widget.movie.skyMoviesHDUrl,
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
                      hdhub4uUrl: widget.movie.hdhub4uUrl,
                      source: widget.movie.sourceType,
                      skyMoviesHDUrl: widget.movie.skyMoviesHDUrl,
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
                  if (url.isEmpty || !url.startsWith('http')) {
                    Get.snackbar(
                      'Invalid Link',
                      'This link cannot be streamed directly.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.redAccent.withOpacity(0.8),
                      colorText: Colors.white,
                      margin: const EdgeInsets.all(20),
                      duration: const Duration(seconds: 2),
                      icon: const Icon(
                        Icons.error_outline,
                        color: Colors.white,
                      ),
                    );
                    return;
                  }
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
                onPressed: () async {
                  final url = link['url'] ?? '';
                  if (url.isEmpty) return;

                  await _downloadController.startDownload(
                    url: url,
                    filename:
                        '${widget.movie.title}_${link['quality'] ?? 'HD'}.mp4',
                    tmdbId: widget.movie.tmdbId,
                    quality: link['quality'],
                    movieTitle: widget.movie.title,
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

  Widget _buildEmbedLinkItem(Map<String, String> link, int index) {
    // Gradient colors based on player priority
    final gradients = <List<Color>>[
      [
        const Color(0xFF6B46C1),
        const Color(0xFF9333EA),
      ], // Purple - Recommended
      [const Color(0xFF2563EB), const Color(0xFF3B82F6)], // Blue - High Speed
      [const Color(0xFF059669), const Color(0xFF10B981)], // Green - Standard
      [const Color(0xFFD97706), const Color(0xFFF59E0B)], // Orange - Backup
      [const Color(0xFF4B5563), const Color(0xFF6B7280)], // Gray - Extra
    ];
    final colors = index < gradients.length ? gradients[index] : gradients.last;

    // Beautiful name from backend, fallback to generated
    final beautifulNames = [
      '⚡ Instant Play (Recommended)',
      '🚀 High Speed Player',
      '📺 Standard Player',
      '🔄 Backup Player',
      '⭐ Premium Player',
    ];
    final displayName =
        link['name'] ??
        (index < beautifulNames.length
            ? beautifulNames[index]
            : 'Player ${index + 1}');

    final quality = link['quality'] ?? 'HD';
    final isRecommended = index == 0;

    // Speed indicator
    final speedIcons = [
      Icons.bolt,
      Icons.speed,
      Icons.network_check,
      Icons.backup,
    ];
    final speedTexts = ['Lightning Fast', 'Fast', 'Stable', 'Backup'];
    final speedIcon = index < speedIcons.length
        ? speedIcons[index]
        : Icons.backup;
    final speedText = index < speedTexts.length ? speedTexts[index] : 'Backup';

    // Quality badge color
    Color qualityColor;
    if (quality.contains('4K') || quality.contains('2160')) {
      qualityColor = Colors.purple;
    } else if (quality.contains('1080')) {
      qualityColor = Colors.blue;
    } else if (quality.contains('720')) {
      qualityColor = Colors.green;
    } else {
      qualityColor = Colors.orange;
    }

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
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () {
            final url = link['url'] ?? '';
            if (url.isEmpty || !url.startsWith('http')) {
              Get.snackbar(
                'Invalid Link',
                'This link cannot be streamed.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
                colorText: Colors.white,
                margin: const EdgeInsets.all(20),
                duration: const Duration(seconds: 2),
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WebViewPlayer(
                  videoUrl: url,
                  movieTitle: widget.movie.title,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Play icon circle
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Link info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // Quality badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: qualityColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                quality,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Speed indicator
                            Icon(speedIcon, size: 13, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(
                              speedText,
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        // Recommended badge
                        if (isRecommended)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.recommend,
                                  size: 13,
                                  color: Colors.amberAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Best Quality & Speed',
                                  style: GoogleFonts.inter(
                                    color: Colors.amberAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Chevron
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
