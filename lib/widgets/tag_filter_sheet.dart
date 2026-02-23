import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/movie_tags.dart';
import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';

/// Bottom sheet for selecting quality and audio tag filters.
class TagFilterSheet extends StatefulWidget {
  final Set<QualityTag> selectedQuality;
  final Set<AudioTag> selectedAudio;
  final ValueChanged<({Set<QualityTag> quality, Set<AudioTag> audio})> onApply;

  const TagFilterSheet({
    super.key,
    required this.selectedQuality,
    required this.selectedAudio,
    required this.onApply,
  });

  @override
  State<TagFilterSheet> createState() => _TagFilterSheetState();

  /// Show the filter sheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required Set<QualityTag> selectedQuality,
    required Set<AudioTag> selectedAudio,
    required ValueChanged<({Set<QualityTag> quality, Set<AudioTag> audio})>
    onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TagFilterSheet(
        selectedQuality: selectedQuality,
        selectedAudio: selectedAudio,
        onApply: onApply,
      ),
    );
  }
}

class _TagFilterSheetState extends State<TagFilterSheet> {
  late Set<QualityTag> _quality;
  late Set<AudioTag> _audio;

  @override
  void initState() {
    super.initState();
    _quality = Set.from(widget.selectedQuality);
    _audio = Set.from(widget.selectedAudio);
  }

  @override
  Widget build(BuildContext context) {
    final tc = Get.find<ThemeController>();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter by Tags',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _quality.clear();
                      _audio.clear();
                    });
                  },
                  child: Text(
                    'Clear All',
                    style: GoogleFonts.inter(
                      color: tc.accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quality section
          _buildSection(
            'Quality',
            QualityTag.values
                .map(
                  (tag) => _buildChip(
                    label: '${tag.emoji} ${tag.label}',
                    isSelected: _quality.contains(tag),
                    accentColor: tc.accentColor,
                    onTap: () {
                      setState(() {
                        if (_quality.contains(tag)) {
                          _quality.remove(tag);
                        } else {
                          _quality.add(tag);
                        }
                      });
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),

          // Audio section
          _buildSection(
            'Audio & Language',
            AudioTag.values
                .map(
                  (tag) => _buildChip(
                    label: '${tag.emoji} ${tag.label}',
                    isSelected: _audio.contains(tag),
                    accentColor: tc.accentColor,
                    onTap: () {
                      setState(() {
                        if (_audio.contains(tag)) {
                          _audio.remove(tag);
                        } else {
                          _audio.add(tag);
                        }
                      });
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),

          // Apply button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply((quality: _quality, audio: _audio));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: tc.accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _quality.isEmpty && _audio.isEmpty
                      ? 'Show All Results'
                      : 'Apply ${_quality.length + _audio.length} Filter${(_quality.length + _audio.length) > 1 ? 's' : ''}',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> chips) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? accentColor : Colors.white12,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? accentColor : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
