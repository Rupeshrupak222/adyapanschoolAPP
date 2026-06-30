import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../core/app_state.dart';
import 'attendance_screen.dart';
import 'homework_screen.dart';
import 'notes_library_screen.dart';
import 'live_classes_screen.dart';
import 'recorded_classes_screen.dart';
import 'doubt_solver_screen.dart';
import 'progress_screen.dart';
import 'leaderboard_screen.dart';
import 'future_skills_detail_screen.dart';
import 'future_skills_hub_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {


  String _getDynamicGreeting(AppState state) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return state.translate('Good morning,');
    } else if (hour >= 12 && hour < 17) {
      return state.translate('Good afternoon,');
    } else if (hour >= 17 && hour < 22) {
      return state.translate('Good evening,');
    } else {
      return state.translate('Happy late night study,');
    }
  }

  // QUICK ACCESS CARD INTERACTION ROUTER
  void _handleQuickAccessTap(BuildContext context, String cardTitle, AppState state) {
    if (cardTitle == 'Gamified' || cardTitle == 'Gemified') {
      state.setTab(3); // Switch to Arcade Tab!
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎮 Entering Quiz and Game Arcade Arena!'), backgroundColor: AdyapanTheme.blueAccent, duration: Duration(seconds: 1)),
      );
    } else if (cardTitle == 'Progress') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen()));
    } else if (cardTitle == 'Attendance') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen()));
    } else if (cardTitle == 'Homework') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeworkScreen()));
    } else if (cardTitle == 'Notes & PDFs') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesLibraryScreen()));
    } else if (cardTitle == 'Live Classes' || cardTitle == 'Today\'s Live Class') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveClassesScreen()));
    } else if (cardTitle == 'Recorded Classes') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const RecordedClassesScreen()));
    } else if (cardTitle == 'Doubt Sessions') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const DoubtSolverScreen()));
    } else if (cardTitle == 'Leaderboard') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
    }
  }

  void _openSkillPage(BuildContext context, Map<String, dynamic> skill, AppState state) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FutureSkillsDetailScreen(skill: skill, state: state),
      ),
    );
  }

  Future<bool> _isZoomInstalledOnWindows() async {
    if (!Platform.isWindows) return false;
    try {
      final appData = Platform.environment['APPDATA'];
      final programFiles = Platform.environment['ProgramFiles'];
      final programFilesx86 = Platform.environment['ProgramFiles(x86)'];
      
      final List<String> pathsToCheck = [
        if (appData != null) '$appData\\Zoom\\bin\\Zoom.exe',
        if (programFiles != null) '$programFiles\\Zoom\\bin\\Zoom.exe',
        if (programFilesx86 != null) '$programFilesx86\\Zoom\\bin\\Zoom.exe',
      ];
      
      for (final path in pathsToCheck) {
        if (File(path).existsSync()) {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  Future<void> _handleZoomLaunch(
    BuildContext context,
    AppState state,
    String subject,
    String topic,
  ) async {
    final Uri zoomUrl = Uri.parse('https://zoom.us/j/9991112222');
    
    if (Platform.isWindows) {
      final bool isInstalled = await _isZoomInstalledOnWindows();
      if (!isInstalled) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.black.withOpacity(0.4),
          builder: (dialogCtx) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: Container(
                  width: 420,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFFFFFF),
                        Color(0xFFF8FAFC),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E3A8A).withOpacity(0.12),
                        blurRadius: 40,
                        offset: const Offset(0, 15),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.15), width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.videocam_off_rounded,
                          color: Color(0xFF2563EB),
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Zoom App Not Detected',
                        style: GoogleFonts.fredoka(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E3A8A),
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'We couldn\'t find the Zoom desktop client on your system. To ensure the absolute highest audio and video fidelity for your live classes, we highly recommend installing the app.',
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF475569),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      Column(
                        children: [
                          InkWell(
                            onTap: () async {
                              Navigator.pop(dialogCtx);
                              final downloadUrl = Uri.parse('https://zoom.us/download');
                              if (await canLaunchUrl(downloadUrl)) {
                                await launchUrl(downloadUrl, mode: LaunchMode.externalApplication);
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2563EB).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Download Zoom Client',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () async {
                              Navigator.pop(dialogCtx);
                              final String meetingId = zoomUrl.pathSegments.isNotEmpty ? zoomUrl.pathSegments.last : '9991112222';
                              final Uri webClientUrl = Uri.parse('https://zoom.us/wc/join/$meetingId');
                              
                              try {
                                if (await canLaunchUrl(webClientUrl)) {
                                  await launchUrl(webClientUrl, mode: LaunchMode.externalApplication);
                                  if (!context.mounted) return;
                                  _secureAttendance(context, state, subject);
                                } else {
                                  throw 'Could not launch Web Client';
                                }
                              } catch (_) {
                                if (!context.mounted) return;
                                _fallbackToInternalStream(context, subject, topic);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: const Color(0xFF3B82F6).withOpacity(0.3), width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: Text(
                              'Continue in Web Browser',
                              style: GoogleFonts.fredoka(
                                fontSize: 13.5,
                                color: const Color(0xFF2563EB),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => Navigator.pop(dialogCtx),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
        return;
      }
    }

    try {
      if (await canLaunchUrl(zoomUrl)) {
        await launchUrl(zoomUrl, mode: LaunchMode.externalApplication);
        if (!context.mounted) return;
        _secureAttendance(context, state, subject);
      } else {
        throw 'Could not launch URL';
      }
    } catch (_) {
      if (!context.mounted) return;
      _fallbackToInternalStream(context, subject, topic);
    }
  }

  void _secureAttendance(BuildContext context, AppState state, String subject) {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    final minutesStr = now.minute < 10 ? '0${now.minute}' : '${now.minute}';
    final timeStr = '$hour:$minutesStr $ampm';
    state.markAttendance(subject, 'Present', timeStr, source: 'Live Zoom Class');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Redirecting to Zoom... Attendance Secured! +30 Focus XP!',
          style: GoogleFonts.fredoka(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _fallbackToInternalStream(BuildContext context, String subject, String topic) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveStreamClassPage(
          teacherName: subject,
          topicName: topic,
          onClassFinished: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Attendance secured! +30 Focus XP!',
                  style: GoogleFonts.fredoka(color: Colors.white, fontSize: 13),
                ),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        if (!state.initialized) {
          return const Center(child: CircularProgressIndicator(color: AdyapanTheme.blueAccent));
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFEEF2F6), // Soft lavender grey
                  Color(0xFFE0E7FF), // Soft indigo
                  Color(0xFFFFF0F5), // Soft pastel pink
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // 1. LAYERED ULTRA-PREMIUM VIBRANT BLUE HEADER BLOCK
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Base Blue Header container with deep decorative mesh gradient
                    Container(
                      width: double.infinity,
                      height: 350,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFFFFFFF), // Pure White
                            Color(0xFFE2EDFF), // Soft Blue-White
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                      ),
                      padding: const EdgeInsets.only(top: 60),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile details and Status Buttons row
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Row(
                              children: [
                                // Sleek Profile Initial ring that opens side drawer
                                GestureDetector(
                                  onTap: () {
                                    Scaffold.of(context).openDrawer();
                                  },
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        )
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: state.profileImagePath.isNotEmpty && state.profileImagePath.startsWith('http')
                                          ? Image.network(
                                              state.profileImagePath,
                                              fit: BoxFit.cover,
                                              width: 46,
                                              height: 46,
                                              errorBuilder: (_, __, ___) => Container(
                                                width: 46, height: 46,
                                                alignment: Alignment.center,
                                                color: const Color(0xFFFBBF24),
                                                child: Text(state.studentName.isNotEmpty ? state.studentName[0].toUpperCase() : 'S', style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                              ),
                                            )
                                          : state.profileImagePath.isNotEmpty && !state.profileImagePath.startsWith('http') && File(state.profileImagePath).existsSync()
                                              ? Image.file(File(state.profileImagePath), fit: BoxFit.cover, width: 46, height: 46)
                                              : Container(
                                              decoration: const BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [Color(0xFFFBBF24), Color(0xFFEA580C)], // Gold-to-Orange
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                              ),
                                              alignment: Alignment.center,
                                              child: () {
                                                String initials = '';
                                                if (state.studentName.trim().isNotEmpty) {
                                                  List<String> parts = state.studentName.trim().split(' ');
                                                  if (parts.isNotEmpty && parts[0].isNotEmpty) {
                                                    initials += parts[0][0];
                                                  }
                                                  if (parts.length > 1 && parts[1].isNotEmpty) {
                                                    initials += parts[1][0];
                                                  }
                                                }
                                                if (initials.isEmpty) initials = 'SL';
                                                return Text(
                                                  initials.toUpperCase(),
                                                  style: GoogleFonts.fredoka(
                                                    fontSize: 16, 
                                                    fontWeight: FontWeight.bold, 
                                                    color: Colors.white,
                                                  ),
                                                );
                                              }(),
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                
                                // Dynamic real-time greeting based on hour
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _getDynamicGreeting(state),
                                        style: GoogleFonts.outfit(
                                          fontSize: 11, 
                                          color: const Color(0xFF1E3A8A).withOpacity(0.7),
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        state.studentName,
                                        style: GoogleFonts.fredoka(
                                          fontSize: 16, 
                                          color: const Color(0xFF1E3A8A),
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.2,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Notification Bell Icon with pulse ring
                                () {
                                  final unreadNotifications = state.notifications.where((n) => n['isRead'] == false).toList();
                                  final hasUnread = unreadNotifications.isNotEmpty;
                                  
                                  return GestureDetector(
                                    onTap: () => _showNotificationInbox(context, state),
                                    child: Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E3A8A).withOpacity(0.08),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.15)),
                                      ),
                                      alignment: Alignment.center,
                                      child: Stack(
                                        alignment: Alignment.topRight,
                                        children: [
                                          const Icon(Icons.notifications_rounded, color: Color(0xFFFBBF24), size: 18),
                                          if (hasUnread)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: Colors.redAccent,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 1.5),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.school_rounded, color: Color(0xFF1E3A8A), size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Active Class:',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1E3A8A).withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  height: 32,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.15)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF1E3A8A).withOpacity(0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: state.studentClass,
                                      icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF1E3A8A), size: 20),
                                      style: GoogleFonts.fredoka(
                                        fontSize: 12,
                                        color: const Color(0xFF1E3A8A),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          state.updateProfile(
                                            name: state.studentName,
                                            email: state.studentEmail,
                                            phone: state.studentPhone,
                                            className: newValue,
                                            school: state.studentSchool,
                                            imagePath: state.profileImagePath.isNotEmpty ? state.profileImagePath : null,
                                          );
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '🎉 Content switched to $newValue successfully!',
                                                style: GoogleFonts.fredoka(color: Colors.white, fontSize: 13),
                                              ),
                                              backgroundColor: const Color(0xFF10B981),
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                            ),
                                          );
                                        }
                                      },
                                      items: <String>[
                                        'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
                                        'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
                                        'Class 11', 'Class 12'
                                      ].map<DropdownMenuItem<String>>((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Header Image Banner
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(40),
                                bottomRight: Radius.circular(40),
                              ),
                              child: Image.asset(
                                'assets/images/dashboard_banner.png',
                                fit: BoxFit.fitWidth,
                                alignment: Alignment.topCenter,
                                width: double.infinity,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 2. OVERLAPPING WHITE SEARCH INPUT PILL
                    Positioned(
                      bottom: -22,
                      left: 20,
                      right: 20,
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.25), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E3A8A).withOpacity(0.08),
                              offset: const Offset(0, 4),
                              blurRadius: 0,
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, color: Color(0xFF2563EB), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                style: GoogleFonts.outfit(fontSize: 13, color: AdyapanTheme.textMain, fontWeight: FontWeight.w600),
                                decoration: InputDecoration(
                                  hintText: state.translate('Search subjects, topics, teachers...'),
                                  hintStyle: GoogleFonts.outfit(fontSize: 13, color: AdyapanTheme.textMuted, fontWeight: FontWeight.w500),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 42),

                // 3. STATS CARD CAPSULE (Lessons, Quests, Rank)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.82),
                      border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.18), width: 1.5),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.15),
                          offset: const Offset(0, 4),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          offset: const Offset(-2, -2),
                          blurRadius: 6,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatsCol('${state.notesList.length + state.completedQuizzesCount + 12}', state.translate('LESSONS')),
                        Container(width: 1.5, height: 28, color: const Color(0xFFEFF6FF)),
                        _buildStatsCol('${state.homeworkList.where((h) => h['submitted'] == false).length}', state.translate('QUESTS')),
                        Container(width: 1.5, height: 28, color: const Color(0xFFEFF6FF)),
                        _buildStatsCol('#${state.studentRank}', state.translate('RANK')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Dynamic Live Session Spotlight Card (Only shows when a class is live)
                () {
                  final activeLive = state.activeLiveClasses;
                  if (activeLive.isEmpty) return const SizedBox.shrink();
                  
                  final cls = activeLive.first;
                  final subject = cls['subject'] as String? ?? 'Mathematics';
                  final topic = cls['topic'] as String? ?? 'Class Session';
                  final teacher = cls['teacher'] as String? ?? 'Educator';
                  
                  final startHour = cls['startHour'] as int? ?? 0;
                  final startMin = cls['startMin'] as int? ?? 0;
                  final now = DateTime.now();
                  final currentMins = now.hour * 60 + now.minute;
                  final startMins = startHour * 60 + startMin;
                  
                  int elapsedMins = currentMins - startMins;
                  if (elapsedMins < 0) elapsedMins += 24 * 60;
                  
                  final isLongerThan10 = elapsedMins > 10;
                  
                  final cardGradient = isLongerThan10
                      ? const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        );
                        
                  final cardShadowColor = isLongerThan10
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981);
                      
                  final joinButtonColor = isLongerThan10
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF059669);
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: GestureDetector(
                      onTap: () => _handleZoomLaunch(context, state, subject, topic),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: cardGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: cardShadowColor.withOpacity(0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'LIVE NOW',
                                        style: GoogleFonts.outfit(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                const Icon(Icons.sensors_rounded, color: Colors.white, size: 20),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              subject,
                              style: GoogleFonts.fredoka(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              topic,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, color: Colors.white70, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  cls['time'] as String? ?? '10:30 AM - 11:30 AM',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Host: $teacher',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    color: Colors.white.withOpacity(0.8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => _handleZoomLaunch(context, state, subject, topic),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: joinButtonColor,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    'Join Now',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }(),
                const SizedBox(height: 16),



                // 4. FUTURE SKILLS HUB HERO SECTION (Premium Visual Spotlight Showcase)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.rocket_launch_rounded, size: 22, color: Color(0xFF2563EB)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const FutureSkillsHubScreen()),
                                      );
                                    },
                                    child: Text(
                                      state.translate('Future Skills Hub'),
                                      style: GoogleFonts.fredoka(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1E3A8A),
                                        letterSpacing: 0.2,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF2563EB).withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                                  ),
                                  child: Text(
                                    state.studentClass,
                                    style: GoogleFonts.outfit(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                  MaterialPageRoute(builder: (_) => const FutureSkillsHubScreen()),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  state.translate('See All'),
                                  style: GoogleFonts.fredoka(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AdyapanTheme.blueAccent,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.arrow_forward_rounded, size: 12, color: AdyapanTheme.blueAccent),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.translate('Learn premium 21st-century superpower skills customized for your school portfolio!'),
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AdyapanTheme.textSub,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Horizontal scrollable skills cards (Elevated, Sleek Showcase)
                      SizedBox(
                        height: 175,
                        child: () {
                          final skills = state.getSkillsForClass(state.studentClass);
                          if (skills.isEmpty) {
                            return Center(
                              child: Text(
                                'No skills mapped for this class.',
                                style: GoogleFonts.outfit(color: AdyapanTheme.textMuted),
                              ),
                            );
                          }
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: skills.length,
                            itemBuilder: (context, idx) {
                              final skill = skills[idx];
                              final modCount = (skill['modules'] as List?)?.length ?? 3;
                              
                              // Curated Premium Theme Gradients
                              final List<List<Color>> bgGradients = [
                                [const Color(0xFFEFF6FF), Colors.white], // blue
                                [const Color(0xFFECFDF5), Colors.white], // emerald
                                [const Color(0xFFFFFBEB), Colors.white], // amber
                                [const Color(0xFFFAF5FF), Colors.white], // purple
                                [const Color(0xFFFDF2F8), Colors.white], // pink
                              ];
                              final List<Color> borderColors = [
                                const Color(0xFF93C5FD),
                                const Color(0xFF6EE7B7),
                                const Color(0xFFFCD34D),
                                const Color(0xFFD8B4FE),
                                const Color(0xFFFBCFE8),
                              ];
                              final List<Color> accentColors = [
                                const Color(0xFF2563EB),
                                const Color(0xFF10B981),
                                const Color(0xFFF59E0B),
                                const Color(0xFF8B5CF6),
                                const Color(0xFFEC4899),
                              ];
                              final clrIdx = idx % bgGradients.length;
 
                              return GestureDetector(
                                onTap: () => _openSkillPage(context, skill, state),
                                child: Container(
                                  width: 156,
                                  margin: const EdgeInsets.only(right: 14, bottom: 6),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: bgGradients[clrIdx],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    border: Border.all(
                                      color: borderColors[clrIdx].withOpacity(0.35),
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accentColors[clrIdx].withOpacity(0.08),
                                        offset: const Offset(0, 4),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Icon Bubble + Modules Badge Row
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: borderColors[clrIdx].withOpacity(0.2),
                                                  blurRadius: 4,
                                                  spreadRadius: 1,
                                                )
                                              ],
                                            ),
                                            alignment: Alignment.center,
                                            child: Icon(
                                              _getSkillIcon(skill['title'] as String? ?? ''),
                                              color: accentColors[clrIdx],
                                              size: 18,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.8),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: borderColors[clrIdx].withOpacity(0.3)),
                                            ),
                                            child: Text(
                                              '$modCount Mod',
                                              style: GoogleFonts.outfit(
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color: accentColors[clrIdx],
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      
                                      // Skill Title
                                      Text(
                                        state.translate(skill['title'] as String),
                                        style: GoogleFonts.fredoka(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1E3A8A),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      
                                      // Visual Mini Progress Indicator & CTA text
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Mini Progress Bar
                                          Container(
                                            height: 4,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: accentColors[clrIdx].withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                            alignment: Alignment.centerLeft,
                                            child: FractionallySizedBox(
                                              widthFactor: 0.35, // Demo progress indicator
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: accentColors[clrIdx],
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Learn & Earn XP',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                  color: accentColors[clrIdx],
                                                ),
                                              ),
                                              Icon(
                                                Icons.play_arrow_rounded,
                                                size: 12,
                                                color: accentColors[clrIdx],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 5. QUICK ACCESS GRID (6 Rounded White Cards with soft colored tints)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        state.translate('Quick access'),
                        style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          state.translate('See all'),
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // 3x2 Grid using clean Rows & Columns
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildGridCard(context, state, Icons.calendar_today_rounded, 'Attendance', '', const Color(0xFFEFF6FF), const Color(0xFF2563EB))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildGridCard(context, state, Icons.assignment_rounded, 'Homework', '', const Color(0xFFFFFBEB), const Color(0xFFF59E0B))),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildGridCard(
                              context, state, Icons.live_tv_rounded, 'Today\'s Live Class', '',
                              const Color(0xFFFDF2F8), const Color(0xFFEC4899),
                              isLive: state.hasLiveClassNow,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildGridCard(context, state, Icons.folder_open_rounded, 'Notes & PDFs', '', const Color(0xFFFAF5FF), const Color(0xFF8B5CF6))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildGridCard(context, state, Icons.video_library_rounded, 'Recorded Classes', '', const Color(0xFFECFDF5), const Color(0xFF10B981))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildGridCard(context, state, Icons.question_answer_rounded, 'Doubt Sessions', '', const Color(0xFFFFF1F2), const Color(0xFFF43F5E))),
                        ],
                      ),
                     ],
                   ),
                 ),
                 const SizedBox(height: 28),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          state.translate('My Progress'),
                          style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain),
                          overflow: TextOverflow.ellipsis, maxLines: 1,
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen())),
                          child: Text(state.translate('View All'), style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2), width: 1.5),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.1), offset: const Offset(0, 4), blurRadius: 12),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.trending_up_rounded, size: 22, color: Colors.white),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(state.translate('Overall Academic Progress'), style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
                                    Text(state.translate('Attendance • Homework • Quizzes'), style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF3B82F6), fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _buildProgressChip(
                                Icons.calendar_today_rounded, 
                                state.translate('Attendance'), 
                                '${state.attendancePercent}%', 
                                const Color(0xFF2563EB),
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen())),
                              ),
                              const SizedBox(width: 10),
                              _buildProgressChip(
                                Icons.assignment_rounded, 
                                state.translate('Homework'), 
                                '${state.homeworkDoneCount}/${state.homeworkList.length}', 
                                const Color(0xFF0EA5E9),
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeworkScreen())),
                              ),
                              const SizedBox(width: 10),
                              _buildProgressChip(
                                Icons.sports_esports_rounded, 
                                state.translate('Quizzes'), 
                                '${state.completedQuizzesCount} ' + state.translate('done'), 
                                const Color(0xFF6366F1),
                                onTap: () => state.setTab(3),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: (state.attendancePercent / 100.0).clamp(0.0, 1.0),
                              minHeight: 7,
                              backgroundColor: const Color(0xFFBFDBFE),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(state.translate('Attendance') + ': ${state.attendancePercent}%', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF1D4ED8))),
                              Text(state.translate('Level') + ' ${state.level} ' + state.translate('Student'), style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF3B82F6))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                 // 6. LEADERBOARD SPOTLIGHT SECTION
                 Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 20.0),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text(
                         state.translate('Leaderboard'),
                         style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain),
                         overflow: TextOverflow.ellipsis,
                         maxLines: 1,
                       ),
                       TextButton(
                         onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
                         child: Text(state.translate('Full Board'), style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                       ),
                     ],
                   ),
                 ),
                 const SizedBox(height: 6),
                 Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 20.0),
                   child: Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                       gradient: const LinearGradient(
                         colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                         begin: Alignment.topLeft,
                         end: Alignment.bottomRight,
                       ),
                       border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.25), width: 1.5),
                       borderRadius: BorderRadius.circular(20),
                       boxShadow: [
                         BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.12), offset: const Offset(0, 4), blurRadius: 12),
                       ],
                     ),
                     child: Column(
                        children: [
                          _buildLeaderboardRow(1, 'Priya Sharma', '2,840 XP', true),
                          const Divider(height: 16, color: Color(0xFFFDE68A)),
                          _buildLeaderboardRow(2, 'Arjun Mehta', '2,610 XP', false),
                          const Divider(height: 16, color: Color(0xFFFDE68A)),
                          _buildLeaderboardRow(3, 'Sneha Patel', '2,490 XP', false),
                          const Divider(height: 16, color: Color(0xFFFDE68A)),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF9C3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(state.translate('You') + ' • #${state.studentRank}', style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFB45309))),
                                Text('${state.xp} XP', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFD97706))),
                              ],
                            ),
                          ),
                        ],
                      ),
                   ),
                 ),
                 const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      );
      },
    );
  }

  // Column builder inside Stats Card
  Widget _buildStatsCol(String numVal, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          numVal,
          style: GoogleFonts.fredoka(
            fontSize: 18, 
            fontWeight: FontWeight.bold, 
            color: const Color(0xFF1E3A8A), // Dark navy blue
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 9, 
            fontWeight: FontWeight.w800, 
            color: AdyapanTheme.textMuted,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  // Premium Quick Access Card Builder (Fully Clickable!)
  Widget _buildGridCard(BuildContext context, AppState state, IconData icon, String title, String subtitle, Color tintColor, Color accentColor, {bool isLive = false}) {
    return GestureDetector(
      onTap: () => _handleQuickAccessTap(context, title, state),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.82),
          border: Border.all(color: accentColor.withOpacity(0.18), width: 1.5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.15),
              offset: const Offset(0, 4),
              blurRadius: 12,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.5),
              offset: const Offset(-2, -2),
              blurRadius: 6,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon Box
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: tintColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor.withOpacity(0.12), width: 1.2),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: accentColor, size: 22),
                ),
                // LIVE Pulsing Red Pill
                if (isLive)
                  Positioned(
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Text(
                        'LIVE', 
                        style: GoogleFonts.outfit(fontSize: 6, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  )
              ],
            ),
            const SizedBox(height: 14),
            Text(
              state.translate(title),
              style: GoogleFonts.fredoka(
                fontSize: 12, 
                fontWeight: FontWeight.bold, 
                color: AdyapanTheme.textMain,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 10, 
                  fontWeight: FontWeight.bold, 
                  color: AdyapanTheme.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressChip(IconData icon, String label, String value, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(height: 3),
              Text(value, style: GoogleFonts.fredoka(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: GoogleFonts.outfit(fontSize: 8, color: const Color(0xFF6D28D9)), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardRow(int rank, String name, String xp, bool isTop) {
    Color medalColor = const Color(0xFF94A3B8); // Default Silver/Grey
    if (rank == 1) {
      medalColor = const Color(0xFFFBBF24); // Gold
    } else if (rank == 3) {
      medalColor = const Color(0xFFD97706); // Bronze
    }
    
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: medalColor.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: medalColor.withOpacity(0.4), width: 1.5),
          ),
          alignment: Alignment.center,
          child: rank <= 3
              ? Icon(Icons.military_tech_rounded, color: medalColor, size: 16)
              : Text(
                  rank.toString(),
                  style: GoogleFonts.fredoka(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF64748B),
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(name, style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF78350F))),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isTop ? const Color(0xFFFBBF24) : const Color(0xFFFDE68A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(xp, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF92400E))),
        ),
      ],
    );
  }

  // GORGEOUS NOTIFICATION INBOX SCREEN MODAL
  void _showNotificationInbox(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return Consumer<AppState>(
          builder: (context, state, child) {
            final list = state.notifications;
            
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF8FAFC).withOpacity(0.98),
                    const Color(0xFFEFF6FF).withOpacity(0.98),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  )
                ],
              ),
              padding: const EdgeInsets.only(top: 14, left: 24, right: 24, bottom: 24),
              child: Column(
                children: [
                  // Drag Handle
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Header Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AdyapanTheme.blueAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_active_rounded, color: AdyapanTheme.blueAccent, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.translate('Notification Inbox'),
                              style: GoogleFonts.fredoka(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              state.translate('Keep track of your study updates'),
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: AdyapanTheme.textSub,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (list.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            state.markAllNotificationsAsRead();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🎉 Marked all notifications as read!'),
                                backgroundColor: AdyapanTheme.blueAccent,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Text(
                            state.translate('Read All'),
                            style: GoogleFonts.fredoka(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AdyapanTheme.blueAccent,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 8),

                  // Notifications list
                  Expanded(
                    child: list.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text('🔔', style: TextStyle(fontSize: 32)),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  state.translate('All caught up!'),
                                  style: GoogleFonts.fredoka(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  state.translate('You do not have any new notifications.'),
                                  style: GoogleFonts.outfit(
                                    fontSize: 11.5,
                                    color: AdyapanTheme.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              final notif = list[index];
                              final isRead = notif['isRead'] as bool? ?? false;
                              
                              return GestureDetector(
                                onTap: () {
                                  state.markNotificationAsRead(notif['id'] as String);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isRead ? Colors.white.withOpacity(0.5) : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isRead ? const Color(0xFFEFF6FF) : AdyapanTheme.blueAccent.withOpacity(0.2),
                                      width: isRead ? 1 : 1.5,
                                    ),
                                    boxShadow: isRead
                                        ? null
                                        : [
                                            BoxShadow(
                                              color: AdyapanTheme.blueAccent.withOpacity(0.04),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            )
                                          ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Unread indicator dot
                                      if (!isRead)
                                        Container(
                                          margin: const EdgeInsets.only(top: 6, right: 10),
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Colors.redAccent,
                                            shape: BoxShape.circle,
                                          ),
                                        )
                                      else
                                        const SizedBox(width: 8),
                                      
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              state.translate(notif['title'] as String? ?? 'Notification'),
                                              style: GoogleFonts.fredoka(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: isRead ? const Color(0xFF64748B) : const Color(0xFF1E293B),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              state.translate(notif['body'] as String? ?? ''),
                                              style: GoogleFonts.outfit(
                                                fontSize: 11.5,
                                                color: const Color(0xFF475569),
                                                fontWeight: FontWeight.w500,
                                                height: 1.4,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              state.translate(notif['time'] as String? ?? 'Just now'),
                                              style: GoogleFonts.outfit(
                                                fontSize: 9.5,
                                                color: AdyapanTheme.textMuted,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      
                                      // Delete button
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                        onPressed: () {
                                          state.deleteNotification(notif['id'] as String);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 14),

                  // Clear All Button
                  if (list.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          state.clearAllNotifications();
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🗑️ All notifications cleared!'),
                              backgroundColor: Colors.redAccent,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 18),
                        label: Text(
                          state.translate('Clear All Notifications'),
                          style: GoogleFonts.fredoka(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

}

IconData _getSkillIcon(String title) {
  final t = title.toLowerCase();
  if (t.contains('code') || t.contains('coding') || t.contains('python') || t.contains('programming') || t.contains('sql') || t.contains('html')) {
    return Icons.code_rounded;
  }
  if (t.contains('speaking') || t.contains('speech') || t.contains('debate') || t.contains('mun') || t.contains('communication') || t.contains('english')) {
    return Icons.record_voice_over_rounded;
  }
  if (t.contains('olympiad') || t.contains('counsel') || t.contains('excel') || t.contains('office') || t.contains('finance') || t.contains('budget') || t.contains('academics')) {
    return Icons.insights_rounded;
  }
  return Icons.star_rounded;
}
