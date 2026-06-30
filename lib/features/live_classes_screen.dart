import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../core/app_state.dart';

class LiveClassesScreen extends StatefulWidget {
  const LiveClassesScreen({Key? key}) : super(key: key);

  @override
  State<LiveClassesScreen> createState() => _LiveClassesScreenState();
}

class _LiveClassesScreenState extends State<LiveClassesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<AppState>(context, listen: false);
      if (state.isLoggedIn) {
        state.syncLiveClassesFromDb();
      }
    });
  }

  Future<void> _joinLiveZoomOrSimulate(String teacherName, String topicName) async {
    final state = Provider.of<AppState>(context, listen: false);
    final subject = _getSubjectFromTopic(topicName);
    final Uri zoomUrl = Uri.parse('https://zoom.us/j/9991112222');
    
    // Find class in schedule to get exact time and duration
    final schedule = state.liveClassesSchedule;
    final match = schedule.firstWhere(
      (cls) => (cls['topic'] as String? ?? '').toLowerCase() == topicName.toLowerCase() ||
               (cls['subject'] as String? ?? '').toLowerCase().contains(subject.toLowerCase()),
      orElse: () => <String, dynamic>{},
    );
    
    int durationMinutes = 60; // default to 60 minutes
    String timeStr = '10:30 AM'; // default time label
    
    if (match.isNotEmpty) {
      final sh = match['startHour'] as int? ?? 10;
      final sm = match['startMin'] as int? ?? 30;
      final eh = match['endHour'] as int? ?? 11;
      final em = match['endMin'] as int? ?? 30;
      durationMinutes = (eh * 60 + em) - (sh * 60 + sm);
      if (durationMinutes <= 0) durationMinutes = 60;
      timeStr = match['time'] as String? ?? '10:30 AM';
    }

    try {
      if (await canLaunchUrl(zoomUrl)) {
        // Start live session tracking in AppState
        state.startLiveClassJoinSession(
          subject: subject,
          time: timeStr,
          durationMinutes: durationMinutes,
        );
        
        await launchUrl(zoomUrl, mode: LaunchMode.externalApplication);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🔗 Redirecting to Zoom... Attendance will be marked after you attend the full $durationMinutes-minute session!',
              style: GoogleFonts.fredoka(color: Colors.white, fontSize: 12),
            ),
            backgroundColor: AdyapanTheme.blueAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
        return;
      }
    } catch (e) {
      // fallback
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveStreamClassPage(
          teacherName: teacherName,
          topicName: topicName,
          onClassFinished: (watchedMinutes) {
            _processLiveAttendance(topicName, watchedMinutes);
          },
        ),
      ),
    );
  }

  String _getSubjectFromTopic(String title) {
    if (title.contains('BODMAS') || title.contains('Math')) return 'Mathematics';
    if (title.contains('Atomic') || title.contains('Science')) return 'Science';
    if (title.contains('Grammar') || title.contains('English')) return 'English';
    return 'Mathematics';
  }

  void _processLiveAttendance(String topicName, int watchedMinutes) {
    final subject = _getSubjectFromTopic(topicName);
    if (watchedMinutes >= 115) {
      final now = DateTime.now();
      final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
      final ampm = now.hour >= 12 ? 'PM' : 'AM';
      final minutesStr = now.minute < 10 ? '0${now.minute}' : '${now.minute}';
      final timeStr = '$hour:$minutesStr $ampm';

      Provider.of<AppState>(context, listen: false).markAttendance(subject, 'Present', timeStr, source: 'Live Class');

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Live Attendance Secured!',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              Text(
                'Attendance secured for Live Class:',
                style: GoogleFonts.outfit(fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                topicName,
                style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Congratulations! You stayed for ${watchedMinutes ~/ 60}h ${watchedMinutes % 60}m (> 1h 55m limit). Attendance successfully marked in portal.',
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
              onPressed: () => Navigator.pop(context),
            )
          ],
        )
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Attendance Locked: You only stayed for ${watchedMinutes ~/ 60}h ${watchedMinutes % 60}m. Stays must exceed 1 hour 55 minutes (115 mins) for attendance!',
            style: GoogleFonts.fredoka(fontSize: 11, color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        )
      );
    }
  }

  Widget _buildLiveTile(String title, String time, String teacher, String emoji, {bool isLive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isLive ? Colors.redAccent.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isLive ? Colors.redAccent.withOpacity(0.2) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isLive ? const Color(0xFFFFF1F2) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.fredoka(fontSize: 12, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain)),
                  const SizedBox(height: 2),
                  Text('Teacher: $teacher  •  $time', style: GoogleFonts.outfit(fontSize: 10, color: AdyapanTheme.textSub, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            if (isLive)
              GestureDetector(
                onTap: () => _joinLiveZoomOrSimulate(teacher, title),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Text(
                    'Join Live',
                    style: GoogleFonts.fredoka(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text('Active Live Classes', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
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
            await state.syncLiveClassesFromDb();
          },
          color: const Color(0xFF6366F1),
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
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.videocam_rounded, color: Color(0xFF2563EB), size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Direct Virtual Streaming', style: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
                          Text('Secure and interactive live classes hosted by your teachers.', style: GoogleFonts.outfit(fontSize: 11, color: AdyapanTheme.textSub)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text('Class Schedule Today', style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
              const SizedBox(height: 12),

              Consumer<AppState>(
                builder: (context, state, _) {
                  final allScheduled = state.liveClassesSchedule;
                  if (allScheduled.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Center(
                        child: Text(
                          'No scheduled live classes today',
                          style: GoogleFonts.outfit(color: AdyapanTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    );
                  }
                  
                  final now = DateTime.now();
                  final currentMins = now.hour * 60 + now.minute;
                  
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2), width: 1.5),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEEF2FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.live_tv_rounded, color: Color(0xFF6366F1), size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    state.translate('Classroom: Live Schedule'),
                                    style: GoogleFonts.fredoka(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E1B4B),
                                    ),
                                  ),
                                  Text(
                                    state.translate('Educator assigned daily streaming slots'),
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      color: const Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        
                        // Timetable list items
                        ...allScheduled.map((cls) {
                          final startHour = cls['startHour'] as int? ?? 0;
                          final startMin = cls['startMin'] as int? ?? 0;
                          final endHour = cls['endHour'] as int? ?? 0;
                          final endMin = cls['endMin'] as int? ?? 0;
                          final startMins = startHour * 60 + startMin;
                          final endMins = endHour * 60 + endMin;
                          
                          final isLive = cls['status'] == 'LIVE NOW' || cls['isLive'] == true || (startMins > 0 && currentMins >= startMins && currentMins <= endMins);
                          final isDone = cls['status'] == 'Finished' || (endMins > 0 && currentMins > endMins);
                          
                          final subject = cls['subject'] as String? ?? 'Mathematics';
                          final topic = cls['topic'] as String? ?? 'Class Lecture';
                          final timeLabel = cls['time'] as String? ?? 'Scheduled';
                          
                          Color itemBgColor = Colors.white;
                          Color borderCol = const Color(0xFFE2E8F0);
                          if (isLive) {
                            itemBgColor = const Color(0xFFEEF2FF);
                            borderCol = const Color(0xFF818CF8);
                          }
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: itemBgColor,
                              border: Border.all(color: borderCol, width: 1.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isLive ? const Color(0xFF6366F1) : const Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    isLive ? Icons.sensors_rounded : Icons.radio_button_checked_rounded,
                                    color: isLive ? Colors.white : const Color(0xFF6366F1),
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            subject,
                                            style: GoogleFonts.fredoka(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF1E293B),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          if (isLive)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEF4444),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'LIVE',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 7,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        topic,
                                        style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          color: const Color(0xFF64748B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isLive)
                                  ElevatedButton(
                                    onPressed: () => _joinLiveZoomOrSimulate(subject, topic),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6366F1),
                                      elevation: 2,
                                      shadowColor: const Color(0xFF6366F1).withOpacity(0.3),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: Text(
                                      'Join →',
                                      style: GoogleFonts.fredoka(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                else
                                  Text(
                                    isDone ? 'Finished' : timeLabel,
                                    style: GoogleFonts.outfit(
                                      fontSize: 9,
                                      color: isDone ? Colors.grey : const Color(0xFF6366F1),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      )),
    );
  }
}

// =========================================================================
//  DEDICATED VISUAL FULL-SCREEN PAGE: SIMULATED LIVE VIDEO STREAM
// =========================================================================
class LiveStreamClassPage extends StatefulWidget {
  final String teacherName;
  final String topicName;
  final Function(int) onClassFinished;

  const LiveStreamClassPage({
    Key? key,
    required this.teacherName,
    required this.topicName,
    required this.onClassFinished,
  }) : super(key: key);

  @override
  State<LiveStreamClassPage> createState() => _LiveStreamClassPageState();
}

class _LiveStreamClassPageState extends State<LiveStreamClassPage> {
  bool _isMuted = false;
  bool _isVideoOff = false;
  int _watchedMinutes = 110; // Start high for quick simulation completion
  Timer? _ticker;
  // Live Quiz state
  int? _selectedAnswer;
  bool _quizSubmitted = false;
  int? _lastQuizTimestamp;
  Timer? _quizDismissTimer;

  final List<Map<String, String>> _chatMessages = [
    {'sender': 'Student 1', 'message': 'Good morning Ma\'am!'},
    {'sender': 'Student 2', 'message': 'Is this session being recorded?'},
  ];
  Timer? _chatTimer;
  final List<Map<String, String>> _mockChatPool = [
    {'sender': 'Mrs. Sharma', 'message': 'Yes, the recording will be in the library!'},
    {'sender': 'Student 3', 'message': 'Wow, the BODMAS rules make absolute sense now.'},
    {'sender': 'Student 1', 'message': 'Ma\'am, will we practice fraction division today?'},
    {'sender': 'Mrs. Sharma', 'message': 'Yes Anya, right after this arithmetic quest!'},
    {'sender': 'Student 2', 'message': 'I have secured the BODMAS game badge!'},
  ];
  int _chatPoolIndex = 0;

  @override
  void initState() {
    super.initState();
    // Simulate time elapsed (1 minute every 800ms)
    _ticker = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_watchedMinutes < 120) {
          _watchedMinutes++;
        } else {
          _ticker?.cancel();
        }
      });
    });

    // Populate class chat messages dynamically
    _chatTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_chatPoolIndex < _mockChatPool.length) {
        setState(() {
          _chatMessages.add(_mockChatPool[_chatPoolIndex]);
          _chatPoolIndex++;
        });
      } else {
        _chatTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _chatTimer?.cancel();
    _quizDismissTimer?.cancel();
    super.dispose();
  }

  void _handleAnswerSelect(int index, Map<String, dynamic> quiz, AppState state) {
    if (_quizSubmitted) return;
    final correctIndex = quiz['correctIndex'] as int;
    final options = List<String>.from(quiz['options'] as List);
    setState(() {
      _selectedAnswer = index;
      _quizSubmitted = true;
    });
    state.submitLiveQuizAnswer(
      state.studentName.isNotEmpty ? state.studentName : 'Student',
      options[index],
      index == correctIndex,
    );
    // Auto-dismiss the overlay after 4 seconds
    _quizDismissTimer?.cancel();
    _quizDismissTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        state.clearLiveQuiz();
        setState(() {
          _selectedAnswer = null;
          _quizSubmitted = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final quiz = appState.pushedLiveQuiz;
        // Reset quiz state if a new quiz is pushed
        if (quiz != null) {
          final ts = quiz['pushedAt'] as int?;
          if (ts != null && ts != _lastQuizTimestamp) {
            // Schedule a microtask to avoid setState during build
            Future.microtask(() {
              if (mounted) {
                setState(() {
                  _selectedAnswer = null;
                  _quizSubmitted = false;
                  _lastQuizTimestamp = ts;
                });
              }
            });
          }
        }

        return Stack(
          children: [
            // ── Main class page content ──
            child!,

            // ── Live Quiz Overlay ──
            if (quiz != null)
              _buildQuizOverlay(quiz, appState),
          ],
        );
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          child: Column(
          children: [
            // Top custom video-meeting header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              color: const Color(0xFF1E293B),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'LIVE',
                      style: GoogleFonts.outfit(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.topicName,
                          style: GoogleFonts.fredoka(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Teacher: ${widget.teacherName}  •  Adyapan Virtual Room',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Close indicator
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 22),
                    onPressed: () {
                      widget.onClassFinished(_watchedMinutes);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),

            // Video Feed box
            Expanded(
              flex: 4,
              child: Stack(
                children: [
                  Container(
                    color: Colors.black,
                    width: double.infinity,
                    height: double.infinity,
                    child: _isVideoOff
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.videocam_off_rounded, color: Colors.white38, size: 48),
                                const SizedBox(height: 10),
                                Text(
                                  'Your camera is turned off',
                                  style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('👩‍🏫', style: TextStyle(fontSize: 72)),
                                const SizedBox(height: 14),
                                Text(
                                  'Mrs. Sharma is presenting her screen...',
                                  style: GoogleFonts.fredoka(
                                    color: Colors.greenAccent,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Topic: BODMAS Equation Balancers',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  // PIP Student avatar box
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      width: 70,
                      height: 95,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24, width: 1.5),
                      ),
                      child: Center(
                        child: Icon(
                          _isVideoOff ? Icons.videocam_off_rounded : Icons.person_rounded,
                          size: 28,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Attendance progression tracker card
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF1E293B),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Simulated Stay: ${_watchedMinutes ~/ 60}h ${_watchedMinutes % 60}m',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Required Stay: 1h 55m',
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _watchedMinutes / 120,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _watchedMinutes >= 115 ? Colors.greenAccent : Colors.amberAccent,
                      ),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _watchedMinutes >= 115
                            ? Icons.check_circle_rounded
                            : Icons.hourglass_top_rounded,
                        color: _watchedMinutes >= 115 ? Colors.greenAccent : Colors.amberAccent,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _watchedMinutes >= 115
                              ? 'Attendance criteria met! You are marked PRESENT ✓'
                              : 'Securing attendance: wait ${115 - _watchedMinutes}s for full attendance.',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: _watchedMinutes >= 115 ? Colors.greenAccent : Colors.amberAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Real-time Virtual Class chat panel
            Expanded(
              flex: 3,
              child: Container(
                color: const Color(0xFF0F172A),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CLASSROOM LIVE CHAT',
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        color: Colors.white60,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _chatMessages.length,
                        itemBuilder: (context, index) {
                          final chat = _chatMessages[index];
                          final isTeacher = chat['sender']!.contains('Mrs.');
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${chat['sender']}: ',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: isTeacher ? Colors.greenAccent : Colors.blueAccent,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    chat['message']!,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11.5,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Call Actions / Controls bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: _isMuted ? Colors.red : Colors.white10,
                    radius: 24,
                    child: IconButton(
                      icon: Icon(_isMuted ? Icons.mic_off_rounded : Icons.mic_rounded, color: Colors.white),
                      onPressed: () => setState(() => _isMuted = !_isMuted),
                    ),
                  ),
                  const SizedBox(width: 20),
                  CircleAvatar(
                    backgroundColor: _isVideoOff ? Colors.red : Colors.white10,
                    radius: 24,
                    child: IconButton(
                      icon: Icon(_isVideoOff ? Icons.videocam_off_rounded : Icons.videocam_rounded, color: Colors.white),
                      onPressed: () => setState(() => _isVideoOff = !_isVideoOff),
                    ),
                  ),
                  const SizedBox(width: 20),
                  CircleAvatar(
                    backgroundColor: Colors.redAccent,
                    radius: 24,
                    child: IconButton(
                      icon: const Icon(Icons.call_end_rounded, color: Colors.white),
                      onPressed: () {
                        widget.onClassFinished(_watchedMinutes);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],          // closes Column's children list
          ),          // closes Column
        ),            // closes SafeArea
      ),              // closes child: Scaffold(
    );               // closes Consumer<AppState>(
  }

  // ── Glassmorphism Live Quiz Overlay Widget ──────────────────────────────────
  Widget _buildQuizOverlay(Map<String, dynamic> quiz, AppState state) {
    final question = quiz['question'] as String? ?? '';
    final options = List<String>.from(quiz['options'] as List? ?? []);
    final correctIndex = quiz['correctIndex'] as int? ?? 0;
    final labels = ['A', 'B', 'C', 'D'];

    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          color: Colors.black.withOpacity(0.55),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.amberAccent.withOpacity(0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amberAccent.withOpacity(0.12),
                      blurRadius: 32,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amberAccent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt_rounded, size: 12, color: Colors.black),
                              const SizedBox(width: 4),
                              Text('LIVE QUIZ', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text('from Teacher', style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Question
                    Text(
                      question,
                      style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, height: 1.35),
                    ),
                    const SizedBox(height: 18),
                    // Options
                    ...List.generate(options.length, (i) {
                      Color bg = Colors.white.withOpacity(0.07);
                      Color border = Colors.white12;
                      Color textCol = Colors.white;
                      IconData? trailingIcon;

                      if (_quizSubmitted) {
                        if (i == correctIndex) {
                          bg = Colors.greenAccent.withOpacity(0.15);
                          border = Colors.greenAccent.withOpacity(0.6);
                          textCol = Colors.greenAccent;
                          trailingIcon = Icons.check_circle_rounded;
                        } else if (i == _selectedAnswer && i != correctIndex) {
                          bg = Colors.redAccent.withOpacity(0.15);
                          border = Colors.redAccent.withOpacity(0.5);
                          textCol = Colors.redAccent;
                          trailingIcon = Icons.cancel_rounded;
                        }
                      } else if (i == _selectedAnswer) {
                        bg = Colors.amberAccent.withOpacity(0.12);
                        border = Colors.amberAccent.withOpacity(0.5);
                        textCol = Colors.amberAccent;
                      }

                      return GestureDetector(
                        onTap: () => _handleAnswerSelect(i, quiz, state),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: border, width: 1.4),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 26, height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.08),
                                  border: Border.all(color: border, width: 1.2),
                                ),
                                child: Center(
                                  child: Text(labels[i], style: GoogleFonts.fredoka(fontSize: 11, fontWeight: FontWeight.bold, color: textCol)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(options[i], style: GoogleFonts.outfit(fontSize: 13, color: textCol, fontWeight: FontWeight.w500)),
                              ),
                              if (trailingIcon != null)
                                Icon(trailingIcon, size: 18, color: textCol),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (_quizSubmitted) ...
                      [
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            _selectedAnswer == correctIndex
                                ? '🎉 Correct! Great job!'
                                : '❌ Incorrect — correct answer highlighted above',
                            style: GoogleFonts.fredoka(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _selectedAnswer == correctIndex ? Colors.greenAccent : Colors.redAccent,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            'Dismissing in 4s…',
                            style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38),
                          ),
                        ),
                      ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
