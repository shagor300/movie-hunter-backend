import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/download_controller.dart';
import '../models/download.dart';
import 'video_player_screen.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DownloadController>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Downloads',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (!controller.isInitialized.value) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.blueAccent),
          );
        }

        if (controller.downloads.isEmpty) {
          return _buildEmptyState();
        }

        final active = controller.activeDownloads;
        final completed = controller.completedDownloads;

        return ListView(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          children: [
            if (active.isNotEmpty) ...[
              _buildSectionHeader('Active Downloads', active.length),
              const SizedBox(height: 12),
              ...active.map((d) => _buildDownloadCard(d, controller)),
              const SizedBox(height: 24),
            ],
            if (completed.isNotEmpty) ...[
              _buildSectionHeader('Completed', completed.length),
              const SizedBox(height: 12),
              ...completed.map((d) => _buildDownloadCard(d, controller)),
            ],
          ],
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_rounded,
            size: 100,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 20),
          Text(
            'No Downloads Yet',
            style: GoogleFonts.poppins(
              color: Colors.white38,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Download movies from the detail page',
            style: GoogleFonts.inter(color: Colors.white24, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count.toString(),
            style: GoogleFonts.inter(
              color: Colors.blueAccent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadCard(Download download, DownloadController controller) {
    Color statusColor;
    IconData statusIcon;

    switch (download.status) {
      case DownloadStatus.downloading:
        statusColor = Colors.blueAccent;
        statusIcon = Icons.downloading;
        break;
      case DownloadStatus.paused:
        statusColor = Colors.orangeAccent;
        statusIcon = Icons.pause_circle;
        break;
      case DownloadStatus.completed:
        statusColor = Colors.greenAccent;
        statusIcon = Icons.check_circle;
        break;
      case DownloadStatus.failed:
        statusColor = Colors.redAccent;
        statusIcon = Icons.error;
        break;
      case DownloadStatus.canceled:
        statusColor = Colors.grey;
        statusIcon = Icons.cancel;
        break;
      case DownloadStatus.queued:
        statusColor = Colors.white54;
        statusIcon = Icons.hourglass_top;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        download.movieTitle,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Quality badge
                          if (download.quality != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.blueAccent.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              child: Text(
                                download.quality!,
                                style: GoogleFonts.inter(
                                  color: Colors.blueAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          // File size (completed only)
                          if (download.status == DownloadStatus.completed &&
                              download.savedPath != null)
                            Builder(
                              builder: (_) {
                                try {
                                  final file = File(download.savedPath!);
                                  if (file.existsSync()) {
                                    final bytes = file.lengthSync();
                                    final size = bytes > 1024 * 1024 * 1024
                                        ? '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB'
                                        : '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
                                    return Text(
                                      size,
                                      style: GoogleFonts.inter(
                                        color: Colors.white38,
                                        fontSize: 11,
                                      ),
                                    );
                                  }
                                } catch (_) {}
                                return const SizedBox.shrink();
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        download.filename,
                        style: GoogleFonts.inter(
                          color: Colors.white24,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildActionButtons(download, controller),
              ],
            ),
            if (download.status == DownloadStatus.downloading ||
                download.status == DownloadStatus.paused) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: download.progress / 100,
                  backgroundColor: Colors.white10,
                  color: statusColor,
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Speed + ETA
                  if (download.status == DownloadStatus.downloading)
                    Row(
                      children: [
                        Icon(Icons.speed, size: 12, color: Colors.white24),
                        const SizedBox(width: 4),
                        Text(
                          controller.getSpeedText(download.taskId),
                          style: GoogleFonts.inter(
                            color: Colors.blueAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.timer_outlined,
                          size: 12,
                          color: Colors.white24,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          controller.getETAText(download.taskId),
                          style: GoogleFonts.inter(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    )
                  else
                    const SizedBox.shrink(),
                  Text(
                    '${download.progress}%',
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Download download, DownloadController controller) {
    switch (download.status) {
      case DownloadStatus.downloading:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.pause,
                color: Colors.orangeAccent,
                size: 20,
              ),
              onPressed: () => controller.pauseDownload(download),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
              onPressed: () => controller.cancelDownload(download),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        );
      case DownloadStatus.paused:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.play_arrow,
                color: Colors.blueAccent,
                size: 20,
              ),
              onPressed: () => controller.resumeDownload(download),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
              onPressed: () => controller.cancelDownload(download),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        );
      case DownloadStatus.failed:
        return IconButton(
          icon: const Icon(Icons.refresh, color: Colors.orangeAccent, size: 20),
          onPressed: () => controller.retryDownload(download),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        );
      case DownloadStatus.completed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (download.savedPath != null && download.savedPath!.isNotEmpty)
              IconButton(
                icon: const Icon(
                  Icons.play_circle_fill,
                  color: Colors.greenAccent,
                  size: 22,
                ),
                tooltip: 'Play',
                onPressed: () {
                  Get.to(
                    () => VideoPlayerScreen(
                      videoUrl: '',
                      localFilePath: download.savedPath,
                      tmdbId: download.tmdbId,
                      movieTitle: download.movieTitle,
                    ),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.white24,
                size: 20,
              ),
              onPressed: () => controller.deleteDownload(download),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
