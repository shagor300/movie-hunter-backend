import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/theme_controller.dart';
import '../models/theme_preferences.dart';

class CustomizationScreen extends StatelessWidget {
  const CustomizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Customization',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        final prefs = controller.preferences.value;

        return ListView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          children: [
            // Theme Mode
            _buildSectionTitle('Theme Mode'),
            const SizedBox(height: 12),
            _buildThemeModeSelector(controller, prefs),

            const SizedBox(height: 32),

            // Accent Color
            _buildSectionTitle('Accent Color'),
            const SizedBox(height: 12),
            _buildAccentColorPicker(controller, prefs),

            const SizedBox(height: 32),

            // Font Size
            _buildSectionTitle('Font Size: ${prefs.fontSize.toInt()}pt'),
            const SizedBox(height: 12),
            _buildFontSizeSlider(controller, prefs),

            const SizedBox(height: 32),

            // Layout Options
            _buildSectionTitle('Layout'),
            const SizedBox(height: 12),
            _buildLayoutOptions(controller, prefs),

            const SizedBox(height: 32),

            // Preview
            _buildSectionTitle('Preview'),
            const SizedBox(height: 12),
            _buildPreview(controller, prefs),
          ],
        );
      }),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildThemeModeSelector(
    ThemeController controller,
    ThemePreferences prefs,
  ) {
    return Row(
      children: [
        _buildThemeOption(
          controller,
          prefs,
          mode: AppThemeMode.dark,
          label: 'Dark',
          icon: Icons.dark_mode,
          bgColor: const Color(0xFF0F0F1E),
        ),
        const SizedBox(width: 12),
        _buildThemeOption(
          controller,
          prefs,
          mode: AppThemeMode.amoled,
          label: 'AMOLED',
          icon: Icons.brightness_1,
          bgColor: Colors.black,
        ),
        const SizedBox(width: 12),
        _buildThemeOption(
          controller,
          prefs,
          mode: AppThemeMode.light,
          label: 'Light',
          icon: Icons.light_mode,
          bgColor: const Color(0xFFF5F5F5),
        ),
      ],
    );
  }

  Widget _buildThemeOption(
    ThemeController controller,
    ThemePreferences prefs, {
    required AppThemeMode mode,
    required String label,
    required IconData icon,
    required Color bgColor,
  }) {
    final isSelected = prefs.themeMode == mode;
    final accent = controller.accentColor;

    return Expanded(
      child: GestureDetector(
        onTap: () => controller.setThemeMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? accent : Colors.white10,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accent.withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? accent : Colors.white38, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: isSelected ? accent : Colors.white54,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccentColorPicker(
    ThemeController controller,
    ThemePreferences prefs,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(ThemeController.accentColors.length, (index) {
        final color = ThemeController.accentColors[index];
        final isSelected = prefs.accentColorIndex == index;

        return GestureDetector(
          onTap: () => controller.setAccentColor(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 24)
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildFontSizeSlider(
    ThemeController controller,
    ThemePreferences prefs,
  ) {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: controller.accentColor,
            inactiveTrackColor: Colors.white10,
            thumbColor: controller.accentColor,
            overlayColor: controller.accentColor.withOpacity(0.2),
          ),
          child: Slider(
            value: prefs.fontSize,
            min: 10,
            max: 20,
            divisions: 10,
            label: '${prefs.fontSize.toInt()}pt',
            onChanged: (value) => controller.setFontSize(value),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Aa',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
            ),
            Text(
              'Aa',
              style: GoogleFonts.inter(fontSize: 20, color: Colors.white38),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLayoutOptions(
    ThemeController controller,
    ThemePreferences prefs,
  ) {
    return Column(
      children: [
        // Grid/List toggle
        _buildSwitchTile(
          title: 'Grid Layout',
          subtitle: 'Show movies in a grid instead of a list',
          icon: prefs.useGridLayout ? Icons.grid_view : Icons.view_list,
          value: prefs.useGridLayout,
          onChanged: (_) => controller.toggleGridLayout(),
        ),
        const SizedBox(height: 12),

        // Grid columns (only show if grid is enabled)
        if (prefs.useGridLayout) ...[
          _buildColumnSelector(controller, prefs),
          const SizedBox(height: 12),
        ],

        // Rounded posters
        _buildSwitchTile(
          title: 'Rounded Posters',
          subtitle: 'Use rounded corners on movie posters',
          icon: prefs.roundedPosters ? Icons.rounded_corner : Icons.crop_square,
          value: prefs.roundedPosters,
          onChanged: (_) => controller.toggleRoundedPosters(),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          title,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
        ),
        secondary: Icon(icon, color: Colors.white54),
        value: value,
        activeTrackColor: Colors.blueAccent,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildColumnSelector(
    ThemeController controller,
    ThemePreferences prefs,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.grid_on, color: Colors.white54),
          const SizedBox(width: 12),
          Text(
            'Columns',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          ...List.generate(3, (i) {
            final count = i + 2;
            final isSelected = prefs.gridColumnCount == count;
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: GestureDetector(
                onTap: () => controller.setGridColumnCount(count),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blueAccent.withOpacity(0.2)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? Colors.blueAccent : Colors.white10,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$count',
                      style: GoogleFonts.inter(
                        color: isSelected ? Colors.blueAccent : Colors.white38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPreview(ThemeController controller, ThemePreferences prefs) {
    final radius = prefs.roundedPosters ? 16.0 : 4.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              prefs.useGridLayout ? prefs.gridColumnCount : 1,
              (i) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: i < prefs.gridColumnCount - 1 ? 8 : 0,
                  ),
                  height: prefs.useGridLayout ? 120 : 60,
                  decoration: BoxDecoration(
                    color: controller.accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: controller.accentColor.withOpacity(0.3),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.movie,
                      color: controller.accentColor.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sample Movie Title',
            style: GoogleFonts.inter(
              fontSize: prefs.fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Preview of your settings',
            style: GoogleFonts.inter(
              fontSize: prefs.fontSize * 0.8,
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }
}
