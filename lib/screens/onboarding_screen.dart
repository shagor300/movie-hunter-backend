import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.blueAccent.withValues(alpha: 0.2),
            Colors.purpleAccent.withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(icon, size: 100, color: Colors.blueAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(fontSize: 19.0, color: Colors.white70);

    const pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      bodyTextStyle: bodyStyle,
      bodyPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Color(0xFF121212),
      imagePadding: EdgeInsets.only(top: 80.0),
    );

    return IntroductionScreen(
      key: GlobalKey<IntroductionScreenState>(),
      globalBackgroundColor: const Color(0xFF121212),
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
      skip: const Text(
        'Skip',
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
      ),
      next: const Icon(Icons.arrow_forward, color: Colors.white),
      done: const Text(
        'Done',
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
      ),
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(16),
      controlsPadding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        color: Colors.white24,
        activeSize: Size(22.0, 10.0),
        activeColor: Colors.blueAccent,
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
    );
  }
}
