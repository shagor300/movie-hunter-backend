import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                activeIcon: Icon(Icons.search, size: 28),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.auto_awesome_outlined),
                activeIcon: Icon(Icons.auto_awesome, size: 28),
                label: 'For You',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.fiber_new_outlined),
                activeIcon: Icon(Icons.fiber_new, size: 28),
                label: 'Latest',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.video_library_outlined),
                activeIcon: Icon(Icons.video_library, size: 28),
                label: 'Library',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.download_outlined),
                activeIcon: Icon(Icons.download, size: 28),
                label: 'Downloads',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleBackPress() {
    // Step 1: If not on home tab (Search), navigate there first
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return;
    }

    // Step 2: On home tab — check double back
    final now = DateTime.now();

    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      // First press or timeout expired
      _lastBackPressed = now;

      // Remove any existing snackbar before showing new one
      ScaffoldMessenger.of(context).removeCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.exit_to_app, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Press back again to exit'),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF323232),
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else {
      // Second press within 2 seconds — exit app
      SystemNavigator.pop();
    }
  }
}
