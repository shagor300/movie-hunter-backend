import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/update_controller.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.cinematicGradient),
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

                          // Logo container
                          _buildLogoContainer(),
                          const SizedBox(height: 24),

                          // App title
                          _buildTitle(),
                          const SizedBox(height: 8),

                          // Tagline
                          _buildTagline(),

                          const Spacer(flex: 2),

                          // Progress section
                          _buildProgressSection(),

                          const SizedBox(height: 64),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Decorative Blurs (From Stitch)
            Positioned(
              bottom: -96,
              left: -96,
              child: Container(
                width: 384,
                height: 384,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 100,
                      spreadRadius: 50,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -96,
              right: -96,
              child: Container(
                width: 384,
                height: 384,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentPurple.withValues(alpha: 0.1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentPurple.withValues(alpha: 0.1),
                      blurRadius: 100,
                      spreadRadius: 50,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoContainer() {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Image.asset(
          'assets/images/moviehub_logo.png',
          width: 64,
          height: 64,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.movie_rounded,
              size: 56,
              color: AppColors.primary,
            );
          },
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
          style: AppTextStyles.displayLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          'Hub',
          style: AppTextStyles.displayLarge.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildTagline() {
    return Text(
      'YOUR ULTIMATE CINEMA',
      style: AppTextStyles.labelSmall.copyWith(
        color: AppColors.textPrimary.withValues(alpha: 0.7),
        letterSpacing: 4.0,
      ),
    );
  }

  Widget _buildProgressSection() {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            children: [
              // Progress bar
              Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Status text
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _statusText.toUpperCase(),
                  key: ValueKey(_statusText),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 10,
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

      paint.color = Colors.white.withValues(alpha: particleOpacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.opacity != opacity;
}
