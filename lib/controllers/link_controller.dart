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
  var embedLinks = <Map<String, String>>[].obs;
  var currentProgress = 0.0.obs;
  var isSuccess = false.obs;

  /// Tracks which movie's links are currently loaded.
  int? _currentTmdbId;

  final List<String> _loadingMessages = [
    "Initializing secure connection...",
    "Scanning databases for content...",
    "Bypassing ad-gateways...",
    "Extracting video streams...",
    "Optimizing stream quality...",
    "Verifying link health...",
    "Finalizing results...",
  ];

  Timer? _messageTimer;
  int _messageIndex = 0;

  Future<void> fetchLinks({
    required int tmdbId,
    required String title,
    String? year,
    String? hdhub4uUrl,
    String? source,
    String? skyMoviesHDUrl,
  }) async {
    // Clear stale links if switching to a different movie
    if (_currentTmdbId != tmdbId) {
      links.clear();
      embedLinks.clear();
    }
    _currentTmdbId = tmdbId;

    isLoading.value = true;
    isSuccess.value = false;
    hasError.value = false;
    errorMessage.value = "";
    links.clear();
    embedLinks.clear();
    currentProgress.value = 0.0;
    _messageIndex = 0;
    progressText.value = _loadingMessages[0];

    // Staggered messages timer
    _messageTimer = Timer.periodic(const Duration(milliseconds: 1800), (timer) {
      if (_messageIndex < _loadingMessages.length - 1) {
        _messageIndex++;
        progressText.value = _loadingMessages[_messageIndex];
        currentProgress.value = (_messageIndex + 1) / _loadingMessages.length;
      }
      // Keeps the last message instead of canceling early
    });

    try {
      // Added timeout for reliability (60s for scraping)
      final results = await _resolverService
          .resolveLinks(
            tmdbId: tmdbId,
            title: title,
            year: year,
            hdhub4uUrl: hdhub4uUrl,
            source: source,
            skyMoviesHDUrl: skyMoviesHDUrl,
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () => throw TimeoutException(
              "Server took too long to respond. Please try again.",
            ),
          );

      final downloadLinks = results['downloadLinks'] ?? [];
      final embeds = results['embedLinks'] ?? [];

      if (downloadLinks.isEmpty && embeds.isEmpty) {
        throw Exception("No links found for this title. Try another source.");
      }

      links.assignAll(downloadLinks);
      embedLinks.assignAll(embeds);

      // Trigger success animation
      isSuccess.value = true;
      currentProgress.value = 1.0;
      progressText.value = "Links Generated Successfully!";
      _messageTimer?.cancel();

      // Keep loading overlay active briefly to show success animation
      await Future.delayed(const Duration(milliseconds: 1500));
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
      isSuccess.value = false;
    }
  }

  void retryFetch({
    required int tmdbId,
    required String title,
    String? year,
    String? hdhub4uUrl,
    String? source,
    String? skyMoviesHDUrl,
  }) {
    fetchLinks(
      tmdbId: tmdbId,
      title: title,
      year: year,
      hdhub4uUrl: hdhub4uUrl,
      source: source,
      skyMoviesHDUrl: skyMoviesHDUrl,
    );
  }

  /// Explicitly clear all links and tracking state (call when opening a new movie).
  void clearData() {
    links.clear();
    embedLinks.clear();
    _currentTmdbId = null;
    hasError.value = false;
    isSuccess.value = false;
    errorMessage.value = "";
    currentProgress.value = 0.0;
  }

  @override
  void onClose() {
    _messageTimer?.cancel();
    super.onClose();
  }
}
