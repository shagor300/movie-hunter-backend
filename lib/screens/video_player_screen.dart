import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:better_player_enhanced/better_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/video_player_controller.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_controller.dart';

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

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with WidgetsBindingObserver {
  BetterPlayerController? _betterPlayerController;
  final VideoPlayerGetxController _positionController =
      Get.find<VideoPlayerGetxController>();
  final Color _accent = Get.find<ThemeController>().accentColor;

  bool _isResolving = false;
  bool _isInitializing = true;
  String? _errorMessage;
  String? _errorType;

  String? _resolvedUrl;
  Map<String, String>? _headers;

  Duration? _lastSavedPosition;
  Timer? _initTimeout;

  // ── Double-tap seek state ──
  bool _showSeekForward = false;
  bool _showSeekBackward = false;
  int _seekSeconds = 0;
  Timer? _seekTimer;

  // ── Enhanced overlay state ──
  bool _showOverlay = true;
  Timer? _overlayTimer;
  bool _isLocked = false;

  // ── Brightness & Volume gesture state ──
  double _currentBrightness = 0.5;
  double _currentVolume = 0.5;
  bool _showBrightnessSlider = false;
  bool _showVolumeSlider = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _startOverlayTimer();
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
            progressBarPlayedColor: _accent,
            progressBarHandleColor: _accent,
            progressBarBufferedColor: AppColors.surfaceLight,
            progressBarBackgroundColor: AppColors.surface,
            controlBarHeight: 48,
            iconsColor: Colors.white,
            loadingWidget: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _accent),
                  const SizedBox(height: 16),
                  Text('Loading video...', style: AppTextStyles.bodySmall),
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Auto-enter PiP when user leaves app while video is playing
    if (state == AppLifecycleState.inactive) {
      final vpc = _betterPlayerController?.videoPlayerController;
      if (vpc != null && vpc.value.isPlaying) {
        try {
          _betterPlayerController?.enablePictureInPicture(
            _betterPlayerController!.betterPlayerGlobalKey!,
          );
        } catch (e) {
          debugPrint('⚠️ PiP error: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _overlayTimer?.cancel();
    _seekTimer?.cancel();
    _initTimeout?.cancel();

    // Save final position
    if (widget.tmdbId != null && _betterPlayerController != null) {
      final vpValue = _betterPlayerController!.videoPlayerController?.value;
      if (vpValue != null && vpValue.initialized) {
        final pos = vpValue.position;
        final dur = vpValue.duration ?? Duration.zero;
        if (pos.inSeconds > 5 && dur.inSeconds > 0) {
          _positionController.savePosition(
            tmdbId: widget.tmdbId!,
            movieTitle: widget.movieTitle ?? 'Unknown',
            posterUrl: widget.posterUrl,
            positionMs: pos.inMilliseconds,
            durationMs: dur.inMilliseconds,
            videoUrl: _resolvedUrl ?? widget.videoUrl,
            localFilePath: widget.localFilePath,
          );
        }
      }
    }

    _betterPlayerController?.dispose();
    WakelockPlus.disable();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  // ── Overlay timer ──
  void _startOverlayTimer() {
    _overlayTimer?.cancel();
    _overlayTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showOverlay = false);
    });
  }

  void _toggleOverlay() {
    if (_isLocked) return;
    setState(() => _showOverlay = !_showOverlay);
    if (_showOverlay) _startOverlayTimer();
  }

  void _toggleLock() {
    setState(() {
      _isLocked = !_isLocked;
      _showOverlay = true;
    });
    if (!_isLocked) _startOverlayTimer();
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
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          Text(
            'Preparing Video...',
            style: AppTextStyles.headingLarge.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Resolving stream link, please wait',
            style: AppTextStyles.bodySmall.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'This may take up to 60 seconds',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
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
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          Text('Loading video...', style: AppTextStyles.bodySmall),
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
              style: AppTextStyles.headingLarge.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
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
                    backgroundColor: Theme.of(context).colorScheme.primary,
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
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.surfaceLight),
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

  /// Seek the video by [seconds] (positive = forward, negative = backward)
  void _seekBy(int seconds) {
    if (_betterPlayerController == null) return;
    final vpValue = _betterPlayerController!.videoPlayerController?.value;
    if (vpValue == null || !vpValue.initialized) return;

    final current = vpValue.position;
    final duration = vpValue.duration ?? Duration.zero;
    final target = current + Duration(seconds: seconds);
    final clamped = Duration(
      milliseconds: target.inMilliseconds.clamp(0, duration.inMilliseconds),
    );
    _betterPlayerController!.seekTo(clamped);
  }

  void _onDoubleTapSeek(bool isForward) {
    _seekTimer?.cancel();
    _seekBy(isForward ? 10 : -10);
    setState(() {
      _seekSeconds += 10;
      if (isForward) {
        _showSeekForward = true;
        _showSeekBackward = false;
      } else {
        _showSeekBackward = true;
        _showSeekForward = false;
      }
    });
    HapticFeedback.lightImpact();
    _seekTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showSeekForward = false;
          _showSeekBackward = false;
          _seekSeconds = 0;
        });
      }
    });
  }

  Widget _buildPlayer() {
    final vpValue = _betterPlayerController?.videoPlayerController?.value;
    final isPlaying = vpValue?.isPlaying ?? false;
    final position = vpValue?.position ?? Duration.zero;
    final duration = vpValue?.duration ?? Duration.zero;

    return Stack(
      children: [
        // ── Video Player ──
        Center(
          child: _betterPlayerController != null
              ? BetterPlayer(controller: _betterPlayerController!)
              : const SizedBox.shrink(),
        ),

        // ── Tap & Swipe Gesture Layer ──
        if (!_isLocked)
          Positioned.fill(
            child: Row(
              children: [
                // Left half — brightness + seek backward
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _toggleOverlay,
                    onDoubleTap: () => _onDoubleTapSeek(false),
                    onVerticalDragUpdate: (details) {
                      setState(() {
                        _currentBrightness =
                            (_currentBrightness - details.delta.dy / 300).clamp(
                              0.0,
                              1.0,
                            );
                        _showBrightnessSlider = true;
                        _showVolumeSlider = false;
                      });
                    },
                    onVerticalDragEnd: (_) {
                      Future.delayed(const Duration(seconds: 1), () {
                        if (mounted) {
                          setState(() => _showBrightnessSlider = false);
                        }
                      });
                    },
                    child: const SizedBox.expand(),
                  ),
                ),
                // Right half — volume + seek forward
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _toggleOverlay,
                    onDoubleTap: () => _onDoubleTapSeek(true),
                    onVerticalDragUpdate: (details) {
                      setState(() {
                        _currentVolume =
                            (_currentVolume - details.delta.dy / 300).clamp(
                              0.0,
                              1.0,
                            );
                        _showVolumeSlider = true;
                        _showBrightnessSlider = false;
                      });
                      _betterPlayerController?.setVolume(_currentVolume);
                    },
                    onVerticalDragEnd: (_) {
                      Future.delayed(const Duration(seconds: 1), () {
                        if (mounted) setState(() => _showVolumeSlider = false);
                      });
                    },
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),

        // ── Double-Tap Seek Backward Ripple ──
        if (_showSeekBackward)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: MediaQuery.of(context).size.width * 0.4,
            child: AnimatedOpacity(
              opacity: _showSeekBackward ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.centerLeft,
                    radius: 0.8,
                    colors: [
                      Colors.white.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.fast_rewind_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$_seekSeconds seconds',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // ── Double-Tap Seek Forward Ripple ──
        if (_showSeekForward)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: MediaQuery.of(context).size.width * 0.4,
            child: AnimatedOpacity(
              opacity: _showSeekForward ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.centerRight,
                    radius: 0.8,
                    colors: [
                      Colors.white.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.fast_forward_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$_seekSeconds seconds',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // ── Brightness Indicator ──
        if (_showBrightnessSlider)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _currentBrightness > 0.5
                        ? Icons.brightness_high
                        : Icons.brightness_low,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _currentBrightness,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation(_accent),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${(_currentBrightness * 100).round()}%',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

        // ── Volume Indicator ──
        if (_showVolumeSlider)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _currentVolume > 0.5
                        ? Icons.volume_up
                        : _currentVolume > 0
                        ? Icons.volume_down
                        : Icons.volume_off,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _currentVolume,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation(_accent),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${(_currentVolume * 100).round()}%',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

        // ── Lock Screen Button (always visible when locked) ──
        if (_isLocked)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _showOverlay = !_showOverlay),
              child: Container(color: Colors.transparent),
            ),
          ),

        if (_isLocked && _showOverlay)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _toggleLock,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: _accent.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_open, color: _accent, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Tap to Unlock',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // ── Top Bar Overlay (title + controls) ──
        if (_showOverlay && !_isLocked)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 4,
                left: 8,
                right: 8,
                bottom: 8,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  // Title + quality
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.movieTitle ?? 'Playing Video',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.quality != null)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _accent.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              widget.quality!,
                              style: TextStyle(
                                color: _accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Lock button
                  IconButton(
                    icon: const Icon(
                      Icons.lock_outline,
                      color: Colors.white,
                      size: 22,
                    ),
                    tooltip: 'Lock Screen',
                    onPressed: _toggleLock,
                  ),
                  // PiP button
                  IconButton(
                    icon: const Icon(
                      Icons.picture_in_picture_alt_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    tooltip: 'Picture in Picture',
                    onPressed: () {
                      try {
                        _betterPlayerController?.enablePictureInPicture(
                          _betterPlayerController!.betterPlayerGlobalKey!,
                        );
                      } catch (e) {
                        debugPrint('⚠️ PiP error: $e');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

        // ── Bottom Progress Bar (when overlay hidden) ──
        if (!_showOverlay && !_isLocked && duration.inSeconds > 0)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: duration.inMilliseconds > 0
                  ? (position.inMilliseconds / duration.inMilliseconds).clamp(
                      0.0,
                      1.0,
                    )
                  : 0,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(_accent),
              minHeight: 3,
            ),
          ),

        // ── Center Play/Pause Button ──
        if (_showOverlay && !_isLocked && _betterPlayerController != null)
          Center(
            child: GestureDetector(
              onTap: () {
                if (isPlaying) {
                  _betterPlayerController?.pause();
                } else {
                  _betterPlayerController?.play();
                }
                setState(() {});
                _startOverlayTimer();
              },
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),

        // ── Skip buttons flanking center ──
        if (_showOverlay && !_isLocked && _betterPlayerController != null)
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.replay_10,
                    color: Colors.white70,
                    size: 30,
                  ),
                  onPressed: () => _seekBy(-10),
                ),
                const SizedBox(width: 80), // space for center play/pause
                IconButton(
                  icon: const Icon(
                    Icons.forward_10,
                    color: Colors.white70,
                    size: 30,
                  ),
                  onPressed: () => _seekBy(10),
                ),
              ],
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
