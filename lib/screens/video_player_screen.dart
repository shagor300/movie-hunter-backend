import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:io';
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
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  final VideoPlayerGetxController _positionController =
      Get.find<VideoPlayerGetxController>();

  bool _isInitializing = true;
  String? _errorMessage;

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
      if (widget.localFilePath != null && widget.localFilePath!.isNotEmpty) {
        final file = File(widget.localFilePath!);
        if (!await file.exists()) {
          setState(() {
            _errorMessage = 'Video file not found at:\n${widget.localFilePath}';
            _isInitializing = false;
          });
          return;
        }
        _videoController = VideoPlayerController.file(file);
      } else if (widget.videoUrl.isNotEmpty) {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUrl),
          httpHeaders: const {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          },
        );
      } else {
        setState(() {
          _errorMessage = 'No video source provided';
          _isInitializing = false;
        });
        return;
      }

      await _videoController.initialize().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception(
          'Video took too long to load. The source may be unreachable.',
        ),
      );

      if (!_videoController.value.isInitialized) {
        throw Exception('Video source could not be initialized.');
      }

      // Resume from saved position
      if (widget.tmdbId != null) {
        final savedPosition = _positionController.getPosition(widget.tmdbId!);
        if (savedPosition != null && savedPosition.positionMs > 0) {
          await _videoController.seekTo(
            Duration(milliseconds: savedPosition.positionMs),
          );
        }
      }

      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        allowPlaybackSpeedChanging: true,
        playbackSpeeds: const [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0],
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.blueAccent,
          handleColor: Colors.blueAccent,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white38,
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.redAccent, size: 60),
                const SizedBox(height: 16),
                Text(
                  'Playback Error',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: GoogleFonts.inter(color: Colors.white54),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );

      // Periodic position save
      _videoController.addListener(_onPositionChanged);

      setState(() => _isInitializing = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to play video:\n$e';
        _isInitializing = false;
      });
    }
  }

  void _onPositionChanged() {
    if (widget.tmdbId == null) return;
    if (!_videoController.value.isInitialized) return;

    final position = _videoController.value.position;
    final duration = _videoController.value.duration;

    // Save every 5 seconds of playback
    if (position.inSeconds % 5 == 0 && position.inSeconds > 0) {
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
    // Save final position
    if (widget.tmdbId != null && _videoController.value.isInitialized) {
      _positionController.savePosition(
        tmdbId: widget.tmdbId!,
        movieTitle: widget.movieTitle ?? 'Unknown',
        posterUrl: widget.posterUrl,
        positionMs: _videoController.value.position.inMilliseconds,
        durationMs: _videoController.value.duration.inMilliseconds,
        videoUrl: widget.videoUrl.isNotEmpty ? widget.videoUrl : null,
        localFilePath: widget.localFilePath,
      );
    }

    _videoController.removeListener(_onPositionChanged);
    _chewieController?.dispose();
    _videoController.dispose();

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isInitializing
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
          child: _chewieController != null
              ? Chewie(controller: _chewieController!)
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
