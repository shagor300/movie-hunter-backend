Hi Antigravity,

We have TWO CRITICAL BUGS that need to be fixed immediately:

═══════════════════════════════════════
BUG 1: VOICE SEARCH - 3 ISSUES
═══════════════════════════════════════

ISSUE 1A: Partial Text Recognition
When user says "yo yo honey singh" the app only captures "yo" or "yo yo" - not the full phrase.

ROOT CAUSE:
- Speech recognition stops too early
- pauseFor duration is too short
- finalResult is triggering before user finishes speaking

FIX REQUIRED:
```dart
await _speech.listen(
  onResult: (result) {
    // ONLY update text, do NOT search yet
    recognizedText.value = result.recognizedWords;
    
    // ONLY trigger search on final result
    if (result.finalResult) {
      _performSearch(result.recognizedWords);
    }
  },
  
  listenFor: Duration(seconds: 30),  // Max listen time
  pauseFor: Duration(seconds: 5),    // Wait 5 seconds after user stops
  partialResults: true,              // Show text while speaking
  cancelOnError: false,              // Don't cancel on small errors
);
```

ISSUE 1B: Black Screen After Voice Search
After voice recognition, app shows black screen instead of search results.

ROOT CAUSE:
- Navigation happening before speech stops
- Competing navigation calls
- Missing mounted check

FIX REQUIRED:
```dart
void _handleVoiceResult(String text) async {
  // Stop listening first
  await _speech.stop();
  isListening.value = false;
  
  // Wait for navigation stack to settle
  await Future.delayed(Duration(milliseconds: 300));
  
  // Safety check
  if (text.trim().isEmpty) return;
  
  // Navigate safely
  if (Get.isRegistered<SearchController>()) {
    Get.find<SearchController>().searchMovies(text);
  }
  
  // Go to search screen if not already there
  if (Get.currentRoute != '/search') {
    Get.toNamed('/search');
  }
}
```

ISSUE 1C: No Sound Effect on Voice Search Tap
When user taps mic button, there should be a sound like YouTube voice search.

FIX REQUIRED:
```dart
// Add to pubspec.yaml
audioplayers: ^5.2.1

// Play sound on mic tap
import 'package:audioplayers/audioplayers.dart';

final player = AudioPlayer();

void _onMicTap() async {
  // Play YouTube-like start sound
  await player.play(AssetSource('sounds/voice_start.mp3'));
  
  // Small delay then start listening
  await Future.delayed(Duration(milliseconds: 200));
  
  startListening();
}

void _onListeningStop() async {
  // Play end sound
  await player.play(AssetSource('sounds/voice_end.mp3'));
}
```

ADD THESE SOUND FILES:
- assets/sounds/voice_start.mp3 (short "ding" sound)
- assets/sounds/voice_end.mp3 (short "end" sound)

UPDATE pubspec.yaml:
```yaml
flutter:
  assets:
    - assets/sounds/voice_start.mp3
    - assets/sounds/voice_end.mp3
```

═══════════════════════════════════════
BUG 2: VIDEO PLAYER CRASH - CRITICAL
═══════════════════════════════════════

CURRENT BEHAVIOR:
1. User taps Play button ✅
2. "Preparing Video... Resolving stream link, please wait" shows ✅
3. Video resolves ✅
4. Video starts playing ✅
5. APP CLOSES IMMEDIATELY ❌ ← CRITICAL BUG

ROOT CAUSE ANALYSIS:
The app crashes when VideoPlayerController initializes because:
1. Memory spike when loading large video (2.1GB or 10.7GB)
2. Missing error handling in video player initialization
3. Player disposing before playback starts
4. Headers/cookies missing causing authentication failure
5. Platform channel error not caught

FIX REQUIRED - Complete Video Player Implementation:
```dart
// lib/screens/player/video_player_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;
  final Map<String, String>? headers;
  
  const VideoPlayerScreen({
    Key? key,
    required this.videoUrl,
    required this.title,
    this.headers,
  }) : super(key: key);
  
  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    
    // Keep screen on during video
    WakelockPlus.enable();
    
    // Force landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // Initialize player safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePlayer();
    });
  }
  
  Future<void> _initializePlayer() async {
    try {
      print('🎬 Initializing video player...');
      print('📡 URL: ${widget.videoUrl}');
      print('📋 Headers: ${widget.headers}');
      
      // Create controller with headers
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        httpHeaders: widget.headers ?? {},
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );
      
      // Initialize with timeout
      await _videoController!.initialize().timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Video initialization timed out');
        },
      );
      
      print('✅ Video initialized successfully');
      print('📐 Size: ${_videoController!.value.size}');
      print('⏱️ Duration: ${_videoController!.value.duration}');
      
      // Create Chewie controller
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        placeholder: Container(color: Colors.black),
        errorBuilder: (context, errorMessage) {
          return _buildErrorScreen(errorMessage);
        },
      );
      
      // Update state safely
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
      }
      
    } on TimeoutException catch (e) {
      print('⏱️ Timeout: $e');
      _showError('Video loading timed out. Please try again.');
      
    } on PlatformException catch (e) {
      print('📱 Platform error: ${e.code} - ${e.message}');
      _showError('Player error: ${e.message}');
      
    } catch (e, stackTrace) {
      print('❌ Player error: $e');
      print('Stack: $stackTrace');
      _showError('Cannot play this video. Try downloading instead.');
    }
  }
  
  void _showError(String message) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = message;
      });
    }
  }
  
  @override
  void dispose() {
    print('🗑️ Disposing video player...');
    
    // Restore orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    
    // Disable wakelock
    WakelockPlus.disable();
    
    // Dispose controllers in order
    _chewieController?.dispose();
    _videoController?.dispose();
    
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Restore portrait on back
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingScreen();
    }
    
    if (_hasError) {
      return _buildErrorScreen(_errorMessage);
    }
    
    return _buildPlayer();
  }
  
  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF6200EE)),
          SizedBox(height: 24),
          Text(
            'Loading video...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            widget.title,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlayer() {
    if (_chewieController == null) {
      return _buildErrorScreen('Player not initialized');
    }
    
    return Chewie(controller: _chewieController!);
  }
  
  Widget _buildErrorScreen(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 64),
            SizedBox(height: 24),
            Text(
              'Playback Error',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _hasError = false;
                    });
                    _initializePlayer();
                  },
                  icon: Icon(Icons.refresh),
                  label: Text('Retry'),
                ),
                SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => Get.back(),
                  icon: Icon(Icons.arrow_back),
                  label: Text('Go Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

DEPENDENCIES TO ADD (pubspec.yaml):
```yaml
dependencies:
  video_player: ^2.8.2
  chewie: ^1.7.4
  wakelock_plus: ^1.1.4
  audioplayers: ^5.2.1
```

═══════════════════════════════════════
HOW TO CALL VIDEO PLAYER CORRECTLY:
═══════════════════════════════════════

When Play button is tapped, call like this:
```dart
void _onPlayTap(String hubdriveUrl, String title) async {
  try {
    // Show loading
    Get.dialog(
      Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    
    // Resolve link (same as download)
    final result = await apiService.resolveStreamLink(hubdriveUrl);
    
    // Close loading
    Get.back();
    
    if (result['success'] == true) {
      // Navigate to player with all required data
      Get.to(
        () => VideoPlayerScreen(
          videoUrl: result['direct_url'],
          title: title,
          headers: {
            'User-Agent': result['user_agent'] ?? '',
            'Cookie': result['cookies'] ?? '',
            'Referer': result['referer'] ?? '',
          },
        ),
        transition: Transition.fadeIn,
      );
    } else {
      Get.snackbar(
        'Error',
        'Cannot load video. Try downloading instead.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
      );
    }
    
  } catch (e) {
    Get.back(); // Close loading
    Get.snackbar(
      'Error',
      'Failed to prepare video: $e',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
```

═══════════════════════════════════════
TESTING CHECKLIST:
═══════════════════════════════════════

Voice Search:
[ ] Say long phrase "yo yo honey singh" - full text shows
[ ] No black screen after voice search
[ ] Sound plays on mic tap
[ ] Sound plays when listening stops
[ ] Search results show correctly

Video Player:
[ ] "Preparing Video" shows
[ ] Video loads without crash
[ ] App does NOT close during playback
[ ] Controls work (play, pause, seek)
[ ] Back button works
[ ] Screen stays landscape during video
[ ] Returns to portrait after exit
[ ] Error screen shows if video fails
[ ] Retry button works

═══════════════════════════════════════
PRIORITY: CRITICAL - Fix immediately!
═══════════════════════════════════════

Thank you!