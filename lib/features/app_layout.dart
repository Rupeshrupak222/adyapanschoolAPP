import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_screen.dart';
import 'roadmap_screen.dart';
import 'live_classes_screen.dart';
import 'future_skills_roadmap_screen.dart';
import 'arcade_screen.dart';
import 'focus_screen.dart';
import 'parent_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'feedback_hub_screen.dart';
import 'messages_screen.dart';
import '../core/theme.dart';
import '../core/app_state.dart';

class AppLayout extends StatefulWidget {
  const AppLayout({Key? key}) : super(key: key);

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> with WidgetsBindingObserver {
  bool _shownLiveClassDialog = false;
  final List<Widget> _screens = const [
    DashboardScreen(),
    RoadmapScreen(),
    FutureSkillsRoadmapScreen(),
    ArcadeScreen(),
    FocusScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-fetch data when app comes back to foreground
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.isLoggedIn && appState.sessionVerified) {
        appState.refreshDataOnResume();
      }
    }
  }

  void _showQuickAddTaskDialog(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    final titleController = TextEditingController();
    String selectedTag = 'Math';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Create Quick Quest', 
            style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold, color: AdyapanTheme.blueAccent),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add a fast study task or chore to your daily checklist directly.',
                style: GoogleFonts.outfit(fontSize: 12, color: AdyapanTheme.textSub),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: 'e.g., Read Physics Chapter 3',
                  hintStyle: GoogleFonts.outfit(fontSize: 13, color: AdyapanTheme.textMuted),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AdyapanTheme.blueAccent, width: 2), borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedTag,
                items: ['Math', 'Science', 'Focus', 'General'].map((tag) {
                  return DropdownMenuItem(value: tag, child: Text(tag, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) selectedTag = val;
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.fredoka(color: AdyapanTheme.textSub)),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  state.addTodo(titleController.text, selectedTag);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Quick task successfully added!'), backgroundColor: AdyapanTheme.green),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AdyapanTheme.blueAccent),
              child: Text('Add Quest', style: GoogleFonts.fredoka(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }

  void _showChatbotDialog(BuildContext context) {
    final messageController = TextEditingController();
    final studentName = Provider.of<AppState>(context, listen: false).studentName;
    final firstName = studentName.isNotEmpty ? studentName.split(' ').first : 'Student';
    final List<Map<String, dynamic>> initialMessages = [
      {'sender': 'bot', 'text': 'Hello $firstName! I am Adyapan AI Assistant. How can I help you study today?'},
    ];

    showDialog(
      context: context,
      builder: (context) {
        List<Map<String, dynamic>> messages = List.from(initialMessages);
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              contentPadding: EdgeInsets.zero,
              title: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 24),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Adyapan AI',
                          style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          'Online Assistant',
                          style: GoogleFonts.outfit(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              content: Container(
                width: 320,
                height: 380,
                color: const Color(0xFFF8FAFC),
                child: Column(
                  children: [
                    // Chat Messages list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isBot = msg['sender'] == 'bot';
                          return Align(
                            alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isBot ? Colors.white : const Color(0xFF3B82F6),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: isBot ? Radius.zero : const Radius.circular(16),
                                  bottomRight: isBot ? const Radius.circular(16) : Radius.zero,
                                ),
                                border: isBot ? Border.all(color: const Color(0xFFE2E8F0)) : null,
                                boxShadow: isBot ? [const BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))] : null,
                              ),
                              child: Text(
                                msg['text'],
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: isBot ? const Color(0xFF1E293B) : Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Input bar
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: TextField(
                                controller: messageController,
                                style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF1E293B)),
                                decoration: InputDecoration(
                                  hintText: 'Ask anything...',
                                  hintStyle: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8)),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                onSubmitted: (value) {
                                  if (value.trim().isNotEmpty) {
                                    final text = value.trim();
                                    messageController.clear();
                                    setDialogState(() {
                                      messages.add({'sender': 'user', 'text': text});
                                    });
                                    // Generate delayed smart reply
                                    Future.delayed(const Duration(milliseconds: 650), () {
                                      String botReply = "That's a great question! Keep studying and you'll master it!";
                                      if (text.toLowerCase().contains('math') || text.toLowerCase().contains('homework')) {
                                        botReply = "Math is all about practice! Try playing the Quiz Arena in the Gamified tab to earn +20 XP!";
                                      } else if (text.toLowerCase().contains('xp') || text.toLowerCase().contains('level')) {
                                        botReply = "You can earn XP by completing focus sessions, homework, and roadmaps!";
                                      } else if (text.toLowerCase().contains('hello') || text.toLowerCase().contains('hi')) {
                                        botReply = "Hello! How are you doing today? Ready to learn something new?";
                                      }
                                      setDialogState(() {
                                        messages.add({'sender': 'bot', 'text': botReply});
                                      });
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Send button
                          GestureDetector(
                            onTap: () {
                              if (messageController.text.trim().isNotEmpty) {
                                final text = messageController.text.trim();
                                messageController.clear();
                                setDialogState(() {
                                  messages.add({'sender': 'user', 'text': text});
                                });
                                // Generate delayed smart reply
                                Future.delayed(const Duration(milliseconds: 650), () {
                                  String botReply = "That's a great question! Keep studying and you'll master it!";
                                  if (text.toLowerCase().contains('math') || text.toLowerCase().contains('homework')) {
                                    botReply = "Math is all about practice! Try playing the Quiz Arena in the Gamified tab to earn +20 XP!";
                                  } else if (text.toLowerCase().contains('xp') || text.toLowerCase().contains('level')) {
                                    botReply = "You can earn XP by completing focus sessions, homework, and roadmaps!";
                                  } else if (text.toLowerCase().contains('hello') || text.toLowerCase().contains('hi')) {
                                    botReply = "Hello! How are you doing today? Ready to learn something new?";
                                  }
                                  setDialogState(() {
                                    messages.add({'sender': 'bot', 'text': botReply});
                                  });
                                });
                              }
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: Color(0xFF3B82F6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.send_rounded, color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showLiveClassWarningDialog(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.live_tv_rounded, color: Colors.redAccent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  state.translate('Live Class Starting!'),
                  style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.translate("It's Student Time! Please join the class"),
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
              ),
              const SizedBox(height: 8),
              Text(
                state.translate("Your class is active now. Let's study together!"),
                style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8)),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveClassesScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                state.translate('Join Class'),
                style: GoogleFonts.fredoka(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        final state = Provider.of<AppState>(context, listen: false);
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
                    child: const Icon(Icons.help_outline_rounded, color: AdyapanTheme.blueAccent, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.translate('Help & Navigation Guide'),
                          style: GoogleFonts.fredoka(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          state.translate('Find answers and navigate Adyapan easily'),
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AdyapanTheme.textSub,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 8),

              // FAQ List
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildFaqTile(
                      state,
                      Icons.live_tv_rounded,
                      'How do I join a live classroom session?',
                      'Tap on "Today\'s Live Class" in the Quick Access grid on your main dashboard. If a session is active, tap the Join button to enter the live streaming room directly.',
                    ),
                    _buildFaqTile(
                      state,
                      Icons.map_rounded,
                      'How does the syllabus and roadmap progression work?',
                      'Head to the Academic Syllabus tab. Tap on unlocked milestone nodes to view lectures, download study guides, and take quizzes. Completing nodes earns you XP and level-ups.',
                    ),
                    _buildFaqTile(
                      state,
                      Icons.shield_rounded,
                      'What is the Focus Shield and how do I use it?',
                      'The Focus Shield blocks phone notifications to keep you distraction-free. Navigate to the Focus tab, select a Pomodoro duration, and tap play to activate it.',
                    ),
                    _buildFaqTile(
                      state,
                      Icons.family_restroom_rounded,
                      'How can my parents check my performance?',
                      'Open the side drawer and select "Parent Gate". Once unlocked with your parent passkey, they can view daily study statistics, set screen time limits, and assign quests.',
                    ),
                    _buildFaqTile(
                      state,
                      Icons.video_library_rounded,
                      'Where can I access past recorded lectures?',
                      'Go to the "Recorded Classes" library from the Quick Access grid on your dashboard. You can search, play, and rewatch any past classroom recording at your own convenience.',
                    ),
                    _buildFaqTile(
                      state,
                      Icons.assignment_rounded,
                      'How do I ask doubts or submit homework?',
                      'Use "Doubt Sessions" in Quick Access to connect with tutors. To submit homework, open the Homework tab, view assigned worksheets, and upload your answers directly.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Support Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                  label: Text(
                    state.translate('Understood, thanks!'),
                    style: GoogleFonts.fredoka(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdyapanTheme.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFaqTile(AppState state, IconData icon, String title, String answer) {
    return Card(
      color: Colors.white.withOpacity(0.9),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFEFF6FF), width: 1.5),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AdyapanTheme.blueAccent.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AdyapanTheme.blueAccent, size: 18),
          ),
          title: Text(
            state.translate(title),
            style: GoogleFonts.fredoka(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          iconColor: AdyapanTheme.blueAccent,
          collapsedIconColor: const Color(0xFF64748B),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                state.translate(answer),
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  color: const Color(0xFF475569),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageBottomSheet(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFF8FAFC).withOpacity(0.95),
                const Color(0xFFEFF6FF).withOpacity(0.95),
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
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              )
            ],
          ),
          padding: const EdgeInsets.only(top: 14, left: 24, right: 24, bottom: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                state.translate('Select Language'),
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                state.translate('Select App Language'),
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),
              _buildLanguageOptionCard(
                context: context,
                state: state,
                langCode: 'en',
                langName: 'English',
                nativeName: 'English',
                flagEmoji: '🇬🇧',
              ),
              const SizedBox(height: 12),
              _buildLanguageOptionCard(
                context: context,
                state: state,
                langCode: 'hi',
                langName: 'Hindi',
                nativeName: 'हिंदी',
                flagEmoji: '🇮🇳',
              ),
              const SizedBox(height: 12),
              _buildLanguageOptionCard(
                context: context,
                state: state,
                langCode: 'te',
                langName: 'Telugu',
                nativeName: 'తెలుగు',
                flagEmoji: '🇮🇳',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOptionCard({
    required BuildContext context,
    required AppState state,
    required String langCode,
    required String langName,
    required String nativeName,
    required String flagEmoji,
  }) {
    bool isSelected = state.selectedLanguage == langCode;
    
    return GestureDetector(
      onTap: () {
        state.changeLanguage(langCode);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${state.translate('Language')} changed to $nativeName!',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            backgroundColor: AdyapanTheme.blueAccent,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? AdyapanTheme.blueAccent.withOpacity(0.8) 
                : Colors.white.withOpacity(0.4),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AdyapanTheme.blueAccent.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected
                    ? AdyapanTheme.blueAccent.withOpacity(0.1)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(flagEmoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nativeName,
                    style: GoogleFonts.fredoka(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AdyapanTheme.blueAccent : AdyapanTheme.textMain,
                    ),
                  ),
                  Text(
                    langName,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AdyapanTheme.textSub,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AdyapanTheme.blueAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              )
            else
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String title, Color? iconColor, required VoidCallback onTap}) {
    final state = Provider.of<AppState>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: ListTile(
          leading: Icon(icon, color: iconColor ?? AdyapanTheme.blueAccent, size: 20),
          title: Text(
            state.translate(title),
            style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onTap: onTap,
          dense: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    
    if (state.isLoggedIn && state.userRole == 'student' && state.hasLiveClassNow) {
      if (!_shownLiveClassDialog) {
        _shownLiveClassDialog = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showLiveClassWarningDialog(context);
        });
      }
    } else {
      _shownLiveClassDialog = false;
    }

    final showLock = state.deviceFrozen || state.isStudyScheduleActive;
    
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (state.currentTab != 0) { state.setTab(0); return; }
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.exit_to_app_rounded, color: Color(0xFFEF4444), size: 20)),
              const SizedBox(width: 10),
              Text(state.translate('Exit Adyapan?'), style: GoogleFonts.fredoka(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
            ]),
            content: Text(state.translate('Are you sure you want to exit Adyapan?'), style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(state.translate('Cancel'), style: GoogleFonts.fredoka(color: const Color(0xFF64748B)))),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: Text(state.translate('Exit'), style: GoogleFonts.fredoka(color: Colors.white, fontWeight: FontWeight.bold))),
            ],
          ),
        );
        if (shouldExit ?? false) { if (context.mounted) SystemNavigator.pop(); }
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: AdyapanTheme.bgDark,
      // 1. Sleek Navigation Drawer (Secondary controls)
      drawer: Drawer(
        backgroundColor: Colors.transparent, // Allow glass gradient to show
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFEEF2F6).withOpacity(0.96), // Frosted glass soft lavender
                const Color(0xFFE0E7FF).withOpacity(0.96), // Frosted glass soft indigo
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Consumer<AppState>(
            builder: (context, state, child) {
              double xpProgress = (state.xp % 200) / 200.0;
              int xpInCurrentLevel = state.xp % 200;
              
              return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // A. Sleek Gradient Drawer Header (Tapping goes to Profile Screen)
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // Close side drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.only(top: 60, bottom: 24, left: 24, right: 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: ClipOval(
                                child: state.profileImagePath.isNotEmpty
                                    ? Image.file(
                                        File(state.profileImagePath),
                                        fit: BoxFit.cover,
                                        width: 50,
                                        height: 50,
                                      )
                                    : Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Color(0xFFFBBF24), Color(0xFFEA580C)],
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
                                            style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                          );
                                        }(),
                                      ),
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    state.studentName,
                                    style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    state.studentEmail,
                                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // B. Student Progress Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.65), // Translucent white glass
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Level ${state.level}',
                              style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)),
                            ),
                            Text(
                              '$xpInCurrentLevel / 200 XP',
                              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: xpProgress,
                            minHeight: 8,
                            backgroundColor: const Color(0xFFF1F5F9),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Keep crushing it! ${200 - xpInCurrentLevel} XP left to next level!',
                          style: GoogleFonts.outfit(fontSize: 9, color: AdyapanTheme.textMuted, fontWeight: FontWeight.w600),
                        )
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // C. Navigation List Items
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildDrawerItem(
                        icon: Icons.dashboard_outlined,
                        title: state.translate('Student Dashboard'),
                        onTap: () {
                          Navigator.pop(context);
                          state.setTab(0);
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.message_outlined,
                        title: state.translate('Messages'),
                        iconColor: const Color(0xFF4F46E5),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MessagesScreen()),
                          );
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.supervised_user_circle_outlined,
                        title: state.translate('Parent Portal Gate'),
                        iconColor: AdyapanTheme.purple,
                        onTap: () {
                          Navigator.pop(context); // close drawer
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ParentScreen()),
                          );
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.shield_outlined,
                        title: state.translate('Focus Shield Settings'),
                        onTap: () {
                          Navigator.pop(context);
                          state.setTab(4);
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.rate_review_rounded,
                        title: state.translate('Teacher Feedback Hub'),
                        iconColor: AdyapanTheme.green,
                        onTap: () {
                          Navigator.pop(context); // close drawer
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const FeedbackHubScreen()),
                          );
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.g_translate_rounded,
                        title: state.translate('Language'),
                        iconColor: AdyapanTheme.blueAccent,
                        onTap: () {
                          Navigator.pop(context); // close drawer
                          _showLanguageBottomSheet(context, state);
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.help_outline_rounded,
                        title: state.translate('Help & FAQ'),
                        onTap: () {
                          Navigator.pop(context);
                          _showHelpDialog(context);
                        },
                      ),
                    ],
                  ),
                ),
                
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFEFF6FF))),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 12),
                      Flexible(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context); // close drawer
                            Provider.of<AppState>(context, listen: false).logout();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          },
                          child: Text(
                            state.translate('Switch Profile / Logout'),
                            style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.redAccent),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
      body: IndexedStack(
        index: state.currentTab,
        children: _screens,
      ),
      // 2. High-floating Add Quick Quest Button (Doesn't overlap and floats nicely!)
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showChatbotDialog(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        highlightElevation: 0,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)], // Vibrant blue gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 24),
        ),
      ),
      bottomNavigationBar: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AdyapanTheme.glassBorder, width: 1.5)),
          boxShadow: [
            BoxShadow(
              color: AdyapanTheme.blueAccent.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, -4),
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Expanded(child: _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, state.translate('Home'), state)),
            Expanded(child: _buildNavItem(1, Icons.import_contacts_rounded, Icons.import_contacts_outlined, state.translate('Syllabus'), state)),
            Expanded(child: _buildNavItem(2, Icons.explore_rounded, Icons.explore_outlined, state.translate('Roadmap'), state)),
            Expanded(child: _buildNavItem(3, Icons.sports_esports_rounded, Icons.sports_esports_outlined, state.translate('Gamified'), state)),
          ],
        ),
      ),
    ),
      if (showLock)
        _buildFrozenOverlay(context, state),
    ],
  ),
);
}

  // Nav Item Builder
  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label, AppState state) {
    bool isActive = state.currentTab == index;
    Color iconColor = isActive ? AdyapanTheme.blueAccent : AdyapanTheme.textMuted;
    
    return GestureDetector(
      onTap: () {
        state.setTab(index);
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : inactiveIcon, 
              color: iconColor,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.fredoka(
                fontSize: 10, 
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: iconColor,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrozenOverlay(BuildContext context, AppState state) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.88),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PulseWarningIcon(),
                    const SizedBox(height: 28),
                    Text(
                      state.translate('Focus Shield Active 🛡️'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.translate('Your parents have locked this device to ensure focused studying. Notifications from WhatsApp, Instagram, and other social alerts are currently blocked.'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.75),
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 48),
                    ElevatedButton.icon(
                      onPressed: () => _showParentBypassDialog(context, state),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdyapanTheme.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 4,
                        shadowColor: AdyapanTheme.purple.withOpacity(0.4),
                      ),
                      icon: const Icon(Icons.lock_open_rounded, size: 18),
                      label: Text(
                        state.translate('Parent Unlock'),
                        style: GoogleFonts.fredoka(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showParentBypassDialog(BuildContext context, AppState state) {
    final List<String> digits = ['', '', '', ''];
    int cursor = 0;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            void verify() {
              if (digits.join() == state.parentPin) {
                // Unfreeze device and disable any active timetables temporarily
                state.setDeviceFrozen(false);
                for (final schedule in state.studySchedules) {
                  if (schedule['active'] == true) {
                    state.toggleStudySchedule(schedule['id'] as String);
                  }
                }
                
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                    state.translate('📱 Device unlocked. Focus Shield deactivated.'),
                    style: GoogleFonts.fredoka(color: Colors.white, fontSize: 13),
                  ),
                  backgroundColor: AdyapanTheme.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ));
              } else {
                HapticFeedback.vibrate();
                setDialogState(() {
                  for (int i = 0; i < 4; i++) {
                    digits[i] = '';
                  }
                  cursor = 0;
                });
                ScaffoldMessenger.of(dialogCtx).showSnackBar(const SnackBar(
                  content: Text('Incorrect PIN! Try again.'),
                  backgroundColor: Colors.redAccent,
                  duration: Duration(seconds: 1),
                ));
              }
            }
            
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Center(
                child: Text(
                  state.translate('Parent Verification'),
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AdyapanTheme.purple,
                  ),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.translate('Enter your 4-digit PIN to bypass focus lock'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 12, color: AdyapanTheme.textSub),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      final filled = i < cursor;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled ? AdyapanTheme.purple : Colors.transparent,
                          border: Border.all(
                            color: filled ? AdyapanTheme.purple : const Color(0xFFCBD5E1),
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  _buildDialogNumpad(
                    onDigit: (digit) {
                      if (cursor < 4) {
                        setDialogState(() {
                          digits[cursor] = digit;
                          cursor++;
                          if (cursor == 4) {
                            verify();
                          }
                        });
                      }
                    },
                    onBackspace: () {
                      if (cursor > 0) {
                        setDialogState(() {
                          cursor--;
                          digits[cursor] = '';
                        });
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDialogNumpad({required Function(String) onDigit, required VoidCallback onBackspace}) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((k) {
              if (k.isEmpty) {
                return const SizedBox(width: 48, height: 40);
              }
              return GestureDetector(
                onTap: () {
                  if (k == '⌫') {
                    onBackspace();
                  } else {
                    onDigit(k);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 48,
                  height: 40,
                  decoration: BoxDecoration(
                    color: k == '⌫' ? const Color(0xFFF1F5F9) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  alignment: Alignment.center,
                  child: k == '⌫'
                      ? const Icon(Icons.backspace_outlined, color: AdyapanTheme.textSub, size: 16)
                      : Text(
                          k,
                          style: GoogleFonts.fredoka(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AdyapanTheme.textMain,
                          ),
                        ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _PulseWarningIcon extends StatefulWidget {
  @override
  State<_PulseWarningIcon> createState() => _PulseWarningIconState();
}

class _PulseWarningIconState extends State<_PulseWarningIcon> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, child) {
        return Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.redAccent.withOpacity(0.1 + (0.15 * _ctrl.value)),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withOpacity(0.2 * _ctrl.value),
                blurRadius: 15 + (15 * _ctrl.value),
                spreadRadius: 2 + (6 * _ctrl.value),
              )
            ],
          ),
          child: const Center(
            child: Icon(Icons.shield_rounded, color: Colors.redAccent, size: 44),
          ),
        );
      },
    );
  }
}
