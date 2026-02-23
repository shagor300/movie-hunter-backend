import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/storage_settings_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class StorageManagementScreen extends StatefulWidget {
  const StorageManagementScreen({super.key});

  @override
  State<StorageManagementScreen> createState() =>
      _StorageManagementScreenState();
}

class _StorageManagementScreenState extends State<StorageManagementScreen> {
  final StorageSettingsService _settings = Get.find<StorageSettingsService>();

  // Local state for sliders and switches before saving
  late bool smartDownloads;
  late bool deleteCompleted;
  late bool downloadNextEpisode;
  late bool customSchedule;
  late String scheduleFrom;
  late String scheduleTo;
  late double downloadSpeedLimit;
  late double storageLimit;

  @override
  void initState() {
    super.initState();
    // Initialize local state with current settings
    smartDownloads = _settings.isSmartDownloadsEnabled.value;
    deleteCompleted = _settings.deleteCompleted.value;
    downloadNextEpisode = _settings.downloadNextEpisode.value;
    customSchedule = _settings.customSchedule.value;
    scheduleFrom = _settings.scheduleFrom.value;
    scheduleTo = _settings.scheduleTo.value;
    downloadSpeedLimit = _settings.downloadSpeedLimit.value;
    storageLimit = _settings.storageLimit.value;
  }

  void _saveChanges() {
    _settings.isSmartDownloadsEnabled.value = smartDownloads;
    _settings.deleteCompleted.value = deleteCompleted;
    _settings.downloadNextEpisode.value = downloadNextEpisode;
    _settings.customSchedule.value = customSchedule;
    _settings.scheduleFrom.value = scheduleFrom;
    _settings.scheduleTo.value = scheduleTo;
    _settings.downloadSpeedLimit.value = downloadSpeedLimit;
    _settings.storageLimit.value = storageLimit;

    _settings.saveSettings();

    Get.back();
    Get.snackbar(
      'Settings Saved',
      'Storage and download preferences have been updated.',
      backgroundColor: Colors.green.withValues(alpha: 0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      // Create a transparent app bar
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
            // Example circular storage graphic here (placeholder since we have the functional StorageDeviceCard in downloads_screen)
            _buildChartMock(),

            const SizedBox(height: 24),

            // Settings Card
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF151928), // Dark slate surface
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Smart Downloads Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Smart Downloads',
                              style: AppTextStyles.titleMedium.copyWith(
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Manage storage automatically',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Smart downloads manages your downloaded episodes so you don\'t run out of space.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSwitchTile(
                    title: 'Delete Completed',
                    subtitle: 'Remove episodes after watching',
                    value: deleteCompleted,
                    onChanged: (val) => setState(() => deleteCompleted = val),
                  ),

                  _buildSwitchTile(
                    title: 'Download Next Episode',
                    subtitle: 'Auto-start next episode on Wi-Fi',
                    value: downloadNextEpisode,
                    onChanged: (val) =>
                        setState(() => downloadNextEpisode = val),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: Colors.white10, height: 1),
                  ),

                  // Custom Schedule
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Custom Schedule',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Download during specific hours',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: customSchedule,
                        onChanged: (val) =>
                            setState(() => customSchedule = val),
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppColors.primary,
                        inactiveThumbColor: AppColors.textMuted,
                        inactiveTrackColor: Colors.white10,
                      ),
                    ],
                  ),

                  if (customSchedule) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTimeDropdown(
                            'FROM',
                            scheduleFrom,
                            (v) => setState(() => scheduleFrom = v!),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.textMuted,
                            size: 16,
                          ),
                        ),
                        Expanded(
                          child: _buildTimeDropdown(
                            'TO',
                            scheduleTo,
                            (v) => setState(() => scheduleTo = v!),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(color: Colors.white10, height: 1),
                  ),

                  // Download Speed Limit
                  _buildSlider(
                    title: 'Download Speed Limit',
                    valueString: downloadSpeedLimit == 0
                        ? 'Unlimited'
                        : '${downloadSpeedLimit.toStringAsFixed(1)} MB/s',
                    value: downloadSpeedLimit,
                    min: 0,
                    max: 10,
                    divisions: 20,
                    minLabel: 'Unlimited',
                    maxLabel: '10 MB/s',
                    onChanged: (val) =>
                        setState(() => downloadSpeedLimit = val),
                  ),

                  const SizedBox(height: 24),

                  // Storage Limit
                  _buildSlider(
                    title: 'Storage Limit',
                    valueString: '${storageLimit.toInt()} GB',
                    value: storageLimit,
                    min: 1,
                    max: 64,
                    divisions: 63,
                    minLabel: '1 GB',
                    maxLabel: 'Max',
                    onChanged: (val) => setState(() => storageLimit = val),
                  ),

                  const SizedBox(height: 32),

                  // Action Buttons
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
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Save Changes',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
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
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: Colors.white10,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDropdown(
    String label,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textMuted,
                size: 18,
              ),
              dropdownColor: AppColors.surfaceLight,
              items:
                  [
                        '12:00 AM',
                        '01:00 AM',
                        '02:00 AM',
                        '06:00 AM',
                        '07:00 AM',
                        '08:00 AM',
                        '10:00 PM',
                      ]
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t, style: AppTextStyles.bodyMedium),
                        ),
                      )
                      .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
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
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              valueString,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: Colors.white10,
            thumbColor: Colors.white,
            trackHeight: 4,
            overlayColor: AppColors.primary.withValues(alpha: 0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
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

  Widget _buildChartMock() {
    return Center(
      child: Container(
        width: 180,
        height: 180,
        margin: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const SweepGradient(
            colors: [
              Color(0xFF4338CA),
              Color(0xFF06B6D4),
              Color(0xFF8B5CF6),
              Color(0xFF1E293B),
            ],
            stops: [0.0, 0.4, 0.6, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.2),
              blurRadius: 40,
              spreadRadius: -10,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.backgroundDark,
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
                      '34.2',
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
                  'of 128 GB',
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
}
