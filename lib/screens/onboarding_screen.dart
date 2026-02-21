import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_button.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _onIntroEnd() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_time', false);
    Get.offAll(
      () => const HomeScreen(),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 600),
    );
  }

  Widget _buildGlassmorphicIcon(IconData icon) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Decorative backlight glow
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 60,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
        // Glass container
        ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.glassBackground, // 3% white
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppColors.glassBorder), // 8% white
              ),
              child: Center(
                child: Icon(icon, size: 80, color: AppColors.primary),
              ),
            ),
          ),
        ),
        // Small floating decorative elements
        Positioned(
          top: 10,
          right: 10,
          child: _buildFloatingElement(Icons.movie, AppColors.primary, 30),
        ),
        Positioned(
          bottom: 15,
          left: 15,
          child: _buildFloatingElement(Icons.star, AppColors.accentPurple, 30),
        ),
      ],
    );
  }

  Widget _buildFloatingElement(IconData icon, Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.glassBackground,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(icon, size: size * 0.5, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageDecoration = PageDecoration(
      titleTextStyle: AppTextStyles.displayMedium.copyWith(fontSize: 28),
      bodyTextStyle: AppTextStyles.bodyLarge,
      bodyPadding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 16.0),
      pageColor: AppColors.backgroundDark,
      imagePadding: const EdgeInsets.only(top: 80.0, bottom: 20.0),
      titlePadding: const EdgeInsets.only(bottom: 16.0),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 120,
                    spreadRadius: 60,
                  ),
                ],
              ),
            ),
          ),

          IntroductionScreen(
            key: GlobalKey<IntroductionScreenState>(),
            globalBackgroundColor: Colors.transparent, // Let gradient show
            allowImplicitScrolling: true,
            pages: [
              PageViewModel(
                title: "Search & Discover",
                body:
                    "Find your favorite movies from multiple sources in one place.",
                image: _buildGlassmorphicIcon(Icons.search_rounded),
                decoration: pageDecoration,
              ),
              PageViewModel(
                title: "Offline Mode",
                body:
                    "Download movies and watch them anytime, anywhere without internet.",
                image: _buildGlassmorphicIcon(Icons.download_rounded),
                decoration: pageDecoration,
              ),
              PageViewModel(
                title: "Personalized Library",
                body:
                    "Keep track of your watchlist, favorites, and history with ease.",
                image: _buildGlassmorphicIcon(Icons.video_library_rounded),
                decoration: pageDecoration,
              ),
            ],
            onDone: () => _onIntroEnd(),
            onSkip: () => _onIntroEnd(),
            showSkipButton: true,
            skipOrBackFlex: 0,
            nextFlex: 0,
            showBackButton: false,
            skip: Text(
              'Skip',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            next: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            done: SizedBox(
              width: 160,
              child: GradientButton(
                text: "Get Started",
                onPressed: () {}, // IntroductionScreen hooks this up
              ),
            ),
            curve: Curves.fastLinearToSlowEaseIn,
            controlsMargin: const EdgeInsets.all(24),
            controlsPadding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 16.0,
            ),
            dotsDecorator: DotsDecorator(
              size: const Size(8.0, 8.0),
              color: AppColors.surfaceLight,
              activeSize: const Size(24.0, 8.0),
              activeColor: AppColors.primary,
              spacing: const EdgeInsets.symmetric(horizontal: 4.0),
              activeShape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(25.0)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
