import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:better_player_enhanced/better_player.dart';
import '../controllers/video_player_controller.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String? localFilePath;
  final int? tmdbId;
  final String? movieTitle;
  final String? posterUrl;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
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

  bool _isInitializing = true;
  String? _errorMessage;
  Duration? _lastSavedPosition;
  Timer? _initTimeout;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      BetterPlayerDataSource dataSource;

      if (widget.localFilePath != null && widget.localFilePath!.isNotEmpty) {
        final file = File(widget.localFilePath!);
        if (!await file.exists()) {
          setState(() {
            _errorMessage = 'Video file not found at:\n${widget.localFilePath}';
            _isInitializing = false;
          });
          return;
        }
        dataSource = BetterPlayerDataSource(
          BetterPlayerDataSourceType.file,
          widget.localFilePath!,
        );
      } else if (widget.videoUrl.isNotEmpty) {
        // Validate URL before passing to player
        final uri = Uri.tryParse(widget.videoUrl);
        if (uri == null || !uri.hasScheme || (!uri.scheme.startsWith('http'))) {
          setState(() {
            _errorMessage =
                'Invalid video URL.\nThis link may be an embedded player that cannot be played directly.';
            _isInitializing = false;
          });
          return;
        }

        dataSource = BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          widget.videoUrl,
          videoFormat: BetterPlayerVideoFormat.other,
          headers: const {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
            'Referer': 'https://hdstream4u.com/',
          },
        );
      } else {
        setState(() {
          _errorMessage = 'No video source provided';
          _isInitializing = false;
        });
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
          // Player behavior
          autoPlay: true,
          looping: false,
          fullScreenByDefault: false,
          allowedScreenSleep: false,
          startAt: startAt,

          // Aspect ratio
          aspectRatio: 16 / 9,
          autoDetectFullscreenAspectRatio: true,
          autoDetectFullscreenDeviceOrientation: true,
          fit: BoxFit.contain,

          // UI configuration
          controlsConfiguration: BetterPlayerControlsConfiguration(
            // Player controls
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

            // Skip durations
            skipBackIcon: Icons.replay_10,
            skipForwardIcon: Icons.forward_10,

            // Colors (modern style)
            progressBarPlayedColor: Colors.blueAccent,
            progressBarHandleColor: Colors.blueAccent,
            progressBarBufferedColor: Colors.white24,
            progressBarBackgroundColor: Colors.white12,

            // Control bar
            controlBarHeight: 48,
            iconsColor: Colors.white,

            // Loading widget
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

          // Buffering configuration
          // Event listener
          eventListener: (BetterPlayerEvent event) {
            if (event.betterPlayerEventType ==
                BetterPlayerEventType.initialized) {
              _initTimeout?.cancel();
              setState(() => _isInitializing = false);
            } else if (event.betterPlayerEventType ==
                BetterPlayerEventType.progress) {
              _onPositionChanged();
            } else if (event.betterPlayerEventType ==
                BetterPlayerEventType.exception) {
              _initTimeout?.cancel();
              setState(() {
                _errorMessage = 'Playback error occurred';
                _isInitializing = false;
              });
            }
          },
        ),
        betterPlayerDataSource: dataSource,
      );

      setState(() {});

      // Start initialization timeout — if player doesn't initialize in 15s, show error
      _initTimeout = Timer(const Duration(seconds: 15), () {
        if (_isInitializing && mounted) {
          setState(() {
            _errorMessage =
                'Video failed to load within 15 seconds.\nThe stream may be unavailable or the link may have expired.';
            _isInitializing = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to play video:\n$e';
        _isInitializing = false;
      });
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
        videoUrl: widget.videoUrl.isNotEmpty ? widget.videoUrl : null,
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
          videoUrl: widget.videoUrl.isNotEmpty ? widget.videoUrl : null,
          localFilePath: widget.localFilePath,
        );
      }
    }

    _betterPlayerController?.dispose();

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isInitializing && _betterPlayerController == null
          ? _buildLoading()
          : _errorMessage != null
          ? _buildError()
          : _buildPlayer(),
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
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Go Back'),
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
}
