import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';

import '../controllers/download_controller.dart';
import '../models/download_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/empty_state.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final controller = Get.find<DownloadController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Downloads',
          style: AppTextStyles.displayMedium.copyWith(fontSize: 28),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.cleaning_services_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
              onPressed: () => _clearCompleted(controller),
              tooltip: 'Clear completed',
            ),
          ),
        ],
      ),
      body: Obx(() {
        final active = controller.activeDownloads;
        final completed = controller.completedDownloads;
        final history = controller.historyDownloads;

        // Calculate storage mock data based on downloads
        double downloadedGb = 0;
        for (var d in completed) {
          final sStr = d.fileSizeText
              .toUpperCase()
              .replaceAll(' GB', '')
              .replaceAll(' MB', '');
          final val = double.tryParse(sStr) ?? 0.0;
          if (d.fileSizeText.toUpperCase().contains('MB')) {
            downloadedGb += (val / 1024);
          } else {
            downloadedGb += val;
          }
        }

        // Mock data for the UI
        final systemGb = 42.5;
        final totalGb = 128.0;
        final freeGb = totalGb - systemGb - downloadedGb;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          physics: const BouncingScrollPhysics(),
          children: [
            // ── Device Storage Card ──
            _DeviceStorageCard(
              systemGb: systemGb,
              downloadedGb: downloadedGb,
              totalGb: totalGb,
              freeGb: freeGb,
            ),

            const SizedBox(height: 24),

            if (active.isEmpty && completed.isEmpty && history.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: EmptyState(
                  icon: Icons.download_outlined,
                  title: 'No Downloads',
                  message: 'Downloaded movies will appear here',
                ),
              )
            else ...[
              // ── Active Downloads ──
              if (active.isNotEmpty) ...[
                _SectionTitle(
                  title: 'Active Downloads',
                  badgeText:
                      '${active.length} Item${active.length > 1 ? 's' : ''}',
                  icon: Icons.downloading_rounded,
                ),
                const SizedBox(height: 12),
                ...active.map(
                  (d) => _ActiveDownloadCard(item: d, controller: controller),
                ),
                const SizedBox(height: 24),
              ],

              // ── Completed Downloads ──
              if (completed.isNotEmpty) ...[
                _SectionTitle(
                  title: 'Downloaded',
                  actionText: 'View All',
                  onAction: () {},
                ),
                const SizedBox(height: 12),
                ...completed.map(
                  (d) => _CompletedCard(item: d, controller: controller),
                ),
                const SizedBox(height: 24),
              ],

              // ── History Downloads (Failed/Cancelled) ──
              if (history.isNotEmpty) ...[
                _SectionTitle(
                  title: 'History',
                  actionText: 'Clear',
                  onAction: () {
                    for (var item in history) {
                      controller.deleteDownload(item);
                    }
                  },
                ),
                const SizedBox(height: 12),
                ...history.map(
                  (d) => _HistoricalCard(item: d, controller: controller),
                ),
                const SizedBox(height: 40),
              ],
            ],
          ],
        );
      }),
    );
  }

  void _clearCompleted(DownloadController controller) {
    final completed = controller.allDownloads
        .where((d) => d.status == 'completed' || d.status == 'cancelled')
        .toList();

    for (final item in completed) {
      if (item.status == 'cancelled') {
        controller.deleteDownload(item);
      }
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// DEVICE STORAGE CARD
// ════════════════════════════════════════════════════════════════════════════
class _DeviceStorageCard extends StatelessWidget {
  final double systemGb;
  final double downloadedGb;
  final double totalGb;
  final double freeGb;

  const _DeviceStorageCard({
    required this.systemGb,
    required this.downloadedGb,
    required this.totalGb,
    required this.freeGb,
  });

  @override
  Widget build(BuildContext context) {
    final sysPct = systemGb / totalGb;
    final downPct = downloadedGb / totalGb;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DEVICE STORAGE',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${freeGb.toStringAsFixed(1)}GB Free',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: ' of ${totalGb.toInt()}GB',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(
                    flex: (sysPct * 100).toInt(),
                    child: Container(
                      color: AppColors.textMuted.withValues(alpha: 0.5),
                    ),
                  ),
                  Expanded(
                    flex: (downPct * 100).toInt(),
                    child: Container(
                      color: const Color(0xFF4338CA),
                    ), // Indigo/Blue
                  ),
                  Expanded(
                    flex: ((1 - sysPct - downPct) * 100).toInt(),
                    child: Container(color: Colors.white12), // Empty
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            children: [
              _DotLegend(
                color: AppColors.textMuted.withValues(alpha: 0.5),
                label: 'System',
              ),
              const SizedBox(width: 16),
              _DotLegend(color: const Color(0xFF4338CA), label: 'Downloads'),
            ],
          ),
        ],
      ),
    );
  }
}

class _DotLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _DotLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SECTION TITLE
// ════════════════════════════════════════════════════════════════════════════
class _SectionTitle extends StatelessWidget {
  final String title;
  final String? badgeText;
  final IconData? icon;
  final String? actionText;
  final VoidCallback? onAction;

  const _SectionTitle({
    required this.title,
    this.badgeText,
    this.icon,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
        ],
        Text(title, style: AppTextStyles.headingLarge.copyWith(fontSize: 20)),
        if (badgeText != null) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              badgeText!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        const Spacer(),
        if (actionText != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionText!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ACTIVE DOWNLOAD CARD (PREMIUM NEON GLOW)
// ════════════════════════════════════════════════════════════════════════════
class _ActiveDownloadCard extends StatelessWidget {
  final DownloadItem item;
  final DownloadController controller;

  const _ActiveDownloadCard({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final speed = controller.getSpeedText(item.id);
      final eta = controller.getETAText(item.id);
      final progress = item.progress;
      final isPaused = item.status == 'paused';

      final primaryGlow = isPaused ? Colors.orange : AppColors.primary;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Tailwind slate-900
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: primaryGlow.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Poster (Mocking with a shaded container if no URL, but MovieHub normally doesn't store poster in DownloadItem. We'll use a stylized icon)
                  Container(
                    width: 70,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          primaryGlow.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.movie_creation_outlined,
                        color: primaryGlow,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.movieTitle,
                                style: AppTextStyles.headingLarge.copyWith(
                                  fontSize: 18,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            InkWell(
                              onTap: () => _optionsSheet(context),
                              child: const Icon(
                                Icons.more_vert,
                                color: AppColors.textMuted,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.fileName,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 16),

                        // Speed & ETA
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isPaused ? 'Paused' : speed,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: primaryGlow,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              isPaused ? '--:--' : eta,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Progress Bar & Stats
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress.clamp(0.0, 1.0),
                                      minHeight: 6,
                                      backgroundColor: AppColors.surfaceLight,
                                      valueColor: AlwaysStoppedAnimation(
                                        primaryGlow,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${item.downloadedText} / ${item.fileSizeText}',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Play/Pause FAB
                            GestureDetector(
                              onTap: () => isPaused
                                  ? controller.resumeDownload(item)
                                  : controller.pauseDownload(item),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB), // Blue-600
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF2563EB,
                                      ).withValues(alpha: 0.4),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isPaused
                                      ? Icons.play_arrow_rounded
                                      : Icons.pause_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom glowing line
            Positioned(
              bottom: 0,
              left: 16,
              right: MediaQuery.of(context).size.width * 0.4,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(3),
                  ),
                  gradient: LinearGradient(
                    colors: [primaryGlow, primaryGlow.withValues(alpha: 0.0)],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _optionsSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text(
                'Cancel Download',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Get.back();
                controller.cancelDownload(item);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// COMPLETED CARD (PREMIUM HORIZONTAL LIST)
// ════════════════════════════════════════════════════════════════════════════
class _CompletedCard extends StatelessWidget {
  final DownloadItem item;
  final DownloadController controller;

  const _CompletedCard({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          // Playable Poster
          GestureDetector(
            onTap: () => _playFile(),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 100,
                  height: 65,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark,
                    border: Border.all(color: Colors.white10),
                    borderRadius: BorderRadius.circular(8),
                    image: const DecorationImage(
                      image: AssetImage(
                        'assets/images/placeholder.png',
                      ), // Replace with actual frame if possible
                      fit: BoxFit.cover,
                      opacity: 0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white54),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.movieTitle,
                  style: AppTextStyles.titleMedium.copyWith(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.quality,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'HDR', // Fake HDR badge for premium look
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${item.fileSizeText} • ${item.fileName}',
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Trailing
          IconButton(
            icon: const Icon(Icons.more_horiz, color: AppColors.textMuted),
            onPressed: () => _optionsSheet(context),
          ),
        ],
      ),
    );
  }

  Future<void> _playFile() async {
    final file = File(item.filePath);
    if (await file.exists()) {
      await OpenFilex.open(item.filePath);
    } else {
      Get.snackbar(
        'File Not Found',
        'The downloaded file was moved or deleted.',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _optionsSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.play_circle_fill,
                color: AppColors.primary,
              ),
              title: const Text('Play Movie'),
              onTap: () {
                Get.back();
                _playFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Delete File',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Get.back();
                controller.deleteDownload(item);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// HISTORICAL CARD (FAILED/CANCELLED)
// ════════════════════════════════════════════════════════════════════════════
class _HistoricalCard extends StatelessWidget {
  final DownloadItem item;
  final DownloadController controller;

  const _HistoricalCard({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isFailed = item.status == 'failed';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isFailed
                  ? Colors.red.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFailed ? Icons.error_outline : Icons.cancel_outlined,
              color: isFailed ? Colors.red : Colors.orange,
            ),
          ),
          const SizedBox(width: 16),
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
                const SizedBox(height: 4),
                Text(
                  isFailed ? 'Failed to download' : 'Cancelled',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isFailed ? Colors.red[300] : Colors.orange[300],
                  ),
                ),
              ],
            ),
          ),
          if (isFailed)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.primary),
              onPressed: () => controller.retryDownload(item),
              tooltip: 'Retry',
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.textMuted),
            onPressed: () => controller.deleteDownload(item),
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}
