import 'package:get/get.dart';
import 'dart:async';
import '../services/resolver_service.dart';

class LinkController extends GetxController {
  final ResolverService _resolverService = ResolverService();

  var isLoading = false.obs;
  var hasError = false.obs;
  var errorMessage = "".obs;
  var progressText = "".obs;
  var links = <Map<String, String>>[].obs;
  var currentProgress = 0.0.obs;

  /// Tracks which movie's links are currently loaded.
  int? _currentTmdbId;

  final List<String> _loadingMessages = [
    "Connecting to YoMovies server...",
    "Searching HDHub4u for 4K quality...",
    "Bypassing ad-gateways...",
    "Extracting direct download links...",
    "Optimizing stream sources...",
    "Finalizing results...",
  ];

  Timer? _messageTimer;
  int _messageIndex = 0;

  Future<void> fetchLinks({
    required int tmdbId,
    required String title,
    String? year,
    String? hdhub4uUrl,
  }) async {
    // Clear stale links if switching to a different movie
    if (_currentTmdbId != tmdbId) {
      links.clear();
    }
    _currentTmdbId = tmdbId;

    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = "";
    links.clear();
    currentProgress.value = 0.0;
    _messageIndex = 0;
    progressText.value = _loadingMessages[0];

    // Staggered messages timer
    _messageTimer = Timer.periodic(const Duration(milliseconds: 1800), (timer) {
      if (_messageIndex < _loadingMessages.length - 1) {
        _messageIndex++;
        progressText.value = _loadingMessages[_messageIndex];
        currentProgress.value = (_messageIndex + 1) / _loadingMessages.length;
      } else {
        timer.cancel();
      }
    });

    try {
      // Added timeout for reliability (60s for scraping)
      final results = await _resolverService
          .resolveLinks(
            tmdbId: tmdbId,
            title: title,
            year: year,
            hdhub4uUrl: hdhub4uUrl,
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () => throw TimeoutException(
              "Server took too long to respond. Please try again.",
            ),
          );

      if (results.isEmpty) {
        throw Exception("No links found for this title. Try another source.");
      }

      links.assignAll(results);
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString().contains("Exception:")
          ? e.toString().split("Exception:")[1].trim()
          : "Unexpected error occurred. Check your connection.";
      _messageTimer?.cancel();
    } finally {
      if (!hasError.value) {
        _messageTimer?.cancel();
        currentProgress.value = 1.0;
      }
      isLoading.value = false;
    }
  }

  void retryFetch({
    required int tmdbId,
    required String title,
    String? year,
    String? hdhub4uUrl,
  }) {
    fetchLinks(
      tmdbId: tmdbId,
      title: title,
      year: year,
      hdhub4uUrl: hdhub4uUrl,
    );
  }

  /// Explicitly clear all links and tracking state (call when opening a new movie).
  void clearData() {
    links.clear();
    _currentTmdbId = null;
    hasError.value = false;
    errorMessage.value = "";
    currentProgress.value = 0.0;
  }

  @override
  void onClose() {
    _messageTimer?.cancel();
    super.onClose();
  }
}
