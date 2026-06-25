import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/app_state.dart';
import 'future_skills_detail_screen.dart';

class FutureSkillsRoadmapScreen extends StatefulWidget {
  const FutureSkillsRoadmapScreen({Key? key}) : super(key: key);

  @override
  State<FutureSkillsRoadmapScreen> createState() => _FutureSkillsRoadmapScreenState();
}

class _FutureSkillsRoadmapScreenState extends State<FutureSkillsRoadmapScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final allSkills = state.getSkillsForClass(state.studentClass);
        
        // Calculate dynamic progress
        int totalSkills = allSkills.length;
        // In this prototype, we simulate that the first 2 skills are unlocked/in-progress and the first 1 is fully completed.
        int completedSkills = totalSkills > 1 ? 1 : 0;
        double overallProgress = totalSkills == 0 ? 0 : completedSkills / totalSkills;

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A), // Premium Dark Midnight Slate
          body: Column(
            children: [
              // --- PREMIUM GLASS HEADER ---
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF312E81), Color(0xFF1E1B4B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
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
                        // Top row with Menu and stats
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
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.white.withOpacity(0.15)),
                              ),
                              child: Text(
                                'Level ${state.level}  •  ${state.xp} XP',
                                style: GoogleFonts.fredoka(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Future Skills Pathway',
                                style: GoogleFonts.fredoka(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Your customized career readiness timeline',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.85),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // --- ROADMAP PATHWAY ---
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // --- OVERALL METRICS CARD ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06), // Frosted glass translucent
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 58,
                                    height: 58,
                                    child: CircularProgressIndicator(
                                      value: overallProgress,
                                      strokeWidth: 5.5,
                                      backgroundColor: Colors.white.withOpacity(0.08),
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF818CF8)),
                                    ),
                                  ),
                                  Text(
                                    '${(overallProgress * 100).toStringAsFixed(0)}%',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF818CF8),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pathway Progression',
                                      style: GoogleFonts.fredoka(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$completedSkills of $totalSkills superpower skills mastered',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        color: const Color(0xFF94A3B8),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF312E81),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '+${completedSkills * 100} XP',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF818CF8),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // --- TIMELINE HEADER ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Career Skills Timeline',
                            style: GoogleFonts.fredoka(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // --- DYNAMIC TIMELINE PATHWAY ---
                      if (totalSkills == 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              'No Future Skills assigned yet.',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: totalSkills,
                            itemBuilder: (context, index) {
                              final skill = allSkills[index];
                              final title = skill['title'] as String? ?? '';
                              final desc = skill['desc'] as String? ?? '';
                              
                              final bool isCompleted = index < completedSkills;
                              final bool isUnlocked = index == completedSkills;
                              final bool isLocked = index > completedSkills;

                              final Color themeColor = index % 3 == 0 
                                  ? const Color(0xFF818CF8) 
                                  : index % 3 == 1 
                                      ? const Color(0xFF34D399) 
                                      : const Color(0xFFFBBF24);

                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Timeline Indicator Left Bar
                                    Column(
                                      children: [
                                        // Top line connector
                                        Container(
                                          width: 3,
                                          height: 10,
                                          color: index == 0 ? Colors.transparent : themeColor.withOpacity(isCompleted ? 0.8 : 0.3),
                                        ),
                                        // Circular node indicator
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: isCompleted
                                                ? const Color(0xFF10B981)
                                                : isUnlocked
                                                    ? themeColor
                                                    : const Color(0xFF334155),
                                            shape: BoxShape.circle,
                                            boxShadow: isUnlocked
                                                ? [
                                                    BoxShadow(
                                                      color: themeColor.withOpacity(0.4),
                                                      blurRadius: 10,
                                                      spreadRadius: 2,
                                                    )
                                                  ]
                                                : [],
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(
                                            isCompleted
                                                ? Icons.check_rounded
                                                : isUnlocked
                                                    ? Icons.explore_rounded
                                                    : Icons.lock_rounded,
                                            color: isLocked ? const Color(0xFF94A3B8) : Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                        // Bottom line connector
                                        Expanded(
                                          child: Container(
                                            width: 3,
                                            color: index == totalSkills - 1 
                                                ? Colors.transparent 
                                                : themeColor.withOpacity(isCompleted ? 0.8 : 0.3),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    
                                    // Skill details Card
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 20),
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => FutureSkillsDetailScreen(
                                                  skill: skill,
                                                  state: state,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: isCompleted
                                                  ? const Color(0xFF065F46).withOpacity(0.25)
                                                  : isUnlocked
                                                      ? Colors.white.withOpacity(0.08)
                                                      : Colors.white.withOpacity(0.02),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: isCompleted
                                                    ? const Color(0xFF059669).withOpacity(0.4)
                                                    : isUnlocked
                                                        ? themeColor.withOpacity(0.5)
                                                        : Colors.white.withOpacity(0.04),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Step ${index + 1}',
                                                        style: GoogleFonts.outfit(
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.bold,
                                                          color: isLocked ? const Color(0xFF64748B) : themeColor,
                                                          letterSpacing: 0.8,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        title,
                                                        style: GoogleFonts.fredoka(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.bold,
                                                          color: isLocked ? const Color(0xFF94A3B8) : Colors.white,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        desc,
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: GoogleFonts.outfit(
                                                          fontSize: 10.5,
                                                          color: const Color(0xFF94A3B8),
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                // CTA status action text
                                                if (isUnlocked)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: themeColor.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      'START',
                                                      style: GoogleFonts.fredoka(
                                                        fontSize: 8.5,
                                                        fontWeight: FontWeight.bold,
                                                        color: themeColor,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 40),
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
}
