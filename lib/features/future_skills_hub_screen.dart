import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/app_state.dart';
import 'future_skills_detail_screen.dart';

class FutureSkillsHubScreen extends StatefulWidget {
  const FutureSkillsHubScreen({Key? key}) : super(key: key);

  @override
  State<FutureSkillsHubScreen> createState() => _FutureSkillsHubScreenState();
}

class _FutureSkillsHubScreenState extends State<FutureSkillsHubScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Tech & Code'; // 'Tech & Code', 'Speech & MUN', 'Academics', 'Habits & Life'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Group skill lists by dynamic category tag
  String _getSkillCategory(String title) {
    final t = title.toLowerCase();
    if (t.contains('coding') || t.contains('python') || t.contains('sql') || t.contains('html') || t.contains('digital') || t.contains('ai tools') || t.contains('editing')) {
      return 'Tech & Code';
    }
    if (t.contains('speaking') || t.contains('speech') || t.contains('extempore') || t.contains('spell bee') || t.contains('language') || t.contains('communication')) {
      return 'Speech & MUN';
    }
    if (t.contains('olympiad') || t.contains('counseling') || t.contains('course') || t.contains('office') || t.contains('readiness') || t.contains('excel')) {
      return 'Academics';
    }
    return 'Habits & Life';
  }

  String _getLiveScheduleStatus(String skillTitle) {
    final t = skillTitle.toLowerCase();
    if (t.contains('html') || t.contains('web')) {
      return 'LIVE NOW';
    }
    if (t.contains('debate') || t.contains('mun') || t.contains('speaking') || t.contains('speech') || t.contains('extempore')) {
      return 'Live Lab: Fri 3:00 PM';
    }
    if (t.contains('finance') || t.contains('budget') || t.contains('literacy')) {
      return 'Live Lab: Thu 4:00 PM';
    }
    if (t.contains('excel') || t.contains('office')) {
      return 'Live Lab: Sat 11:00 AM';
    }
    return 'Live Lab: Scheduled Weekly';
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final allSkills = state.getSkillsForClass(state.studentClass);

    // Apply search and category filtering
    final filteredSkills = allSkills.where((skill) {
      final title = (skill['title'] as String? ?? '').toLowerCase();
      final desc = (skill['desc'] as String? ?? '').toLowerCase();
      final modules = (skill['modules'] as List? ?? []).join(' ').toLowerCase();
      final matchesSearch = title.contains(_searchQuery) || desc.contains(_searchQuery) || modules.contains(_searchQuery);

      if (_selectedCategory == 'All') {
        return matchesSearch;
      }
      return matchesSearch && _getSkillCategory(skill['title'] as String? ?? '') == _selectedCategory;
    }).toList();

    return Scaffold(
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
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ─── Custom Premium Glass AppBar ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withOpacity(0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: const Color(0xFF1E3A8A), size: 16),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.translate('Future Skills Hub'),
                            style: GoogleFonts.fredoka(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E3A8A),
                            ),
                          ),
                          Text(
                            'Premium 21st-century superpower portfolio',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: const Color(0xFF1E3A8A).withOpacity(0.65),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Glass Badge showing dynamic points
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.25), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          const Text('⚡ ', style: TextStyle(fontSize: 12)),
                          Text(
                            '${state.xp} XP',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Top Dynamic Mesh Banner with Glassmorphic Stats ───
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.22),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
                                ),
                                child: Text(
                                  'FUTURE LEADER PORTFOLIO',
                                  style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                state.translate('Supercharge Your Future!'),
                                style: GoogleFonts.fredoka(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                state.translate('Learn practical, industry-standard skills tailored specifically for your academic level.'),
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Floating dynamic stats bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildMiniStat('Streak', '${state.streak} Days'),
                          Container(width: 1, height: 16, color: Colors.white.withOpacity(0.25)),
                          _buildMiniStat('Level', 'Lvl ${state.level}'),
                          Container(width: 1, height: 16, color: Colors.white.withOpacity(0.25)),
                          _buildMiniStat('Quizzes', '${state.completedQuizzesCount} Done'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Search Bar ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim().toLowerCase();
                      });
                    },
                    style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF1E3A8A), fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: state.translate('Search skills e.g., coding, spelling, debate...'),
                      hintStyle: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2563EB), size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8), size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),

              // ─── Premium Filter Tags ───
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    {'tag': 'Tech & Code', 'icon': Icons.code_rounded, 'gradient': [const Color(0xFF10B981), const Color(0xFF059669)]},
                    {'tag': 'Speech & MUN', 'icon': Icons.mic_external_on_rounded, 'gradient': [const Color(0xFFEC4899), const Color(0xFFDB2777)]},
                    {'tag': 'Academics', 'icon': Icons.school_rounded, 'gradient': [const Color(0xFF6366F1), const Color(0xFF4F46E5)]},
                    {'tag': 'Habits & Life', 'icon': Icons.eco_rounded, 'gradient': [const Color(0xFFF59E0B), const Color(0xFFD97706)]},
                  ].map((catObj) {
                    final cat = catObj['tag'] as String;
                    final icon = catObj['icon'] as IconData;
                    final gradColors = catObj['gradient'] as List<Color>;
                    final isSelected = _selectedCategory == cat;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: gradColors,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : const LinearGradient(
                                  colors: [Colors.white, Colors.white],
                                ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : const Color(0xFF93C5FD).withOpacity(0.3),
                            width: 1.2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: gradColors[0].withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  )
                                ],
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          children: [
                            Icon(icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF475569)),
                            const SizedBox(width: 6),
                            Text(
                              state.translate(cat),
                              style: GoogleFonts.fredoka(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 6),

              // ─── Skills Grid List ───
              Expanded(
                child: filteredSkills.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF93C5FD).withOpacity(0.3)),
                              ),
                              child: const Icon(Icons.menu_book_rounded, size: 40, color: Color(0xFF3B82F6)),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              state.translate('No Matching Skills Found'),
                              style: GoogleFonts.fredoka(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E3A8A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              state.translate('Try adjusting your search query or filter tags.'),
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        itemCount: filteredSkills.length,
                        itemBuilder: (context, idx) {
                          final skill = filteredSkills[idx];
                          final emoji = skill['emoji'] as String? ?? '📚';
                          final title = skill['title'] as String? ?? '';
                          final desc = skill['desc'] as String? ?? '';
                          final modules = skill['modules'] as List? ?? [];
                          final catName = _getSkillCategory(title);

                          // Colorful accents based on category
                          final List<Color> accents = catName == 'Tech & Code'
                              ? [const Color(0xFF10B981), const Color(0xFF059669)]
                              : catName == 'Speech & MUN'
                                  ? [const Color(0xFFEC4899), const Color(0xFFDB2777)]
                                  : catName == 'Academics'
                                      ? [const Color(0xFF6366F1), const Color(0xFF4F46E5)]
                                      : [const Color(0xFFF59E0B), const Color(0xFFD97706)];
                          final accentColor = accents[0];

                          // Interactive mock progress based on index for gamey look
                          final progress = idx == 0 ? 0.75 : idx == 1 ? 0.40 : idx == 2 ? 0.15 : 0.0;
                          final progressText = idx == 0 ? '75% Done' : idx == 1 ? '40% Done' : idx == 2 ? '15% Done' : 'Not Started';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: accentColor.withOpacity(0.18), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
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
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
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
                                  child: Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Skill Icon Circle
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color: accentColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(18),
                                            border: Border.all(color: accentColor.withOpacity(0.2), width: 1.2),
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(
                                            _getSkillIcon(title),
                                            color: accentColor,
                                            size: 26,
                                          ),
                                        ),
                                        const SizedBox(width: 16),

                                        // Text Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: accentColor.withOpacity(0.12),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      state.translate(catName).toUpperCase(),
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 8.5,
                                                        fontWeight: FontWeight.bold,
                                                        color: accentColor,
                                                      ),
                                                    ),
                                                  ),
                                                  // Dynamic reward badge
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFFEF3C7),
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: const Color(0xFFFCD34D).withOpacity(0.5)),
                                                    ),
                                                    child: Text(
                                                      '+100 XP',
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 8.5,
                                                        fontWeight: FontWeight.bold,
                                                        color: const Color(0xFFB45309),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                state.translate(title),
                                                style: GoogleFonts.fredoka(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF1E3A8A),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              
                                              // Dynamic Schedule / Pulsing Live Badge
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 6,
                                                    height: 6,
                                                    decoration: BoxDecoration(
                                                      color: title.toLowerCase().contains('html') || title.toLowerCase().contains('web') ? Colors.red : Colors.green,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Flexible(
                                                    child: Text(
                                                      state.translate(_getLiveScheduleStatus(title)),
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 9.5,
                                                        fontWeight: FontWeight.bold,
                                                        color: title.toLowerCase().contains('html') || title.toLowerCase().contains('web') ? Colors.red : const Color(0xFF16A34A),
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              
                                              Text(
                                                state.translate(desc),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 11.5,
                                                  color: AdyapanTheme.textSub,
                                                  height: 1.4,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 14),

                                              // Sleek Mini Progress Bar
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: LinearProgressIndicator(
                                                        value: progress,
                                                        minHeight: 5,
                                                        backgroundColor: const Color(0xFFE2E8F0),
                                                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    progressText,
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                      color: accentColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 14),

                                              // Action row
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(Icons.play_circle_fill_rounded, color: accentColor, size: 14),
                                                      const SizedBox(width: 5),
                                                      Text(
                                                        progress > 0 ? state.translate('Continue Study') : state.translate('Start Learning'),
                                                        style: GoogleFonts.fredoka(
                                                          fontSize: 11,
                                                          color: accentColor,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        '${modules.length} modules',
                                                        style: GoogleFonts.outfit(
                                                          fontSize: 10,
                                                          color: const Color(0xFF94A3B8),
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF94A3B8), size: 10),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.fredoka(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
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
