import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Represents one chunk of a parallel download.
class DownloadChunk {
  final int index;
  final int startByte;
  final int endByte;
  final String tempPath;

  int downloadedBytes = 0;
  bool isCompleted = false;
  CancelToken cancelToken = CancelToken();

  DownloadChunk({
    required this.index,
    required this.startByte,
    required this.endByte,
    required this.tempPath,
  });

  int get totalBytes => endByte - startByte + 1;
  double get progress => totalBytes > 0 ? downloadedBytes / totalBytes : 0;
}

/// Speed sample for moving average calculation.
class _SpeedSample {
  final int totalBytes;
  final DateTime time;
  _SpeedSample(this.totalBytes, this.time);
}

/// Chrome-style parallel download engine.
///
/// Splits large files into chunks and downloads them simultaneously.
/// Falls back to single-thread for small files or servers that don't
/// support HTTP Range headers.
class ParallelDownloadEngine {
  final String id;
  final String url;
  final String savePath;
  final Map<String, String> headers;
  final int maxChunks;

  // State
  List<DownloadChunk> chunks = [];
  bool isPaused = false;
  bool isCancelled = false;

  // Progress tracking
  int totalFileSize = 0;
  final List<_SpeedSample> _speedSamples = [];
  double currentSpeedBps = 0;
  int etaSeconds = 0;

  // Single-download cancel token (fallback mode)
  CancelToken? _singleCancelToken;

  // Callbacks
  final Function(int downloaded, int total, double speed, int eta)? onProgress;
  final Function(String filePath)? onComplete;
  final Function(String error)? onError;

  ParallelDownloadEngine({
    required this.id,
    required this.url,
    required this.savePath,
    required this.headers,
    this.maxChunks = 4,
    this.onProgress,
    this.onComplete,
    this.onError,
  });

  /// Start the download.
  Future<void> start() async {
    final dio = Dio();
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(minutes: 30);
    dio.options.headers = {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13; SM-G991B) AppleWebKit/537.36',
      ...headers,
    };

    try {
      debugPrint('[$id] 🔍 Checking server capabilities...');

      // Step 1: HEAD request to get file size and range support
      final response = await dio.head(url).timeout(const Duration(seconds: 15));

      final contentLength =
          int.tryParse(response.headers.value('content-length') ?? '0') ?? 0;

      final acceptRanges = response.headers.value('accept-ranges');
      final supportsRanges = acceptRanges == 'bytes' && contentLength > 0;

      totalFileSize = contentLength;
      debugPrint('[$id] 📏 File size: ${_formatBytes(contentLength)}');
      debugPrint('[$id] ⚡ Parallel supported: $supportsRanges');

      if (supportsRanges && contentLength > 1024 * 1024) {
        // File > 1MB and server supports ranges → parallel download
        await _parallelDownload(dio, contentLength);
      } else {
        // Small file or no range support → single-thread download
        await _singleDownload(dio);
      }
    } catch (e) {
      if (!isCancelled && !isPaused) {
        debugPrint('[$id] ❌ Error: $e');
        onError?.call(e.toString());
      }
    } finally {
      dio.close();
    }
  }

  // ── Parallel chunk download ────────────────────────────────────────

  Future<void> _parallelDownload(Dio dio, int fileSize) async {
    final numChunks = min(maxChunks, max(1, (fileSize / (512 * 1024)).ceil()));
    final chunkSize = (fileSize / numChunks).ceil();

    debugPrint('[$id] ⚡ Starting $numChunks parallel chunks');

    final tempDir = await getTemporaryDirectory();
    chunks = List.generate(numChunks, (i) {
      final start = i * chunkSize;
      final end = min(start + chunkSize - 1, fileSize - 1);
      return DownloadChunk(
        index: i,
        startByte: start,
        endByte: end,
        tempPath: '${tempDir.path}/${id}_chunk_$i.tmp',
      );
    });

    // Check for existing partial chunks (resume support)
    for (final chunk in chunks) {
      final tempFile = File(chunk.tempPath);
      if (await tempFile.exists()) {
        final existingSize = await tempFile.length();
        if (existingSize >= chunk.totalBytes) {
          chunk.downloadedBytes = chunk.totalBytes;
          chunk.isCompleted = true;
          debugPrint('[$id] ✅ Chunk ${chunk.index} already completed');
        } else {
          chunk.downloadedBytes = existingSize;
          debugPrint(
            '[$id] 📂 Chunk ${chunk.index} resuming from '
            '${_formatBytes(existingSize)}',
          );
        }
      }
    }

    // Start all incomplete chunks simultaneously
    final futures = chunks
        .where((c) => !c.isCompleted)
        .map((chunk) => _downloadChunk(dio, chunk));

    await Future.wait(futures);

    if (!isCancelled && !isPaused) {
      await _mergeChunks(fileSize);
    }
  }

  Future<void> _downloadChunk(Dio dio, DownloadChunk chunk) async {
    final startByte = chunk.startByte + chunk.downloadedBytes;

    try {
      final response = await dio.get<ResponseBody>(
        url,
        cancelToken: chunk.cancelToken,
        options: Options(
          headers: {...headers, 'Range': 'bytes=$startByte-${chunk.endByte}'},
          responseType: ResponseType.stream,
        ),
      );

      final file = File(chunk.tempPath);
      final sink = file.openWrite(mode: FileMode.append);

      final stream = response.data!.stream;
      await for (final data in stream) {
        if (isCancelled || isPaused) break;
        sink.add(data);
        chunk.downloadedBytes += data.length;
        _updateProgress();
      }

      await sink.flush();
      await sink.close();

      if (!isCancelled && !isPaused) {
        chunk.isCompleted = true;
        debugPrint('[$id] ✅ Chunk ${chunk.index} complete');
      }
    } catch (e) {
      if (!isCancelled && !isPaused) {
        debugPrint('[$id] ❌ Chunk ${chunk.index} error: $e');
        rethrow;
      }
    }
  }

  Future<void> _mergeChunks(int expectedSize) async {
    debugPrint('[$id] 🔀 Merging ${chunks.length} chunks...');

    final outputFile = File(savePath);
    final sink = outputFile.openWrite();

    try {
      for (final chunk in chunks) {
        final chunkFile = File(chunk.tempPath);
        if (!await chunkFile.exists()) {
          throw Exception('Chunk ${chunk.index} file missing!');
        }
        await sink.addStream(chunkFile.openRead());
      }

      await sink.flush();
      await sink.close();

      // Verify final file size
      final finalSize = await outputFile.length();
      debugPrint('[$id] 📁 Final size: ${_formatBytes(finalSize)}');

      if (finalSize != expectedSize && expectedSize > 0) {
        throw Exception(
          'Size mismatch: got $finalSize, expected $expectedSize',
        );
      }

      // Clean up temp chunks
      for (final chunk in chunks) {
        final f = File(chunk.tempPath);
        if (await f.exists()) await f.delete();
      }

      debugPrint('[$id] ✅ Download complete!');
      onComplete?.call(savePath);
    } catch (e) {
      await sink.close();
      debugPrint('[$id] ❌ Merge error: $e');
      onError?.call('Merge failed: $e');
    }
  }

  // ── Single-threaded download (fallback) ────────────────────────────

  Future<void> _singleDownload(Dio dio) async {
    debugPrint('[$id] ⬇️ Single-thread download...');
    _singleCancelToken = CancelToken();

    // Check for partial file (resume)
    int startByte = 0;
    final file = File(savePath);
    if (await file.exists()) {
      startByte = await file.length();
      debugPrint('[$id] 📂 Resuming from ${_formatBytes(startByte)}');
    }

    final rangeHeaders = startByte > 0
        ? {...headers, 'Range': 'bytes=$startByte-'}
        : headers;

    await dio.download(
      url,
      savePath,
      cancelToken: _singleCancelToken,
      deleteOnError: false,
      options: Options(headers: rangeHeaders),
      onReceiveProgress: (received, total) {
        if (isCancelled || isPaused) return;
        final totalReceived = startByte + received;
        final totalSize = total > 0 ? startByte + total : 0;
        totalFileSize = totalSize;
        _updateProgressDirect(totalReceived, totalSize);
      },
    );

    if (!isCancelled && !isPaused) {
      onComplete?.call(savePath);
    }
  }

  // ── Progress tracking ──────────────────────────────────────────────

  void _updateProgress() {
    final totalDownloaded = chunks.fold<int>(
      0,
      (sum, c) => sum + c.downloadedBytes,
    );
    _updateProgressDirect(totalDownloaded, totalFileSize);
  }

  void _updateProgressDirect(int downloaded, int total) {
    final now = DateTime.now();

    _speedSamples.add(_SpeedSample(downloaded, now));

    // Keep only last 8 seconds of samples
    final cutoff = now.subtract(const Duration(seconds: 8));
    _speedSamples.removeWhere((s) => s.time.isBefore(cutoff));

    // Calculate speed using moving average
    if (_speedSamples.length >= 2) {
      final oldest = _speedSamples.first;
      final newest = _speedSamples.last;
      final ms = newest.time.difference(oldest.time).inMilliseconds;
      final bytes = newest.totalBytes - oldest.totalBytes;

      if (ms > 0) {
        currentSpeedBps = (bytes / ms) * 1000;
      }
    }

    // Calculate ETA
    if (currentSpeedBps > 0 && total > 0) {
      final remaining = total - downloaded;
      etaSeconds = (remaining / currentSpeedBps).round();
    }

    onProgress?.call(downloaded, total, currentSpeedBps, etaSeconds);
  }

  // ── Controls ───────────────────────────────────────────────────────

  /// Pause the download.
  void pause() {
    isPaused = true;
    for (final chunk in chunks) {
      if (!chunk.cancelToken.isCancelled) {
        chunk.cancelToken.cancel('paused');
      }
    }
    _singleCancelToken?.cancel('paused');
  }

  /// Cancel the download and delete temp files.
  void cancel() {
    isCancelled = true;
    for (final chunk in chunks) {
      if (!chunk.cancelToken.isCancelled) {
        chunk.cancelToken.cancel('cancelled');
      }
    }
    _singleCancelToken?.cancel('cancelled');

    // Delete temp files
    for (final chunk in chunks) {
      final f = File(chunk.tempPath);
      f.exists().then((exists) {
        if (exists) f.delete();
      });
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────

  static String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
