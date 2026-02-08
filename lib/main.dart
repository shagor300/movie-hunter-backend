import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const MovieHunterApp());
}

class MovieHunterApp extends StatelessWidget {
  const MovieHunterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'MovieHunter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F0F1E),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
