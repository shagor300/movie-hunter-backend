import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator/palette_generator.dart';

/// Service to extract dominant colors from movie posters.
/// Caches results to avoid re-computation.
class ColorExtractionService {
  static final Map<String, Color> _cache = {};

  /// Extract dominant color from a network image URL.
  /// Returns a muted dark version suitable for backgrounds.
  static Future<Color> getDominantColor(String imageUrl) async {
    if (_cache.containsKey(imageUrl)) {
      return _cache[imageUrl]!;
    }

    try {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(imageUrl),
        size: const Size(80, 120), // Small size for speed
        maximumColorCount: 6,
      ).timeout(const Duration(seconds: 3));

      // Priority: darkMuted > muted > dominant > fallback
      final color =
          paletteGenerator.darkMutedColor?.color ??
          paletteGenerator.mutedColor?.color ??
          paletteGenerator.dominantColor?.color ??
          const Color(0xFF1A1A2E);

      _cache[imageUrl] = color;
      return color;
    } catch (_) {
      return const Color(0xFF1A1A2E);
    }
  }

  /// Get a vibrant accent color from poster for glow effects.
  static Future<Color> getVibrantColor(String imageUrl) async {
    final cacheKey = '${imageUrl}_vibrant';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(imageUrl),
        size: const Size(80, 120),
        maximumColorCount: 8,
      ).timeout(const Duration(seconds: 3));

      final color =
          paletteGenerator.vibrantColor?.color ??
          paletteGenerator.lightVibrantColor?.color ??
          paletteGenerator.dominantColor?.color ??
          const Color(0xFF448AFF);

      _cache[cacheKey] = color;
      return color;
    } catch (_) {
      return const Color(0xFF448AFF);
    }
  }

  /// Clear cache (e.g. on memory pressure)
  static void clearCache() => _cache.clear();
}
