import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:better_player_enhanced/better_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/video_player_controller.dart';
import '../services/api_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String? linkUrl; // Original link (HubDrive, GoFile, etc.)
  final String? quality; // Quality label (1080p, 720p, etc.)
  final Map<String, String>?
  headers; // Pre-resolved headers from details screen
  final String? localFilePath;
  final int? tmdbId;
  final String? movieTitle;
  final String? posterUrl;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    this.linkUrl,
    this.quality,
    this.headers,
    this.localFilePath,
    this.tmdbId,
    this.movieTitle,
    this.posterUrl,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  BetterPlayerController? _betterPlayerController;
  final VideoPlayerGetxController _positionController =
      Get.find<VideoPlayerGetxController>();

  bool _isResolving = false;
  bool _isInitializing = true;
  String? _errorMessage;
  String? _errorType;

  String? _resolvedUrl;
  Map<String, String>? _headers;

  Duration? _lastSavedPosition;
  Timer? _initTimeout;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initialize();
  }

  Future<void> _initialize() async {
    // If pre-resolved headers were passed from the details screen, use them
    if (widget.headers != null && widget.headers!.isNotEmpty) {
      _headers = widget.headers;
    }

    // Case 1: Need to resolve a link URL (HubDrive, GoFile, etc.)
    if (widget.linkUrl != null && widget.linkUrl!.isNotEmpty) {
      await _resolveLink();
    }
    // Case 2: Direct video URL provided (possibly with pre-resolved headers)
    else if (widget.videoUrl.isNotEmpty) {
      _resolvedUrl = widget.videoUrl;
      await _initPlayer();
    }
    // Case 3: Local file
    else if (widget.localFilePath != null && widget.localFilePath!.isNotEmpty) {
      await _initPlayer();
    }
    // Case 4: Nothing provided
    else {
      if (mounted) {
        setState(() {
          _errorMessage = 'No video source provided';
          _errorType = 'no_source';
          _isInitializing = false;
        });
      }
    }
  }

  /// STEP 1: Resolve link through backend
  Future<void> _resolveLink() async {
    setState(() {
      _isResolving = true;
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService();
      final result = await apiService.resolveDownloadLink(
        url: widget.linkUrl!,
        quality: widget.quality ?? '1080p',
      );

      if (!mounted) return;

      if (result['success'] == true && result['directUrl'] != null) {
        _resolvedUrl = result['directUrl'];

        // Merge headers from resolve if present
        if (result['headers'] != null && result['headers'] is Map) {
          final resolved = Map<String, String>.from(result['headers']);
          _headers = {...?_headers, ...resolved};
          debugPrint('✅ Got streaming headers: ${_headers!.keys.join(", ")}');
        }

        setState(() => _isResolving = false);
        await _initPlayer();
      } else {
        setState(() {
          _isResolving = false;
          _isInitializing = false;
          _errorMessage = result['error'] ?? 'Failed to resolve link';
          _errorType = 'resolve_error';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isResolving = false;
        _isInitializing = false;
        _errorMessage = 'Failed to connect to server: $e';
        _errorType = 'network_error';
      });
    }
  }

  /// STEP 2: Initialize player with resolved URL + headers
  Future<void> _initPlayer() async {
    try {
      BetterPlayerDataSource dataSource;

      // Local file
      if (widget.localFilePath != null && widget.localFilePath!.isNotEmpty) {
        final file = File(widget.localFilePath!);
        if (!await file.exists()) {
          if (mounted) {
            setState(() {
              _errorMessage =
                  'Video file not found at:\n${widget.localFilePath}';
              _errorType = 'file_not_found';
              _isInitializing = false;
            });
          }
          return;
        }
        dataSource = BetterPlayerDataSource(
          BetterPlayerDataSourceType.file,
          widget.localFilePath!,
        );
      }
      // Network URL
      else if (_resolvedUrl != null && _resolvedUrl!.isNotEmpty) {
        // Validate URL
        final uri = Uri.tryParse(_resolvedUrl!);
        if (uri == null || !uri.hasScheme || !uri.scheme.startsWith('http')) {
          if (mounted) {
            setState(() {
              _errorMessage =
                  'Invalid video URL.\nThis link may be an embedded player that cannot be played directly.';
              _errorType = 'invalid_url';
              _isInitializing = false;
            });
          }
          return;
        }

        // Detect embedded player links that BetterPlayer can't handle
        if (_resolvedUrl!.contains('/embed/') ||
            _resolvedUrl!.contains('player.php') ||
            _resolvedUrl!.contains('player.html')) {
          if (mounted) {
            setState(() {
              _errorMessage =
                  'This is an embedded player link.\nCannot play directly in app.';
              _errorType = 'embedded';
              _isInitializing = false;
            });
          }
          return;
        }

        // Build final headers: use backend headers if available, otherwise default
        final effectiveHeaders =
            _headers ??
            const {
              'User-Agent':
                  'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
              'Referer': 'https://hdstream4u.com/',
            };

        dataSource = BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          _resolvedUrl!,
          videoFormat: BetterPlayerVideoFormat.other,
          headers: effectiveHeaders,
        );
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'No video source provided';
            _errorType = 'no_url';
            _isInitializing = false;
          });
        }
        return;
      }

      // Resume from saved position
      Duration? startAt;
      if (widget.tmdbId != null) {
        final savedPosition = _positionController.getPosition(widget.tmdbId!);
        if (savedPosition != null && savedPosition.positionMs > 0) {
          startAt = Duration(milliseconds: savedPosition.positionMs);
        }
      }

      _betterPlayerController = BetterPlayerController(
        BetterPlayerConfiguration(
          autoPlay: true,
          looping: false,
          fullScreenByDefault: false,
          allowedScreenSleep: false,
          startAt: startAt,
          aspectRatio: 16 / 9,
          autoDetectFullscreenAspectRatio: true,
          autoDetectFullscreenDeviceOrientation: true,
          fit: BoxFit.contain,
          controlsConfiguration: BetterPlayerControlsConfiguration(
            enablePlayPause: true,
            enableMute: true,
            enableFullscreen: true,
            enablePip: true,
            enableSkips: true,
            enableProgressBar: true,
            enableProgressText: true,
            enableProgressBarDrag: true,
            enableSubtitles: true,
            enableQualities: true,
            enablePlaybackSpeed: true,
            enableOverflowMenu: true,
            enableRetry: true,
            skipBackIcon: Icons.replay_10,
            skipForwardIcon: Icons.forward_10,
            progressBarPlayedColor: Colors.blueAccent,
            progressBarHandleColor: Colors.blueAccent,
            progressBarBufferedColor: Colors.white24,
            progressBarBackgroundColor: Colors.white12,
            controlBarHeight: 48,
            iconsColor: Colors.white,
            loadingWidget: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.blueAccent),
                  const SizedBox(height: 16),
                  Text(
                    'Loading video...',
                    style: GoogleFonts.inter(color: Colors.white54),
                  ),
                ],
              ),
            ),
          ),
          eventListener: (BetterPlayerEvent event) {
            if (event.betterPlayerEventType ==
                BetterPlayerEventType.initialized) {
              _initTimeout?.cancel();
              if (mounted) setState(() => _isInitializing = false);
            } else if (event.betterPlayerEventType ==
                BetterPlayerEventType.progress) {
              _onPositionChanged();
            } else if (event.betterPlayerEventType ==
                BetterPlayerEventType.exception) {
              _initTimeout?.cancel();
              if (mounted) {
                setState(() {
                  _errorMessage = 'Playback error occurred';
                  _errorType = 'playback_error';
                  _isInitializing = false;
                });
              }
            }
          },
        ),
        betterPlayerDataSource: dataSource,
      );

      if (mounted) setState(() {});

      // Timeout — if player doesn't initialize in 30s, show error
      _initTimeout = Timer(const Duration(seconds: 30), () {
        if (_isInitializing && mounted) {
          setState(() {
            _errorMessage =
                'Video failed to load within 30 seconds.\nThe stream may be unavailable or the link may have expired.';
            _errorType = 'timeout';
            _isInitializing = false;
          });
        }
      });
    } on PlatformException catch (e) {
      debugPrint('📱 Platform error: ${e.code} - ${e.message}');
      if (mounted) {
        setState(() {
          _errorMessage =
              'Player error: ${e.message}\nTry downloading instead.';
          _errorType = 'platform_error';
          _isInitializing = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Player error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to play video:\n$e';
          _errorType = 'init_error';
          _isInitializing = false;
        });
      }
    }
  }

  void _onPositionChanged() {
    if (widget.tmdbId == null) return;
    if (_betterPlayerController == null) return;

    final videoPlayerValue =
        _betterPlayerController!.videoPlayerController?.value;
    if (videoPlayerValue == null || !videoPlayerValue.initialized) return;

    final position = videoPlayerValue.position;
    final duration = videoPlayerValue.duration;
    if (duration == null) return;

    // Save every 5 seconds of playback
    if (position.inSeconds % 5 == 0 &&
        position.inSeconds > 0 &&
        (_lastSavedPosition == null ||
            (position - _lastSavedPosition!).inSeconds.abs() >= 4)) {
      _lastSavedPosition = position;
      _positionController.savePosition(
        tmdbId: widget.tmdbId!,
        movieTitle: widget.movieTitle ?? 'Unknown',
        posterUrl: widget.posterUrl,
        positionMs: position.inMilliseconds,
        durationMs: duration.inMilliseconds,
        videoUrl: _resolvedUrl ?? widget.videoUrl,
        localFilePath: widget.localFilePath,
      );
    }
  }

  @override
  void dispose() {
    _initTimeout?.cancel();

    // Save final position
    if (widget.tmdbId != null && _betterPlayerController != null) {
      final videoPlayerValue =
          _betterPlayerController!.videoPlayerController?.value;
      if (videoPlayerValue != null && videoPlayerValue.initialized) {
        _positionController.savePosition(
          tmdbId: widget.tmdbId!,
          movieTitle: widget.movieTitle ?? 'Unknown',
          posterUrl: widget.posterUrl,
          positionMs: videoPlayerValue.position.inMilliseconds,
          durationMs:
              (videoPlayerValue.duration ?? Duration.zero).inMilliseconds,
          videoUrl: _resolvedUrl ?? widget.videoUrl,
          localFilePath: widget.localFilePath,
        );
      }
    }

    _betterPlayerController?.dispose();
    WakelockPlus.disable();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black, body: _buildBody());
  }

  Widget _buildBody() {
    // Resolving link
    if (_isResolving) {
      return _buildResolving();
    }
    // Initializing player (no controller yet)
    if (_isInitializing && _betterPlayerController == null) {
      return _buildLoading();
    }
    // Error
    if (_errorMessage != null) {
      return _buildError();
    }
    // Playing
    return _buildPlayer();
  }

  Widget _buildResolving() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.blueAccent),
          const SizedBox(height: 20),
          Text(
            'Preparing Video...',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Resolving stream link, please wait',
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'This may take up to 60 seconds',
            style: GoogleFonts.inter(color: Colors.white30, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.blueAccent),
          const SizedBox(height: 20),
          Text(
            'Loading video...',
            style: GoogleFonts.inter(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    final isEmbedded = _errorType == 'embedded';
    final canOpenExternal =
        isEmbedded || _errorType == 'playback_error' || _errorType == 'timeout';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 80),
            const SizedBox(height: 20),
            Text(
              'Cannot Play Video',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                // Retry button
                ElevatedButton.icon(
                  onPressed: () {
                    _betterPlayerController?.dispose();
                    _betterPlayerController = null;
                    setState(() {
                      _isResolving = false;
                      _isInitializing = true;
                      _errorMessage = null;
                      _errorType = null;
                    });
                    _initialize();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                // Open in external player
                if (canOpenExternal && _resolvedUrl != null)
                  ElevatedButton.icon(
                    onPressed: () => _openExternal(),
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('Open Externally'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                // Go back
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    return Stack(
      children: [
        Center(
          child: _betterPlayerController != null
              ? BetterPlayer(controller: _betterPlayerController!)
              : const SizedBox.shrink(),
        ),
        // Back button overlay
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  /// Open URL in external video player (MX Player, VLC, etc.)
  Future<void> _openExternal() async {
    if (_resolvedUrl == null) return;

    try {
      final uri = Uri.parse(_resolvedUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar(
          'Error',
          'No external player app found.\nInstall MX Player or VLC.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          margin: const EdgeInsets.all(20),
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to open external player',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(20),
      );
    }
  }
}
