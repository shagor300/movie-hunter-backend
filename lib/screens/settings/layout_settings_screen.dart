import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/theme_controller.dart';

/// Dedicated Layout settings screen — reached from Settings > Layout.
class LayoutSettingsScreen extends StatelessWidget {
  const LayoutSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tc = Get.find<ThemeController>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Theme.of(context).colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Layout',
          style: AppTextStyles.headingLarge.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: Obx(() {
        final accent = tc.accentColor;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          physics: const BouncingScrollPhysics(),
          children: [
            // ═══ PREVIEW ═══
            _buildPreview(context, tc, accent),
            const SizedBox(height: 24),

            // ═══ LAYOUT MODE ═══
            _buildSectionLabel(context, 'VIEW MODE', accent),
            const SizedBox(height: 8),
            _buildCard(context, [
              _buildSwitchTile(
                context,
                icon: Icons.grid_on_rounded,
                title: 'Grid Layout',
                subtitle: 'Display movies in a grid',
                value: tc.useGridLayout,
                accent: accent,
                onChanged: (_) => tc.toggleGridLayout(),
              ),
            ]),

            const SizedBox(height: 24),

            // ═══ POSTER STYLE ═══
            _buildSectionLabel(context, 'POSTER STYLE', accent),
            const SizedBox(height: 8),
            _buildCard(context, [
              _buildSwitchTile(
                context,
                icon: Icons.rounded_corner_rounded,
                title: 'Rounded Posters',
                subtitle: 'Apply rounded corners to movie posters',
                value: tc.roundedPosters,
                accent: accent,
                onChanged: (_) => tc.toggleRoundedPosters(),
              ),
            ]),

            const SizedBox(height: 24),

            // ═══ GRID COLUMNS ═══
            _buildSectionLabel(context, 'GRID COLUMNS', accent),
            const SizedBox(height: 8),
            _buildCard(context, [
              Text(
                'Choose how many columns to display in grid view',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: List.generate(3, (i) {
                  final count = i + 2;
                  final isSelected = tc.gridColumnCount == count;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: i > 0 ? 12 : 0),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          tc.setGridColumnCount(count);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 72,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accent.withValues(alpha: 0.15)
                                : Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? accent.withValues(alpha: 0.6)
                                  : Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.1),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Mini grid preview icon
                              _buildMiniGrid(
                                context,
                                count,
                                isSelected,
                                accent,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$count cols',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isSelected
                                      ? accent
                                      : AppColors.textMuted,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ]),

            const SizedBox(height: 32),

            // ═══ FONT SIZE ═══
            _buildSectionLabel(context, 'FONT SIZE', accent),
            const SizedBox(height: 8),
            _buildCard(context, [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Text Size',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${tc.fontSize.toInt()} sp',
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
                  inactiveTrackColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.1),
                  thumbColor: Colors.white,
                  trackHeight: 4,
                  overlayColor: accent.withValues(alpha: 0.2),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                ),
                child: Slider(
                  value: tc.fontSize,
                  min: 10,
                  max: 20,
                  divisions: 10,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    tc.setFontSize(v);
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Small',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    'Default',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Large',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ]),

            const SizedBox(height: 40),
          ],
        );
      }),
    );
  }

  // ═══════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════

  Widget _buildSectionLabel(BuildContext context, String text, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTextStyles.labelSmall.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.38),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color accent,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:
                (value
                        ? accent
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.12))
                    .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: value ? accent : AppColors.textMuted,
            size: 20,
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
          inactiveThumbColor: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.4),
          inactiveTrackColor: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ],
    );
  }

  Widget _buildMiniGrid(
    BuildContext context,
    int cols,
    bool isSelected,
    Color accent,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        cols,
        (i) => Container(
          width: 8,
          height: 12,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            color: isSelected
                ? accent.withValues(alpha: 0.6)
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context, ThemeController tc, Color accent) {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.1),
              blurRadius: 30,
              spreadRadius: -5,
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: _buildPreviewGrid(context, tc, accent),
      ),
    );
  }

  Widget _buildPreviewGrid(
    BuildContext context,
    ThemeController tc,
    Color accent,
  ) {
    final cols = tc.gridColumnCount;
    final rounded = tc.roundedPosters;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cols * 3,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
        childAspectRatio: 0.7,
      ),
      itemBuilder: (_, i) => Container(
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.15 + (i * 0.05).clamp(0.0, 0.3)),
          borderRadius: BorderRadius.circular(rounded ? 4 : 1),
          border: Border.all(color: accent.withValues(alpha: 0.2), width: 0.5),
        ),
      ),
    );
  }
}
