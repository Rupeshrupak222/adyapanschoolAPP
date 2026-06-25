import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/app_state.dart';

class RoadmapScreen extends StatefulWidget {
  const RoadmapScreen({Key? key}) : super(key: key);

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  int _selectedSubjectIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<Map<String, dynamic>> _getNodes(AppState state, List<Map<String, dynamic>> subjects) {
    if (subjects.isEmpty) return [];
    if (_selectedSubjectIndex >= subjects.length) {
      _selectedSubjectIndex = 0;
    }
    final key = subjects[_selectedSubjectIndex]['key'];
    return state.roadmaps[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final subjects = state.getSubjectsForClass(state.studentClass);
        if (_selectedSubjectIndex >= subjects.length) {
          _selectedSubjectIndex = 0;
        }
        final nodes = _getNodes(state, subjects);
        final subject = subjects.isEmpty
            ? {
                'name': 'No Subject',
                'emoji': '📚',
                'color': const Color(0xFF64748B),
                'bgColor': const Color(0xFFF1F5F9),
                'gradient': [const Color(0xFF64748B), const Color(0xFF475569)],
                'key': 'None',
              }
            : subjects[_selectedSubjectIndex];
            
        final Color accentColor = subject['color'] as Color;
        final List<Color> gradient = subject['gradient'] as List<Color>;

        // Calculate subject-specific progress
        int completedCount = nodes.where((n) => n['status'] == 'completed').length;
        double progressPct = nodes.isEmpty ? 0 : completedCount / nodes.length;

        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          body: Column(
            children: [
              // ── HEADER ──
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
                              onPressed: () => Scaffold.of(context).openDrawer(),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                              ),
                              child: Text(
                                '⭐ Level ${state.level}  •  ${state.xp} XP',
                                style: GoogleFonts.fredoka(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Learning Roadmap',
                                style: GoogleFonts.fredoka(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Text(
                                'Your path to academic excellence 🚀',
                                style: GoogleFonts.outfit(fontSize: 12, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Subject Tab Row
                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            itemCount: subjects.length,
                            itemBuilder: (context, i) {
                              bool isSelected = _selectedSubjectIndex == i;
                              final accentColor = subjects[i]['color'] as Color;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedSubjectIndex = i),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getSubjectIcon(subjects[i]['name'] as String? ?? ''),
                                        size: 14,
                                        color: isSelected ? accentColor : Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        state.translate(subjects[i]['name'] as String),
                                        style: GoogleFonts.fredoka(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? accentColor : Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── CONTENT ──
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // ── SUBJECT PROGRESS CARD ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withOpacity(0.1),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Progress ring
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: CircularProgressIndicator(
                                      value: progressPct,
                                      strokeWidth: 6,
                                      backgroundColor: accentColor.withOpacity(0.1),
                                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                                    ),
                                  ),
                                  Text(
                                    '${(progressPct * 100).toStringAsFixed(0)}%',
                                    style: GoogleFonts.fredoka(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                      Row(
                                        children: [
                                          Icon(
                                            _getSubjectIcon(subject['name'] as String? ?? ''),
                                            size: 16,
                                            color: accentColor,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              state.translate(subject['name'] as String? ?? ''),
                                              style: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    Text(
                                      '$completedCount of ${nodes.length} topics completed',
                                      style: GoogleFonts.outfit(fontSize: 11, color: AdyapanTheme.textSub, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: progressPct,
                                        minHeight: 6,
                                        backgroundColor: accentColor.withOpacity(0.1),
                                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: subject['bgColor'],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '+${completedCount * 50} XP',
                                  style: GoogleFonts.fredoka(fontSize: 11, fontWeight: FontWeight.bold, color: accentColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── SECTION TITLE ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Text('Learning Path', style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain)),
                            const Spacer(),
                            Text('${nodes.length} topics', style: GoogleFonts.outfit(fontSize: 11, color: AdyapanTheme.textMuted, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── ZIGZAG PATH NODES ──
                      ...List.generate(nodes.length, (index) {
                        final node = nodes[index];
                        bool isCompleted = node['status'] == 'completed';
                        bool isUnlocked = node['status'] == 'unlocked';
                        bool isLocked = node['status'] == 'locked';

                        // Alternating left / right
                        bool isRight = index % 2 == 1;

                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment: isRight ? MainAxisAlignment.end : MainAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => RoadmapNodeDetailsPage(
                                            node: node,
                                            subject: subject,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 260,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isCompleted
                                            ? const Color(0xFFECFDF5)
                                            : isUnlocked
                                                ? Colors.white
                                                : const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isCompleted
                                              ? const Color(0xFF10B981).withOpacity(0.3)
                                              : isUnlocked
                                                  ? accentColor.withOpacity(0.3)
                                                  : const Color(0xFFE2E8F0),
                                          width: 1.5,
                                        ),
                                        boxShadow: isUnlocked
                                            ? [
                                                BoxShadow(
                                                  color: accentColor.withOpacity(0.12),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 4),
                                                )
                                              ]
                                            : [],
                                      ),
                                      child: Row(
                                        children: [
                                          // Node icon circle
                                          Container(
                                            width: 46,
                                            height: 46,
                                            decoration: BoxDecoration(
                                              color: isCompleted
                                                  ? const Color(0xFF10B981)
                                                  : isUnlocked
                                                      ? accentColor
                                                      : const Color(0xFFE2E8F0),
                                              shape: BoxShape.circle,
                                              boxShadow: isUnlocked
                                                  ? [
                                                      BoxShadow(
                                                        color: accentColor.withOpacity(0.35),
                                                        blurRadius: 10,
                                                        spreadRadius: 1,
                                                      )
                                                    ]
                                                  : [],
                                            ),
                                            alignment: Alignment.center,
                                            child: Icon(
                                              isCompleted
                                                  ? Icons.check_rounded
                                                  : isUnlocked
                                                      ? Icons.play_arrow_rounded
                                                      : Icons.lock_rounded,
                                              color: isLocked ? AdyapanTheme.textMuted : Colors.white,
                                              size: 22,
                                            ),
                                          ),
                                          const SizedBox(width: 12),

                                          // Node info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Step ${index + 1}',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: isLocked ? AdyapanTheme.textMuted : accentColor,
                                                    letterSpacing: 0.8,
                                                  ),
                                                ),
                                                Text(
                                                  node['title'],
                                                  style: GoogleFonts.fredoka(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: isLocked ? AdyapanTheme.textMuted : AdyapanTheme.textMain,
                                                  ),
                                                ),
                                                Text(
                                                  node['subtitle'],
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 10,
                                                    color: AdyapanTheme.textMuted,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Status badge
                                          if (isCompleted)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF10B981).withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 12),
                                            )
                                          else if (isUnlocked)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: accentColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'GO',
                                                style: GoogleFonts.fredoka(fontSize: 9, fontWeight: FontWeight.bold, color: accentColor),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Connector arrow between nodes
                            if (index < nodes.length - 1)
                              Padding(
                                padding: EdgeInsets.only(
                                  left: isRight ? 20 : 0,
                                  right: isRight ? 0 : 20,
                                ),
                                child: Align(
                                  alignment: isRight ? Alignment.centerLeft : Alignment.centerRight,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 2),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 2,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: accentColor.withOpacity(0.25),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        Icon(Icons.keyboard_arrow_down_rounded, color: accentColor.withOpacity(0.4), size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      }),
                      const SizedBox(height: 20),

                      // ── UPCOMING TOPICS TEASER ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [accentColor.withOpacity(0.07), accentColor.withOpacity(0.02)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: accentColor.withOpacity(0.15)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: Icon(Icons.explore_rounded, color: accentColor, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'More coming soon!',
                                      style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold, color: accentColor),
                                    ),
                                    Text(
                                      'Complete current path to unlock advanced topics & bonus challenges.',
                                      style: GoogleFonts.outfit(fontSize: 10, color: AdyapanTheme.textSub, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── WEEKLY TARGET CARD ──
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.track_changes_rounded, color: accentColor, size: 16),
                                  const SizedBox(width: 8),
                                  Text('This Week\'s Target', style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain)),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF7ED),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                                    ),
                                    child: Text('3 days left', style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFFD97706))),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildWeeklyTarget('Complete 1 ${state.translate(subject['name'] as String)} topic', true, accentColor),
                              const SizedBox(height: 6),
                              _buildWeeklyTarget('Play 2 Arcade games', false, accentColor),
                              const SizedBox(height: 6),
                              _buildWeeklyTarget('Log 3 study sessions', false, accentColor),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: 1 / 3,
                                  minHeight: 6,
                                  backgroundColor: accentColor.withOpacity(0.1),
                                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('1 of 3 weekly goals completed', style: GoogleFonts.outfit(fontSize: 9, color: AdyapanTheme.textMuted, fontWeight: FontWeight.w500)),
                            ],
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
      },
    );
  }

  Widget _buildWeeklyTarget(String title, bool done, Color accentColor) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: done ? accentColor : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
            border: Border.all(color: done ? accentColor : const Color(0xFFE2E8F0)),
          ),
          child: Icon(
            done ? Icons.check_rounded : Icons.circle_outlined,
            size: 10,
            color: done ? Colors.white : AdyapanTheme.textMuted,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: done ? AdyapanTheme.textMuted : AdyapanTheme.textMain,
              decoration: done ? TextDecoration.lineThrough : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// =========================================================================
//  DEDICATED VISUAL FULL-SCREEN PAGE: ROADMAP NODE DETAILS PAGE
// =========================================================================
class RoadmapNodeDetailsPage extends StatelessWidget {
  final Map<String, dynamic> node;
  final Map<String, dynamic> subject;

  const RoadmapNodeDetailsPage({
    Key? key,
    required this.node,
    required this.subject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final Color accentColor = subject['color'] as Color;
    final List<Color> gradient = subject['gradient'] as List<Color>;

    // Dynamically retrieve node state from appState so editing matches
    final subjectKey = subject['key'] as String;
    final activeNodes = state.roadmaps[subjectKey] ?? [];
    final activeNode = activeNodes.firstWhere((n) => n['id'] == node['id'], orElse: () => node);

    bool isLocked = activeNode['status'] == 'locked';
    bool isCompleted = activeNode['status'] == 'completed';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Milestone Details',
          style: GoogleFonts.fredoka(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
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
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 3D Beveled details container card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.12),
                      offset: const Offset(0, 10),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.8),
                      offset: const Offset(-4, -4),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? const Color(0xFFECFDF5)
                                : isLocked
                                    ? const Color(0xFFF1F5F9)
                                    : accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isCompleted
                                  ? const Color(0xFF10B981).withOpacity(0.3)
                                  : isLocked
                                      ? const Color(0xFFE2E8F0)
                                      : accentColor.withOpacity(0.2),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCompleted
                                    ? Icons.check_circle_rounded
                                    : isLocked
                                        ? Icons.lock_rounded
                                        : Icons.play_circle_rounded,
                                size: 14,
                                color: isCompleted
                                    ? const Color(0xFF10B981)
                                    : isLocked
                                        ? AdyapanTheme.textMuted
                                        : accentColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isCompleted
                                    ? 'COMPLETED'
                                    : isLocked
                                        ? 'LOCKED'
                                        : 'IN PROGRESS',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isCompleted
                                      ? const Color(0xFF10B981)
                                      : isLocked
                                          ? AdyapanTheme.textMuted
                                          : accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Small subject banner
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              state.translate(subject['name'] as String? ?? ''),
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF475569),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Title section with big emoji
                    Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            _getSubjectIcon(subject['name'] as String? ?? ''),
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeNode['title'] ?? 'Milestone Title',
                                style: GoogleFonts.fredoka(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AdyapanTheme.textMain,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                activeNode['subtitle'] ?? 'Sub-milestone description',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: AdyapanTheme.textSub,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFE2E8F0), height: 1),
                    const SizedBox(height: 20),

                    // XP Reward Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withOpacity(0.25),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('⭐', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '+${activeNode['xp'] ?? 75} XP Milestone Reward',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFD97706),
                                  ),
                                ),
                                Text(
                                  'Acquire knowledge and advance levels instantly!',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    color: const Color(0xFFB45309),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Description text
                    Text(
                      'MILESTONE OVERVIEW',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: AdyapanTheme.textMuted,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      activeNode['desc'] ??
                          'Explore interactive nodes, learn new concepts, and play retro games to secure your curriculum targets smoothly.',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: const Color(0xFF334155),
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (activeNode['pdfPath'] != null && activeNode['pdfPath'].toString().isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'ATTACHED SYLLABUS / STUDY MATERIAL',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: AdyapanTheme.textMuted,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red[50]!.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red[200]!.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.picture_as_pdf_rounded, color: Colors.red[700], size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activeNode['pdfName'] ?? 'Syllabus Document.pdf',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red[900],
                                    ),
                                  ),
                                  Text(
                                    'Click below to open study file',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      color: Colors.red[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('📂 Opening PDF: ${activeNode['pdfName']}'),
                                backgroundColor: Colors.red[700],
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          },
                          icon: const Icon(Icons.open_in_new_rounded, size: 14),
                          label: Text('Open Syllabus PDF', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red[700],
                            side: BorderSide(color: Colors.red[300]!),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Gained Skills List
                    Text(
                      'ACADEMIC SKILLS YOU\'LL MASTER',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: AdyapanTheme.textMuted,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['Curriculum Core', 'Critical Evaluation', 'Practical Application'].map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: accentColor.withOpacity(0.18),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.stars_rounded, size: 12, color: accentColor),
                              const SizedBox(width: 6),
                              Text(
                                skill,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: accentColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Dynamic Interactive Main Action Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLocked
                      ? null
                      : () {
                          if (!isCompleted) {
                            state.completeRoadmapNode(subjectKey, activeNode['id']);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('🎉 "${activeNode['title']}" marked complete! +${activeNode['xp'] ?? 75} XP awarded!'),
                                backgroundColor: const Color(0xFF10B981),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Already completed! Go ahead and play Arcade games to earn extra rewards.'),
                                backgroundColor: Color(0xFF10B981),
                              ),
                            );
                          }
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompleted
                        ? const Color(0xFF10B981)
                        : isLocked
                            ? const Color(0xFFCBD5E1)
                            : accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: isLocked ? 0 : 6,
                    shadowColor: accentColor.withOpacity(0.3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isCompleted
                            ? Icons.verified_rounded
                            : isLocked
                                ? Icons.lock_outline_rounded
                                : Icons.rocket_launch_rounded,
                        color: isLocked ? const Color(0xFF94A3B8) : Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isCompleted
                            ? 'Complete / Revise Pathway'
                            : isLocked
                                ? '🔒 Milestone Locked'
                                : 'Start Learning & Complete Quest',
                        style: GoogleFonts.fredoka(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isLocked ? const Color(0xFF94A3B8) : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _getSubjectIcon(String subjectName) {
  final name = subjectName.toLowerCase();
  if (name.contains('math') || name.contains('📐')) return Icons.calculate_rounded;
  if (name.contains('science') || name.contains('⚛️')) return Icons.science_rounded;
  if (name.contains('english') || name.contains('📖')) return Icons.translate_rounded;
  if (name.contains('social') || name.contains('🌍')) return Icons.public_rounded;
  if (name.contains('commerce') || name.contains('business')) return Icons.trending_up_rounded;
  if (name.contains('humanity') || name.contains('humanities')) return Icons.palette_rounded;
  return Icons.book_rounded;
}
