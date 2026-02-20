import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/stitch_design_system.dart';
import 'search_screen.dart';
import 'library_screen.dart';
import 'downloads_screen.dart';
import 'recommendations_screen.dart';
import 'hdhub4u/hdhub4u_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  DateTime? _lastBackPressed;

  final _screens = const [
    SearchScreen(),
    RecommendationsScreen(),
    HDHub4uTab(),
    LibraryScreen(),
    DownloadsScreen(),
  ];

  static const _navItems = [
    _NavItem(
      icon: Icons.search_rounded,
      activeIcon: Icons.search_rounded,
      label: 'Search',
    ),
    _NavItem(
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome,
      label: 'For You',
    ),
    _NavItem(
      icon: Icons.fiber_new_outlined,
      activeIcon: Icons.fiber_new,
      label: 'Latest',
    ),
    _NavItem(
      icon: Icons.video_library_outlined,
      activeIcon: Icons.video_library,
      label: 'Library',
    ),
    _NavItem(
      icon: Icons.download_outlined,
      activeIcon: Icons.download_for_offline,
      label: 'Downloads',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: _buildFloatingNav(),
      ),
    );
  }

  Widget _buildFloatingNav() {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: StitchColors.glassNav,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (i) {
                final item = _navItems[i];
                final isActive = _currentIndex == i;
                return _buildNavItem(item, isActive, i);
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(_NavItem item, bool isActive, int index) {
    // "For You" tab (index 1) gets the elevated treatment
    final isElevated = isActive && index == 1;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isElevated) ...[
              // Elevated icon with emerald glow (raised effect)
              Transform.translate(
                offset: const Offset(0, -10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: StitchColors.bgDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: StitchColors.emerald.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: StitchColors.emerald.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    item.activeIcon,
                    size: 26,
                    color: StitchColors.emerald,
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -6),
                child: Text(
                  item.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: StitchColors.emerald,
                  ),
                ),
              ),
            ] else ...[
              Icon(
                isActive ? item.activeIcon : item.icon,
                size: 24,
                color: isActive
                    ? StitchColors.emerald
                    : StitchColors.textTertiary,
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? StitchColors.emerald
                      : StitchColors.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleBackPress() {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return;
    }

    final now = DateTime.now();

    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;

      ScaffoldMessenger.of(context).removeCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.exit_to_app, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                'Press back again to exit',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: StitchColors.surfaceDark,
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: StitchColors.glassBorder),
          ),
        ),
      );
    } else {
      SystemNavigator.pop();
    }
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
