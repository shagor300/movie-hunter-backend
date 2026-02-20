import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/update_controller.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';
import '../utils/stitch_design_system.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _progressController;
  late AnimationController _particleController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;

  String _statusText = 'Initializing';

  final _statusStages = [
    'Initializing',
    'Loading Assets',
    'Preparing Experience',
  ];

  @override
  void initState() {
    super.initState();
    debugPrint('🎬 SplashScreen: initState called');

    // Main logo animation
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _mainController, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutBack),
    );

    // Progress bar animation
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Particle animation (looping)
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _mainController.forward();

    // Start progress after a short delay
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _progressController.forward();
    });

    // Cycle status text
    _cycleStatusText();

    _proceedToHome();
  }

  void _cycleStatusText() {
    for (int i = 0; i < _statusStages.length; i++) {
      Future.delayed(Duration(milliseconds: 800 * i), () {
        if (mounted) {
          setState(() => _statusText = _statusStages[i]);
        }
      });
    }
  }

  Future<void> _proceedToHome() async {
    try {
      debugPrint('🎬 SplashScreen: _proceedToHome started');

      // Safety timeout
      Timer(const Duration(seconds: 5), () {
        if (mounted && Get.currentRoute != '/HomeScreen') {
          debugPrint('⚠️ Splash safety timeout triggered');
          Get.offAll(() => const HomeScreen());
        }
      });

      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;

      unawaited(_checkUpdateInBackground());

      final prefs = await SharedPreferences.getInstance();
      final isFirstTime = prefs.getBool('is_first_time') ?? true;

      if (!mounted) return;

      if (isFirstTime) {
        debugPrint('🎬 SplashScreen: Navigating to OnboardingScreen');
        Get.offAll(
          () => const OnboardingScreen(),
          transition: Transition.fade,
          duration: const Duration(milliseconds: 800),
        );
      } else {
        debugPrint('🎬 SplashScreen: Navigating to HomeScreen');
        Get.offAll(
          () => const HomeScreen(),
          transition: Transition.fade,
          duration: const Duration(milliseconds: 800),
        );
      }
    } catch (e) {
      debugPrint('❌ Critical error in splash screen navigation: $e');
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

        await Future.delayed(const Duration(seconds: 1));

        if (Get.currentRoute == '/' ||
            Get.currentRoute == '/HomeScreen' ||
            true) {
          UpdateDialog.show(info: info, currentVersion: currentVersion);
        }
      }
    } catch (e) {
      debugPrint('Background update check error: $e');
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _progressController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: StitchGradients.splash),
        child: Stack(
          children: [
            // Floating particles
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) => CustomPaint(
                painter: _ParticlePainter(
                  progress: _particleController.value,
                  opacity: _fadeAnimation.value,
                ),
                size: MediaQuery.of(context).size,
              ),
            ),

            // Main content
            Center(
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, _) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 3),

                          // Logo container with emerald glow
                          _buildLogoContainer(),
                          const SizedBox(height: 32),

                          // App title
                          _buildTitle(),
                          const SizedBox(height: 8),

                          // Tagline
                          _buildTagline(),

                          const Spacer(flex: 2),

                          // Progress section
                          _buildProgressSection(),

                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoContainer() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: StitchColors.emerald.withValues(alpha: 0.35),
            blurRadius: 40,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: StitchColors.emerald.withValues(alpha: 0.15),
            blurRadius: 80,
            spreadRadius: 20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Gradient background
            Container(
              decoration: const BoxDecoration(gradient: StitchGradients.accent),
            ),
            // App logo
            Image.asset(
              'assets/images/moviehub_logo.png',
              width: 80,
              height: 80,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.movie_rounded,
                  size: 56,
                  color: Colors.white,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Movie',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          'Hub',
          style: GoogleFonts.plusJakartaSans(
            color: StitchColors.emerald,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTagline() {
    return Text(
      'YOUR ULTIMATE CINEMA',
      style: GoogleFonts.plusJakartaSans(
        color: Colors.white.withValues(alpha: 0.35),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 3.0,
      ),
    );
  }

  Widget _buildProgressSection() {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 64),
          child: Column(
            children: [
              // Status text
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _statusText,
                  key: ValueKey(_statusText),
                  style: GoogleFonts.plusJakartaSans(
                    color: StitchColors.emerald.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Progress bar
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: StitchGradients.splashProgress,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: StitchColors.emerald.withValues(alpha: 0.4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  Floating Particle Effect
// ─────────────────────────────────────────────

class _ParticlePainter extends CustomPainter {
  final double progress;
  final double opacity;
  final Random _rng = Random(42); // Fixed seed for stable positions

  _ParticlePainter({required this.progress, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity < 0.1) return;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 30; i++) {
      final baseX = _rng.nextDouble() * size.width;
      final baseY = _rng.nextDouble() * size.height;
      final radius = _rng.nextDouble() * 2 + 0.5;
      final speed = _rng.nextDouble() * 0.3 + 0.1;
      final phase = _rng.nextDouble() * 2 * pi;

      final dx = sin(progress * 2 * pi * speed + phase) * 20;
      final dy =
          cos(progress * 2 * pi * speed + phase) * 30 - (progress * 40 * speed);

      final x = (baseX + dx) % size.width;
      final y = (baseY + dy) % size.height;

      final particleOpacity = (0.15 + _rng.nextDouble() * 0.15) * opacity;

      paint.color = (i % 3 == 0 ? StitchColors.emerald : Colors.white)
          .withValues(alpha: particleOpacity);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.opacity != opacity;
}
