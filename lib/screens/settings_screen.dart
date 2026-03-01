import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/notification_controller.dart';
import '../theme/theme_controller.dart';
import '../controllers/update_controller.dart';
import 'notification_settings_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../services/app_lock_service.dart';
import 'settings/appearance_settings.dart';
import 'settings/app_lock_settings_screen.dart';
import 'settings/layout_settings_screen.dart';
import 'settings/data_cache_settings_screen.dart';
import 'request_movie_screen.dart';
import 'collections_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tc = Get.find<ThemeController>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                Obx(() {
                  final tcInner = Get.find<ThemeController>();
                  return _ActionTile(
                    icon: Icons.dashboard_customize_rounded,
                    title: 'Layout & Display',
                    subtitle:
                        '${tcInner.useGridLayout ? 'Grid' : 'List'} • ${tcInner.gridColumnCount} columns • ${tcInner.roundedPosters ? 'Rounded' : 'Sharp'}',
                    iconColor: tc.accentColor,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LayoutSettingsScreen(),
                      ),
                    ),
                  );
                }),
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
            // MORE FEATURES
            // ═══════════════════════════════════════════
            _SectionHeader(title: 'More', icon: Icons.auto_awesome),
            const SizedBox(height: 8),

            _SettingsCard(
              children: [
                _ActionTile(
                  icon: Icons.movie_filter,
                  title: 'Request a Movie',
                  subtitle: "Can't find a movie? Request it here!",
                  iconColor: Colors.amber,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RequestMovieScreen(),
                    ),
                  ),
                ),
                const Divider(color: Colors.white10, height: 24),
                _ActionTile(
                  icon: Icons.collections_bookmark,
                  title: 'My Collections',
                  subtitle: 'Create and manage movie collections',
                  iconColor: Colors.deepPurpleAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CollectionsScreen(),
                    ),
                  ),
                ),
              ],
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
                  icon: Icons.storage_rounded,
                  title: 'Data & Cache',
                  subtitle: 'Clear cache, watchlist, download history',
                  iconColor: Colors.orangeAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DataCacheSettingsScreen(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ═══════════════════════════════════════════
            // SECURITY
            // ═══════════════════════════════════════════
            _SectionHeader(title: 'Security', icon: Icons.security_outlined),
            const SizedBox(height: 8),

            _SettingsCard(
              children: [
                _ActionTile(
                  icon: Icons.lock_outline,
                  title: 'App Lock',
                  subtitle: AppLockService.instance.isLockEnabled
                      ? 'Enabled • ${AppLockService.instance.lockType == AppLockType.pin
                            ? 'PIN'
                            : AppLockService.instance.lockType == AppLockType.biometric
                            ? 'Biometric'
                            : 'PIN + Biometric'}'
                      : 'Off',
                  iconColor: tc.accentColor,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AppLockSettingsScreen(),
                      ),
                    );
                    // Rebuild to update subtitle
                    (context as Element).markNeedsBuild();
                  },
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
                  title: 'FlixHub',
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
                              'FlixHub v1.0.0',
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
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.primary,
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
                const Divider(color: Colors.white10, height: 20),
                _ActionTile(
                  icon: Icons.info_outline,
                  title: 'About FlixHub',
                  subtitle: 'Version Info & Legal',
                  iconColor: Colors.white70,
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
                            const SizedBox(height: 16),
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.05),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                                image: const DecorationImage(
                                  image: AssetImage(
                                    'assets/images/app_logo.png',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'FlixHub',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Obx(() {
                              final uc = Get.find<UpdateController>();
                              final version =
                                  uc.updateInfo.value?.latestVersionName ??
                                  "1.0.0";
                              return Text(
                                'Version $version',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white54,
                                ),
                              );
                            }),
                            const SizedBox(height: 24),
                            Text(
                              'FlixHub is an ad-free movie download platform. Content is fetched from public sources and is not hosted on our servers.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white38,
                                height: 1.5,
                              ),
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
    final tc = Get.find<ThemeController>();
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 16, bottom: 8),
      child: Row(
        children: [
          Obx(() => Icon(icon, color: tc.accentColor, size: 18)),
          const SizedBox(width: 8),
          Obx(
            () => Text(
              title.toUpperCase(),
              style: AppTextStyles.headingLarge
                  .copyWith(
                    color: tc.accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  )
                  .copyWith(letterSpacing: 1.2),
            ),
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
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
