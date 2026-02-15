import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/update_controller.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    print('🎬 SplashScreen: initState called');

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    // Run splash animation and then navigate
    _proceedToHome();
  }

  Future<void> _proceedToHome() async {
    try {
      print('🎬 SplashScreen: _proceedToHome started');

      // 1. Safety Timeout - App MUST navigate to home within 5 seconds regardless of what happens
      Timer(const Duration(seconds: 5), () {
        if (mounted && Get.currentRoute != '/HomeScreen') {
          print('⚠️ Splash safety timeout triggered - forcing navigation');
          Get.offAll(() => const HomeScreen());
        }
      });

      // 2. Wait for splash animation (standard duration)
      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;

      // 3. Start update check in background (non-blocking)
      // We don't await this so it doesn't hold up navigation
      unawaited(_checkUpdateInBackground());

      // 4. Check if it's the first time
      final prefs = await SharedPreferences.getInstance();
      final isFirstTime = prefs.getBool('is_first_time') ?? true;

      if (!mounted) return;

      if (isFirstTime) {
        print('🎬 SplashScreen: Navigating to OnboardingScreen');
        Get.offAll(
          () => const OnboardingScreen(),
          transition: Transition.fade,
          duration: const Duration(milliseconds: 800),
        );
      } else {
        print('🎬 SplashScreen: Navigating to HomeScreen');
        Get.offAll(
          () => const HomeScreen(),
          transition: Transition.fade,
          duration: const Duration(milliseconds: 800),
        );
      }
    } catch (e) {
      print('❌ Critical error in splash screen navigation: $e');
      // Emergency fallback
      if (mounted) {
        Get.offAll(() => const HomeScreen());
      }
    }
  }

  Future<void> _checkUpdateInBackground() async {
    try {
      final updateController = Get.find<UpdateController>();
      await updateController.checkForUpdate();

      final info = updateController.updateInfo.value;
      if (info != null) {
        final updateService = UpdateService();
        final currentVersion = await updateService.getCurrentVersionName();

        // Wait a bit for HomeScreen to be ready
        await Future.delayed(const Duration(seconds: 1));

        if (Get.currentRoute == '/' ||
            Get.currentRoute == '/HomeScreen' ||
            true) {
          UpdateDialog.show(info: info, currentVersion: currentVersion);
        }
      }
    } catch (e) {
      print('Background update check error: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('🎬 SplashScreen: build() called');

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                          BoxShadow(
                            color: Colors.purpleAccent.withValues(alpha: 0.2),
                            blurRadius: 50,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // App Logo with Fallback
                          Image.asset(
                            'assets/images/moviehub_logo.png',
                            width: 100,
                            height: 100,
                            errorBuilder: (context, error, stackTrace) {
                              return ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                      colors: [
                                        Colors.blueAccent,
                                        Colors.purpleAccent,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ).createShader(bounds),
                                child: const Icon(
                                  Icons.play_circle_filled,
                                  size: 100,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Text(
                    'MovieHub',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'YOUR ULTIMATE CINEMA',
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
