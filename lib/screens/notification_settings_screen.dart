import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../utils/stitch_design_system.dart';

import '../controllers/notification_controller.dart';
import '../controllers/theme_controller.dart';
import '../services/notification_service.dart';

/// Detailed notification preferences screen.
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nc = Get.find<NotificationController>();
    final tc = Get.find<ThemeController>();
    final accent = tc.accentColor;

    return Scaffold(
      backgroundColor: StitchColors.bgDark,
      appBar: AppBar(
        backgroundColor: StitchColors.bgDark,
        elevation: 0,
        title: Text(
          'Notifications',
          style: StitchText.heading(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Obx(() {
        final s = nc.settings.value;
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // ─── Master Toggle ─────────────────────
            _Card(
              children: [
                _MasterToggle(
                  enabled: s.masterEnabled,
                  accent: accent,
                  onChanged: (v) {
                    HapticFeedback.lightImpact();
                    nc.toggleMaster(v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ─── Download Notifications ────────────
            _Header(icon: Icons.download_rounded, title: 'Downloads'),
            const SizedBox(height: 8),
            _Card(
              children: [
                _CategoryTile(
                  icon: Icons.check_circle_outline,
                  title: 'Download Complete',
                  description: 'When a file finishes downloading',
                  value: s.downloadComplete,
                  enabled: s.masterEnabled,
                  accent: accent,
                  onChanged: (v) => nc.toggle('downloadComplete', v),
                  onTest: () => NotificationService.instance.showPreview(
                    'downloadComplete',
                  ),
                ),
                const _Divider(),
                _CategoryTile(
                  icon: Icons.error_outline,
                  title: 'Download Failed',
                  description: 'When a download encounters an error',
                  value: s.downloadFailed,
                  enabled: s.masterEnabled,
                  accent: accent,
                  onChanged: (v) => nc.toggle('downloadFailed', v),
                  onTest: () => NotificationService.instance.showPreview(
                    'downloadFailed',
                  ),
                ),
                const _Divider(),
                _CategoryTile(
                  icon: Icons.sd_storage_outlined,
                  title: 'Storage Warnings',
                  description: 'Alert when storage space is low',
                  value: s.storageLow,
                  enabled: s.masterEnabled,
                  accent: accent,
                  onChanged: (v) => nc.toggle('storageLow', v),
                  onTest: () =>
                      NotificationService.instance.showPreview('storageLow'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ─── App Updates ───────────────────────
            _Header(icon: Icons.system_update_outlined, title: 'App Updates'),
            const SizedBox(height: 8),
            _Card(
              children: [
                _CategoryTile(
                  icon: Icons.new_releases_outlined,
                  title: 'Update Available',
                  description: 'When a new version is released',
                  value: s.appUpdate,
                  enabled: s.masterEnabled,
                  accent: accent,
                  onChanged: (v) => nc.toggle('appUpdate', v),
                  onTest: () =>
                      NotificationService.instance.showPreview('appUpdate'),
                ),
                const _Divider(),
                _CategoryTile(
                  icon: Icons.security_outlined,
                  title: 'Critical Updates',
                  description: 'Security and critical fixes (always on)',
                  value: true,
                  enabled: false, // cannot disable
                  accent: Colors.grey,
                  onChanged: (_) {},
                  locked: true,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ─── Content Updates ───────────────────
            _Header(icon: Icons.movie_outlined, title: 'Content'),
            const SizedBox(height: 8),
            _Card(
              children: [
                _CategoryTile(
                  icon: Icons.fiber_new_outlined,
                  title: 'Daily New Movies',
                  description: 'Morning update on newly added movies',
                  value: s.newMoviesDaily,
                  enabled: s.masterEnabled,
                  accent: accent,
                  onChanged: (v) => nc.toggle('newMoviesDaily', v),
                  onTest: () => NotificationService.instance.showPreview(
                    'newMoviesDaily',
                  ),
                ),
                if (s.newMoviesDaily && s.masterEnabled)
                  _TimePicker(
                    label: 'Daily notification time',
                    hour: s.dailyNotifHour,
                    minute: s.dailyNotifMinute,
                    accent: accent,
                    onChanged: (t) => nc.setDailyTime(t),
                  ),
                const _Divider(),
                _CategoryTile(
                  icon: Icons.trending_up,
                  title: 'Weekly Trending',
                  description: 'Top trending movies every Saturday',
                  value: s.weeklyTrending,
                  enabled: s.masterEnabled,
                  accent: accent,
                  onChanged: (v) => nc.toggle('weeklyTrending', v),
                  onTest: () => NotificationService.instance.showPreview(
                    'weeklyTrending',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ─── Watchlist ─────────────────────────
            _Header(icon: Icons.bookmark_outline, title: 'Watchlist'),
            const SizedBox(height: 8),
            _Card(
              children: [
                _CategoryTile(
                  icon: Icons.movie_creation_outlined,
                  title: 'Movie Available',
                  description: 'When a watchlist movie becomes available',
                  value: s.watchlistAvailable,
                  enabled: s.masterEnabled,
                  accent: accent,
                  onChanged: (v) => nc.toggle('watchlistAvailable', v),
                  onTest: () => NotificationService.instance.showPreview(
                    'watchlistAvailable',
                  ),
                ),
                const _Divider(),
                _CategoryTile(
                  icon: Icons.high_quality_outlined,
                  title: 'Quality Upgraded',
                  description: 'When a higher quality becomes available',
                  value: s.qualityUpgraded,
                  enabled: s.masterEnabled,
                  accent: accent,
                  onChanged: (v) => nc.toggle('qualityUpgraded', v),
                  onTest: () => NotificationService.instance.showPreview(
                    'qualityUpgraded',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ─── Playback ──────────────────────────
            _Header(icon: Icons.play_circle_outline, title: 'Playback'),
            const SizedBox(height: 8),
            _Card(
              children: [
                _CategoryTile(
                  icon: Icons.replay,
                  title: 'Resume Watching',
                  description: 'Remind about unfinished movies',
                  value: s.resumeWatching,
                  enabled: s.masterEnabled,
                  accent: accent,
                  onChanged: (v) => nc.toggle('resumeWatching', v),
                  onTest: () => NotificationService.instance.showPreview(
                    'resumeWatching',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ─── System ────────────────────────────
            _Header(icon: Icons.settings_outlined, title: 'System'),
            const SizedBox(height: 8),
            _Card(
              children: [
                _CategoryTile(
                  icon: Icons.sync,
                  title: 'Sync Complete',
                  description: 'When background sync finishes',
                  value: s.syncComplete,
                  enabled: s.masterEnabled,
                  accent: accent,
                  onChanged: (v) => nc.toggle('syncComplete', v),
                ),
                const _Divider(),
                _CategoryTile(
                  icon: Icons.cleaning_services_outlined,
                  title: 'Cache Cleared',
                  description: 'When cache cleanup completes',
                  value: s.cacheCleared,
                  enabled: s.masterEnabled,
                  accent: accent,
                  onChanged: (v) => nc.toggle('cacheCleared', v),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ─── Quiet Hours ───────────────────────
            _Header(
              icon: Icons.do_not_disturb_on_outlined,
              title: 'Quiet Hours',
            ),
            const SizedBox(height: 8),
            _Card(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.nightlight_round,
                      color: Colors.white38,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enable Quiet Hours',
                            style: StitchText.body(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Silence notifications during set times',
                            style: StitchText.caption(
                              color: StitchColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: s.quietHoursEnabled,
                      onChanged: (v) {
                        HapticFeedback.lightImpact();
                        nc.toggleQuietHours(v);
                      },
                      activeTrackColor: StitchColors.emerald,
                    ),
                  ],
                ),
                if (s.quietHoursEnabled) ...[
                  const SizedBox(height: 8),
                  _TimePicker(
                    label: 'Start',
                    hour: s.quietStartHour,
                    minute: s.quietStartMinute,
                    accent: accent,
                    onChanged: (t) => nc.setQuietStart(t),
                  ),
                  const SizedBox(height: 4),
                  _TimePicker(
                    label: 'End',
                    hour: s.quietEndHour,
                    minute: s.quietEndMinute,
                    accent: accent,
                    onChanged: (t) => nc.setQuietEnd(t),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 40),
          ],
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// PRIVATE WIDGETS
// ═══════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  final IconData icon;
  final String title;
  const _Header({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 18),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: StitchText.heading(
              color: StitchColors.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ).copyWith(letterSpacing: 1.2),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StitchColors.glassBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StitchColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext c) =>
      const Divider(color: StitchColors.glassBorder, height: 24);
}

class _MasterToggle extends StatelessWidget {
  final bool enabled;
  final Color accent;
  final ValueChanged<bool> onChanged;
  const _MasterToggle({
    required this.enabled,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: enabled
                  ? [accent, accent.withValues(alpha: 0.6)]
                  : [Colors.white12, Colors.white10],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            enabled ? Icons.notifications_active : Icons.notifications_off,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'All Notifications',
                style: StitchText.body(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                enabled
                    ? 'Notifications are enabled'
                    : 'All notifications silenced',
                style: StitchText.caption(
                  color: enabled
                      ? StitchColors.emerald
                      : StitchColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: enabled,
          onChanged: onChanged,
          activeTrackColor: StitchColors.emerald,
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final bool enabled;
  final Color accent;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onTest;
  final bool locked;

  const _CategoryTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.enabled,
    required this.accent,
    required this.onChanged,
    this.onTest,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAlpha = enabled ? 1.0 : 0.4;

    return Opacity(
      opacity: effectiveAlpha,
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: StitchText.body(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (locked) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.lock,
                        color: StitchColors.textTertiary,
                        size: 14,
                      ),
                    ],
                  ],
                ),
                Text(
                  description,
                  style: StitchText.caption(color: StitchColors.textTertiary),
                ),
              ],
            ),
          ),
          if (onTest != null)
            IconButton(
              icon: const Icon(Icons.preview_outlined, size: 18),
              color: Colors.white24,
              tooltip: 'Preview',
              onPressed: enabled ? onTest : null,
              splashRadius: 18,
            ),
          Switch(
            value: value,
            onChanged: enabled && !locked ? onChanged : null,
            activeTrackColor: StitchColors.emerald,
          ),
        ],
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  final String label;
  final int hour;
  final int minute;
  final Color accent;
  final ValueChanged<TimeOfDay> onChanged;

  const _TimePicker({
    required this.label,
    required this.hour,
    required this.minute,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay(hour: hour, minute: minute);
    final formatted = time.format(context);

    return Padding(
      padding: const EdgeInsets.only(left: 32, top: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: time,
            builder: (c, child) => Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: ColorScheme.dark(primary: accent),
              ),
              child: child!,
            ),
          );
          if (picked != null) onChanged(picked);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Row(
            children: [
              Icon(Icons.access_time, size: 16, color: accent),
              const SizedBox(width: 8),
              Text(
                label,
                style: StitchText.caption(
                  color: StitchColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: StitchColors.emerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  formatted,
                  style: StitchText.body(
                    color: StitchColors.emerald,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
