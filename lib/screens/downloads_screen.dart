import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:open_filex/open_filex.dart';
import '../controllers/download_controller.dart';
import '../models/download_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/empty_state.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DownloadController>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Obx(
          () => Text(
            'Downloads (${controller.allDownloads.length})',
            style: AppTextStyles.headingLarge.copyWith(fontSize: 20),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () => _clearCompleted(controller),
            tooltip: 'Clear completed',
          ),
        ],
      ),
      body: Obx(() {
        final active = controller.activeDownloads;
        final completed = controller.completedDownloads;
        final history = controller.historyDownloads;

        if (active.isEmpty && completed.isEmpty && history.isEmpty) {
          return const Center(
            child: EmptyState(
              icon: Icons.download_outlined,
              title: 'No Downloads',
              message: 'Downloaded movies will appear here',
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            if (active.isNotEmpty) ...[
              _buildSectionHeader(
                'Active Downloads',
                active.length,
                colorScheme,
              ),
              ...active.map(
                (d) => _DownloadCard(item: d, controller: controller),
              ),
              const SizedBox(height: 16),
            ],
            if (completed.isNotEmpty) ...[
              _buildSectionHeader('Completed', completed.length, colorScheme),
              ...completed.map(
                (d) => _DownloadCard(item: d, controller: controller),
              ),
              const SizedBox(height: 16),
            ],
            if (history.isNotEmpty) ...[
              _buildSectionHeader('History', history.length, colorScheme),
              ...history.map(
                (d) => _DownloadCard(item: d, controller: controller),
              ),
            ],
            const SizedBox(height: 32),
          ],
        );
      }),
    );
  }

  Widget _buildSectionHeader(String title, int count, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Text(title, style: AppTextStyles.titleMedium),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearCompleted(DownloadController controller) {
    final completed = controller.allDownloads
        .where((d) => d.status == 'completed' || d.status == 'cancelled')
        .toList();

    for (final item in completed) {
      controller.deleteDownload(item);
    }
  }
}

// ═════════════════════════════════════════════════════════════════════
// DOWNLOAD CARD
// ═════════════════════════════════════════════════════════════════════

class _DownloadCard extends StatelessWidget {
  final DownloadItem item;
  final DownloadController controller;

  const _DownloadCard({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: AppColors.glassBackground,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: status icon + title + actions
            Row(
              children: [
                _StatusIcon(status: item.status),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.movieTitle,
                        style: AppTextStyles.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          _QualityBadge(quality: item.quality),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              item.fileName,
                              style: AppTextStyles.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _ActionButtons(item: item, controller: controller),
              ],
            ),

            // Progress section (active downloads)
            if (item.status == 'downloading' || item.status == 'paused')
              _ProgressSection(item: item, controller: controller),

            // Complete info
            if (item.status == 'completed')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '✅ ${item.fileSizeText} · Completed',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),

            // Failed info
            if (item.status == 'failed')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '❌ Failed · Tap retry to try again',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.red[400],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// PROGRESS SECTION — live speed, ETA, percentage
// ═════════════════════════════════════════════════════════════════════

class _ProgressSection extends StatelessWidget {
  final DownloadItem item;
  final DownloadController controller;

  const _ProgressSection({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final speed = controller.getSpeedText(item.id);
      final eta = controller.getETAText(item.id);
      final progress = item.progress;
      final isPaused = item.status == 'paused';

      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          children: [
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: AppColors.surfaceLight,
                valueColor: AlwaysStoppedAnimation(
                  isPaused ? Colors.orange : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${item.downloadedText} / ${item.fileSizeText}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  item.progressText,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                if (!isPaused)
                  Text(
                    '$speed · $eta',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  )
                else
                  Text(
                    'Paused',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.orange,
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

// ═════════════════════════════════════════════════════════════════════
// WIDGETS
// ═════════════════════════════════════════════════════════════════════

class _StatusIcon extends StatelessWidget {
  final String status;
  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (status) {
      case 'downloading':
        color = AppColors.primary;
        icon = Icons.download;
        break;
      case 'completed':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'failed':
        color = Colors.red;
        icon = Icons.error;
        break;
      case 'paused':
        color = Colors.orange;
        icon = Icons.pause_circle;
        break;
      default:
        color = Colors.grey;
        icon = Icons.hourglass_empty;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _QualityBadge extends StatelessWidget {
  final String quality;
  const _QualityBadge({required this.quality});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        quality,
        style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final DownloadItem item;
  final DownloadController controller;

  const _ActionButtons({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    switch (item.status) {
      case 'downloading':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.pause, color: Colors.orange, size: 22),
              onPressed: () => controller.pauseDownload(item),
              tooltip: 'Pause',
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red, size: 22),
              onPressed: () => controller.cancelDownload(item),
              tooltip: 'Cancel',
            ),
          ],
        );

      case 'paused':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.green, size: 22),
              onPressed: () => controller.resumeDownload(item),
              tooltip: 'Resume',
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red, size: 22),
              onPressed: () => controller.cancelDownload(item),
              tooltip: 'Cancel',
            ),
          ],
        );

      case 'completed':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.play_circle_outline,
                color: AppColors.primary,
                size: 22,
              ),
              onPressed: () async {
                final file = File(item.filePath);
                if (await file.exists()) {
                  await OpenFilex.open(item.filePath);
                } else {
                  Get.snackbar(
                    'File Not Found',
                    'The downloaded file was moved or deleted',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red.withValues(alpha: 0.8),
                    colorText: Colors.white,
                    margin: const EdgeInsets.all(20),
                  );
                }
              },
              tooltip: 'Play',
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 22,
              ),
              onPressed: () => _deleteDialog(context),
              tooltip: 'Delete',
            ),
          ],
        );

      case 'failed':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.orange, size: 22),
              onPressed: () => controller.retryDownload(item),
              tooltip: 'Retry',
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 22,
              ),
              onPressed: () => controller.deleteDownload(item),
              tooltip: 'Delete',
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  void _deleteDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Download?', style: AppTextStyles.titleMedium),
        content: Text(
          'Delete "${item.movieTitle}" from your downloads?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: AppTextStyles.bodyMedium),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteDownload(item);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
