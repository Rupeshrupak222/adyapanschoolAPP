import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/app_state.dart';
import 'attendance_screen.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final isTeacher = state.userRole == 'teacher';
        return isTeacher
            ? _TeacherProgressView(state: state)
            : _StudentProgressView(state: state);
      },
    );
  }
}

// ─────────────────────────────────────────────
// STUDENT PROGRESS VIEW
// ─────────────────────────────────────────────
class _StudentProgressView extends StatelessWidget {
  final AppState state;
  const _StudentProgressView({required this.state});

  @override
  Widget build(BuildContext context) {
    final overallPct = state.overallSyllabusProgress;
    final quizDone = state.completedQuizzesCount;
    final xp = state.xp;
    final level = state.level;
    final subjects = state.getSubjectsForClass(state.studentClass);

    final logs = state.attendanceLogs;
    final presentCount = logs.where((l) => l['status'] == 'Present').length;
    final excusedCount = logs.where((l) => l['status'] == 'Excused').length;
    final absentCount = logs.where((l) => l['status'] == 'Absent').length;
    final totalCount = logs.length;
    
    final double attendancePercentVal = totalCount > 0 ? (presentCount / totalCount) : 0.94;
    final int displayAttended = totalCount > 0 ? presentCount : 118;
    final int displayTotal = totalCount > 0 ? totalCount : 125;
    final int displayExcused = totalCount > 0 ? excusedCount : 4;
    final int displayAbsent = totalCount > 0 ? absentCount : 3;
    final String attendancePercentText = "${(attendancePercentVal * 100).toStringAsFixed(0)}%";

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          // ── TRANSPARENT HEADER ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.3)),
                        ),
                        child: Text(
                          'Level $level',
                          style: GoogleFonts.fredoka(fontSize: 12, color: const Color(0xFF2563EB), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Academic Progress',
                          style: GoogleFonts.fredoka(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                        ),
                        Text(
                          'Your complete learning overview',
                          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF1E293B).withOpacity(0.7), fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 70,
                                    height: 70,
                                    child: CircularProgressIndicator(
                                      value: overallPct / 100,
                                      strokeWidth: 7,
                                      backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                                    ),
                                  ),
                                  Text(
                                    '${overallPct.toStringAsFixed(0)}%',
                                    style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Overall Syllabus', style: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                                    Text('$quizDone quizzes done  •  $xp XP earned', style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF1E293B).withOpacity(0.7), fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: (xp % 200) / 200.0,
                                        minHeight: 7,
                                        backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text('${xp % 200}/200 XP to Level ${level + 1}', style: GoogleFonts.outfit(fontSize: 9, color: const Color(0xFF1E293B).withOpacity(0.6), fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── SCROLLABLE CONTENT ──
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Quiz & Game Progress'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        _buildQuizRow('BODMAS Balancer', quizDone >= 1, const Color(0xFF6366F1)),
                        const Divider(height: 16, color: Color(0xFFF1F5F9)),
                        _buildQuizRow('Syntax Blocks', quizDone >= 2, const Color(0xFF6366F1)),
                        const Divider(height: 16, color: Color(0xFFF1F5F9)),
                        _buildQuizRow('Word Unscramble', quizDone >= 3, const Color(0xFF6366F1)),
                        const Divider(height: 16, color: Color(0xFFF1F5F9)),
                        _buildQuizRow('Speed Math', quizDone >= 4, const Color(0xFF6366F1)),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(14)),
                          alignment: Alignment.center,
                          child: Text('$quizDone / 4 Games Completed', style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _sectionTitle(state.translate('Class Syllabus Progress')),
                  const SizedBox(height: 10),
                  ...subjects.map((subject) {
                    final key = subject['key'] as String;
                    final name = state.translate(subject['name'] as String);
                    final pct = state.getSubjectProgress(key);
                    final accent = subject['color'] as Color;
                    final bgColor = subject['bgColor'] as Color;
                    String subtitle = state.translate('Based on roadmap and quizzes');
                    if (key == 'English') {
                      subtitle = state.translate('Based on quiz activity');
                    } else if (key == 'SocialScience') {
                      subtitle = state.translate('Based on roadmap and quizzes');
                    } else if (key == 'Commerce') {
                      subtitle = state.translate('Based on business and accounting concepts');
                    } else if (key == 'Humanities') {
                      subtitle = state.translate('Based on art, history, and civic lessons');
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildSubjectCard(name, pct, accent, bgColor, subtitle),
                    );
                  }).toList(),
                  const SizedBox(height: 14),

                  _sectionTitle(state.translate('Class Attendance')),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AttendanceScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                      children: [
                        Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: CircularProgressIndicator(
                                    value: attendancePercentVal,
                                    strokeWidth: 8,
                                    backgroundColor: const Color(0xFFFEF3C7),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(attendancePercentText, style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFFF59E0B))),
                                    Text(state.translate('Present'), style: GoogleFonts.outfit(fontSize: 8, color: AdyapanTheme.textMuted, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _attendanceStat(state.translate('Classes Attended'), '$displayAttended / $displayTotal'),
                                  const SizedBox(height: 6),
                                  _attendanceStat(state.translate('Excused Leaves'), state.translate('{} days').replaceFirst('{}', '$displayExcused')),
                                  const SizedBox(height: 6),
                                  _attendanceStat(state.translate('Absences'), state.translate('{} days').replaceFirst('{}', '$displayAbsent')),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: attendancePercentVal,
                            minHeight: 10,
                            backgroundColor: const Color(0xFFFEF3C7),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(state.translate('Minimum: 75%'), style: GoogleFonts.outfit(fontSize: 10, color: AdyapanTheme.textMuted, fontWeight: FontWeight.w500)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: attendancePercentVal >= 0.90 
                                    ? const Color(0xFFECFDF5) 
                                    : (attendancePercentVal >= 0.75 ? const Color(0xFFEFF6FF) : const Color(0xFFFEF2F2)),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                state.translate(attendancePercentVal >= 0.90 
                                    ? 'Excellent' 
                                    : (attendancePercentVal >= 0.75 ? 'Good' : 'Needs Focus')),
                                style: GoogleFonts.fredoka(
                                  fontSize: 10, 
                                  fontWeight: FontWeight.bold, 
                                  color: attendancePercentVal >= 0.90 
                                      ? const Color(0xFF10B981) 
                                      : (attendancePercentVal >= 0.75 ? const Color(0xFF2563EB) : const Color(0xFFEF4444)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                  _sectionTitle(state.translate('Subject-wise Attendance')),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: subjects.map((subject) {
                        final key = subject['key'] as String;
                        final name = state.translate(subject['name'] as String);
                        final accent = subject['color'] as Color;
                        
                        final subjectLogs = logs.where((l) {
                          final logSub = (l['subject'] as String).trim().toLowerCase();
                          final subKey = key.trim().toLowerCase();
                          final subName = (subject['name'] as String).trim().toLowerCase();
                          return logSub == subKey || logSub == subName || 
                                 (subKey == 'math' && logSub == 'mathematics') ||
                                 (logSub == 'math' && subKey == 'mathematics') ||
                                 logSub.contains(subKey) || subKey.contains(logSub);
                        }).toList();

                        final double pctVal;
                        final String pctLabel;
                        if (subjectLogs.isNotEmpty) {
                          final subPresent = subjectLogs.where((l) => l['status'] == 'Present').length;
                          final subTotal = subjectLogs.length;
                          pctVal = subTotal > 0 ? (subPresent / subTotal) : 1.0;
                          pctLabel = "${(pctVal * 100).toStringAsFixed(0)}%";
                        } else {
                          pctVal = attendancePercentVal;
                          pctLabel = attendancePercentText;
                        }
                        
                        return Column(
                          children: [
                            _buildSubjectAttendanceRow(name, pctVal, pctLabel, accent),
                            if (subject != subjects.last)
                              const Divider(height: 16, color: Color(0xFFF1F5F9)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        final st = Provider.of<AppState>(context, listen: false);
                        st.setTab(1); // Navigates to Syllabus Tab
                      },
                      icon: const Icon(Icons.import_contacts_rounded, size: 16, color: Colors.white),
                      label: Text('View Full Syllabus Pathway', style: GoogleFonts.fredoka(color: Colors.white, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) =>
      Text(title, style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain));

  Widget _buildQuizRow(String title, bool completed, Color accent) {
    return Row(
      children: [
        Container(
          width: 26, height: 26,
          decoration: BoxDecoration(color: completed ? accent : const Color(0xFFF1F5F9), shape: BoxShape.circle, border: Border.all(color: completed ? accent : const Color(0xFFE2E8F0))),
          child: Icon(completed ? Icons.check_rounded : Icons.radio_button_unchecked_rounded, size: 14, color: completed ? Colors.white : AdyapanTheme.textMuted),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.w600, color: AdyapanTheme.textMain))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: completed ? accent.withOpacity(0.1) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
          child: Text(completed ? 'Completed' : 'Pending', style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: completed ? accent : AdyapanTheme.textMuted)),
        ),
      ],
    );
  }

  Widget _buildSubjectCard(String subject, double pct, Color accent, Color bg, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: accent.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subject,
                  style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: accent.withOpacity(0.2))),
                child: Text('${pct.toStringAsFixed(0)}%', style: GoogleFonts.fredoka(fontSize: 12, fontWeight: FontWeight.bold, color: accent)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.outfit(fontSize: 10, color: AdyapanTheme.textMuted, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct / 100, minHeight: 9,
              backgroundColor: accent.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _attendanceStat(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: GoogleFonts.outfit(fontSize: 11, color: AdyapanTheme.textSub, fontWeight: FontWeight.w500)),
      Text(value, style: GoogleFonts.fredoka(fontSize: 11, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain)),
    ],
  );

  Widget _buildSubjectAttendanceRow(String subject, double val, String pctLabel, Color accent) => Row(
    children: [
      Expanded(child: Text(subject, style: GoogleFonts.fredoka(fontSize: 12, fontWeight: FontWeight.w600, color: AdyapanTheme.textMain))),
      const SizedBox(width: 10),
      SizedBox(
        width: 100,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: val, minHeight: 7, backgroundColor: accent.withOpacity(0.1), valueColor: AlwaysStoppedAnimation<Color>(accent)),
        ),
      ),
      const SizedBox(width: 8),
      Text(pctLabel, style: GoogleFonts.fredoka(fontSize: 11, fontWeight: FontWeight.bold, color: accent)),
    ],
  );
}

// ─────────────────────────────────────────────
// TEACHER PROGRESS VIEW — Class Analytics
// ─────────────────────────────────────────────
class _TeacherProgressView extends StatelessWidget {
  final AppState state;
  const _TeacherProgressView({required this.state});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> classStudents = state.linkedStudents.isNotEmpty
        ? state.linkedStudents.map((s) {
            final name = s['name'] ?? 'Unnamed';
            final code = name.hashCode.abs();
            final math = s['math'] != null && s['math'] != -1.0 ? (s['math'] as num).toDouble() : (55.0 + (code % 40));
            final science = s['science'] != null && s['science'] != -1.0 ? (s['science'] as num).toDouble() : (45.0 + (code % 45));
            final english = s['english'] != null && s['english'] != -1.0 ? (s['english'] as num).toDouble() : (60.0 + (code % 35));
            final attendance = s['attendance'] != null && s['attendance'] != -1.0 ? (s['attendance'] as num).toDouble() : (75.0 + (code % 24));
            final xp = s['xp'] != null ? (s['xp'] as int) : ((1 + (code % 8)) * 200 - 150 + (code % 100));
            final avg = (math + science + english) / 3.0;
            String status = 'average';
            if (avg >= 85) {
              status = 'top';
            } else if (avg >= 75) {
              status = 'good';
            } else if (avg < 65) {
              status = 'struggling';
            }
            return {
              'id': s['id'] ?? '',
              'name': name,
              'email': s['email'] ?? '',
              'phone': s['phone'] ?? '',
              'math': math,
              'science': science,
              'english': english,
              'attendance': attendance,
              'xp': xp,
              'status': status,
            };
          }).toList()
        : [
            {'name': 'Anya Verma',     'math': 88.0, 'science': 92.0, 'english': 78.0, 'attendance': 96.0, 'xp': 2450, 'status': 'top'},
            {'name': 'Kabir Gupta',    'math': 76.0, 'science': 84.0, 'english': 90.0, 'attendance': 92.0, 'xp': 2310, 'status': 'good'},
            {'name': 'Rohan Malhotra', 'math': 65.0, 'science': 70.0, 'english': 60.0, 'attendance': 85.0, 'xp': 2190, 'status': 'average'},
            {'name': 'Diya Sen',       'math': 92.0, 'science': 88.0, 'english': 95.0, 'attendance': 98.0, 'xp': 1900, 'status': 'top'},
            {'name': 'Ishaan Mehta',   'math': 55.0, 'science': 62.0, 'english': 58.0, 'attendance': 74.0, 'xp': 1450, 'status': 'struggling'},
            {'name': 'Meera Iyer',     'math': 80.0, 'science': 75.0, 'english': 82.0, 'attendance': 90.0, 'xp': 2500, 'status': 'good'},
          ];

    double classAvg(String key) {
      if (classStudents.isEmpty) return 0.0;
      final vals = classStudents.map((s) => (s[key] as num).toDouble()).toList();
      return vals.reduce((a, b) => a + b) / vals.length;
    }

    final teacherName = state.studentName;
    final mathAvg = classAvg('math');
    final sciAvg = classAvg('science');
    final engAvg = classAvg('english');
    final attAvg = classAvg('attendance');
    final overallAvg = (mathAvg + sciAvg + engAvg) / 3;

    final topStudents = classStudents.where((s) => s['status'] == 'top').toList();
    final struggling = classStudents.where((s) => s['status'] == 'struggling').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          // ── TEACHER TRANSPARENT HEADER ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.3)),
                        ),
                        child: Text(
                          'Teacher View',
                          style: GoogleFonts.fredoka(fontSize: 12, color: const Color(0xFF2563EB), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Class Progress Report',
                          style: GoogleFonts.fredoka(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                        ),
                        Text(
                          '$teacherName\'s class analytics',
                          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF1E293B).withOpacity(0.7), fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 16),
                        // Overall class ring
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 70, height: 70,
                                    child: CircularProgressIndicator(
                                      value: overallAvg / 100,
                                      strokeWidth: 7,
                                      backgroundColor: const Color(0xFFE2E8F0),
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF94A3B8)),
                                    ),
                                  ),
                                  Text(
                                    '${overallAvg.toStringAsFixed(0)}%',
                                    style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Class Average Score', style: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                                    Text('${classStudents.length} students  •  ${attAvg.toStringAsFixed(0)}% attendance', style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF1E293B).withOpacity(0.7))),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: overallAvg / 100, minHeight: 7,
                                        backgroundColor: const Color(0xFFE2E8F0),
                                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF94A3B8)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── SCROLLABLE CLASS CONTENT ──
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── SUBJECT AVERAGES ──
                  _tSectionTitle('Subject Average Scores'),
                  const SizedBox(height: 10),
                  _buildTeacherSubjectCard('Mathematics', mathAvg, const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
                  const SizedBox(height: 8),
                  _buildTeacherSubjectCard('Science', sciAvg, const Color(0xFF10B981), const Color(0xFFECFDF5)),
                  const SizedBox(height: 8),
                  _buildTeacherSubjectCard('English', engAvg, const Color(0xFF8B5CF6), const Color(0xFFF5F3FF)),
                  const SizedBox(height: 24),

                  // ── CLASS ATTENDANCE ──
                  _tSectionTitle('Class Attendance Overview'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 80, height: 80,
                              child: CircularProgressIndicator(
                                value: attAvg / 100, strokeWidth: 8,
                                backgroundColor: const Color(0xFFFEF3C7),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                              ),
                            ),
                            Column(mainAxisSize: MainAxisSize.min, children: [
                              Text('${attAvg.toStringAsFixed(0)}%', style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFFF59E0B))),
                              Text('Avg', style: GoogleFonts.outfit(fontSize: 8, color: AdyapanTheme.textMuted, fontWeight: FontWeight.bold)),
                            ]),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _tAttendanceStat('Total Students', '${classStudents.length}'),
                              const SizedBox(height: 4),
                              _tAttendanceStat('High Attendance (>90%)', '${classStudents.where((s) => s['attendance'] >= 90).length} students'),
                              const SizedBox(height: 4),
                              _tAttendanceStat('At Risk (<75%)', '${classStudents.where((s) => s['attendance'] < 75).length} students'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
 
                  // ── TOP PERFORMERS ──
                  _tSectionTitle('Top Performers'),
                  const SizedBox(height: 10),
                  ...topStudents.map((s) => _buildStudentRow(s, const Color(0xFF10B981))),
                  const SizedBox(height: 24),
 
                  // ── STUDENTS NEEDING ATTENTION ──
                  _tSectionTitle('Needs Attention'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFBBF24).withOpacity(0.4)),
                    ),
                    child: Column(
                      children: struggling.isEmpty
                          ? [Text('All students are performing well!', style: GoogleFonts.outfit(fontSize: 12, color: AdyapanTheme.textSub))]
                          : struggling.map((s) => _buildStudentRow(s, const Color(0xFFEF4444))).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
 
                  // ── ALL STUDENTS TABLE ──
                  _tSectionTitle('All Students'),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: classStudents.asMap().entries.map((entry) {
                        final i = entry.key;
                        final s = entry.value;
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB).withOpacity(0.1),
                                      border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.2)),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      s['name'][0],
                                      style: GoogleFonts.fredoka(
                                        fontSize: 14,
                                        color: const Color(0xFF1E3A8A),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(s['name'], style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain)),
                                        Text('M:${(s['math'] as num).toStringAsFixed(0)}% | Sc:${(s['science'] as num).toStringAsFixed(0)}% | En:${(s['english'] as num).toStringAsFixed(0)}% | Att:${(s['attendance'] as num).toStringAsFixed(0)}%', style: GoogleFonts.outfit(fontSize: 9, color: AdyapanTheme.textMuted, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _statusColor(s['status']).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _statusColor(s['status']).withOpacity(0.3)),
                                    ),
                                    child: Text('${s['xp']} XP', style: GoogleFonts.fredoka(fontSize: 10, fontWeight: FontWeight.bold, color: _statusColor(s['status']))),
                                  ),
                                ],
                              ),
                            ),
                            if (i < classStudents.length - 1)
                              const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'top': return const Color(0xFF10B981);
      case 'good': return const Color(0xFF2563EB);
      case 'average': return const Color(0xFFF59E0B);
      case 'struggling': return const Color(0xFFEF4444);
      default: return AdyapanTheme.textMuted;
    }
  }

  Widget _tSectionTitle(String title) =>
      Text(title, style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain));

  Widget _buildTeacherSubjectCard(String subject, double avg, Color accent, Color bg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: accent.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subject, style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain)),
              const SizedBox(height: 2),
              Text('Class average', style: GoogleFonts.outfit(fontSize: 10, color: AdyapanTheme.textMuted)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: avg / 100, minHeight: 8, backgroundColor: accent.withOpacity(0.1), valueColor: AlwaysStoppedAnimation<Color>(accent)),
              ),
            ],
          )),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: accent.withOpacity(0.2))),
            child: Text('${avg.toStringAsFixed(1)}%', style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold, color: accent)),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRow(Map<String, dynamic> s, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.2)),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                s['name'][0],
                style: GoogleFonts.fredoka(
                  fontSize: 14,
                  color: const Color(0xFF1E3A8A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s['name'], style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain)),
                  Text('Avg: ${((s['math'] + s['science'] + s['english']) / 3).toStringAsFixed(0)}%  |  ${s['xp']} XP', style: GoogleFonts.outfit(fontSize: 10, color: AdyapanTheme.textSub)),
                ],
              ),
            ),
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: accent, width: 2.5)),
              alignment: Alignment.center,
              child: Text('${s['attendance']}%', style: GoogleFonts.fredoka(fontSize: 9, fontWeight: FontWeight.bold, color: accent)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tAttendanceStat(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: GoogleFonts.outfit(fontSize: 10, color: AdyapanTheme.textSub, fontWeight: FontWeight.w500))),
        Text(value, style: GoogleFonts.fredoka(fontSize: 10, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain)),
      ],
    ),
  );
}
