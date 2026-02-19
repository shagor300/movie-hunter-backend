import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/download_controller.dart';
import '../models/download.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';
import 'video_player_screen.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DownloadController>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Downloads',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 22),
        ),
        centerTitle: true,
        actions: [
          Obx(() {
            final history = controller.historyDownloads;
            if (history.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, size: 22),
              tooltip: 'Clear History',
              onPressed: () async {
                final confirmed = await Get.dialog<bool>(
                  AlertDialog(
                    backgroundColor: const Color(0xFF1A1A2E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(
                      'Clear History?',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: Text(
                      'Remove all failed and canceled download entries?',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(result: false),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(color: Colors.white60),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Get.back(result: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  for (final d in List.from(history)) {
                    await controller.deleteDownload(d);
                  }
                }
              },
            );
          }),
        ],
      ),
      body: Obx(() {
        if (!controller.isInitialized.value) {
          return const SkeletonList(itemCount: 5);
        }

        if (controller.downloads.isEmpty) {
          return const EmptyState(
            icon: Icons.download_rounded,
            title: 'No Downloads Yet',
            message:
                'Downloaded movies will appear here.\nBrowse movies and tap download to get started.',
          );
        }

        final active = controller.activeDownloads;
        final completed = controller.completedDownloads;
        final history = controller.historyDownloads;

        return RefreshIndicator(
          onRefresh: () async {
            // Downloads are tracked via flutter_downloader callbacks,
            // so a manual refresh just provides UX feedback.
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: colorScheme.primary,
          backgroundColor: colorScheme.surface,
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            children: [
              if (active.isNotEmpty) ...[
                _buildSectionHeader(
                  'Active Downloads',
                  active.length,
                  colorScheme,
                ),
                const SizedBox(height: 12),
                ...active.map(
                  (d) => _buildDownloadCard(d, controller, colorScheme),
                ),
                const SizedBox(height: 24),
              ],
              if (completed.isNotEmpty) ...[
                _buildSectionHeader('Completed', completed.length, colorScheme),
                const SizedBox(height: 12),
                ...completed.map(
                  (d) => _buildDownloadCard(d, controller, colorScheme),
                ),
                const SizedBox(height: 24),
              ],
              if (history.isNotEmpty) ...[
                _buildSectionHeader('History', history.length, colorScheme),
                const SizedBox(height: 12),
                ...history.map(
                  (d) => _buildDownloadCard(d, controller, colorScheme),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionHeader(String title, int count, ColorScheme colorScheme) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count.toString(),
            style: GoogleFonts.inter(
              color: colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadCard(
    Download download,
    DownloadController controller,
    ColorScheme colorScheme,
  ) {
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
        statusColor = colorScheme.onSurface.withValues(alpha: 0.54);
        statusIcon = Icons.hourglass_top;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
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
                    color: statusColor.withValues(alpha: 0.1),
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
                                color: colorScheme.primary.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              child: Text(
                                download.quality!,
                                style: GoogleFonts.inter(
                                  color: colorScheme.primary,
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
                                        color: colorScheme.onSurface
                                            .withValues(alpha: 0.38),
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
                          color: colorScheme.onSurface.withValues(alpha: 0.24),
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
                  backgroundColor: colorScheme.onSurface.withValues(alpha: 0.1),
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
                        Icon(
                          Icons.speed,
                          size: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.24),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          controller.getSpeedText(download.taskId),
                          style: GoogleFonts.inter(
                            color: colorScheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.timer_outlined,
                          size: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.24),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          controller.getETAText(download.taskId),
                          style: GoogleFonts.inter(
                            color: colorScheme.onSurface.withValues(alpha: 0.38),
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
                      color: colorScheme.onSurface.withValues(alpha: 0.38),
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
              icon: Icon(
                Icons.delete_outline,
                color: Colors.white.withValues(alpha: 0.24),
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
