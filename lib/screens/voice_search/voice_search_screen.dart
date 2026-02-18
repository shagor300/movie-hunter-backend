import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:avatar_glow/avatar_glow.dart';
import '../../services/voice_search_service.dart';

/// Full-screen voice search overlay with animated mic, sound wave
/// visualization, language selector, and auto-search on recognition.
class VoiceSearchScreen extends StatefulWidget {
  /// Called with the recognized text when a search should be triggered.
  final void Function(String query) onSearchResult;

  const VoiceSearchScreen({super.key, required this.onSearchResult});

  @override
  State<VoiceSearchScreen> createState() => _VoiceSearchScreenState();
}

class _VoiceSearchScreenState extends State<VoiceSearchScreen>
    with SingleTickerProviderStateMixin {
  final VoiceSearchService _voiceService = Get.find<VoiceSearchService>();

  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Start listening immediately on open
    _startListening();
  }

  void _startListening() {
    _voiceService.startListening(
      onResult: (text) {
        if (text.isNotEmpty) {
          // Wait for speech to finish, then auto-search
          Future.delayed(const Duration(seconds: 2), () {
            if (!_voiceService.isListening.value && mounted) {
              _performSearch(text);
            }
          });
        }
      },
    );
  }

  void _performSearch(String query) {
    Navigator.of(context).pop(); // close voice screen
    widget.onSearchResult(query);
  }

  @override
  void dispose() {
    _waveController.dispose();
    _voiceService.stopListening();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _voiceService.cancelListening();
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Voice Search',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          // Language selector
          PopupMenuButton<String>(
            icon: Icon(Icons.language, color: colorScheme.primary),
            tooltip: 'Language',
            onSelected: (languageCode) {
              _voiceService.changeLanguage(languageCode);
              _voiceService.stopListening();
              _startListening();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'en-US',
                child: Text('🇺🇸  English', style: GoogleFonts.inter()),
              ),
              PopupMenuItem(
                value: 'hi-IN',
                child: Text('🇮🇳  हिंदी', style: GoogleFonts.inter()),
              ),
              PopupMenuItem(
                value: 'bn-IN',
                child: Text('🇧🇩  বাংলা', style: GoogleFonts.inter()),
              ),
            ],
          ),
        ],
      ),
      body: Obx(() {
        return Column(
          children: [
            const Spacer(),

            // ── Animated microphone ──
            GestureDetector(
              onTap: () {
                if (_voiceService.isListening.value) {
                  _voiceService.stopListening();
                } else {
                  _startListening();
                }
              },
              child: AvatarGlow(
                animate: _voiceService.isListening.value,
                glowColor: colorScheme.primary,
                duration: const Duration(milliseconds: 2000),
                repeat: true,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: _voiceService.isListening.value
                        ? colorScheme.primary
                        : colorScheme.onSurface.withOpacity(0.12),
                    shape: BoxShape.circle,
                    boxShadow: _voiceService.isListening.value
                        ? [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    _voiceService.isListening.value ? Icons.mic : Icons.mic_off,
                    size: 70,
                    color: _voiceService.isListening.value
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // ── Status text ──
            Text(
              _voiceService.isListening.value ? 'Listening...' : 'Tap to speak',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 16),

            // ── Recognized text ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _voiceService.recognizedText.value.isEmpty
                    ? 'Say a movie name'
                    : _voiceService.recognizedText.value,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: _voiceService.recognizedText.value.isEmpty
                      ? colorScheme.onSurface.withOpacity(0.38)
                      : colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 32),

            // ── Sound-wave visualization ──
            if (_voiceService.isListening.value) _buildSoundWave(colorScheme),

            const Spacer(),

            // ── Control buttons ──
            Padding(
              padding: const EdgeInsets.all(32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Cancel
                  ElevatedButton.icon(
                    onPressed: () {
                      _voiceService.cancelListening();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close, size: 20),
                    label: Text('Cancel', style: GoogleFonts.inter()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.onSurface.withOpacity(0.12),
                      foregroundColor: colorScheme.onSurface,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  // Stop / Start toggle
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_voiceService.isListening.value) {
                        _voiceService.stopListening();
                      } else {
                        _startListening();
                      }
                    },
                    icon: Icon(
                      _voiceService.isListening.value ? Icons.stop : Icons.mic,
                      size: 20,
                    ),
                    label: Text(
                      _voiceService.isListening.value ? 'Stop' : 'Start',
                      style: GoogleFonts.inter(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Confidence ──
            if (_voiceService.confidenceLevel.value > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  'Confidence: ${(_voiceService.confidenceLevel.value * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.38),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  /// Animated sound-wave bars that oscillate while speech is being recognized.
  Widget _buildSoundWave(ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(7, (index) {
            final phase = index * 0.15;
            final sineValue = sin(
              (_waveController.value * 2 * pi) - (phase * 2 * pi),
            );
            final height = 20.0 + 25.0 * ((sineValue + 1) / 2);

            return AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: 4,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.8),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
