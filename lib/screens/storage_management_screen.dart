import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/storage_settings_service.dart';
import '../controllers/download_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_controller.dart';

class StorageManagementScreen extends StatefulWidget {
  const StorageManagementScreen({super.key});

  @override
  State<StorageManagementScreen> createState() =>
      _StorageManagementScreenState();
}

class _StorageManagementScreenState extends State<StorageManagementScreen> {
  final StorageSettingsService _settings = Get.find<StorageSettingsService>();

  // Local state mirrors
  late bool wifiOnly;
  late int maxSimultaneous;
  late bool autoRetry;
  late double speedLimit;
  late double storageLimit;

  // Real storage data
  double _totalStorageGb = 0;
  double _freeStorageGb = 0;
  double _appStorageMb = 0;
  bool _loadingStorage = true;

  @override
  void initState() {
    super.initState();
    wifiOnly = _settings.wifiOnlyDownload.value;
    maxSimultaneous = _settings.maxSimultaneousDownloads.value;
    autoRetry = _settings.autoRetryFailed.value;
    speedLimit = _settings.downloadSpeedLimit.value;
    storageLimit = _settings.storageLimit.value;
    _loadRealStorage();
  }

  Future<void> _loadRealStorage() async {
    try {
      final diskSpace = DiskSpacePlus();
      final free = await diskSpace.getFreeDiskSpace ?? 0;
      final total = await diskSpace.getTotalDiskSpace ?? 0;

      // Calculate app download folder size
      double appMb = 0;
      try {
        final downloadDir = Platform.isAndroid
            ? Directory('/storage/emulated/0/Download/FlixHub')
            : null;
        if (downloadDir != null && await downloadDir.exists()) {
          await for (final entity in downloadDir.list(
            recursive: true,
            followLinks: false,
          )) {
            if (entity is File) {
              appMb += await entity.length() / (1024 * 1024);
            }
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _freeStorageGb = free / 1024;
          _totalStorageGb = total / 1024;
          _appStorageMb = appMb;
          _loadingStorage = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Failed to read storage: $e');
      if (mounted) setState(() => _loadingStorage = false);
    }
  }

  void _saveChanges() {
    _settings.wifiOnlyDownload.value = wifiOnly;
    _settings.maxSimultaneousDownloads.value = maxSimultaneous;
    _settings.autoRetryFailed.value = autoRetry;
    _settings.downloadSpeedLimit.value = speedLimit;
    _settings.storageLimit.value = storageLimit;
    _settings.saveSettings();

    Get.back();
    final tc = Get.find<ThemeController>();
    Get.snackbar(
      '✅ Settings Saved',
      'Storage and download preferences updated.',
      backgroundColor: tc.accentColor.withValues(alpha: 0.9),
      colorText: Colors.black,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.check_circle, color: Colors.black),
    );
  }

  Future<void> _clearDownloadedFiles() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete All Downloads?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This will permanently delete all downloaded movie files from your device.',
          style: TextStyle(color: Colors.white60, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete All',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final downloadDir = Platform.isAndroid
            ? Directory('/storage/emulated/0/Download/FlixHub')
            : null;
        if (downloadDir != null && await downloadDir.exists()) {
          await downloadDir.delete(recursive: true);
          await downloadDir.create(recursive: true);
        }
        // Clear Hive download history
        try {
          final box = await Hive.openBox('downloads');
          await box.clear();
          Get.find<DownloadController>().downloads.clear();
        } catch (_) {}

        _loadRealStorage();
        Get.snackbar(
          '✅ Downloads Cleared',
          'All downloaded files have been deleted.',
          backgroundColor: Colors.green.withValues(alpha: 0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
      } catch (e) {
        Get.snackbar(
          '❌ Error',
          'Failed to delete downloads: $e',
          backgroundColor: Colors.red.withValues(alpha: 0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = Get.find<ThemeController>();
    final accent = tc.accentColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Storage & Downloads',
          style: AppTextStyles.titleMedium.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ═══ STORAGE CHART ═══
            _buildStorageChart(accent),
            const SizedBox(height: 8),

            // ═══ STORAGE BREAKDOWN ═══
            _buildStorageBreakdown(accent),
            const SizedBox(height: 24),

            // ═══ DOWNLOAD SETTINGS ═══
            _buildSectionHeader(
              'Download Settings',
              Icons.download_rounded,
              accent,
            ),
            const SizedBox(height: 8),
            _buildCard([
              _buildSwitchTile(
                title: 'Wi-Fi Only Downloads',
                subtitle: 'Only download when connected to Wi-Fi',
                icon: Icons.wifi,
                value: wifiOnly,
                accent: accent,
                onChanged: (val) => setState(() => wifiOnly = val),
              ),
              const Divider(color: Colors.white10, height: 24),
              _buildSwitchTile(
                title: 'Auto-Retry Failed',
                subtitle: 'Automatically retry failed downloads',
                icon: Icons.refresh_rounded,
                value: autoRetry,
                accent: accent,
                onChanged: (val) => setState(() => autoRetry = val),
              ),
              const Divider(color: Colors.white10, height: 24),
              _buildCounterTile(
                title: 'Simultaneous Downloads',
                subtitle: 'Maximum parallel downloads',
                icon: Icons.layers_rounded,
                value: maxSimultaneous,
                min: 1,
                max: 5,
                accent: accent,
                onChanged: (val) => setState(() => maxSimultaneous = val),
              ),
            ]),

            const SizedBox(height: 24),

            // ═══ LIMITS ═══
            _buildSectionHeader('Limits', Icons.speed_rounded, accent),
            const SizedBox(height: 8),
            _buildCard([
              _buildSlider(
                title: 'Download Speed Limit',
                valueString: speedLimit == 0
                    ? 'Unlimited'
                    : '${speedLimit.toStringAsFixed(1)} MB/s',
                value: speedLimit,
                min: 0,
                max: 10,
                divisions: 20,
                minLabel: 'Unlimited',
                maxLabel: '10 MB/s',
                accent: accent,
                onChanged: (val) => setState(() => speedLimit = val),
              ),
              const SizedBox(height: 24),
              _buildSlider(
                title: 'Storage Limit',
                valueString: '${storageLimit.toInt()} GB',
                value: storageLimit,
                min: 1,
                max: 64,
                divisions: 63,
                minLabel: '1 GB',
                maxLabel: '64 GB',
                accent: accent,
                onChanged: (val) => setState(() => storageLimit = val),
              ),
            ]),

            const SizedBox(height: 24),

            // ═══ DANGER ZONE ═══
            _buildSectionHeader(
              'Manage Storage',
              Icons.delete_sweep_outlined,
              Colors.redAccent,
            ),
            const SizedBox(height: 8),
            _buildCard([
              GestureDetector(
                onTap: _clearDownloadedFiles,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.delete_forever_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delete All Downloaded Files',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.redAccent,
                            ),
                          ),
                          Text(
                            _appStorageMb > 0
                                ? 'Free up ${_appStorageMb > 1024 ? '${(_appStorageMb / 1024).toStringAsFixed(1)} GB' : '${_appStorageMb.toStringAsFixed(0)} MB'}'
                                : 'Remove all movie files',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white24,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ]),

            const SizedBox(height: 32),

            // ═══ ACTION BUTTONS ═══
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Get.back(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.white10),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Save Changes',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151928),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Color accent,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (value ? accent : Colors.white12).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: value ? accent : AppColors.textMuted,
            size: 18,
          ),
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
        Switch(
          value: value,
          onChanged: (v) {
            HapticFeedback.lightImpact();
            onChanged(v);
          },
          activeThumbColor: Colors.white,
          activeTrackColor: accent,
          inactiveThumbColor: AppColors.textMuted,
          inactiveTrackColor: Colors.white10,
        ),
      ],
    );
  }

  Widget _buildCounterTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required int value,
    required int min,
    required int max,
    required Color accent,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: accent, size: 18),
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
        // Counter buttons
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _counterBtn(Icons.remove, value > min, () {
                HapticFeedback.lightImpact();
                onChanged(value - 1);
              }),
              Container(
                width: 36,
                alignment: Alignment.center,
                child: Text(
                  '$value',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: accent,
                    fontSize: 16,
                  ),
                ),
              ),
              _counterBtn(Icons.add, value < max, () {
                HapticFeedback.lightImpact();
                onChanged(value + 1);
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _counterBtn(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 16,
          color: enabled ? Colors.white : Colors.white24,
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String title,
    required String valueString,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String minLabel,
    required String maxLabel,
    required Color accent,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                valueString,
                style: AppTextStyles.bodySmall.copyWith(
                  color: accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accent,
            inactiveTrackColor: Colors.white10,
            thumbColor: Colors.white,
            trackHeight: 4,
            overlayColor: accent.withValues(alpha: 0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              minLabel,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            Text(
              maxLabel,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStorageChart(Color accent) {
    final freeStr = _freeStorageGb > 0
        ? _freeStorageGb.toStringAsFixed(1)
        : '...';
    final totalStr = _totalStorageGb > 0
        ? _totalStorageGb.toStringAsFixed(0)
        : '...';
    final usedPct = _totalStorageGb > 0
        ? ((_totalStorageGb - _freeStorageGb) / _totalStorageGb).clamp(0.0, 1.0)
        : 0.0;

    return Center(
      child: Container(
        width: 180,
        height: 180,
        margin: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [
              accent,
              accent.withValues(alpha: 0.6),
              const Color(0xFF8B5CF6),
              const Color(0xFF1E293B),
            ],
            stops: [0.0, usedPct * 0.6, usedPct * 0.9, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.2),
              blurRadius: 40,
              spreadRadius: -10,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Available',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      freeStr,
                      style: AppTextStyles.displayMedium.copyWith(
                        fontSize: 28,
                        height: 1.0,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2, left: 2),
                      child: Text(
                        'GB',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'of $totalStr GB',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStorageBreakdown(Color accent) {
    final appGb = _appStorageMb / 1024;
    final usedGb = _totalStorageGb - _freeStorageGb;
    final otherGb = (usedGb - appGb).clamp(0.0, double.infinity);

    return _buildCard([
      Text(
        'Storage Breakdown',
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      const SizedBox(height: 16),
      // Progress bar
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          height: 10,
          child: Row(
            children: [
              if (_totalStorageGb > 0) ...[
                Expanded(
                  flex: (appGb / _totalStorageGb * 100).round().clamp(1, 100),
                  child: Container(color: accent),
                ),
                Expanded(
                  flex: (otherGb / _totalStorageGb * 100).round().clamp(1, 100),
                  child: Container(color: const Color(0xFF8B5CF6)),
                ),
                Expanded(
                  flex: (_freeStorageGb / _totalStorageGb * 100).round().clamp(
                    1,
                    100,
                  ),
                  child: Container(color: Colors.white10),
                ),
              ] else
                Expanded(child: Container(color: Colors.white10)),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      // Legend
      _legendItem(
        accent,
        'FlixHub Downloads',
        _appStorageMb > 1024
            ? '${appGb.toStringAsFixed(1)} GB'
            : '${_appStorageMb.toStringAsFixed(0)} MB',
      ),
      const SizedBox(height: 8),
      _legendItem(
        const Color(0xFF8B5CF6),
        'Other Apps',
        '${otherGb.toStringAsFixed(1)} GB',
      ),
      const SizedBox(height: 8),
      _legendItem(
        Colors.white24,
        'Free Space',
        '${_freeStorageGb.toStringAsFixed(1)} GB',
      ),
    ]);
  }

  Widget _legendItem(Color color, String label, String value) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          _loadingStorage ? '...' : value,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
