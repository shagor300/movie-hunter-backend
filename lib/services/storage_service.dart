import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/movie.dart';

class StorageService {
  static const String _watchlistFile = 'watchlist.json';
  static const String _historyFile = 'history.json';

  Future<String> _getFilePath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$fileName';
  }

  // --- Watchlist ---
  Future<List<Map<String, dynamic>>> getWatchlist() async {
    try {
      final path = await _getFilePath(_watchlistFile);
      final file = File(path);
      if (!await file.exists()) return [];

      final content = await file.readAsString();
      return List<Map<String, dynamic>>.from(jsonDecode(content));
    } catch (e) {
      return [];
    }
  }

  Future<void> addToWatchlist(Movie movie) async {
    final watchlist = await getWatchlist();
    if (!watchlist.any((m) => m['title'] == movie.title)) {
      watchlist.add({
        'title': movie.title,
        'poster_path': movie.tmdbPoster,
        'release_date': movie.releaseDate,
        'rating': movie.rating,
        'plot': movie.plot,
      });
      final path = await _getFilePath(_watchlistFile);
      await File(path).writeAsString(jsonEncode(watchlist));
    }
  }

  Future<void> removeFromWatchlist(String title) async {
    final watchlist = await getWatchlist();
    watchlist.removeWhere((m) => m['title'] == title);
    final path = await _getFilePath(_watchlistFile);
    await File(path).writeAsString(jsonEncode(watchlist));
  }

  // --- Download History ---
  Future<List<Map<String, dynamic>>> getDownloadHistory() async {
    try {
      final path = await _getFilePath(_historyFile);
      final file = File(path);
      if (!await file.exists()) return [];

      final content = await file.readAsString();
      return List<Map<String, dynamic>>.from(jsonDecode(content));
    } catch (e) {
      return [];
    }
  }

  Future<void> addToHistory(
    String movieTitle,
    String url,
    String quality,
  ) async {
    final history = await getDownloadHistory();
    history.add({
      'title': movieTitle,
      'url': url,
      'quality': quality,
      'timestamp': DateTime.now().toIso8601String(),
    });
    final path = await _getFilePath(_historyFile);
    await File(path).writeAsString(jsonEncode(history));
  }
}
