import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';

class TeacherFutureSkillsPlannerScreen extends StatefulWidget {
  const TeacherFutureSkillsPlannerScreen({Key? key}) : super(key: key);

  @override
  State<TeacherFutureSkillsPlannerScreen> createState() => _TeacherFutureSkillsPlannerScreenState();
}

class _TeacherFutureSkillsPlannerScreenState extends State<TeacherFutureSkillsPlannerScreen> {
  String _selectedClass = 'Class 6';

  // Helper HSL-harmonious color palettes
  Color getAccentColor(String title) {
    final colors = [
      const Color(0xFF1E3A8A), // Slate Navy Blue
      const Color(0xFF2563EB), // Royal Blue
    ];
    return colors[title.length % colors.length];
  }

  // Pre-configured Classroom Lesson Guides that are Class-Level Specific
  Map<String, dynamic> _getClassroomLessonGuide(String moduleTitle, String selectedClass) {
    final cleanTitle = moduleTitle.toLowerCase();
    final int classNum = int.tryParse(selectedClass.replaceAll(RegExp(r'[^0-9]'), '')) ?? 6;

    if (classNum <= 5) {
      // Primary School level lessons (Class 1-5): Playful, visual, basic spelling/phonetics, simple puzzles, basic habits
      if (cleanTitle.contains('spelling') || cleanTitle.contains('word') || cleanTitle.contains('roots') || cleanTitle.contains('phonetic') || cleanTitle.contains('speech') || cleanTitle.contains('tell') || cleanTitle.contains('story')) {
        return {
          'objective': 'Develop foundational phonics, pronounciation, and simple word spelling expression.',
          'icebreaker': 'Phonics Train: Make a train sound "Chugga Chugga!" and ask each student to call out a simple word starting with the letter "S" when you point to them.',
          'teachingTip': 'Draw a big tree on the board. Put base letters (e.g. "a", "t") in the trunk and let children draw leaf letters (e.g. "c", "b", "h") to build simple words like "cat", "bat", "hat".',
          'activity': 'Show & Tell Parade: Invite 3 students to choose any item from their pencil box (e.g. eraser, colored pencil) and tell the class three simple lines about it.',
          'mcq': {
            'question': 'Which of these three animal words has the short "/a/" sound like in the word "Apple"?',
            'options': ['C-A-T (Cat)', 'B-E-E (Bee)', 'D-O-G (Dog)'],
            'answerIndex': 0,
            'rationale': 'The word "Cat" has the short "/a/" sound, sounding exactly like the beginning of "Apple"!'
          }
        };
      } else if (cleanTitle.contains('math') || cleanTitle.contains('puzzle') || cleanTitle.contains('riddle') || cleanTitle.contains('habit')) {
        return {
          'objective': 'Master basic visual patterns, logical shape sorting, and daily hygiene habits.',
          'icebreaker': 'Clap & Repeat: Clap a rhythmic sequence and challenge the class to clap it back together. Speeds up classroom focus instantly!',
          'teachingTip': 'Draw a visual repeating pattern on the board: Red Circle, Blue Star, Red Circle, Blue Star. Ask children to shout out what shape should be drawn next.',
          'activity': 'The Healthy Habit Mimic: Play a game where students mimic the physical actions of brushing teeth, washing hands, and sleeping early as a fun physical break.',
          'mcq': {
            'question': 'What is the next number in this counting pattern: 2, 4, 6, 8, ___?',
            'options': ['9', '10', '12'],
            'answerIndex': 1,
            'rationale': 'We are skipping by 2 every time! So, 8 + 2 equals 10.'
          }
        };
      } else {
        return {
          'objective': 'Foster high classroom curiosity, school pride, and basic classroom decorum.',
          'icebreaker': 'Animal Guessing Game: Make an animal sound (like a lion or frog) and have the children raise their hands to guess the animal.',
          'teachingTip': 'Keep drawings on the board large, colorful, and accompanied by happy faces to maintain young child engagement.',
          'activity': 'Pass the Smile: Gently toss a soft ball. Whoever catches it shares one simple thing they love about their school, then passes it on.',
          'mcq': {
            'question': 'Which of these is a great way to greet your teacher in the morning?',
            'options': ['Saying "Good Morning, Teacher!" with a smile', 'Shouting loudly and running away', 'Ignoring the teacher'],
            'answerIndex': 0,
            'rationale': 'Greeting with a polite voice and a happy smile spreads kindness and starts the school day wonderfully!'
          }
        };
      }
    } else if (classNum <= 8) {
      // Middle School (Class 6-8): Practical applications, financial basics, introduction to code, public speaking
      if (cleanTitle.contains('spelling') || cleanTitle.contains('word') || cleanTitle.contains('speech') || cleanTitle.contains('communication') || cleanTitle.contains('public') || cleanTitle.contains('speaking')) {
        return {
          'objective': 'Master impromptu expression, voice projection, and foundational debate formats like MUN.',
          'icebreaker': 'Vocal Warmups: Have the class hum in a low pitch for 10 seconds, then transition to a high pitch to wake up vocal muscles.',
          'teachingTip': 'Write the OREO outline on the board: Opinion -> Reason -> Example -> Opinion restated. Keep this formula visible throughout the class.',
          'activity': 'The 45-Second Hat: Write simple topics on pieces of paper (e.g. "Summer vs Winter"). Have students draw a topic and speak immediately using OREO.',
          'mcq': {
            'question': 'What is the absolute best way to start an introductory speech to capture attention?',
            'options': [
              'Saying "My name is Raj and my topic today is..."',
              'Starting with a shocking fact, a deep question, or a short storytelling hook',
              'Coughing and reading directly from a piece of paper'
            ],
            'answerIndex': 1,
            'rationale': 'An opening hook is vital to make your audience look up and listen. Avoid generic introductions.'
          }
        };
      } else if (cleanTitle.contains('code') || cleanTitle.contains('coding') || cleanTitle.contains('html') || cleanTitle.contains('tech') || cleanTitle.contains('digital')) {
        return {
          'objective': 'Learn basic HTML layout structure, computational algorithms, and digital security.',
          'icebreaker': 'The Human Loop: Designate one student as the Loop Counter. Tell the class to clap, and have the counter count to 5 before shouting "Stop!".',
          'teachingTip': 'Draw an HTML skeletal model on the blackboard. Color-code the <html>, <head>, and <body> tags so structural nesting is obvious.',
          'activity': 'Draw a Website: Have students design their dream game page on paper, labeling where the <h1> heading and the <img> tags would sit.',
          'mcq': {
            'question': 'Which HTML tag is specifically used to create the main heading of a web page?',
            'options': ['<paragraph>', '<h1>', '<head>'],
            'answerIndex': 1,
            'rationale': '<h1> stands for Heading 1, which represents the primary, largest title on a web page.'
          }
        };
      } else if (cleanTitle.contains('math') || cleanTitle.contains('puzzle') || cleanTitle.contains('riddle') || cleanTitle.contains('finance') || cleanTitle.contains('budget')) {
        return {
          'objective': 'Understand elementary budget balancing, personal savings, and logic patterns.',
          'icebreaker': 'The Pocket Money Question: Ask the class if they would spend \$5 on a snack today or save it to get a \$15 board game in three weeks.',
          'teachingTip': 'Draw two columns on the blackboard: "NEEDS" (essential) vs "WANTS" (optional). List common student expenses and have them categorize.',
          'activity': 'Classroom Budget Run: Give student pairs a virtual pocket money budget of \$50. Ask them to build a list of 5 school items, staying under budget.',
          'mcq': {
            'question': 'If you earn \$20 and want to follow the basic 50-30-20 savings rule, how much should go directly to savings (20%)?',
            'options': ['\$2', '\$4', '\$10'],
            'answerIndex': 1,
            'rationale': '20% of \$20 is calculated as (20/100) * 20, which equals exactly \$4.'
          }
        };
      } else {
        return {
          'objective': 'Foster high-order problem solving, digital marketing awareness, and active research skills.',
          'icebreaker': 'The Reverse Quiz: Give the class an answer like "Internet" and ask students to raise hands and create the question.',
          'teachingTip': 'Explain complicated terms by drawing real-world analogies (e.g. compare computer RAM to a student\'s desk space).',
          'activity': 'Idea Pitch: Divide the class into teams. Ask them to invent a school pen with one superpower and pitch it to the class in 1 minute.',
          'mcq': {
            'question': 'When searching for reliable academic information on the internet, which source is generally the most trustworthy?',
            'options': [
              'A random post on a social media forum',
              'A website ending in ".edu" or ".gov" belonging to a university or government agency',
              'A blog post with no author listed'
            ],
            'answerIndex': 1,
            'rationale': '.edu and .gov domains are vetted institutional sources, whereas personal blogs or social media have no scientific review.'
          }
        };
      }
    } else {
      // High School & Senior (Class 9-12): Advanced career prep, AI prompt engineering, advanced programming, advanced corporate finance, counselor guidelines
      if (cleanTitle.contains('spelling') || cleanTitle.contains('word') || cleanTitle.contains('speech') || cleanTitle.contains('extempore') || cleanTitle.contains('impromptu') || cleanTitle.contains('counselling') || cleanTitle.contains('counsel')) {
        return {
          'objective': 'Develop senior-level career alignment, advanced persuasive speaking, and high-pressure interview skills.',
          'icebreaker': 'The 5-Second Pitch: Give students 5 seconds to pitch "Water" as if they are selling a premium designer energy drink.',
          'teachingTip': 'Outline advanced interview rhetoric on the board: Hook -> Credibility -> Value Proposition -> Clear Call to Action (CTA).',
          'activity': 'Rapid Extempore: Give students high-level subjects (e.g., "AI replacing jobs vs creating options"). Challenge them to argue both sides in 60 seconds.',
          'mcq': {
            'question': 'In high-stakes university interviews, what is the best strategy to answer a complex question you do not know the answer to?',
            'options': [
              'Make up a completely false fact to sound highly intelligent',
              'Acknowledge the question, explain your logical path of thinking out loud, and express eagerness to learn',
              'Stay completely silent and refuse to speak'
            ],
            'answerIndex': 1,
            'rationale': 'Interviewers value cognitive honesty, logical problem-solving frameworks, and learning agility over memorized facts.'
          }
        };
      } else if (cleanTitle.contains('code') || cleanTitle.contains('coding') || cleanTitle.contains('python') || cleanTitle.contains('sql') || cleanTitle.contains('ai') || cleanTitle.contains('prompt')) {
        return {
          'objective': 'Understand AI prompts, script variables, SQL database querying, and code algorithms.',
          'icebreaker': 'The AI Simulator: Give a student a vague instruction like "Draw a shape". Point out how vague inputs generate bad outputs (Prompt Engineering).',
          'teachingTip': 'Write a Python snippet with syntax bugs on the blackboard. Let the class collaborate live to identify and resolve the bugs.',
          'activity': 'Prompt Engineering Battle: Write a target image description on the board. Challenge students to draft the most descriptive 3-line text prompt to achieve it.',
          'mcq': {
            'question': 'Which of the following describes the core goal of "Prompt Engineering" in AI?',
            'options': [
              'Writing database scripts to backup servers',
              'Crafting highly structured, descriptive inputs to get the most accurate and high-quality outputs from AI models',
              'Assembling physical hardware inside a CPU case'
            ],
            'answerIndex': 1,
            'rationale': 'AI models require contextual parameters. Prompt engineering optimizes instructions to yield optimal outputs.'
          }
        };
      } else if (cleanTitle.contains('math') || cleanTitle.contains('puzzle') || cleanTitle.contains('finance') || cleanTitle.contains('budget') || cleanTitle.contains('investment') || cleanTitle.contains('company')) {
        return {
          'objective': 'Analyze corporate balance sheets, investment compounding curves, and stock valuations.',
          'icebreaker': 'The Compounding Question: Ask students if they would take \$1,000,000 cash or a penny that doubles daily for 30 days. Explain that the doubling penny yields \$5.3 Million!',
          'teachingTip': 'Draw an exponential compounding curve on the board next to a flat simple interest line. Show how time is the major compounding multiplier.',
          'activity': 'Corporate Valuation Run: Give student teams a virtual startup with \$100k revenue and \$80k expenses. Challenge them to compute profit margin and pitch a growth investment.',
          'mcq': {
            'question': 'If a company has high Revenue (\$10 Million) but a negative Net Profit, what does this indicate?',
            'options': [
              'The company has zero sales',
              'The operating, tax, and manufacturing expenses exceed their sales revenue',
              'The company is highly profitable and safe'
            ],
            'answerIndex': 1,
            'rationale': 'Net Profit equals Revenue minus all Expenses. High sales but high costs can lead to an operating loss.'
          }
        };
      } else {
        return {
          'objective': 'Synthesize exam readiness strategies, JEE/NEET timing hacks, and general global awareness.',
          'icebreaker': 'The Time Block: Give students a virtual day. Ask them how they would split 24 hours between sleep, school, self-study, and rest.',
          'teachingTip': 'Teach the Pomodoro technique and active recall cycles. Draw a curve of forgetting to illustrate why reviews are crucial.',
          'activity': 'Mock Strategy Planner: Challenge students to design a 3-hour exam time allocation map, budgeting for revision runs and tough questions.',
          'mcq': {
            'question': 'According to cognitive learning science, which method achieves the absolute highest active retention before exams?',
            'options': [
              'Re-reading the textbook chapter highlighting lines over and over',
              'Active recall (quizzing yourself, practicing flashcards, and teaching concepts to peers without looking)',
              'Studying all night with zero hours of sleep'
            ],
            'answerIndex': 1,
            'rationale': 'Active recall triggers neural pathway consolidation, forcing the brain to retrieve information. Passive reading is a low-retention habit.'
          }
        };
      }
    }
  }

  void _openSyllabusEditor(BuildContext context, String skillTitle) {
    final state = Provider.of<AppState>(context, listen: false);
    final currentSyllabus = state.getSkillSyllabus(_selectedClass, skillTitle);
    
    // Ensure we have exactly 5 elements
    final List<String> paddedSyllabus = List.filled(5, '');
    for (int i = 0; i < 5; i++) {
      if (i < currentSyllabus.length) {
        paddedSyllabus[i] = currentSyllabus[i];
      }
    }

    final controllers = List.generate(5, (i) {
      // Strip out the prefix "Chapter X: ", "Interactive Practice: ", "Practical Lab: " to make it clean to edit!
      String rawText = paddedSyllabus[i];
      if (rawText.startsWith(RegExp(r'Chapter \d+:'))) {
        rawText = rawText.split(':').sublist(1).join(':').trim();
      } else if (rawText.startsWith('Interactive Practice:')) {
        rawText = rawText.replaceAll('Interactive Practice:', '').trim();
      } else if (rawText.startsWith('Practical Lab:')) {
        rawText = rawText.replaceAll('Practical Lab:', '').trim();
      } else if (rawText.startsWith('Project:')) {
        rawText = rawText.replaceAll('Project:', '').trim();
      }
      return TextEditingController(text: rawText);
    });

    final accentColor = getAccentColor(skillTitle);
    final int classNum = int.tryParse(_selectedClass.replaceAll(RegExp(r'[^0-9]'), '')) ?? 6;
    final finalChapterPrefix = classNum < 6 ? "Interactive Practice" : "Practical Lab";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Indicator
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.edit_note_rounded, color: accentColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CURRICULUM EDITOR • $_selectedClass',
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          'Edit $skillTitle Syllabus',
                          style: GoogleFonts.fredoka(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(ctx),
                  )
                ],
              ),
              const Divider(height: 24, color: Color(0xFFF1F5F9)),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: List.generate(5, (index) {
                      final isLast = index == 4;
                      final label = isLast
                          ? finalChapterPrefix
                          : "Chapter ${index + 1} Topic";
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: controllers[index],
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: const Color(0xFF1E293B),
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter topic details...',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: accentColor, width: 2),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    // Collect texts and append the prefix back
                    final List<String> updatedSyllabus = [];
                    for (int i = 0; i < 5; i++) {
                      final text = controllers[i].text.trim();
                      if (text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '❌ Please fill in all syllabus fields before saving.',
                              style: GoogleFonts.fredoka(color: Colors.white, fontSize: 13),
                            ),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        );
                        return;
                      }
                      if (i < 4) {
                        updatedSyllabus.add("Chapter ${i + 1}: $text");
                      } else {
                        updatedSyllabus.add("$finalChapterPrefix: $text");
                      }
                    }

                    // Save to State
                    state.updateSkillSyllabus(_selectedClass, skillTitle, updatedSyllabus);

                    Navigator.pop(ctx); // Close editor
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '✅ $skillTitle syllabus updated successfully for $_selectedClass!',
                          style: GoogleFonts.fredoka(color: Colors.white, fontSize: 13),
                        ),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Save Syllabus Changes',
                    style: GoogleFonts.fredoka(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openLessonDetails(BuildContext context, Map<String, dynamic> skill) {
    final title = skill['title'] as String;
    final emoji = skill['emoji'] as String;
    final modules = skill['modules'] as List? ?? [];
    final accentColor = getAccentColor(title);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag indicator + Header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(emoji, style: const TextStyle(fontSize: 22)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CLASSROOM MANUAL',
                                      style: GoogleFonts.outfit(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: accentColor,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    Text(
                                      title,
                                      style: GoogleFonts.fredoka(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1E293B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                                onPressed: () => Navigator.pop(ctx),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Content Scroll
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Brief Objective Block
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFCBD5E1).withOpacity(0.35)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.lightbulb_outline_rounded, color: accentColor, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Target Outcomes',
                                      style: GoogleFonts.fredoka(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  skill['desc'] as String? ?? 'Empower students to master next-generation capabilities through classroom simulation.',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11.5,
                                    color: const Color(0xFF64748B),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Modules Expansion List
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Curriculum Modules',
                                style: GoogleFonts.fredoka(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: accentColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  backgroundColor: accentColor.withOpacity(0.06),
                                ),
                                icon: const Icon(Icons.edit_note_rounded, size: 18),
                                label: Text(
                                  'Edit Syllabus',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () {
                                  _openSyllabusEditor(context, title);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          
                          if (modules.isEmpty)
                            Center(
                              child: Text(
                                'No modules configured for this skill.',
                                style: GoogleFonts.outfit(color: const Color(0xFF94A3B8)),
                              ),
                            )
                          else
                            ...List.generate(modules.length, (idx) {
                              final module = modules[idx] as String;
                              final guide = _getClassroomLessonGuide(module, _selectedClass);
                              final mcq = guide['mcq'] as Map<String, dynamic>;
                              final options = mcq['options'] as List;
                              final correctIdx = mcq['answerIndex'] as int;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.01),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                    child: ExpansionTile(
                                      leading: CircleAvatar(
                                        radius: 14,
                                        backgroundColor: accentColor.withOpacity(0.1),
                                        child: Text(
                                          '${idx + 1}',
                                          style: GoogleFonts.fredoka(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: accentColor,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        module,
                                        style: GoogleFonts.fredoka(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1E293B),
                                        ),
                                      ),
                                      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      children: [
                                        const Divider(height: 1),
                                        const SizedBox(height: 12),

                                        // PREMIUM GO LIVE PRESENTATION MODE BUTTON
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.pop(ctx); // Close sheet
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => TeacherSmartboardSessionScreen(
                                                  title: title,
                                                  emoji: emoji,
                                                  moduleTitle: module,
                                                  guide: guide,
                                                  accentColor: accentColor,
                                                  selectedClass: _selectedClass,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            margin: const EdgeInsets.only(bottom: 16),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [accentColor, accentColor.withOpacity(0.8)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: accentColor.withOpacity(0.25),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 5),
                                                )
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.cast_for_education_rounded, color: Colors.white, size: 20),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Launch Live Smartboard Session',
                                                  style: GoogleFonts.fredoka(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        // Objective
                                        _buildGuideSection(
                                          title: 'Objective',
                                          body: guide['objective'] as String,
                                          accentColor: accentColor,
                                        ),
                                        const SizedBox(height: 12),
                                        
                                        // Icebreaker
                                        _buildGuideSection(
                                          title: '60-Second Icebreaker Activity',
                                          body: guide['icebreaker'] as String,
                                          accentColor: accentColor,
                                        ),
                                        const SizedBox(height: 12),
                                        
                                        // Board Explanation Tip
                                        _buildGuideSection(
                                          title: 'Board Explanation Tip',
                                          body: guide['teachingTip'] as String,
                                          accentColor: accentColor,
                                        ),
                                        const SizedBox(height: 12),
                                        
                                        // Main Classroom Activity
                                        _buildGuideSection(
                                          title: 'Group Interactive Practice',
                                          body: guide['activity'] as String,
                                          accentColor: accentColor,
                                        ),
                                        const SizedBox(height: 16),
                                        
                                        // Interactive Board MCQ Quiz Simulator
                                        Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.quiz_rounded, color: Color(0xFFF59E0B), size: 16),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'Try Live Classroom Quiz',
                                                    style: GoogleFonts.fredoka(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: const Color(0xFFF59E0B),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                mcq['question'] as String,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF1E293B),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              ...List.generate(options.length, (oIdx) {
                                                bool isCorrect = oIdx == correctIdx;
                                                return Container(
                                                  width: double.infinity,
                                                  margin: const EdgeInsets.only(bottom: 6),
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                  decoration: BoxDecoration(
                                                    color: isCorrect ? const Color(0xFFECFDF5) : Colors.white,
                                                    border: Border.all(
                                                      color: isCorrect ? const Color(0xFF34D399) : const Color(0xFFE2E8F0),
                                                      width: isCorrect ? 1.5 : 1,
                                                    ),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        isCorrect ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                                        color: isCorrect ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                                                        size: 14,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          options[oIdx] as String,
                                                          style: GoogleFonts.outfit(
                                                            fontSize: 10.5,
                                                            color: isCorrect ? const Color(0xFF065F46) : const Color(0xFF475569),
                                                            fontWeight: isCorrect ? FontWeight.bold : FontWeight.w500,
                                                          ),
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                );
                                              }),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Rationale: ${mcq['rationale']}',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 9.5,
                                                  color: const Color(0xFF64748B),
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              )
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            })
                        ],
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

  Widget _buildGuideSection({
    required String title,
    required String body,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.fredoka(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withOpacity(0.12)),
          ),
          child: Text(
            body,
            style: GoogleFonts.outfit(
              fontSize: 10.5,
              color: const Color(0xFF64748B),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final skills = state.getSkillsForClass(_selectedClass);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
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
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 180.0,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF1E3A8A),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    'Future Skills Planner',
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                      shadows: [const Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ];
          },
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dynamic Grade Dropdown Selector Panel
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Classroom Grade',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          'Browsing $_selectedClass Manual',
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        )
                      ],
                    ),
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedClass,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: const Color(0xFF1E293B),
                            fontWeight: FontWeight.bold,
                          ),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedClass = newValue;
                              });
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
              
              // Skills Grid
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  itemCount: skills.length,
                  itemBuilder: (context, idx) {
                    final skill = skills[idx];
                    final title = skill['title'] as String;
                    final emoji = skill['emoji'] as String;
                    final modCount = (skill['modules'] as List?)?.length ?? 3;
                    final accentColor = getAccentColor(title);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14.0),
                      child: GestureDetector(
                        onTap: () => _openLessonDetails(context, skill),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: accentColor.withOpacity(0.18), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(emoji, style: const TextStyle(fontSize: 22)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: GoogleFonts.fredoka(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '📚 $modCount Lesson Modules Mapped',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        color: const Color(0xFF64748B),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Open Manual',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
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
}

// 📺 GORGEOUS SMARTBOARD LIVE CLASSROOM SESSION SCREEN
class TeacherSmartboardSessionScreen extends StatefulWidget {
  final String title;
  final String emoji;
  final String moduleTitle;
  final Map<String, dynamic> guide;
  final Color accentColor;
  final String selectedClass;

  const TeacherSmartboardSessionScreen({
    Key? key,
    required this.title,
    required this.emoji,
    required this.moduleTitle,
    required this.guide,
    required this.accentColor,
    required this.selectedClass,
  }) : super(key: key);

  @override
  State<TeacherSmartboardSessionScreen> createState() => _TeacherSmartboardSessionScreenState();
}

class _TeacherSmartboardSessionScreenState extends State<TeacherSmartboardSessionScreen> {
  int _currentSlide = 0;
  final int _totalSlides = 4;

  // Slide 1 (Icebreaker) Timer State
  int _secondsLeft = 60;
  Timer? _timer;
  bool _isTimerRunning = false;

  // Slide 4 (Quiz Game) State
  int _selectedOptionIndex = -1;
  bool _isAnswerChecked = false;
  bool _showSuccessAlert = false;
  bool _showErrorAlert = false;
  bool _showRationale = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_isTimerRunning) return;
    setState(() {
      _isTimerRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _isTimerRunning = false;
        });
        // Feedback vibration / alert
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = 60;
      _isTimerRunning = false;
    });
  }

  void _checkQuizAnswer(int selectedIdx, int correctIdx) {
    setState(() {
      _selectedOptionIndex = selectedIdx;
      _isAnswerChecked = true;
      if (selectedIdx == correctIdx) {
        _showSuccessAlert = true;
        _showErrorAlert = false;
      } else {
        _showErrorAlert = true;
        _showSuccessAlert = false;
      }
    });
  }

  void _nextSlide() {
    if (_currentSlide < _totalSlides - 1) {
      setState(() {
        _currentSlide++;
      });
    }
  }

  void _prevSlide() {
    if (_currentSlide > 0) {
      setState(() {
        _currentSlide--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mcq = widget.guide['mcq'] as Map<String, dynamic>;
    final options = mcq['options'] as List;
    final correctIdx = mcq['answerIndex'] as int;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate 900: High contrast for smartboards & projectors
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Smartboard Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                border: Border(bottom: BorderSide(color: const Color(0xFF334155), width: 1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: widget.accentColor.withOpacity(0.3)),
                    ),
                    child: Text(widget.emoji, style: const TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: widget.accentColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.selectedClass.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'LIVE CLASSROOM PRESENTATION',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF94A3B8),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.moduleTitle,
                          style: GoogleFonts.fredoka(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.fullscreen_exit_rounded, color: Color(0xFF94A3B8), size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Progress Bar / Navigation Dots
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              color: const Color(0xFF1E293B).withOpacity(0.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Slide ${_currentSlide + 1} of $_totalSlides',
                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: List.generate(_totalSlides, (idx) {
                      bool isActive = idx == _currentSlide;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: isActive ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 6),
                        decoration: BoxDecoration(
                          color: isActive ? widget.accentColor : const Color(0xFF475569),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  )
                ],
              ),
            ),

            // Slide Canvas Area
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildCurrentSlide(mcq, options, correctIdx),
                ),
              ),
            ),

            // Smartboard Celebrations / Error Warnings
            if (_showSuccessAlert)
              _buildSuccessBanner(),
            if (_showErrorAlert)
              _buildErrorBanner(),

            // Control Navigation Toolbar (Large Buttons for Easy Smartboard Taps)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                border: Border(top: BorderSide(color: const Color(0xFF334155), width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _prevSlide,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: _currentSlide == 0 ? const Color(0xFF0F172A).withOpacity(0.3) : const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _currentSlide == 0 ? Colors.transparent : const Color(0xFF475569)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_back_rounded, color: _currentSlide == 0 ? const Color(0xFF475569) : Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Previous',
                            style: GoogleFonts.fredoka(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _currentSlide == 0 ? const Color(0xFF475569) : Colors.white,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _currentSlide == _totalSlides - 1 ? () => Navigator.pop(context) : _nextSlide,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [widget.accentColor, widget.accentColor.withOpacity(0.85)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: widget.accentColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(
                            _currentSlide == _totalSlides - 1 ? 'Finish Lesson' : 'Next Step',
                            style: GoogleFonts.fredoka(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentSlide == _totalSlides - 1 ? Icons.check_circle_outline_rounded : Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // BUILD SLIDES FOR LIVE TEACHING FLOW
  Widget _buildCurrentSlide(Map<String, dynamic> mcq, List options, int correctIdx) {
    switch (_currentSlide) {
      case 0:
        return _buildIcebreakerSlide();
      case 1:
        return _buildBlackboardPlanSlide();
      case 2:
        return _buildGroupPlaySlide();
      case 3:
        return _buildSmartboardQuizSlide(mcq, options, correctIdx);
      default:
        return const SizedBox.shrink();
    }
  }

  // SLIDE 1: ICEBREAKER & LIVE COUNTDOWN TIMER
  Widget _buildIcebreakerSlide() {
    return Column(
      key: const ValueKey('icebreaker_slide'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flash_on_rounded, color: Color(0xFFF59E0B), size: 28),
            const SizedBox(width: 8),
            Text(
              'STEP 1: Classroom Icebreaker',
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Get your students hyper-focused and excited with this 60-second opening activity!',
          style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Activity Description',
                style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFFF59E0B)),
              ),
              const SizedBox(height: 10),
              Text(
                widget.guide['icebreaker'] as String,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: Colors.white,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        
        // Dynamic Board Timer Face
        Center(
          child: Container(
            width: 250,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: _isTimerRunning ? widget.accentColor : const Color(0xFF334155),
                width: 2,
              ),
              boxShadow: _isTimerRunning ? [
                BoxShadow(
                  color: widget.accentColor.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ] : [],
            ),
            child: Column(
              children: [
                Text(
                  'CLASSROOM TIMER',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF64748B),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '00:${_secondsLeft.toString().padLeft(2, '0')}',
                  style: GoogleFonts.fredoka(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: _secondsLeft == 0 
                        ? const Color(0xFFEF4444) 
                        : (_isTimerRunning ? Colors.white : const Color(0xFF94A3B8)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isTimerRunning ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                        color: _isTimerRunning ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                        size: 40,
                      ),
                      onPressed: _isTimerRunning ? _pauseTimer : _startTimer,
                    ),
                    const SizedBox(width: 14),
                    IconButton(
                      icon: const Icon(Icons.replay_circle_filled_rounded, color: Color(0xFF64748B), size: 40),
                      onPressed: _resetTimer,
                    ),
                  ],
                )
              ],
            ),
          ),
        )
      ],
    );
  }

  // SLIDE 2: BLACKBOARD ILLUSTRATION PLAN
  Widget _buildBlackboardPlanSlide() {
    return Column(
      key: const ValueKey('blackboard_slide'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: Color(0xFF3B82F6), size: 28),
            const SizedBox(width: 8),
            Text(
              'STEP 2: Board Explanation Plan',
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Grab your physical chalk/marker! Illustrate this step-by-step concept flow clearly on the classroom board.',
          style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.palette_rounded, color: Color(0xFF3B82F6), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'What to Write / Draw on Board',
                    style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF3B82F6)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                widget.guide['teachingTip'] as String,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: Colors.white,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tip: Call a volunteer to write their opinion or code line directly inside your drawing!',
                        style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  // SLIDE 3: GROUP INTERACTIVE CLASSROOM PLAY
  Widget _buildGroupPlaySlide() {
    return Column(
      key: const ValueKey('groupplay_slide'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.groups_rounded, color: Color(0xFF10B981), size: 28),
            const SizedBox(width: 8),
            Text(
              'STEP 3: Collaborative Classroom Game',
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Split your classroom into pairs or dynamic team sides. Drive real-world practice of the concept live!',
          style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.sports_esports_rounded, color: Color(0xFF10B981), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Class Game & Practice Rules',
                    style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                widget.guide['activity'] as String,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: Colors.white,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // SLIDE 4: SMARTBOARD INTERACTIVE MCQ QUIZ
  Widget _buildSmartboardQuizSlide(Map<String, dynamic> mcq, List options, int correctIdx) {
    return Column(
      key: const ValueKey('smartboard_quiz_slide'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.quiz_rounded, color: Color(0xFFEF4444), size: 28),
            const SizedBox(width: 8),
            Text(
              'STEP 4: Smartboard Live Quiz Challenge',
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Project this question on the screen. Ask the class for a show of hands before clicking the correct answer card!',
          style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 24),
        
        // Massive Board Question Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Text(
            mcq['question'] as String,
            style: GoogleFonts.fredoka(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Large Kahoot-style Board Option Buttons
        ...List.generate(options.length, (idx) {
          bool isSelected = idx == _selectedOptionIndex;
          bool isCorrect = idx == correctIdx;
          
          Color cardBorderColor = const Color(0xFF334155);
          Color cardBgColor = const Color(0xFF1E293B);
          Color fontColor = Colors.white;

          if (_isAnswerChecked) {
            if (isCorrect) {
              cardBgColor = const Color(0xFF065F46); // Dark Emerald Green
              cardBorderColor = const Color(0xFF10B981);
            } else if (isSelected) {
              cardBgColor = const Color(0xFF7F1D1D); // Dark Crimson Red
              cardBorderColor = const Color(0xFFEF4444);
            }
          } else if (isSelected) {
            cardBorderColor = widget.accentColor;
          }

          // Large game letters
          final letters = ['A', 'B', 'C', 'D'];
          final colors = [
            const Color(0xFFEF4444), // Red
            const Color(0xFF3B82F6), // Blue
            const Color(0xFF10B981), // Emerald
            const Color(0xFFF59E0B), // Amber
          ];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: GestureDetector(
              onTap: () {
                if (!_isAnswerChecked) {
                  _checkQuizAnswer(idx, correctIdx);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cardBorderColor, width: 2),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: colors[idx % colors.length],
                      child: Text(
                        letters[idx],
                        style: GoogleFonts.fredoka(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        options[idx] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: fontColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_isAnswerChecked && isCorrect)
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
                    if (_isAnswerChecked && isSelected && !isCorrect)
                      const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 24),
                  ],
                ),
              ),
            ),
          );
        }),

        if (_isAnswerChecked) ...[
          const SizedBox(height: 10),
          Center(
            child: TextButton.icon(
              icon: Icon(
                _showRationale ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                color: widget.accentColor,
              ),
              label: Text(
                _showRationale ? 'Hide Board Rationale' : 'Explain to Class (Show Rationale)',
                style: GoogleFonts.fredoka(color: widget.accentColor, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                setState(() {
                  _showRationale = !_showRationale;
                });
              },
            ),
          ),
          if (_showRationale)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Text(
                'Concept Explanation:\n\n${mcq['rationale']}',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: const Color(0xFFE2E8F0),
                  height: 1.45,
                ),
              ),
            )
        ]
      ],
    );
  }

  // STUNNING SUCCESS BANNER (CELEBRATORY GREEN OVERLAY ON BOARD)
  Widget _buildSuccessBanner() {
    return Container(
      color: const Color(0xFF065F46),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CLASS CRACKED IT! +50 XP Gained',
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'The classroom erupted in cheers! Excellent teaching coach.',
                  style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFFA7F3D0)),
                )
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () {
              setState(() {
                _showSuccessAlert = false;
              });
            },
          )
        ],
      ),
    );
  }

  // TRY AGAIN BANNER
  Widget _buildErrorBanner() {
    return Container(
      color: const Color(0xFF7F1D1D),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NOT QUITE! Lets try a show of hands again',
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Guide your students to analyze the clues and try another option!',
                  style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFFFECACA)),
                )
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () {
              setState(() {
                _showErrorAlert = false;
              });
            },
          )
        ],
      ),
    );
  }
}
