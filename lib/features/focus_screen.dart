import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../core/flutter_dnd.dart';
import '../core/theme.dart';
import '../core/app_state.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ConfettiController _confettiController;

  // ── Pomodoro Timer ──
  Timer? _timer;
  int _selectedDurationMinutes = 25;
  int _secondsLeft = 25 * 60;
  bool _isRunning = false;

  // ── DND / Focus Shield ──
  bool _dndGranted = false;
  bool _shieldActive = false; // true when DND is ON

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _secondsLeft = _selectedDurationMinutes * 60;
    _checkDndPermission();
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Always restore notifications when screen is left
    if (_shieldActive) _disableDnd();
    _tabController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  // ── DND Helpers ──

  Future<void> _checkDndPermission() async {
    try {
      final granted = await FlutterDnd.isNotificationPolicyAccessGranted;
      if (mounted) {
        setState(() {
          _dndGranted = granted ?? false;
        });
      }
    } catch (_) {}
  }

  Future<void> _requestDndPermission() async {
    // Opens Android's DND access settings page (returns void, no await needed)
    FlutterDnd.gotoPolicySettings();
    // Re-check after returning from settings
    await Future.delayed(const Duration(milliseconds: 800));
    await _checkDndPermission();
  }

  Future<void> _enableDnd() async {
    try {
      // INTERRUPTION_FILTER_NONE = total silence, no notifications at all
      await FlutterDnd.setInterruptionFilter(
          FlutterDnd.INTERRUPTION_FILTER_NONE);
      if (mounted) setState(() => _shieldActive = true);
    } catch (e) {
      debugPrint('DND enable failed: $e');
    }
  }

  Future<void> _disableDnd() async {
    try {
      // INTERRUPTION_FILTER_ALL = normal mode, all notifications allowed
      await FlutterDnd.setInterruptionFilter(
          FlutterDnd.INTERRUPTION_FILTER_ALL);
      if (mounted) setState(() => _shieldActive = false);
    } catch (e) {
      debugPrint('DND disable failed: $e');
    }
  }

  // ── Timer Controls ──

  void _changeDuration(int minutes) {
    if (_isRunning) return;
    setState(() {
      _selectedDurationMinutes = minutes;
      _secondsLeft = minutes * 60;
    });
  }

  Future<void> _startTimer() async {
    if (_isRunning) return;

    // Check DND permission before starting
    if (!_dndGranted) {
      await _checkDndPermission();
      if (!_dndGranted) {
        if (!mounted) return;
        _showPermissionDialog();
        return;
      }
    }

    // Enable DND — block all notifications
    await _enableDnd();

    setState(() => _isRunning = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        timer.cancel();
        _onTimerComplete();
      }
    });
  }

  Future<void> _onTimerComplete() async {
    // Re-enable notifications first
    await _disableDnd();

    final state = Provider.of<AppState>(context, listen: false);
    state.logStudySession(_selectedDurationMinutes);
    _confettiController.play();

    setState(() {
      _secondsLeft = _selectedDurationMinutes * 60;
      _isRunning = false;
    });

    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final mins = _selectedDurationMinutes;
      messenger.showSnackBar(SnackBar(
        content: Text(
          '$mins min session complete! +${mins * 2} XP. Notifications restored.',
          style: AdyapanTheme.fredoka(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: AdyapanTheme.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
    }
  }

  Future<void> _pauseTimer() async {
    _timer?.cancel();
    // Restore notifications when paused
    await _disableDnd();
    setState(() => _isRunning = false);
  }

  Future<void> _resetTimer() async {
    _timer?.cancel();
    await _disableDnd();
    setState(() {
      _secondsLeft = _selectedDurationMinutes * 60;
      _isRunning = false;
    });
  }

  Future<void> _logAndStop() async {
    _timer?.cancel();
    final state = Provider.of<AppState>(context, listen: false);
    int minutesStudied =
        ((_selectedDurationMinutes * 60 - _secondsLeft) / 60).ceil();
    await _disableDnd();
    if (minutesStudied > 0) {
      state.logStudySession(minutesStudied);
    }
    setState(() {
      _secondsLeft = _selectedDurationMinutes * 60;
      _isRunning = false;
    });
    if (mounted && minutesStudied > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Logged $minutesStudied min! +${minutesStudied * 2} XP. Notifications restored.',
          style: AdyapanTheme.fredoka(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: AdyapanTheme.blueAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
    }
  }

  String _formatTime(int totalSeconds) {
    int m = totalSeconds ~/ 60;
    int s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── Permission Dialog ──
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AdyapanTheme.cyan.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.shield_rounded, color: AdyapanTheme.cyan),
            ),
            const SizedBox(width: 12),
            Text('Allow Focus Shield',
                style: AdyapanTheme.fredoka(
                    fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Focus Shield needs "Do Not Disturb" access to block all phone notifications while you study.\n\nTap "Open Settings" → find Adyapan → toggle ON.',
          style: AdyapanTheme.outfit(
              fontSize: 13, color: AdyapanTheme.textSub, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Later',
                style: AdyapanTheme.fredoka(color: AdyapanTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _requestDndPermission();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdyapanTheme.cyan,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Open Settings',
                style: AdyapanTheme.fredoka(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Focus Rank ──
  String _getFocusRank(int count) {
    if (count > 6) return 'Zen Master';
    if (count > 4) return 'Focus Guru';
    if (count > 2) return 'Explorer';
    return 'Rookie';
  }

  // ── UI ──

  Widget _buildStatsBar(AppState state) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AdyapanTheme.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statCell('Streak', '${state.streak} Days', AdyapanTheme.pink),
          Container(width: 1, height: 30, color: AdyapanTheme.glassBorder),
          _statCell(
            'Total Study',
            '${state.studySessions.fold(0, (a, b) => a + b)}m',
            AdyapanTheme.blueAccent,
          ),
          Container(width: 1, height: 30, color: AdyapanTheme.glassBorder),
          _statCell(
            'Rank',
            _getFocusRank(state.studySessions.length),
            AdyapanTheme.green,
          ),
        ],
      ),
    );
  }

  Widget _statCell(String label, String value, Color color) {
    return Column(
      children: [
        Text(label.toUpperCase(),
            style: AdyapanTheme.outfit(
                fontSize: 9,
                color: AdyapanTheme.textMuted,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        Text(value,
            style: AdyapanTheme.fredoka(
                fontSize: 13, color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ── TAB 1: Pomodoro ──
  Widget _buildPomodoroTab(AppState state) {
    final double progress = _secondsLeft == _selectedDurationMinutes * 60
        ? 0
        : (_selectedDurationMinutes * 60 - _secondsLeft) /
            (_selectedDurationMinutes * 60);

    return Column(
      children: [
        const SizedBox(height: 12),

        // ── DND permission banner ──
        if (!_dndGranted)
          GestureDetector(
            onTap: _showPermissionDialog,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AdyapanTheme.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AdyapanTheme.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AdyapanTheme.orange, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tap here to allow notification blocking for Focus Shield',
                      style: AdyapanTheme.outfit(
                          fontSize: 12,
                          color: AdyapanTheme.orange,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: AdyapanTheme.orange, size: 14),
                ],
              ),
            ),
          ),

        // ── Active DND status pill ──
        if (_shieldActive)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: AdyapanTheme.cyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                  color: AdyapanTheme.cyan.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AdyapanTheme.cyan,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Focus Shield ON — All notifications blocked',
                  style: AdyapanTheme.outfit(
                      fontSize: 12,
                      color: AdyapanTheme.cyan,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

        // ── Circular timer ──
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 190,
              height: 190,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 14,
                backgroundColor: AdyapanTheme.bgLightDark,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _shieldActive
                      ? AdyapanTheme.cyan
                      : _isRunning
                          ? AdyapanTheme.pink
                          : AdyapanTheme.blueAccent,
                ),
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(_secondsLeft),
                  style: AdyapanTheme.fredoka(
                      fontSize: 40, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  _shieldActive
                      ? 'SHIELD ACTIVE'
                      : _isRunning
                          ? 'FOCUSING...'
                          : 'SET TIMER',
                  style: AdyapanTheme.outfit(
                    fontSize: 11,
                    color: _shieldActive
                        ? AdyapanTheme.cyan
                        : _isRunning
                            ? AdyapanTheme.pink
                            : AdyapanTheme.textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Duration pills ──
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [15, 25, 45, 60].map((m) {
                final bool sel = _selectedDurationMinutes == m;
                return GestureDetector(
                  onTap: () => _changeDuration(m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: sel ? AdyapanTheme.pink : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: sel
                            ? Colors.transparent
                            : AdyapanTheme.glassBorder,
                      ),
                      boxShadow: sel
                          ? [
                              BoxShadow(
                                color: AdyapanTheme.pink.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Text(
                      '$m min',
                      style: AdyapanTheme.fredoka(
                        fontSize: 12,
                        color: sel ? Colors.white : AdyapanTheme.textSub,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // ── Controls: Reset | Play/Pause | Log Done ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Reset
            _iconBtn(
              icon: Icons.refresh_rounded,
              color: AdyapanTheme.textSub,
              onTap: _isRunning ? _resetTimer : null,
              enabled: _isRunning,
            ),
            const SizedBox(width: 20),

            // Play / Pause — big gradient button
            GestureDetector(
              onTap: _isRunning ? _pauseTimer : _startTimer,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _shieldActive
                        ? [AdyapanTheme.cyan, const Color(0xFF0284C7)]
                        : [AdyapanTheme.pink, AdyapanTheme.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_shieldActive
                              ? AdyapanTheme.cyan
                              : AdyapanTheme.pink)
                          .withOpacity(0.45),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Icon(
                  _isRunning
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(width: 20),

            // Log & Stop
            _iconBtn(
              icon: Icons.check_circle_outline_rounded,
              color: progress > 0
                  ? AdyapanTheme.green
                  : AdyapanTheme.textMuted,
              onTap: progress > 0 ? _logAndStop : null,
              enabled: progress > 0,
            ),
          ],
        ),
        const SizedBox(height: 32),

        // ── What happens when you start ──
        if (!_isRunning)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AdyapanTheme.blueAccent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AdyapanTheme.blueAccent.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What happens when you press Play:',
                    style: AdyapanTheme.fredoka(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AdyapanTheme.blueAccent)),
                const SizedBox(height: 10),
                _infoRow(Icons.notifications_off_rounded,
                    'All phone notifications blocked instantly (WhatsApp, Instagram, everything)'),
                _infoRow(Icons.timer_rounded,
                    'Timer counts down — you study distraction-free'),
                _infoRow(Icons.notifications_active_rounded,
                    'Notifications automatically restored when timer ends'),
                _infoRow(Icons.stop_circle_outlined,
                    'Pause anytime to restore notifications immediately'),
              ],
            ),
          ),

        const SizedBox(height: 28),

        // ── Session Checklist ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Session Checklist',
                style: AdyapanTheme.fredoka(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline,
                  color: AdyapanTheme.blueAccent, size: 22),
              onPressed: () => _showAddTaskDialog(context, state),
            ),
          ],
        ),
        const SizedBox(height: 8),
        state.todos.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No tasks yet. Add tasks to track your session goals.',
                  style: AdyapanTheme.outfit(
                      fontSize: 12, color: AdyapanTheme.textMuted),
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.todos.length,
                itemBuilder: (ctx, i) {
                  final todo = state.todos[i];
                  final done = todo['completed'] as bool;
                  return Card(
                    color: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(
                          color: AdyapanTheme.glassBorder),
                    ),
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      dense: true,
                      leading: Checkbox(
                        value: done,
                        activeColor: AdyapanTheme.green,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                        onChanged: (_) {
                          state.toggleTodo(todo['id']);
                          if (!done) _confettiController.play();
                        },
                      ),
                      title: Text(
                        todo['title'],
                        style: AdyapanTheme.fredoka(
                          fontSize: 13,
                          color: done
                              ? AdyapanTheme.textMuted
                              : AdyapanTheme.textMain,
                          fontWeight: FontWeight.bold,
                        ).copyWith(
                          decoration: done
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AdyapanTheme.blueAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          todo['tag'],
                          style: AdyapanTheme.outfit(
                              fontSize: 9,
                              color: AdyapanTheme.blueAccent,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : AdyapanTheme.bgLightDark,
          shape: BoxShape.circle,
          border: Border.all(color: AdyapanTheme.glassBorder),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AdyapanTheme.blueAccent),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: AdyapanTheme.outfit(
                      fontSize: 12,
                      color: AdyapanTheme.textSub,
                      height: 1.4))),
        ],
      ),
    );
  }

  // ── TAB 2: Shield Info ──
  Widget _buildShieldTab() {
    return Column(
      children: [
        const SizedBox(height: 12),

        // Big shield status card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _shieldActive
                  ? AdyapanTheme.cyan.withOpacity(0.5)
                  : AdyapanTheme.glassBorder,
              width: 1.5,
            ),
            boxShadow: _shieldActive
                ? [
                    BoxShadow(
                      color: AdyapanTheme.cyan.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 2,
                    )
                  ]
                : AdyapanTheme.cardShadow,
          ),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _shieldActive
                      ? AdyapanTheme.cyan.withOpacity(0.12)
                      : _dndGranted
                          ? AdyapanTheme.green.withOpacity(0.08)
                          : AdyapanTheme.bgLightDark,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _shieldActive
                        ? AdyapanTheme.cyan
                        : _dndGranted
                            ? AdyapanTheme.green
                            : AdyapanTheme.textMuted.withOpacity(0.3),
                    width: 3,
                  ),
                  boxShadow: _shieldActive
                      ? [
                          BoxShadow(
                            color: AdyapanTheme.cyan.withOpacity(0.4),
                            blurRadius: 24,
                            spreadRadius: 4,
                          )
                        ]
                      : [],
                ),
                child: Icon(
                  _shieldActive
                      ? Icons.shield_rounded
                      : _dndGranted
                          ? Icons.shield_outlined
                          : Icons.no_encryption_gmailerrorred_rounded,
                  size: 46,
                  color: _shieldActive
                      ? AdyapanTheme.cyan
                      : _dndGranted
                          ? AdyapanTheme.green
                          : AdyapanTheme.textMuted.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _shieldActive
                    ? 'FOCUS SHIELD ACTIVE'
                    : _dndGranted
                        ? 'SHIELD READY'
                        : 'PERMISSION REQUIRED',
                style: AdyapanTheme.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _shieldActive
                      ? AdyapanTheme.cyan
                      : _dndGranted
                          ? AdyapanTheme.green
                          : AdyapanTheme.textSub,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _shieldActive
                    ? 'All notifications are currently blocked on your phone. Timer is running.'
                    : _dndGranted
                        ? 'Press Play on the Pomodoro tab to start blocking notifications automatically.'
                        : 'Grant Do Not Disturb access so Focus Shield can block all notifications.',
                style: AdyapanTheme.outfit(
                    fontSize: 13,
                    color: AdyapanTheme.textSub,
                    height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (!_dndGranted)
                ElevatedButton.icon(
                  onPressed: _requestDndPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdyapanTheme.cyan,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50)),
                    minimumSize: const Size(220, 50),
                    shadowColor: AdyapanTheme.cyan.withOpacity(0.4),
                    elevation: 6,
                  ),
                  icon: const Icon(Icons.settings_rounded,
                      color: Colors.white, size: 18),
                  label: Text('Grant DND Access',
                      style: AdyapanTheme.fredoka(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ),
              if (_dndGranted && !_shieldActive)
                ElevatedButton.icon(
                  onPressed: () {
                    _tabController.animateTo(0);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdyapanTheme.pink,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50)),
                    minimumSize: const Size(220, 50),
                    shadowColor: AdyapanTheme.pink.withOpacity(0.4),
                    elevation: 6,
                  ),
                  icon: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 20),
                  label: Text('Start Pomodoro',
                      style: AdyapanTheme.fredoka(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ),
              if (_shieldActive)
                ElevatedButton.icon(
                  onPressed: _pauseTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdyapanTheme.pink,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50)),
                    minimumSize: const Size(220, 50),
                    shadowColor: AdyapanTheme.pink.withOpacity(0.4),
                    elevation: 6,
                  ),
                  icon: const Icon(Icons.pause_rounded,
                      color: Colors.white, size: 20),
                  label: Text('Pause & Restore Notifications',
                      style: AdyapanTheme.fredoka(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // How it works
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AdyapanTheme.bgLightDark,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How Focus Shield works',
                  style: AdyapanTheme.fredoka(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AdyapanTheme.textMain)),
              const SizedBox(height: 12),
              _shieldInfoRow('1', Icons.play_circle_rounded,
                  'Set your study duration and press Play', AdyapanTheme.pink),
              _shieldInfoRow('2', Icons.notifications_off_rounded,
                  'Phone goes into Do Not Disturb — NO notification from any app will appear',
                  AdyapanTheme.cyan),
              _shieldInfoRow('3', Icons.timer_rounded,
                  'Study peacefully until the timer completes',
                  AdyapanTheme.blueAccent),
              _shieldInfoRow('4', Icons.notifications_active_rounded,
                  'Timer done → notifications automatically unblocked + XP awarded',
                  AdyapanTheme.green),
            ],
          ),
        ),
      ],
    );
  }

  Widget _shieldInfoRow(
      String num, IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(num,
                style: AdyapanTheme.fredoka(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: AdyapanTheme.outfit(
                      fontSize: 12,
                      color: AdyapanTheme.textSub,
                      height: 1.4))),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, AppState state) {
    final tc = TextEditingController();
    String tag = 'Math';
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Add Session Task',
              style: AdyapanTheme.fredoka(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tc,
                decoration: InputDecoration(
                  hintText: 'e.g., Solve 10 algebra problems',
                  hintStyle: AdyapanTheme.outfit(
                      fontSize: 13, color: AdyapanTheme.textMuted),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: tag,
                decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
                items: ['Math', 'Science', 'English', 'Focus', 'General']
                    .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t,
                            style: AdyapanTheme.outfit(fontSize: 13))))
                    .toList(),
                onChanged: (v) {
                  if (v != null) tag = v;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: AdyapanTheme.fredoka(color: AdyapanTheme.textSub)),
            ),
            ElevatedButton(
              onPressed: () {
                if (tc.text.isNotEmpty) {
                  state.addTodo(tc.text, tag);
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AdyapanTheme.blueAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: Text('Add',
                  style:
                      AdyapanTheme.fredoka(color: Colors.white, fontSize: 14)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    return Scaffold(
      backgroundColor: AdyapanTheme.bgDark,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── Header ──
                Padding(
                  padding:
                      const EdgeInsets.only(top: 20, left: 12, right: 20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu_rounded,
                            color: AdyapanTheme.textMain, size: 24),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                      const SizedBox(width: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _shieldActive
                              ? AdyapanTheme.cyan.withOpacity(0.12)
                              : AdyapanTheme.pink.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _shieldActive
                              ? Icons.shield_rounded
                              : Icons.timer_10_rounded,
                          color: _shieldActive
                              ? AdyapanTheme.cyan
                              : AdyapanTheme.pink,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Study Focus Room',
                                style: AdyapanTheme.fredoka(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            Text(
                              _shieldActive
                                  ? 'All notifications blocked — stay focused!'
                                  : 'Start timer to block all distractions',
                              style: AdyapanTheme.outfit(
                                  fontSize: 11,
                                  color: _shieldActive
                                      ? AdyapanTheme.cyan
                                      : AdyapanTheme.textSub),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                _buildStatsBar(state),

                // ── Tab bar ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicator: BoxDecoration(
                      gradient: AdyapanTheme.focusGradient,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: AdyapanTheme.textSub,
                    labelStyle: AdyapanTheme.fredoka(
                        fontSize: 12, fontWeight: FontWeight.bold),
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(text: state.translate('Study Pomodoro')),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(state.translate('Focus Shield'),
                                style: AdyapanTheme.fredoka(fontSize: 12)),
                            if (_dndGranted) ...[
                              const SizedBox(width: 5),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _shieldActive
                                      ? AdyapanTheme.cyan
                                      : AdyapanTheme.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: _buildPomodoroTab(state)),
                      SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: _buildShieldTab()),
                    ],
                  ),
                ),
              ],
            ),

            // Confetti
            Align(
              alignment: Alignment.center,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  AdyapanTheme.pink,
                  AdyapanTheme.purple,
                  AdyapanTheme.cyan,
                  AdyapanTheme.green,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
