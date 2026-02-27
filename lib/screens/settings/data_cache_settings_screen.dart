import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../controllers/watchlist_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/theme_controller.dart';
import '../../theme/theme_config.dart' as config;

/// Dedicated Data & Cache screen — reached from Settings > Data & Cache.
class DataCacheSettingsScreen extends StatefulWidget {
  const DataCacheSettingsScreen({super.key});

  @override
  State<DataCacheSettingsScreen> createState() =>
      _DataCacheSettingsScreenState();
}

class _DataCacheSettingsScreenState extends State<DataCacheSettingsScreen> {
  // Track sizes for display
  int _movieCacheCount = 0;
  int _watchlistCount = 0;
  int _downloadHistoryCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    try {
      final movieBox = await Hive.openBox('homepage_movies');
      final watchlistBox = await Hive.openBox('watchlist');
      final downloadsBox = await Hive.openBox('downloads');

      if (mounted) {
        setState(() {
          _movieCacheCount = movieBox.length;
          _watchlistCount = watchlistBox.length;
          _downloadHistoryCount = downloadsBox.length;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = Get.find<ThemeController>();
    final accent = tc.accentColor;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Data & Cache',
          style: AppTextStyles.headingLarge.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const BouncingScrollPhysics(),
        children: [
          // ═══ SUMMARY HEADER ═══
          _buildSummaryHeader(accent),
          const SizedBox(height: 24),

          // ═══ CACHE ═══
          _buildSectionLabel('CACHE', accent),
          const SizedBox(height: 8),
          _buildCard([
            _buildActionTile(
              icon: Icons.image_outlined,
              title: 'Clear Image Cache',
              subtitle: 'Remove cached movie posters & thumbnails',
              iconColor: Colors.tealAccent,
              onTap: () => _clearImageCache(accent),
            ),
            const Divider(color: Colors.white10, height: 24),
            _buildActionTile(
              icon: Icons.movie_outlined,
              title: 'Clear Movie Data Cache',
              subtitle: _loading
                  ? 'Calculating...'
                  : '$_movieCacheCount items cached',
              iconColor: Colors.orangeAccent,
              onTap: () => _clearMovieCache(accent),
            ),
          ]),

          const SizedBox(height: 24),

          // ═══ USER DATA ═══
          _buildSectionLabel('USER DATA', accent),
          const SizedBox(height: 8),
          _buildCard([
            _buildActionTile(
              icon: Icons.bookmark_remove_outlined,
              title: 'Clear Watchlist',
              subtitle: _loading
                  ? 'Calculating...'
                  : '$_watchlistCount movies saved',
              iconColor: Colors.redAccent,
              onTap: () => _clearWatchlist(accent),
            ),
            const Divider(color: Colors.white10, height: 24),
            _buildActionTile(
              icon: Icons.delete_sweep_outlined,
              title: 'Clear Download History',
              subtitle: _loading
                  ? 'Calculating...'
                  : '$_downloadHistoryCount records',
              iconColor: const Color(0xFFF59E0B),
              onTap: () => _clearDownloadHistory(accent),
            ),
          ]),

          const SizedBox(height: 24),

          // ═══ DANGER ZONE ═══
          _buildSectionLabel('DANGER ZONE', Colors.redAccent),
          const SizedBox(height: 8),
          _buildCard([
            _buildActionTile(
              icon: Icons.restart_alt_rounded,
              title: 'Reset All Settings',
              subtitle: 'Restore theme, layout & all preferences',
              iconColor: Colors.redAccent,
              onTap: () => _resetAllSettings(accent),
            ),
            const Divider(color: Colors.white10, height: 24),
            _buildActionTile(
              icon: Icons.delete_forever_rounded,
              title: 'Clear All App Data',
              subtitle: 'Remove everything — cache, watchlist, history',
              iconColor: const Color(0xFFEF4444),
              onTap: () => _clearAllData(accent),
            ),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════

  Future<void> _clearImageCache(Color accent) async {
    final confirmed = await _showConfirmDialog(
      title: 'Clear Image Cache?',
      message:
          'Cached images will be removed. They will be re-downloaded when needed.',
    );
    if (confirmed == true) {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      _showSuccess('Image cache cleared', accent);
    }
  }

  Future<void> _clearMovieCache(Color accent) async {
    final confirmed = await _showConfirmDialog(
      title: 'Clear Movie Cache?',
      message:
          'Cached movie data will be removed. The app will re-fetch from the server.',
    );
    if (confirmed == true) {
      final box = await Hive.openBox('homepage_movies');
      await box.clear();
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      _loadCounts();
      _showSuccess('Movie & image cache cleared', accent);
    }
  }

  Future<void> _clearWatchlist(Color accent) async {
    final confirmed = await _showConfirmDialog(
      title: 'Clear Watchlist?',
      message:
          'This will permanently delete all $_watchlistCount movies from your watchlist.',
    );
    if (confirmed == true) {
      final box = await Hive.openBox('watchlist');
      await box.clear();
      try {
        Get.find<WatchlistController>().allMovies.clear();
      } catch (_) {}
      _loadCounts();
      _showSuccess('Watchlist cleared', accent);
    }
  }

  Future<void> _clearDownloadHistory(Color accent) async {
    final confirmed = await _showConfirmDialog(
      title: 'Clear Download History?',
      message:
          'This will clear $_downloadHistoryCount download records. Downloaded files will NOT be deleted.',
    );
    if (confirmed == true) {
      final box = await Hive.openBox('downloads');
      await box.clear();
      _loadCounts();
      _showSuccess('Download history cleared', accent);
    }
  }

  Future<void> _resetAllSettings(Color accent) async {
    final confirmed = await _showConfirmDialog(
      title: 'Reset All Settings?',
      message:
          'This will restore theme, layout, and all preferences to their defaults.',
    );
    if (confirmed == true) {
      final tc = Get.find<ThemeController>();
      tc.setThemeMode(config.AppThemeMode.dark);
      tc.setAccentColorByKey('mint_green');
      tc.setFontSize(14.0);
      tc.setGridColumnCount(2);
      if (!tc.useGridLayout) tc.toggleGridLayout();
      if (!tc.roundedPosters) tc.toggleRoundedPosters();
      _showSuccess('All settings restored to defaults', accent);
    }
  }

  Future<void> _clearAllData(Color accent) async {
    final confirmed = await _showConfirmDialog(
      title: 'Clear All App Data?',
      message:
          'This will delete ALL cached data, your watchlist, download history, and reset settings. This action is irreversible!',
      isDestructive: true,
    );
    if (confirmed == true) {
      // Clear everything
      try {
        final movieBox = await Hive.openBox('homepage_movies');
        await movieBox.clear();
      } catch (_) {}
      try {
        final watchlistBox = await Hive.openBox('watchlist');
        await watchlistBox.clear();
        Get.find<WatchlistController>().allMovies.clear();
      } catch (_) {}
      try {
        final downloadsBox = await Hive.openBox('downloads');
        await downloadsBox.clear();
      } catch (_) {}
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // Reset settings
      final tc = Get.find<ThemeController>();
      tc.setThemeMode(config.AppThemeMode.dark);
      tc.setAccentColorByKey('mint_green');
      tc.setFontSize(14.0);
      tc.setGridColumnCount(2);
      if (!tc.useGridLayout) tc.toggleGridLayout();
      if (!tc.roundedPosters) tc.toggleRoundedPosters();

      _loadCounts();
      _showSuccess('All app data cleared', accent);
    }
  }

  // ═══════════════════════════════════════
  // UI HELPERS
  // ═══════════════════════════════════════

  void _showSuccess(String message, Color accent) {
    Get.snackbar(
      '✅ Done',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: accent.withValues(alpha: 0.9),
      colorText: Colors.black,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.check_circle, color: Colors.black),
    );
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(color: Colors.white60, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx, true);
            },
            child: Text(
              isDestructive ? 'Delete All' : 'Confirm',
              style: GoogleFonts.inter(
                color: isDestructive ? Colors.redAccent : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(Color accent) {
    final total = _movieCacheCount + _watchlistCount + _downloadHistoryCount;
    return Center(
      child: Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.only(top: 16),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.25),
              accent.withValues(alpha: 0.08),
            ],
          ),
          border: Border.all(color: accent.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: 0.15), blurRadius: 30),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storage_rounded, size: 28, color: accent),
            const SizedBox(height: 4),
            Text(
              _loading ? '...' : '$total items',
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.white60,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: color,
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
              color: Colors.white38,
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

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
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
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.white24,
            size: 22,
          ),
        ],
      ),
    );
  }
}
