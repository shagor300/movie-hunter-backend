import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';

/// Service that wraps [SpeechToText] for voice-based movie search.
///
/// Exposes observable state so any UI can react to listening status,
/// recognized text, and confidence level.
class VoiceSearchService extends GetxService {
  final SpeechToText _speech = SpeechToText();

  // Observable state
  var isAvailable = false.obs;
  var isListening = false.obs;
  var recognizedText = ''.obs;
  var confidenceLevel = 0.0.obs;
  var errorMessage = ''.obs;

  // Supported locales for speech recognition
  final List<String> supportedLanguages = [
    'en-US', // English (US)
    'hi-IN', // Hindi
    'bn-IN', // Bengali
  ];

  var selectedLanguage = 'en-US'.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeSpeech();
  }

  /// One-time initialization of the speech recognition engine.
  Future<void> _initializeSpeech() async {
    try {
      isAvailable.value = await _speech.initialize(
        onError: (error) {
          debugPrint('❌ Speech error: ${error.errorMsg}');
          errorMessage.value = error.errorMsg;
          isListening.value = false;
        },
        onStatus: (status) {
          debugPrint('🎤 Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            isListening.value = false;
          }
        },
      );

      if (isAvailable.value) {
        debugPrint('✅ Speech recognition initialized');
      } else {
        debugPrint('❌ Speech recognition not available');
      }
    } catch (e) {
      debugPrint('❌ Speech init error: $e');
      isAvailable.value = false;
    }
  }

  /// Begin listening for speech input.
  ///
  /// [onResult] is called whenever recognized text changes.
  /// [language] overrides the current [selectedLanguage] for this session.
  Future<void> startListening({
    Function(String)? onResult,
    String? language,
  }) async {
    // Check microphone permission first
    final hasPermission = await _checkPermission();
    if (!hasPermission) {
      Get.snackbar(
        'Permission Required',
        'Microphone permission is needed for voice search',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Ensure speech engine is ready
    if (!isAvailable.value) {
      // Try re-initializing once (covers cold-boot edge case)
      await _initializeSpeech();
      if (!isAvailable.value) {
        Get.snackbar(
          'Not Available',
          'Voice search is not available on this device',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    }

    // Reset previous results
    recognizedText.value = '';
    errorMessage.value = '';

    try {
      isListening.value = true;

      await _speech.listen(
        onResult: (result) {
          recognizedText.value = result.recognizedWords;
          confidenceLevel.value = result.confidence;

          debugPrint('🎤 Recognized: ${result.recognizedWords}');
          debugPrint('📊 Confidence: ${result.confidence}');

          if (onResult != null && result.recognizedWords.isNotEmpty) {
            onResult(result.recognizedWords);
          }

          // Auto-stop on final result
          if (result.finalResult) {
            isListening.value = false;
          }
        },
        localeId: language ?? selectedLanguage.value,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('❌ Listen error: $e');
      errorMessage.value = e.toString();
      isListening.value = false;
    }
  }

  /// Stop listening gracefully (keeps partial results).
  Future<void> stopListening() async {
    if (isListening.value) {
      await _speech.stop();
      isListening.value = false;
    }
  }

  /// Cancel listening and discard all results.
  Future<void> cancelListening() async {
    if (isListening.value) {
      await _speech.cancel();
      isListening.value = false;
      recognizedText.value = '';
    }
  }

  /// Request microphone permission; opens app settings if permanently denied.
  Future<bool> _checkPermission() async {
    var status = await Permission.microphone.status;

    if (status.isDenied) {
      status = await Permission.microphone.request();
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return status.isGranted;
  }

  /// Switch the recognition locale.
  void changeLanguage(String languageCode) {
    selectedLanguage.value = languageCode;
  }

  @override
  void onClose() {
    _speech.stop();
    super.onClose();
  }
}
