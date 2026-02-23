import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

// ─── Hardcoded Onboarding Colors (never change with theme) ───
class _OBColors {
  static const Color bg = Color(0xFF0A0A18);
  static const Color blue = Color(0xFF448AFF);
  static const Color blueDark = Color(0xFF2962FF);
  static const Color purple = Color(0xFF6C63FF);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textFaded = Color(0xFFB4B4C8);
  static const Color surfaceLight = Color(0xFF2A2A40);
  static const Color glass = Color(0x331A1A2E);
  static const Color glassBorder = Color(0x1AFFFFFF);
  static const LinearGradient btnGradient = LinearGradient(
    colors: [purple, blueDark],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

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
            color: _OBColors.blue.withValues(alpha: 0.2),
            boxShadow: [
              BoxShadow(
                color: _OBColors.blue.withValues(alpha: 0.3),
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
                color: _OBColors.glass,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: _OBColors.glassBorder),
              ),
              child: Center(child: Icon(icon, size: 80, color: _OBColors.blue)),
            ),
          ),
        ),
        // Small floating decorative elements
        Positioned(
          top: 10,
          right: 10,
          child: _buildFloatingElement(Icons.movie, _OBColors.blue, 30),
        ),
        Positioned(
          bottom: 15,
          left: 15,
          child: _buildFloatingElement(Icons.star, _OBColors.purple, 30),
        ),
      ],
    );
  }

  Widget _buildFloatingElement(IconData icon, Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _OBColors.glass,
        shape: BoxShape.circle,
        border: Border.all(color: _OBColors.glassBorder),
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
      titleTextStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: _OBColors.textWhite,
      ),
      bodyTextStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: _OBColors.textFaded,
        height: 1.5,
      ),
      bodyPadding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 16.0),
      pageColor: _OBColors.bg,
      imagePadding: const EdgeInsets.only(top: 80.0, bottom: 20.0),
      titlePadding: const EdgeInsets.only(bottom: 16.0),
    );

    return Scaffold(
      backgroundColor: _OBColors.bg,
      body: Stack(
        children: [
          // Background blue glow
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _OBColors.blue.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(
                    color: _OBColors.blue.withValues(alpha: 0.1),
                    blurRadius: 120,
                    spreadRadius: 60,
                  ),
                ],
              ),
            ),
          ),

          IntroductionScreen(
            key: GlobalKey<IntroductionScreenState>(),
            globalBackgroundColor: Colors.transparent,
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
            skip: const Text(
              'Skip',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _OBColors.textFaded,
              ),
            ),
            next: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: _OBColors.btnGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _OBColors.purple.withValues(alpha: 0.3),
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
            done: Container(
              width: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: _OBColors.btnGradient,
                boxShadow: [
                  BoxShadow(
                    color: _OBColors.purple.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onIntroEnd(),
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    child: Center(
                      child: Text(
                        'Get Started',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
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
              color: _OBColors.surfaceLight,
              activeSize: const Size(24.0, 8.0),
              activeColor: _OBColors.blue,
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
