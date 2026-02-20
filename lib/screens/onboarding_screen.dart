import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/stitch_design_system.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _onIntroEnd() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_time', false);
    Get.offAll(() => const HomeScreen());
  }

  Widget _buildIcon(IconData icon) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: LinearGradient(
          colors: [
            StitchColors.emerald.withValues(alpha: 0.2),
            StitchColors.emeraldDark.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: StitchColors.emerald.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: StitchColors.emerald.withValues(alpha: 0.15),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Icon(icon, size: 80, color: StitchColors.emerald),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bodyStyle = GoogleFonts.plusJakartaSans(
      fontSize: 16,
      color: StitchColors.textSecondary,
      fontWeight: FontWeight.w400,
      height: 1.6,
    );

    final pageDecoration = PageDecoration(
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: -0.5,
      ),
      bodyTextStyle: bodyStyle,
      bodyPadding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 16.0),
      pageColor: StitchColors.bgDark,
      imagePadding: const EdgeInsets.only(top: 80.0),
    );

    return IntroductionScreen(
      key: GlobalKey<IntroductionScreenState>(),
      globalBackgroundColor: StitchColors.bgDark,
      allowImplicitScrolling: true,
      pages: [
        PageViewModel(
          title: "Search & Discover",
          body: "Find your favorite movies from multiple sources in one place.",
          image: _buildIcon(Icons.search_rounded),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Offline Mode",
          body:
              "Download movies and watch them anytime, anywhere without internet.",
          image: _buildIcon(Icons.download_rounded),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Personalized Library",
          body:
              "Keep track of your watchlist, favorites, and history with ease.",
          image: _buildIcon(Icons.video_library_rounded),
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
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          color: StitchColors.textSecondary,
          fontSize: 15,
        ),
      ),
      next: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: StitchGradients.accent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: StitchColors.emerald.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_forward_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
      done: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          gradient: StitchGradients.accent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: StitchColors.emerald.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          'Get Started',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 15,
          ),
        ),
      ),
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(16),
      controlsPadding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
      dotsDecorator: DotsDecorator(
        size: const Size(8.0, 8.0),
        color: Colors.white.withValues(alpha: 0.15),
        activeSize: const Size(24.0, 8.0),
        activeColor: StitchColors.emerald,
        activeShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
    );
  }
}
