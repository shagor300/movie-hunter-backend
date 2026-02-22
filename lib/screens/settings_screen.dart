import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/notification_controller.dart';
import '../theme/theme_controller.dart';
import '../controllers/watchlist_controller.dart';
import '../controllers/update_controller.dart';
import '../theme/theme_config.dart' as config;
import 'notification_settings_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'settings/appearance_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tc = Get.find<ThemeController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Settings',
          style: AppTextStyles.headingLarge.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Obx(() {
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // ═══════════════════════════════════════════
            // APPEARANCE
            // ═══════════════════════════════════════════
            _SectionHeader(title: 'Appearance', icon: Icons.palette_outlined),
            const SizedBox(height: 8),

            _SettingsCard(
              children: [
                _ActionTile(
                  icon: Icons.color_lens,
                  title: 'Theme & Accent',
                  subtitle: 'Manage theme mode and custom accent colors',
                  iconColor: tc.accentColor,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AppearanceSettings(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ═══════════════════════════════════════════
            // LAYOUT
            // ═══════════════════════════════════════════
            _SectionHeader(title: 'Layout', icon: Icons.grid_view_rounded),
            const SizedBox(height: 8),

            _SettingsCard(
              children: [
                _ToggleTile(
                  icon: Icons.grid_on,
                  title: 'Grid Layout',
                  subtitle: 'Show movies in a grid',
                  value: tc.useGridLayout,
                  accentColor: tc.accentColor,
                  onChanged: (_) => tc.toggleGridLayout(),
                ),
                const Divider(color: Colors.white10, height: 24),
                _ToggleTile(
                  icon: Icons.rounded_corner,
                  title: 'Rounded Posters',
                  subtitle: 'Apply rounded corners to movie posters',
                  value: tc.roundedPosters,
                  accentColor: tc.accentColor,
                  onChanged: (_) => tc.toggleRoundedPosters(),
                ),
                const Divider(color: Colors.white10, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SettingsLabel('Grid Columns'),
                    Row(
                      children: List.generate(3, (i) {
                        final count = i + 2;
                        final isSelected = tc.gridColumnCount == count;
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: GestureDetector(
                            onTap: () => tc.setGridColumnCount(count),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? tc.accentColor.withValues(alpha: 0.2)
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? tc.accentColor
                                      : Colors.white10,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '$count',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textMuted,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ═══════════════════════════════════════════
            // NOTIFICATIONS
            // ═══════════════════════════════════════════
            _SectionHeader(
              title: 'Notifications',
              icon: Icons.notifications_outlined,
            ),
            const SizedBox(height: 8),

            Builder(
              builder: (_) {
                final nc = Get.find<NotificationController>();
                return Obx(() {
                  final s = nc.settings.value;
                  return _SettingsCard(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: s.masterEnabled
                                    ? [
                                        tc.accentColor,
                                        tc.accentColor.withValues(alpha: 0.6),
                                      ]
                                    : [Colors.white12, Colors.white10],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              s.masterEnabled
                                  ? Icons.notifications_active
                                  : Icons.notifications_off,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Notifications',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  s.masterEnabled ? 'Enabled' : 'Disabled',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: s.masterEnabled,
                            onChanged: (v) {
                              HapticFeedback.lightImpact();
                              nc.toggleMaster(v);
                            },
                            activeThumbColor: tc.accentColor,
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white10, height: 24),
                      _ActionTile(
                        icon: Icons.tune,
                        title: 'Notification Preferences',
                        subtitle: 'Configure individual notification types',
                        iconColor: tc.accentColor,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationSettingsScreen(),
                          ),
                        ),
                      ),
                    ],
                  );
                });
              },
            ),

            const SizedBox(height: 24),

            // ═══════════════════════════════════════════
            // DATA & CACHE
            // ═══════════════════════════════════════════
            _SectionHeader(title: 'Data & Cache', icon: Icons.storage_rounded),
            const SizedBox(height: 8),

            _SettingsCard(
              children: [
                _ActionTile(
                  icon: Icons.cached,
                  title: 'Clear Movie Cache',
                  subtitle: 'Remove locally cached movie data',
                  iconColor: Colors.orangeAccent,
                  onTap: () => _confirmAction(
                    context,
                    title: 'Clear Movie Cache?',
                    message:
                        'This will remove all cached movie data. The app will re-fetch from the server on next launch.',
                    onConfirm: () async {
                      final box = await Hive.openBox('homepage_movies');
                      await box.clear();
                      // Also clear image cache
                      PaintingBinding.instance.imageCache.clear();
                      PaintingBinding.instance.imageCache.clearLiveImages();
                      Get.snackbar(
                        '✅ Cache Cleared',
                        'Movie & image cache has been cleared',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.85,
                        ),
                        colorText: Colors.black,
                        margin: const EdgeInsets.all(20),
                        duration: const Duration(seconds: 2),
                      );
                    },
                  ),
                ),
                const Divider(color: AppColors.surfaceLight, height: 20),
                _ActionTile(
                  icon: Icons.bookmark_remove_outlined,
                  title: 'Clear Watchlist',
                  subtitle: 'Remove all movies from your watchlist',
                  iconColor: AppColors.error,
                  onTap: () => _confirmAction(
                    context,
                    title: 'Clear Watchlist?',
                    message:
                        'This will permanently delete all movies from your watchlist.',
                    onConfirm: () async {
                      final box = await Hive.openBox('watchlist');
                      await box.clear();
                      // Refresh WatchlistController
                      try {
                        Get.find<WatchlistController>().allMovies.clear();
                      } catch (_) {}
                      Get.snackbar(
                        '✅ Watchlist Cleared',
                        'All watchlist items removed',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.85,
                        ),
                        colorText: Colors.black,
                        margin: const EdgeInsets.all(20),
                        duration: const Duration(seconds: 2),
                      );
                    },
                  ),
                ),
                const Divider(color: AppColors.surfaceLight, height: 20),
                _ActionTile(
                  icon: Icons.delete_sweep_outlined,
                  title: 'Clear Download History',
                  subtitle: 'Remove download records (files remain)',
                  iconColor: const Color(0xFFF59E0B),
                  onTap: () => _confirmAction(
                    context,
                    title: 'Clear Download History?',
                    message:
                        'This will clear the download history. Downloaded files will not be deleted.',
                    onConfirm: () async {
                      final box = await Hive.openBox('downloads');
                      await box.clear();
                      Get.snackbar(
                        '✅ History Cleared',
                        'Download history has been cleared',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.85,
                        ),
                        colorText: Colors.black,
                        margin: const EdgeInsets.all(20),
                        duration: const Duration(seconds: 2),
                      );
                    },
                  ),
                ),
                const Divider(color: AppColors.surfaceLight, height: 20),
                _ActionTile(
                  icon: Icons.restart_alt,
                  title: 'Reset All Settings',
                  subtitle: 'Restore all settings to default',
                  iconColor: AppColors.error,
                  onTap: () => _confirmAction(
                    context,
                    title: 'Reset All Settings?',
                    message:
                        'This will restore theme, layout, and all preferences to their default values.',
                    onConfirm: () {
                      tc.setThemeMode(
                        config.AppThemeMode.dark,
                      ); // theme_config.dart enum
                      tc.setAccentColorByKey('mint_green');
                      tc.setFontSize(14.0);
                      tc.setGridColumnCount(2);
                      if (!tc.useGridLayout) tc.toggleGridLayout();
                      if (!tc.roundedPosters) tc.toggleRoundedPosters();
                      Get.snackbar(
                        '✅ Settings Reset',
                        'All settings restored to default',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.85,
                        ),
                        colorText: Colors.black,
                        margin: const EdgeInsets.all(20),
                        duration: const Duration(seconds: 2),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ═══════════════════════════════════════════
            // ABOUT
            // ═══════════════════════════════════════════
            _SectionHeader(title: 'About', icon: Icons.info_outline),
            const SizedBox(height: 8),

            _SettingsCard(
              children: [
                _ActionTile(
                  icon: Icons.movie_filter,
                  title: 'MovieHub',
                  subtitle: 'Version 1.0.0',
                  iconColor: Colors.blueAccent,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1A2E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Row(
                          children: [
                            Icon(
                              Icons.movie_filter,
                              color: tc.accentColor,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'MovieHub v1.0.0',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "What's New:",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...[
                                'Phase 3: Experience Screens (Stitch Redesign)',
                                'Phase 2: Home Shell & Core Tabs',
                                'Phase 1: Theme & Entry Screens',
                                'Personalized For You tab with 20+ sections',
                                'Voice search support',
                                'Grid & list view toggle',
                                'Customizable themes & accent colors',
                                'Smart notification system',
                                'Download manager with progress tracking',
                                'Watchlist with categories',
                                'Video player with resume support',
                              ].map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '• ',
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          item,
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                                color: AppColors.textSecondary,
                                                fontSize: 13,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    try {
                                      Get.find<UpdateController>()
                                          .checkForUpdate();
                                    } catch (_) {}
                                  },
                                  icon: const Icon(
                                    Icons.system_update,
                                    size: 18,
                                  ),
                                  label: Text(
                                    'Check for Updates',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style:
                                      ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ).copyWith(
                                        elevation: WidgetStateProperty.all(0),
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Close',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(color: Colors.white10, height: 20),
                _ActionTile(
                  icon: Icons.code,
                  title: 'Source Code',
                  subtitle: 'View on GitHub',
                  iconColor: Colors.white70,
                  onTap: () async {
                    final uri = Uri.parse(
                      'https://github.com/shagor300/movie-hunter-backend',
                    );
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
                const Divider(color: Colors.white10, height: 20),
                _ActionTile(
                  icon: Icons.person_outline,
                  title: 'Developer',
                  subtitle: 'Shagor',
                  iconColor: Colors.purpleAccent,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1A2E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 8),
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: tc.accentColor,
                              child: Text(
                                'S',
                                style: GoogleFonts.poppins(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Shagor',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'App Developer',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white38,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.email_outlined,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () {
                                    launchUrl(
                                      Uri.parse('mailto:shagor300@gmail.com'),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.code,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () {
                                    launchUrl(
                                      Uri.parse('https://github.com/shagor300'),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Close',
                              style: GoogleFonts.inter(color: Colors.white60),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Footer
            Center(
              child: Text(
                'Made with ❤️ for movie lovers',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        );
      }),
    );
  }

  void _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: AppTextStyles.headingLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ).copyWith(elevation: WidgetStateProperty.all(0)),
            child: Text(
              'Confirm',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Reusable Widgets
// ═══════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 16, bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: AppTextStyles.headingLarge
                .copyWith(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                )
                .copyWith(letterSpacing: 1.2),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class _SettingsLabel extends StatelessWidget {
  final String text;
  const _SettingsLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.bodyMedium.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Color accentColor;
  final ValueChanged<bool> onChanged;
  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primary,
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.surfaceLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
