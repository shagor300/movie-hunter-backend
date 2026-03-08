import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_text_styles.dart';
import 'package:get/get.dart';
import '../theme/theme_controller.dart';
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
  final _searchKey = GlobalKey<SearchScreenState>();

  late final _screens = [
    SearchScreen(key: _searchKey),
    const RecommendationsScreen(),
    const HDHub4uTab(),
    const LibraryScreen(),
    const DownloadsScreen(),
  ];

  static const _navItems = [
    _NavItem(
      icon: Icons.search_outlined,
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
      activeIcon: Icons.fiber_new_rounded,
      label: 'Latest',
    ),
    _NavItem(
      icon: Icons.video_library_outlined,
      activeIcon: Icons.video_library_rounded,
      label: 'Library',
    ),
    _NavItem(
      icon: Icons.download_outlined,
      activeIcon: Icons.download_rounded,
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
    final tc = Get.find<ThemeController>();
    return Obx(
      () => Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: tc.currentThemeConfig.surfaceColor.withValues(
                  alpha: 0.92,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: tc.accentColor.withValues(alpha: 0.08),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: tc.accentColor.withValues(alpha: 0.06),
                    blurRadius: 20,
                    spreadRadius: 1,
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
      ),
    );
  }

  Widget _buildNavItem(_NavItem item, bool isActive, int index) {
    final tc = Get.find<ThemeController>();

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Obx(() {
        final activeColor = tc.accentColor;
        final inactiveColor = Theme.of(context).hintColor;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          width: isActive ? 72 : 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: isActive
              ? BoxDecoration(
                  color: activeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                )
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  isActive ? item.activeIcon : item.icon,
                  size: isActive ? 28 : 26,
                  color: isActive ? activeColor : inactiveColor,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: AppTextStyles.labelSmall.copyWith(
                  fontSize: isActive ? 11 : 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? activeColor : inactiveColor,
                  letterSpacing: isActive ? 0.3 : 0,
                ),
                child: Text(item.label),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _handleBackPress() {
    // If on Search tab and has active search text → clear search first
    if (_currentIndex == 0) {
      final searchState = _searchKey.currentState;
      if (searchState != null && searchState.hasActiveSearch) {
        searchState.clearSearch();
        return;
      }
    }

    final now = DateTime.now();

    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      // Silent double-back — no snackbar, just exit on second press
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
