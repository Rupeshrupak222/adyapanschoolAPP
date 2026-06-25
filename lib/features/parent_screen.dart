import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/app_state.dart';

class ParentScreen extends StatefulWidget {
  const ParentScreen({Key? key}) : super(key: key);

  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> with SingleTickerProviderStateMixin {
  bool _isUnlocked = false;
  final TextEditingController _passcodeController = TextEditingController();
  final TextEditingController _questController = TextEditingController();
  double _xpReward = 150;

  // Live class alert banner
  bool _liveClassAlertDismissed = false;
  Timer? _liveClassCheckTimer;

  // Tab controller for 3 sections
  late TabController _tabController;

  // Real-life rewards milestones state
  final List<Map<String, dynamic>> _customRewards = [
    {
      'title': '1 Hour PlayStation Time 🎮',
      'requirement': 'Reach Level 3 & Complete homework',
      'status': 'Ready to Claim',
      'points': '300 XP'
    },
    {
      'title': 'Pizza Sunday Feast 🍕',
      'requirement': 'Complete 5 Math Quizzes in Quiz Arena',
      'status': 'Locked',
      'points': '500 XP'
    },
    {
      'title': 'New Comic Books Set 📚',
      'requirement': 'Reach Focus Zen Master Rank',
      'status': 'Claimed',
      'points': '800 XP'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {}); // Rebuild to update tab indicator
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<AppState>(context, listen: false);
      if (state.isLoggedIn) {
        state.syncTeacherMessagesFromDb();
        state.syncDoubtsFromDb();
        state.syncHomeworkAndNotesFromDb();
        state.syncLiveClassesFromDb();
      }
    });

    // Check for live class every 30 seconds
    _liveClassCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _passcodeController.dispose();
    _questController.dispose();
    _liveClassCheckTimer?.cancel();
    super.dispose();
  }

  // Check if any live class is happening NOW or within 15 minutes
  Map<String, dynamic>? _getUpcomingLiveClass(AppState state) {
    final now = DateTime.now();
    for (final cls in state.liveClassesSchedule) {
      try {
        final timeStr = cls['time'] ?? cls['scheduled_time'] ?? '';
        if (timeStr.isEmpty) continue;

        // Parse time string like "10:30 AM" or "14:00"
        TimeOfDay? classTime;
        if (timeStr.contains('AM') || timeStr.contains('PM')) {
          final parts = timeStr.trim().split(' ');
          final timeParts = parts[0].split(':');
          int hour = int.parse(timeParts[0]);
          int minute = int.parse(timeParts[1]);
          if (parts[1] == 'PM' && hour != 12) hour += 12;
          if (parts[1] == 'AM' && hour == 12) hour = 0;
          classTime = TimeOfDay(hour: hour, minute: minute);
        } else if (timeStr.contains(':')) {
          final parts = timeStr.split(':');
          classTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }

        if (classTime != null) {
          final classDateTime = DateTime(now.year, now.month, now.day, classTime.hour, classTime.minute);
          final diff = classDateTime.difference(now).inMinutes;
          // Show alert if class is within 15 minutes or ongoing (within duration)
          final durationMin = int.tryParse(cls['duration']?.toString() ?? '45') ?? 45;
          if (diff >= -durationMin && diff <= 15) {
            return cls;
          }
        }
      } catch (_) {}
    }
    return null;
  }

  void _verifyPasscode(AppState state) {
    final pin = _passcodeController.text;
    if (pin == '1234' || pin == '0000' || pin == state.parentPin) {
      setState(() {
        _isUnlocked = true;
        _liveClassAlertDismissed = false;
      });
      _passcodeController.clear();
    } else {
      _passcodeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.translate('❌ Invalid PIN! (Hint: Try 1234 or 0000)')),
          backgroundColor: AdyapanTheme.pink,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAddRewardDialog(AppState state) {
    final titleController = TextEditingController();
    final reqController = TextEditingController();
    final xpController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            state.translate('Add Real-Life Reward 🎁'),
            style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold, color: AdyapanTheme.purple),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: state.translate('Reward Name (e.g., Pizza, Xbox Time)'),
                  labelStyle: GoogleFonts.outfit(fontSize: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reqController,
                decoration: InputDecoration(
                  labelText: state.translate('Requirement (e.g., Reach Level 5)'),
                  labelStyle: GoogleFonts.outfit(fontSize: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: xpController,
                decoration: InputDecoration(
                  labelText: state.translate('XP Threshold (e.g., 400 XP)'),
                  labelStyle: GoogleFonts.outfit(fontSize: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(state.translate('Cancel'), style: GoogleFonts.fredoka(color: AdyapanTheme.textSub)),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  setState(() {
                    _customRewards.add({
                      'title': titleController.text,
                      'requirement': reqController.text.isNotEmpty ? reqController.text : 'Complete Study Milestones',
                      'status': 'Locked',
                      'points': xpController.text.isNotEmpty ? '${xpController.text} XP' : '200 XP',
                    });
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.translate('🎉 New Reward Milestone added!')),
                      backgroundColor: AdyapanTheme.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AdyapanTheme.purple),
              child: Text(state.translate('Add Reward'), style: GoogleFonts.fredoka(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }

  // ──────────────────────────────────────────
  // BUILD PIN ACCESS LOCK SCREEN
  // ──────────────────────────────────────────
  Widget _buildAccessLock(AppState state) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AdyapanTheme.purple.withOpacity(0.12), AdyapanTheme.blueAccent.withOpacity(0.08)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.supervised_user_circle_rounded, size: 64, color: AdyapanTheme.purple),
            ),
            const SizedBox(height: 20),
            Text(
              state.translate('Parent Portal Gatekeeper'),
              style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              state.translate('Please enter your 4-digit PIN to access parent analytics, limit sliders, and quest creators.'),
              style: GoogleFonts.outfit(fontSize: 12, color: AdyapanTheme.textSub),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            Container(
              width: 220,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(color: AdyapanTheme.purple.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4)),
                ],
              ),
              child: TextField(
                controller: _passcodeController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 12),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '••••',
                  hintStyle: GoogleFonts.outfit(color: AdyapanTheme.textMuted, letterSpacing: 8),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AdyapanTheme.purple, width: 2.5),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onSubmitted: (_) => _verifyPasscode(state),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 220,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _verifyPasscode(state),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdyapanTheme.purple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  elevation: 3,
                ),
                child: Text(
                  state.translate('Unlock Portal'),
                  style: GoogleFonts.fredoka(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              state.translate('(Demo Bypass PIN: 1234)'),
              style: GoogleFonts.outfit(fontSize: 10, color: AdyapanTheme.textMuted, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // LIVE CLASS ALERT BANNER
  // ──────────────────────────────────────────
  Widget _buildLiveClassAlert(AppState state, Map<String, dynamic> cls) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🔴 ${state.translate('Live Class Starting!')}',
                  style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  '${cls['subject'] ?? state.translate('Class')} • ${cls['time'] ?? ''}',
                  style: GoogleFonts.outfit(fontSize: 11, color: Colors.white.withOpacity(0.9)),
                ),
                Text(
                  state.translate('Your child\'s class is about to begin. Please ensure they are ready!'),
                  style: GoogleFonts.outfit(fontSize: 10, color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _liveClassAlertDismissed = true),
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // TAB: OVERVIEW
  // ──────────────────────────────────────────
  Widget _buildOverviewTab(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Device Lock Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: state.deviceFrozen ? Colors.red.withOpacity(0.06) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: state.deviceFrozen ? Colors.redAccent.withOpacity(0.4) : AdyapanTheme.glassBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: state.deviceFrozen ? Colors.red.withOpacity(0.12) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  state.deviceFrozen ? Icons.lock_rounded : Icons.phonelink_lock_rounded,
                  color: state.deviceFrozen ? Colors.redAccent : AdyapanTheme.purple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.deviceFrozen
                          ? state.translate('Remote Device Frozen')
                          : state.translate('Freeze Child Device'),
                      style: GoogleFonts.fredoka(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: state.deviceFrozen ? Colors.redAccent : AdyapanTheme.textMain,
                      ),
                    ),
                    Text(
                      state.deviceFrozen
                          ? state.translate('Broadcast lock is active.')
                          : state.translate('Instantly freeze all study & game rooms.'),
                      style: GoogleFonts.outfit(fontSize: 10, color: AdyapanTheme.textSub),
                    ),
                  ],
                ),
              ),
              Switch(
                value: state.deviceFrozen,
                activeColor: Colors.redAccent,
                onChanged: (val) {
                  state.setDeviceFrozen(val);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        val
                            ? state.translate('🛑 Device instantly locked! App is frozen.')
                            : state.translate('📱 Device unlocked. Study rooms are active.'),
                      ),
                      backgroundColor: val ? Colors.redAccent : AdyapanTheme.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. Stats Row
        Text(
          state.translate('Active Study Metrics & Streaks'),
          style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('📈', state.translate('Study Ratio'), state.translate('78% Efficiency'), AdyapanTheme.green)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('⏳', state.translate('Daily Screen Limit'), '${state.screenLimit.toInt()} ${state.translate('Mins')}', AdyapanTheme.blueAccent)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('🔥', state.translate('Streak'), '${state.streak} ${state.translate('Days')}', AdyapanTheme.orange)),
          ],
        ),
        const SizedBox(height: 16),

        // 3. Subject Progress
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AdyapanTheme.glassCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.translate('Subject Focus Distribution'),
                style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain),
              ),
              const SizedBox(height: 14),
              _buildSubjectProgressBar(state.translate('Mathematics & BODMAS'), 0.80, '120 ${state.translate('Mins')}', AdyapanTheme.pink),
              const SizedBox(height: 10),
              _buildSubjectProgressBar(state.translate('Science & Orbitals'), 0.60, '90 ${state.translate('Mins')}', AdyapanTheme.blueAccent),
              const SizedBox(height: 10),
              _buildSubjectProgressBar(state.translate('English & Voices'), 0.40, '60 ${state.translate('Mins')}', AdyapanTheme.green),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 4. Screen Time Slider
        Text(
          state.translate('Manage Play Limits'),
          style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AdyapanTheme.glassCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(state.translate('Max Daily Screen Time:'), style: GoogleFonts.outfit(fontSize: 13, color: AdyapanTheme.textSub)),
                  Text(
                    '${state.screenLimit.toInt()} ${state.translate('Mins')}',
                    style: GoogleFonts.fredoka(fontSize: 14, color: AdyapanTheme.blueAccent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: state.screenLimit,
                min: 15,
                max: 180,
                divisions: 11,
                activeColor: AdyapanTheme.blueAccent,
                inactiveColor: AdyapanTheme.bgLightDark,
                onChanged: (val) => state.updateScreenLimit(val),
              ),
              Text(
                state.translate('Once this limit is hit, Focus Mode engaged screens will freeze until verified by parents.'),
                style: GoogleFonts.outfit(fontSize: 10, color: AdyapanTheme.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 5. Quest Assigner
        Text(state.translate('Assign Custom Special Quest'), style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AdyapanTheme.glassCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _questController,
                style: GoogleFonts.outfit(fontSize: 13, color: AdyapanTheme.textMain),
                decoration: InputDecoration(
                  hintText: state.translate('e.g., Complete Atomic Shell Game...'),
                  hintStyle: GoogleFonts.outfit(fontSize: 12, color: AdyapanTheme.textMuted),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AdyapanTheme.purple, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(state.translate('Select XP Reward:'), style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('${_xpReward.toInt()} XP', style: GoogleFonts.fredoka(fontSize: 13, color: AdyapanTheme.orange, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: _xpReward,
                min: 50,
                max: 500,
                divisions: 9,
                activeColor: AdyapanTheme.purple,
                inactiveColor: AdyapanTheme.bgLightDark,
                onChanged: (val) => setState(() => _xpReward = val),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  if (_questController.text.isNotEmpty) {
                    state.setParentQuest(_questController.text, _xpReward.toInt());
                    _questController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.translate('🎉 Quest successfully synced to Child\'s Dashboard!')),
                        backgroundColor: AdyapanTheme.green,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdyapanTheme.purple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  minimumSize: const Size(double.infinity, 46),
                ),
                child: Text(state.translate('Assign Quest to Child'), style: GoogleFonts.fredoka(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 6. Real-Life Milestones & Shop
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(state.translate('Real-Life Milestones & Shop 🎁'), style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain)),
            IconButton(
              icon: const Icon(Icons.add_box_rounded, color: AdyapanTheme.purple, size: 24),
              onPressed: () => _showAddRewardDialog(state),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...List.generate(_customRewards.length, (index) {
          final reward = _customRewards[index];
          final String status = reward['status'];
          final Color statusColor = status == 'Ready to Claim'
              ? AdyapanTheme.green
              : status == 'Claimed'
                  ? AdyapanTheme.textMuted
                  : AdyapanTheme.pink;

          return Card(
            color: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AdyapanTheme.glassBorder),
            ),
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(state.translate(reward['title'] ?? ''), style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: Text(
                '${state.translate(reward['requirement'] ?? '')} (${state.translate(reward['points'] ?? '')})',
                style: GoogleFonts.outfit(fontSize: 10, color: AdyapanTheme.textSub),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  state.translate(status),
                  style: GoogleFonts.fredoka(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold),
                ),
              ),
              onTap: () {
                setState(() {
                  if (status == 'Locked') {
                    reward['status'] = 'Ready to Claim';
                  } else if (status == 'Ready to Claim') {
                    reward['status'] = 'Claimed';
                  } else {
                    reward['status'] = 'Locked';
                  }
                });
              },
            ),
          );
        }),
        const SizedBox(height: 20),
      ],
    );
  }

  // ──────────────────────────────────────────
  // TAB: TEACHER MESSAGES
  // ──────────────────────────────────────────
  Widget _buildMessagesTab(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with refresh
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.translate('Teacher Messages'),
                  style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain),
                ),
                Text(
                  state.translate('Messages & alerts sent by school teachers'),
                  style: GoogleFonts.outfit(fontSize: 11, color: AdyapanTheme.textSub),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AdyapanTheme.blueAccent),
              onPressed: () => state.syncTeacherMessagesFromDb(),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (state.teacherMessages.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: AdyapanTheme.glassCardDecoration(),
            child: Column(
              children: [
                const Text('📬', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 10),
                Text(
                  state.translate('No recent alerts from school teachers.'),
                  style: GoogleFonts.outfit(fontSize: 13, color: AdyapanTheme.textSub),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  state.translate('Teacher messages will appear here when sent.'),
                  style: GoogleFonts.outfit(fontSize: 11, color: AdyapanTheme.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...List.generate(state.teacherMessages.length, (index) {
            final msg = state.teacherMessages[index];
            final isMeeting = msg['category'] == 'Meeting Request';
            final response = msg['meetingResponse'] ?? '';
            final isRead = msg['isRead'] == true;

            final categoryColor = isMeeting ? AdyapanTheme.orange : (msg['category'] == 'Syllabus Alert' ? AdyapanTheme.green : AdyapanTheme.purple);

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isRead ? AdyapanTheme.glassBorder : categoryColor.withOpacity(0.3),
                  width: isRead ? 1.0 : 1.8,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isMeeting ? Icons.event_rounded : Icons.notifications_rounded,
                          color: categoryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg['teacherName'] ?? state.translate('Teacher'),
                              style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain),
                            ),
                            Text(
                              msg['date'] ?? 'Today',
                              style: GoogleFonts.outfit(fontSize: 10, color: AdyapanTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          state.translate(msg['category'] ?? 'Notice'),
                          style: GoogleFonts.fredoka(fontSize: 10, fontWeight: FontWeight.bold, color: categoryColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg['message'] ?? '',
                      style: GoogleFonts.outfit(fontSize: 12, color: AdyapanTheme.textMain, height: 1.5),
                    ),
                  ),
                  if (isMeeting) ...[
                    const SizedBox(height: 12),
                    if (response.isEmpty)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                state.respondToMeeting(msg['id'], 'accepted');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(state.translate('✅ Meeting request accepted! Teacher notified.')),
                                    backgroundColor: AdyapanTheme.green,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.check_circle_outline, size: 14, color: Colors.white),
                              label: Text(state.translate('Accept'), style: GoogleFonts.fredoka(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AdyapanTheme.green,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                state.respondToMeeting(msg['id'], 'declined');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(state.translate('❌ Meeting request declined. Teacher notified.')),
                                    backgroundColor: AdyapanTheme.pink,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.cancel_outlined, size: 14, color: AdyapanTheme.pink),
                              label: Text(state.translate('Decline'), style: GoogleFonts.fredoka(fontSize: 12, fontWeight: FontWeight.bold, color: AdyapanTheme.pink)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AdyapanTheme.pink),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (response == 'accepted' ? AdyapanTheme.green : AdyapanTheme.pink).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              response == 'accepted' ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              size: 16,
                              color: response == 'accepted' ? AdyapanTheme.green : AdyapanTheme.pink,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              response == 'accepted'
                                  ? state.translate('Confirmed ✓ (Teacher notified)')
                                  : state.translate('Declined ✗ (Teacher notified)'),
                              style: GoogleFonts.fredoka(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: response == 'accepted' ? AdyapanTheme.green : AdyapanTheme.pink,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            );
          }),
        const SizedBox(height: 20),
      ],
    );
  }

  // ──────────────────────────────────────────
  // TAB: REPORTS
  // ──────────────────────────────────────────
  Widget _buildReportsTab(AppState state) {
    final homeworkTotal = state.homeworkList.length;
    final homeworkSubmitted = state.submittedHomeworkCount;
    final homeworkPending = state.pendingHomeworkCount;
    final attendanceList = state.attendanceLogs;
    final presentCount = attendanceList.where((a) => a['status'] == 'Present').length;
    final totalAttendance = attendanceList.isNotEmpty ? attendanceList.length : 1;
    final attendancePct = ((presentCount / totalAttendance) * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          state.translate('Academic Report Card'),
          style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain),
        ),
        Text(
          state.translate('Real-time summary of your child\'s performance'),
          style: GoogleFonts.outfit(fontSize: 11, color: AdyapanTheme.textSub),
        ),
        const SizedBox(height: 18),

        // Overall Score Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(state.translate('Overall Performance'), style: GoogleFonts.fredoka(fontSize: 14, color: Colors.white70)),
              const SizedBox(height: 6),
              Text(
                '${((state.overallSyllabusProgress)).toStringAsFixed(0)}%',
                style: GoogleFonts.fredoka(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                state.translate('Syllabus Completion Rate'),
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: state.overallSyllabusProgress / 100,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Stats Grid
        Row(
          children: [
            Expanded(
              child: _buildReportCard(
                '📚',
                state.translate('Homework'),
                '$homeworkSubmitted/${homeworkTotal} ${state.translate('Done')}',
                '$homeworkPending ${state.translate('Pending')}',
                AdyapanTheme.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildReportCard(
                '🗓️',
                state.translate('Attendance'),
                '$attendancePct% ${state.translate('Present')}',
                '$presentCount/$totalAttendance ${state.translate('Days')}',
                AdyapanTheme.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildReportCard(
                '🎮',
                state.translate('Quiz Score'),
                '${state.completedQuizzesCount} ${state.translate('Quizzes')}',
                '+${state.xp} XP ${state.translate('Earned')}',
                AdyapanTheme.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildReportCard(
                '🔥',
                state.translate('Study Streak'),
                '${state.streak} ${state.translate('Days')}',
                state.translate('Keep it up!'),
                AdyapanTheme.pink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Subject Progress Detail
        Text(
          state.translate('Subject-wise Progress'),
          style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AdyapanTheme.glassCardDecoration(),
          child: Column(
            children: [
              _buildDetailedSubjectRow('📐', state.translate('Mathematics'), state.mathSyllabusProgress / 100, AdyapanTheme.pink, state),
              const Divider(height: 20),
              _buildDetailedSubjectRow('🔬', state.translate('Science'), state.scienceSyllabusProgress / 100, AdyapanTheme.blueAccent, state),
              const Divider(height: 20),
              _buildDetailedSubjectRow('📖', state.translate('English'), state.englishSyllabusProgress / 100, AdyapanTheme.green, state),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Recent Homework List
        Text(
          state.translate('Recent Homework'),
          style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain),
        ),
        const SizedBox(height: 12),
        if (state.homeworkList.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: AdyapanTheme.glassCardDecoration(),
            child: Column(
              children: [
                const Text('📋', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                Text(
                  state.translate('No homework assigned yet.'),
                  style: GoogleFonts.outfit(fontSize: 12, color: AdyapanTheme.textSub),
                ),
              ],
            ),
          )
        else
          ...state.homeworkList.take(5).map((hw) {
            final bool submitted = hw['submitted'] == true;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AdyapanTheme.glassBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: submitted ? AdyapanTheme.green.withOpacity(0.1) : AdyapanTheme.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      submitted ? Icons.check_circle_rounded : Icons.pending_rounded,
                      color: submitted ? AdyapanTheme.green : AdyapanTheme.orange,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hw['title'] ?? '', style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold)),
                        Text(
                          '${hw['subject'] ?? ''} • ${state.translate('Due')}: ${hw['dueDate'] ?? ''}',
                          style: GoogleFonts.outfit(fontSize: 10, color: AdyapanTheme.textSub),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (submitted ? AdyapanTheme.green : AdyapanTheme.orange).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      submitted ? state.translate('Done') : state.translate('Pending'),
                      style: GoogleFonts.fredoka(fontSize: 10, fontWeight: FontWeight.bold, color: submitted ? AdyapanTheme.green : AdyapanTheme.orange),
                    ),
                  ),
                ],
              ),
            );
          }),

        const SizedBox(height: 20),

        // Live Class Schedule
        Text(
          state.translate('Upcoming Live Classes'),
          style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain),
        ),
        const SizedBox(height: 12),
        if (state.liveClassesSchedule.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: AdyapanTheme.glassCardDecoration(),
            child: Column(
              children: [
                const Text('📹', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                Text(
                  state.translate('No live classes scheduled.'),
                  style: GoogleFonts.outfit(fontSize: 12, color: AdyapanTheme.textSub),
                ),
              ],
            ),
          )
        else
          ...state.liveClassesSchedule.take(5).map((cls) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.videocam_rounded, color: Color(0xFFEF4444), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cls['subject'] ?? cls['title'] ?? state.translate('Class'), style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold)),
                        Text(
                          '${cls['time'] ?? ''} • ${cls['duration'] ?? '45'} ${state.translate('Mins')}',
                          style: GoogleFonts.outfit(fontSize: 10, color: AdyapanTheme.textSub),
                        ),
                      ],
                    ),
                  ),
                  Text(cls['date'] ?? '', style: GoogleFonts.outfit(fontSize: 10, color: AdyapanTheme.textMuted)),
                ],
              ),
            );
          }),
        const SizedBox(height: 20),
      ],
    );
  }

  // Helper widgets
  Widget _buildStatCard(String emoji, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AdyapanTheme.glassCardDecoration(),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.outfit(fontSize: 9, color: AdyapanTheme.textMuted, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          Text(value, style: GoogleFonts.fredoka(fontSize: 13, color: color, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildReportCard(String emoji, String title, String mainVal, String subVal, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(title, style: GoogleFonts.outfit(fontSize: 10, color: AdyapanTheme.textMuted, fontWeight: FontWeight.bold)),
          Text(mainVal, style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(subVal, style: GoogleFonts.outfit(fontSize: 10, color: AdyapanTheme.textSub)),
        ],
      ),
    );
  }

  Widget _buildDetailedSubjectRow(String emoji, String subject, double ratio, Color color, AppState state) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(subject, style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('${(ratio * 100).toStringAsFixed(0)}%', style: GoogleFonts.fredoka(fontSize: 13, color: color, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 7,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectProgressBar(String title, double ratio, String meta, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: GoogleFonts.outfit(fontSize: 11, color: AdyapanTheme.textMain, fontWeight: FontWeight.bold)),
            Text(meta, style: GoogleFonts.outfit(fontSize: 10, color: AdyapanTheme.textSub, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────
  // MAIN UNLOCKED DASHBOARD
  // ──────────────────────────────────────────
  Widget _buildParentDashboard(AppState state) {
    final upcomingClass = !_liveClassAlertDismissed ? _getUpcomingLiveClass(state) : null;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AdyapanTheme.purple, AdyapanTheme.blueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.supervisor_account_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.translate('Welcome, Parent!'),
                      style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold, color: AdyapanTheme.purple),
                    ),
                    Text(
                      state.translate('Monitor & manage your child\'s learning'),
                      style: GoogleFonts.outfit(fontSize: 11, color: AdyapanTheme.textSub),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AdyapanTheme.blueAccent, size: 22),
                onPressed: () async {
                  await state.syncTeacherMessagesFromDb();
                  await state.syncLiveClassesFromDb();
                  await state.syncHomeworkAndNotesFromDb();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.translate('Data refreshed!')), backgroundColor: AdyapanTheme.green, duration: const Duration(seconds: 1)),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.lock_rounded, color: AdyapanTheme.textSub, size: 22),
                onPressed: () => setState(() => _isUnlocked = false),
              ),
            ],
          ),
        ),

        // Tab Bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF2563EB)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: AdyapanTheme.textSub,
            labelStyle: GoogleFonts.fredoka(fontSize: 12, fontWeight: FontWeight.bold),
            unselectedLabelStyle: GoogleFonts.fredoka(fontSize: 12),
            dividerColor: Colors.transparent,
            padding: const EdgeInsets.all(4),
            tabs: [
              Tab(text: state.translate('Overview')),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.translate('Messages'), style: GoogleFonts.fredoka(fontSize: 12)),
                    if (state.teacherMessages.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                        child: Text('${state.teacherMessages.length}', style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ),
              Tab(text: state.translate('Reports')),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Tab Content
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await state.syncTeacherMessagesFromDb();
              await state.syncHomeworkAndNotesFromDb();
              await state.syncLiveClassesFromDb();
            },
            color: AdyapanTheme.purple,
            backgroundColor: Colors.white,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 0: Overview
                SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Column(
                    children: [
                      if (upcomingClass != null) _buildLiveClassAlert(state, upcomingClass),
                      _buildOverviewTab(state),
                    ],
                  ),
                ),
                // Tab 1: Messages
                SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: _buildMessagesTab(state),
                ),
                // Tab 2: Reports
                SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: _buildReportsTab(state),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    return Scaffold(
      backgroundColor: AdyapanTheme.bgDark,
      body: SafeArea(
        child: _isUnlocked ? _buildParentDashboard(state) : _buildAccessLock(state),
      ),
    );
  }
}
