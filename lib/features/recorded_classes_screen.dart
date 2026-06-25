import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../core/theme.dart';
import '../core/app_state.dart';
import 'feedback_hub_screen.dart';

class RecordedClassesScreen extends StatefulWidget {
  const RecordedClassesScreen({Key? key}) : super(key: key);

  @override
  State<RecordedClassesScreen> createState() => _RecordedClassesScreenState();
}

class _RecordedClassesScreenState extends State<RecordedClassesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<AppState>(context, listen: false);
      if (state.isLoggedIn) {
        state.syncRecordedLecturesFromDb();
      }
    });
  }


  void _simulatePlayVideo(String videoTitle, String teacherName, String durationStr, String videoUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerPlaybackPage(
          videoTitle: videoTitle,
          durationStr: durationStr,
          videoUrl: videoUrl,
          onVideoFinished: () {
            final subject = _getSubjectFromTopic(videoTitle);
            final now = DateTime.now();
            final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
            final ampm = now.hour >= 12 ? 'PM' : 'AM';
            final minutesStr = now.minute < 10 ? '0${now.minute}' : '${now.minute}';
            final timeStr = '$hour:$minutesStr $ampm';
            
            Provider.of<AppState>(context, listen: false).markAttendance(subject, 'Present', timeStr, source: 'Recorded Video');
            _showCelebrationDialog(videoTitle, teacherName);
          },
        ),
      ),
    );
  }

  String _getSubjectFromTopic(String title) {
    if (title.contains('Math')) return 'Mathematics';
    if (title.contains('Science')) return 'Science';
    if (title.contains('English')) return 'English';
    if (title.contains('Social')) return 'Social Studies';
    return 'Mathematics';
  }

  void _showCelebrationDialog(String videoTitle, String teacherName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Lecture Completed!',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text(
              'Fantastic job completing the lecture:',
              style: GoogleFonts.outfit(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              videoTitle,
              style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Your attendance for this recorded session has been auto-marked as Present!',
              style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Bonus Reward: +30 Focus XP!',
              style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueAccent),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Awesome!', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(context); // Close celebration dialog
              // Open Feedback Modal popup!
              VideoLectureFeedbackModal.show(context, videoTitle, teacherName);
            },
          )
        ],
      )
    );
  }

  Widget _buildRecordedTile(String topicName, String meta, String teacher, String icon, String videoUrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: () => _simulatePlayVideo(topicName, teacher, meta, videoUrl),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.82),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.18), width: 1.5),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.12),
                offset: const Offset(0, 4),
                blurRadius: 10,
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF10B981), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(topicName, style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('$meta • $teacher', style: GoogleFonts.outfit(fontSize: 10, color: AdyapanTheme.textSub)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF059669).withOpacity(0.3), offset: const Offset(0, 3), blurRadius: 4),
                  ],
                ),
                child: Text(
                  'Play',
                  style: GoogleFonts.fredoka(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          appBar: AppBar(
            title: Text('Library of Recorded Classes', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
            backgroundColor: Colors.white.withOpacity(0.8),
            elevation: 0,
            iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFEEF2F6),
                  Color(0xFFE0E7FF),
                  Color(0xFFFFF0F5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
        child: RefreshIndicator(
          onRefresh: () async {
            await state.syncRecordedLecturesFromDb();
          },
          color: const Color(0xFF10B981),
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Intro
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.82),
                      border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.18), width: 1.5),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.video_library_rounded, color: Color(0xFF1E3A8A), size: 32),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Class Video Library', style: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
                              Text('Watch past lecture recordings of your classroom at your own convenience.', style: GoogleFonts.outfit(fontSize: 11, color: AdyapanTheme.textSub)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text('Past Recorded Lectures', style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
                  const SizedBox(height: 12),

                  ...state.recordedLectures.map((lecture) {
                    return _buildRecordedTile(
                      lecture['title'] as String? ?? '',
                      lecture['duration'] as String? ?? 'Recorded • 40 mins',
                      lecture['teacher'] as String? ?? 'Teacher',
                      lecture['emoji'] as String? ?? '📹',
                      lecture['videoUrl'] as String? ?? '',
                    );
                  }).toList(),
                ],
              ),
            ),
          )),
        );
      },
    );
  }
}

// =========================================================================
//  DEDICATED VISUAL FULL-SCREEN PAGE: SIMULATED VIDEO PLAYER PLAYBACK
// =========================================================================
class VideoPlayerPlaybackPage extends StatefulWidget {
  final String videoTitle;
  final String durationStr;
  final String videoUrl;
  final VoidCallback onVideoFinished;

  const VideoPlayerPlaybackPage({
    Key? key,
    required this.videoTitle,
    required this.durationStr,
    required this.videoUrl,
    required this.onVideoFinished,
  }) : super(key: key);

  @override
  State<VideoPlayerPlaybackPage> createState() => _VideoPlayerPlaybackPageState();
}

class _VideoPlayerPlaybackPageState extends State<VideoPlayerPlaybackPage> {
  double _progress = 0.0;
  double _maxWatchedProgress = 0.05;
  bool _isPlaying = false;
  Timer? _videoPlayTimer;
  double _totalMinutes = 45.0;

  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _totalMinutes = _parseDurationMinutes(widget.durationStr);
    _initializePlayer();
  }

  double _parseDurationMinutes(String durationStr) {
    final lower = durationStr.toLowerCase();
    
    // Check if duration specifies hours/hr
    if (lower.contains('hour') || lower.contains('hr')) {
      final regex = RegExp(r'(\d+(?:\.\d+)?)');
      final match = regex.firstMatch(lower);
      if (match != null) {
        final hours = double.tryParse(match.group(1) ?? '');
        if (hours != null) {
          return hours * 60.0;
        }
      }
    }
    
    // Fallback to parsing minutes directly
    final regex = RegExp(r'(\d+(?:\.\d+)?)');
    final matches = regex.allMatches(lower);
    if (matches.isNotEmpty) {
      return double.tryParse(matches.first.group(0) ?? '') ?? 45.0;
    }
    return 45.0;
  }

  void _initializePlayer() {
    String videoUrl = widget.videoUrl.isNotEmpty 
        ? widget.videoUrl 
        : 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4';
    
    // If local file path doesn't exist, fall back to online demo video so player actually initializes and plays
    if (!videoUrl.startsWith('http')) {
      final file = File(videoUrl);
      if (!file.existsSync()) {
        videoUrl = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
      }
    }
    
    if (videoUrl.startsWith('http')) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    } else {
      _controller = VideoPlayerController.file(File(videoUrl));
    }

    _controller!.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isPlaying = true;
        });
        _controller!.play();
      }
    }).catchError((error) {
      print('Error initializing video player: $error');
      if (mounted) {
        _startTimer();
      }
    });

    _controller!.addListener(() {
      if (mounted && _isInitialized) {
        setState(() {
          final duration = _controller!.value.duration.inMilliseconds;
          final position = _controller!.value.position.inMilliseconds;
          if (duration > 0) {
            _progress = (position / duration).clamp(0.0, 1.0);
            if (_progress > _maxWatchedProgress) {
              _maxWatchedProgress = _progress;
            }
            if (_progress >= 1.0 || position >= duration - 300) {
              _controller!.pause();
              Navigator.pop(context);
              widget.onVideoFinished();
            }
          }
          _isPlaying = _controller!.value.isPlaying;
        });
      }
    });
  }

  void _startTimer() {
    _progress = 0.15;
    _maxWatchedProgress = 0.15;
    _isPlaying = true;
    _videoPlayTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (!_isPlaying || !mounted) return;
      
      setState(() {
        if (_progress < 1.0) {
          _progress = (_progress + 0.006).clamp(0.0, 1.0);
          if (_progress > _maxWatchedProgress) {
            _maxWatchedProgress = _progress;
          }
        } else {
          _videoPlayTimer?.cancel();
          _videoPlayTimer = null;
          
          Navigator.pop(context);
          widget.onVideoFinished();
        }
      });
    });
  }

  @override
  void dispose() {
    _videoPlayTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
          onPressed: () {
            _videoPlayTimer?.cancel();
            _controller?.pause();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Lecture Playback Room',
          style: GoogleFonts.fredoka(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: const Color(0xFF1E293B).withOpacity(0.5),
              child: Row(
                children: [
                  const Icon(Icons.video_camera_back_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.videoTitle,
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Adyapan Video Library  •  Unrestricted Rewinds',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                color: Colors.black,
                width: double.infinity,
                child: Center(
                  child: _isInitialized
                      ? AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: VideoPlayer(_controller!),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24, width: 2),
                              ),
                              child: Icon(
                                _isPlaying ? Icons.play_arrow_rounded : Icons.pause_rounded,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isPlaying ? 'Streaming High-Definition Lecture...' : 'Lecture Playback Paused',
                              style: GoogleFonts.fredoka(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Class 10 Syllabus • Mrs. Sharma',
                              style: GoogleFonts.outfit(
                                color: Colors.white38,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              color: const Color(0xFF1E293B),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      trackHeight: 4,
                      activeTrackColor: Colors.greenAccent,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.greenAccent,
                    ),
                    child: Slider(
                      value: _progress,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (newVal) {
                        setState(() {
                          if (newVal > _maxWatchedProgress) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '🔒 First Watch Lock: You cannot fast-forward! Please watch the full lecture first.',
                                  style: GoogleFonts.fredoka(fontSize: 11),
                                ),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            _progress = _maxWatchedProgress;
                          } else {
                            _progress = newVal;
                            if (_isInitialized) {
                              final duration = _controller!.value.duration.inMilliseconds;
                              _controller!.seekTo(Duration(milliseconds: (newVal * duration).toInt()));
                            }
                          }
                        });
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(_progress * _totalMinutes).toStringAsFixed(1)} mins elapsed',
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Total ${_totalMinutes.toStringAsFixed(1)} mins',
                        style: GoogleFonts.outfit(
                          color: Colors.white60,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 28),
                        onPressed: () {
                          setState(() {
                            _progress = (_progress - 0.03).clamp(0.0, 1.0);
                            if (_isInitialized) {
                              final pos = _controller!.value.position;
                              _controller!.seekTo(pos - const Duration(seconds: 10));
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        icon: Icon(
                          _isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_filled_rounded,
                          color: Colors.greenAccent,
                          size: 58,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPlaying = !_isPlaying;
                            if (_isInitialized) {
                              if (_isPlaying) {
                                _controller!.play();
                              } else {
                                _controller!.pause();
                              }
                            } else {
                              if (!_isPlaying) {
                                _videoPlayTimer?.cancel();
                                _videoPlayTimer = null;
                              } else {
                                _startTimer();
                              }
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        icon: Icon(
                          Icons.forward_10_rounded,
                          color: _progress >= _maxWatchedProgress ? Colors.white24 : Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          if (_progress >= _maxWatchedProgress) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '🔒 Fast-forward is locked for your first watch!',
                                  style: GoogleFonts.fredoka(fontSize: 11),
                                ),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          } else {
                            setState(() {
                              _progress = (_progress + 0.03).clamp(0.0, _maxWatchedProgress);
                              if (_isInitialized) {
                                final pos = _controller!.value.position;
                                _controller!.seekTo(pos + const Duration(seconds: 10));
                              }
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
