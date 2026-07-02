import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/app_state.dart';
import 'live_classes_screen.dart';

class FutureSkillsDetailScreen extends StatefulWidget {
  final Map<String, dynamic> skill;
  final AppState state;

  const FutureSkillsDetailScreen({
    super.key,
    required this.skill,
    required this.state,
  });

  @override
  State<FutureSkillsDetailScreen> createState() =>
      _FutureSkillsDetailScreenState();
}

class _FutureSkillsDetailScreenState extends State<FutureSkillsDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;
  final List<bool> _moduleChecked = [];

  @override
  void initState() {
    super.initState();
    final modules = widget.skill['modules'] as List? ?? [];
    _moduleChecked.addAll(List.filled(modules.length, false));

    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // Color palette based on emoji/title hash
  Color get _accentColor {
    final title = widget.skill['title'] as String? ?? '';
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEF4444), // Red
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFDB2777), // Pink
      const Color(0xFF7C3AED), // Purple
    ];
    return colors[title.length % colors.length];
  }

  Color get _lightBg =>
      _accentColor.withValues(alpha: 0.06);

  List<String> _getSkillSyllabus(String skillTitle) {
    final state = Provider.of<AppState>(context);
    return state.getSkillSyllabus(state.studentClass, skillTitle);
  }

  bool _isLiveClassScheduledForSkill() {
    final state = Provider.of<AppState>(context);
    final titleLower = (widget.skill['title'] as String? ?? '').toLowerCase();
    for (final liveClass in state.liveClassesSchedule) {
      final subject = (liveClass['subject'] as String? ?? '').toLowerCase();
      final topic = (liveClass['topic'] as String? ?? '').toLowerCase();
      
      if (titleLower.contains('coding') || titleLower.contains('web')) {
        if (subject.contains('coding') || subject.contains('web') || topic.contains('html') || topic.contains('css') || topic.contains('web')) {
          return true;
        }
      } else if (titleLower.contains('financial') || titleLower.contains('business')) {
        if (subject.contains('financial') || subject.contains('business') || topic.contains('budget') || topic.contains('bank') || topic.contains('stock')) {
          return true;
        }
      } else if (titleLower.contains('speech') || titleLower.contains('debate') || titleLower.contains('mun')) {
        if (subject.contains('speech') || subject.contains('debate') || topic.contains('debate') || topic.contains('mun') || topic.contains('public speaking')) {
          return true;
        }
      } else if (titleLower.contains('ai tools') || titleLower.contains('prompt')) {
        if (subject.contains('ai') || topic.contains('prompt') || topic.contains('automation')) {
          return true;
        }
      } else if (titleLower.contains('art') || titleLower.contains('wellbeing')) {
        if (subject.contains('art') || subject.contains('well') || topic.contains('sketch') || topic.contains('color') || topic.contains('posture')) {
          return true;
        }
      } else if (titleLower.contains('olympiad') || titleLower.contains('academic')) {
        if (subject.contains('math') || subject.contains('science') || topic.contains('olympiad') || topic.contains('science concepts') || topic.contains('logical math')) {
          return true;
        }
      }
    }
    return false;
  }

  // Curriculum Module Study Database for Students
  Map<String, dynamic> _getModuleStudyData(String moduleTitle) {
    final clean = moduleTitle.toLowerCase();
    
    // --- TECH & CODE SKILLS ---
    // AI Tools & Productivity
    if (clean.contains('prompt')) {
      return {
        'explanation': 'Prompt Engineering is the science of structuring text queries so a GenAI model yields optimal answers. The ROLE-TASK-CONTEXT framework provides an instant structural guide!',
        'options': [
          'Act as a Python coach. Debug this loop statement.',
          'Solve this code for me right now.'
        ],
        'correctIndex': 0,
        'motivation': 'Perfect! Specifying a clear role ("Python coach") dramatically improves the reasoning parameters of the AI.'
      };
    } else if (clean.contains('automation')) {
      return {
        'explanation': 'Workflow Automation links multiple applications using automated "triggers" (an event like getting an email) and "actions" (auto-adding an entry to a sheet).',
        'options': [
          'Background trigger-action automated loops',
          'Writing manuals every hour'
        ],
        'correctIndex': 0,
        'motivation': 'Spot on! Automated workflows save countless hours by executing triggers in the background.'
      };
    }
    // Coding Basics & HTML/CSS/SQL
    else if (clean.contains('logic 101') || clean.contains('coding logic')) {
      return {
        'explanation': 'Computers require explicit instructions. An algorithm is a step-by-step logic recipe to solve a problem with finite starting and ending bounds.',
        'options': [
          'A precise, step-by-step set of instructions to solve a problem.',
          'A simple hardware component inside the computer motherboard.'
        ],
        'correctIndex': 0,
        'motivation': 'Great job! Algorithms form the foundational baseline of all software and apps.'
      };
    } else if (clean.contains('tags') || (clean.contains('structure') && clean.contains('html'))) {
      return {
        'explanation': 'HTML (HyperText Markup Language) uses nested tags to define document layouts. <h1> denotes the primary heading, whereas <p> is for general text blocks.',
        'options': [
          '<paragraph>',
          '<h1>',
          '<body>'
        ],
        'correctIndex': 1,
        'motivation': 'Correct! <h1> defines the top-level main heading on a website page.'
      };
    } else if (clean.contains('css basics') || clean.contains('css')) {
      return {
        'explanation': 'CSS (Cascading Style Sheets) decorates dry HTML layouts. It controls responsive sizing, harmonized HSL color borders, and visual card alignments.',
        'options': [
          'HTML tags',
          'CSS properties (e.g. background-color, border-radius)'
        ],
        'correctIndex': 1,
        'motivation': 'Fabulous! CSS breathes premium life and visuals into structural HTML text skeletons.'
      };
    } else if (clean.contains('responsive')) {
      return {
        'explanation': 'Responsive Web Design ensures that websites adjust dynamically to look spectacular on small smartphone screens as well as massive TV monitors.',
        'options': [
          'Flexible layouts and media queries',
          'Creating a completely separate website for every phone model'
        ],
        'correctIndex': 0,
        'motivation': 'Perfect! Flexible layouts adapt grids fluidly to any viewport size.'
      };
    } else if (clean.contains('sql relational') || clean.contains('sql queries')) {
      return {
        'explanation': 'SQL (Structured Query Language) is the global coding key to search, filter, and extract records from structured relational databases.',
        'options': [
          'SELECT student_name FROM rosters WHERE class = "Class 10";',
          'GET student_name IN rosters;'
        ],
        'correctIndex': 0,
        'motivation': 'Brilliant! SELECT and WHERE form the core parameters of clean SQL queries.'
      };
    } else if (clean.contains('python control')) {
      return {
        'explanation': 'Python control flow uses if, elif, and else statements to execute code blocks conditionally based on logical statements.',
        'options': [
          'elif',
          'else if'
        ],
        'correctIndex': 0,
        'motivation': 'Perfect! Python uses "elif" for secondary conditional checks, keeping logic chains clean.'
      };
    } else if (clean.contains('database') || clean.contains('queries')) {
      return {
        'explanation': 'Relational databases store tables linked by keys. A primary key uniquely identifies each record in a table.',
        'options': [
          'Primary Key',
          'Foreign Key'
        ],
        'correctIndex': 0,
        'motivation': 'Exactly! Primary keys guarantee unique identification and integrity in relational tables.'
      };
    } else if (clean.contains('excel pivot') || clean.contains('pivot table')) {
      return {
        'explanation': 'Pivot Tables in Excel allow you to dynamically summarize, aggregate, and analyze massive tables of data instantly without writing formulas.',
        'options': [
          'Pivot Tables',
          'Merged Cells'
        ],
        'correctIndex': 0,
        'motivation': 'Correct! Pivot tables are extremely powerful tools to summarize large datasets in seconds.'
      };
    } else if (clean.contains('word professional') || clean.contains('word')) {
      return {
        'explanation': 'Professional documents in Word use Paragraph Styles (Headings, Subtitles, Body) to maintain formatting consistency and auto-generate tables of contents.',
        'options': [
          'Styles Panel',
          'Manual font changes'
        ],
        'correctIndex': 0,
        'motivation': 'Perfect! Word styles keep styling consistent and simplify document management.'
      };
    } else if (clean.contains('powerpoint')) {
      return {
        'explanation': 'PowerPoint presentations should support the speaker. Follow the rule of visual hierarchy: keep text concise in bullet points and use clean imagery.',
        'options': [
          'Keep slides clean with high-contrast visual bullet points',
          'Copy-paste entire book paragraphs onto slides'
        ],
        'correctIndex': 0,
        'motivation': 'Splendid! Slide cards are designed for visual aids, not text dumps.'
      };
    } else if (clean.contains('social media') || clean.contains('channels')) {
      return {
        'explanation': 'Digital media channels rely on targeting specific demographics. B2B business networking is optimal on platforms like LinkedIn, while quick visual B2C branding fits Instagram.',
        'options': [
          'LinkedIn for professional B2B, Instagram/TikTok for B2C',
          'Using personal messenger groups for global sales'
        ],
        'correctIndex': 0,
        'motivation': 'Spot on! Choosing the right channel saves money and increases marketing conversion rates.'
      };
    } else if (clean.contains('seo') || clean.contains('keywords')) {
      return {
        'explanation': 'Search Engine Optimization (SEO) involves research to target words your audience searches for on Google, aligning content structure to rank higher organically.',
        'options': [
          'Target relevant keyword search volumes with high-quality content',
          'Buying fake views or traffic bots'
        ],
        'correctIndex': 0,
        'motivation': 'Brilliant! Google rewards helpful content matching user search intent.'
      };
    } else if (clean.contains('data flow') || clean.contains('privacy')) {
      return {
        'explanation': 'Data Flow security protects customer credentials. The HTTPS protocol encrypts web traffic, stopping bad actors from reading form submissions.',
        'options': [
          'HTTPS with SSL/TLS encryption',
          'Standard HTTP connections'
        ],
        'correctIndex': 0,
        'motivation': 'Exactly! HTTPS encrypts client-server communications for total transaction security.'
      };
    } else if (clean.contains('video editing') || clean.contains('premiere') || clean.contains('fcp') || clean.contains('color correction') || clean.contains('audio mixing')) {
      return {
        'explanation': 'Video editing combines raw footage into visual stories. A primary workflow is using standard J-cuts or L-cuts to make dialogue scenes transition seamlessly.',
        'options': [
          'J-cuts and L-cuts to blend audio and video timing',
          'Only cutting at the end of each raw clip'
        ],
        'correctIndex': 0,
        'motivation': 'Wunderbar! J/L cuts overlap audio and visual borders, making storytelling look incredibly natural.'
      };
    }
    
    // --- SPEECH, MUN & DEBATE SKILLS ---
    else if (clean.contains('public debating') || clean.contains('debate format')) {
      return {
        'explanation': 'Public debating formats (like British Parliamentary) rely on structured rules, official timings, and diplomatic points of information (POIs).',
        'options': [
          'British Parliamentary with formal POIs',
          'Unstructured open-floor shouting match'
        ],
        'correctIndex': 0,
        'motivation': 'Superb! Parliamentary rules maintain democratic flow and force teams to engage with counter-arguments.'
      };
    } else if (clean.contains('mun delegate') || clean.contains('protocol')) {
      return {
        'explanation': 'Model UN (MUN) protocols require delegates to represent their designated country\'s official policies, using moderated caucuses for structured debates.',
        'options': [
          'Represent the designated country\'s policy using moderated caucuses',
          'Debate your personal opinions and argue with the Chair'
        ],
        'correctIndex': 0,
        'motivation': 'Awesome! MUN delegates must stay in country character and practice formal diplomacy.'
      };
    } else if (clean.contains('resolution writing') || clean.contains('resolution')) {
      return {
        'explanation': 'MUN Resolutions have preambulatory clauses (setting the background) and operative clauses (action-oriented solutions starting with active verbs).',
        'options': [
          'Operative clauses that recommend policies and actions',
          'Preambulatory clauses only'
        ],
        'correctIndex': 0,
        'motivation': 'Correct! Operative clauses are numbered, start with active verbs, and propose actual work plans.'
      };
    } else if (clean.contains('speech initiation') || clean.contains('hacks') || clean.contains('hook')) {
      return {
        'explanation': 'The first 3 seconds of a speech are vital. A "Hook" captures the room instantly: start with a dramatic statistic, question, or quote instead of standard introductions.',
        'options': [
          'A shocking statistic or dramatic query to hook focus',
          'Saying "My name is [your name], and today I will talk about..."'
        ],
        'correctIndex': 0,
        'motivation': 'Perfect! An evocative hook immediately gathers the audience\'s attention.'
      };
    } else if (clean.contains('impromptu speaking') || clean.contains('extempore') || clean.contains('impromptu structures')) {
      return {
        'explanation': 'Extempore requires instant speech construction. The OREO framework (Opinion, Reason, Explanation, Opinion restatement) offers an outstanding structural guide!',
        'options': [
          'The OREO framework (Opinion, Reason, Example, Opinion)',
          'Speaking completely randomly until time runs out'
        ],
        'correctIndex': 0,
        'motivation': 'Brilliant! The OREO framework gives your thoughts a logical, professional flow.'
      };
    } else if (clean.contains('modulation') || clean.contains('voice') || clean.contains('speech structuring')) {
      return {
        'explanation': 'Vocal modulation involves shifting pitch, speed, and volume. Slow down and add a 2-second deliberate pause before major points to let them sink in.',
        'options': [
          'Varying pitch, speed, and pausing deliberately before key points',
          'Speaking in a fast, constant monotone'
        ],
        'correctIndex': 0,
        'motivation': 'Fabulous! Controlled pacing and vocal variety project high confidence and leadership.'
      };
    }
    
    // --- FINANCIAL LITERACY & BUSINESS ---
    else if (clean.contains('budgeting 101') || clean.contains('budget')) {
      return {
        'explanation': 'A household budget tracks income and divides expenses. The standard 50/30/20 rule allocates 50% for Needs, 30% for Wants, and 20% for Savings.',
        'options': [
          'Needs (50%), Wants (30%), Savings (20%)',
          'Needs (80%), Wants (20%), Savings (0%)'
        ],
        'correctIndex': 0,
        'motivation': 'Perfect! Keeping savings at 20% ensures compound wealth building from early on.'
      };
    } else if (clean.contains('banking') || clean.contains('savings')) {
      return {
        'explanation': 'Savings accounts provide liquidity and security. A Fixed Deposit (FD) locks money for a specific duration to earn guaranteed higher interest rates.',
        'options': [
          'Fixed Deposits that lock funds for higher interest',
          'A checking account with zero interest'
        ],
        'correctIndex': 0,
        'motivation': 'Splendid! Fixed Deposits offer a safe, low-risk, guaranteed return yield.'
      };
    } else if (clean.contains('compound interest') || clean.contains('compounding')) {
      return {
        'explanation': 'Compound interest multiplies wealth exponentially. The mathematical formula is A = P(1 + r/n)^(nt). Time is the exponent, making early savings massive!',
        'options': [
          'Interest earned on principal PLUS accrued interest over time',
          'Interest earned on the initial principal capital only'
        ],
        'correctIndex': 0,
        'motivation': 'Exactly! Albert Einstein famously called compound interest the eighth wonder of the world.'
      };
    } else if (clean.contains('taxation') || clean.contains('tax')) {
      return {
        'explanation': 'Taxes fund public services. Income Tax is a direct tax on personal earnings, whereas Goods & Services Tax (GST) is an indirect tax paid on transactions.',
        'options': [
          'Direct tax on earnings (Income Tax), Indirect tax on shopping (GST)',
          'All taxes are paid directly to school administrations'
        ],
        'correctIndex': 0,
        'motivation': 'Great! Direct taxes apply directly to income, while indirect taxes apply to consumption.'
      };
    } else if (clean.contains('stock market') || clean.contains('share')) {
      return {
        'explanation': 'Stocks represent fractional ownership of public corporations. Shareholders benefit when company earnings grow, raising stock valuations.',
        'options': [
          'Fractional ownership in a public corporation',
          'A guaranteed loan to the government'
        ],
        'correctIndex': 0,
        'motivation': 'Perfect! Buying shares makes you a partial owner of the business.'
      };
    } else if (clean.contains('financial statements') || clean.contains('balance sheet') || clean.contains('cash flow')) {
      return {
        'explanation': 'Relational corporate finance uses the accounting equation: Assets = Liabilities + Shareholder\'s Equity. The balance sheet must balance these three parameters.',
        'options': [
          'Assets = Liabilities + Owner\'s Equity',
          'Assets = Expenses + Liabilities'
        ],
        'correctIndex': 0,
        'motivation': 'Correct! This fundamental balance equation is the structural basis of all corporate accounting.'
      };
    }
    
    // --- ART THEORY & WELLBEING ---
    else if (clean.contains('color wheel') || clean.contains('color matching')) {
      return {
        'explanation': 'The Color Wheel helps designers match palettes. Complementary colors lie directly opposite each other (e.g. blue and orange), creating maximum visual vibrance.',
        'options': [
          'Complementary colors (opposite on the wheel like Blue/Orange)',
          'Analogous colors only'
        ],
        'correctIndex': 0,
        'motivation': 'Spectacular! Complementary pairings produce high-contrast, professional layouts.'
      };
    } else if (clean.contains('art history') || clean.contains('art eras')) {
      return {
        'explanation': 'The Renaissance era reintroduced realistic depth and anatomy, whereas Impressionism (e.g. Claude Monet) focused on capturing light, atmospheric shifts, and quick strokes.',
        'options': [
          'Impressionism, which captures atmospheric light and natural shifts',
          'Renaissance perspective diagrams'
        ],
        'correctIndex': 0,
        'motivation': 'Fabulous! Impressionism challenged classical studio styles to capture natural light changes outdoors.'
      };
    } else if (clean.contains('sketching') || clean.contains('pencil')) {
      return {
        'explanation': 'Pencil grades indicate lead hardness. "B" pencils (e.g. 4B, 6B) are soft and black, optimal for rich shading, whereas "H" pencils are hard and light.',
        'options': [
          'Softer, darker pencils like 4B',
          'Hard, light pencils like 3H'
        ],
        'correctIndex': 0,
        'motivation': 'Great! 4B contains more graphite and less clay, providing dark, easily blended shading marks.'
      };
    } else if (clean.contains('macronutrient') || clean.contains('nutrition') || clean.contains('protein')) {
      return {
        'explanation': 'Our body requires macronutrients: Proteins (tissue repair), Carbohydrates (primary fuel), and Healthy Fats (hormones and brain protection).',
        'options': [
          'Proteins for tissue repair, Carbs for energy, Fats for brain health',
          'Only taking vitamin pills without food'
        ],
        'correctIndex': 0,
        'motivation': 'Correct! A balanced macronutrient profile supports peak student focus and immunity.'
      };
    } else if (clean.contains('postur') || clean.contains('ergonomic')) {
      return {
        'explanation': 'Ergonomic study spaces reduce fatigue. Keep your feet flat on the floor, back supported by a chair, and study screens positioned right at eye level.',
        'options': [
          'Feet flat on the floor, back supported, screen at eye level',
          'Slouching forward with screens resting directly on your lap'
        ],
        'correctIndex': 0,
        'motivation': 'Exactly! Good posture minimizes physical stress, letting you study longer without strain.'
      };
    } else if (clean.contains('stress') || clean.contains('breathing') || clean.contains('calm')) {
      return {
        'explanation': 'Box Breathing is an amazing stress relief method used by elite forces. Inhale for 4 seconds, hold for 4, exhale for 4, and hold for 4. This instantly lowers cortisol!',
        'options': [
          'Box Breathing: Inhale 4s, Hold 4s, Exhale 4s, Hold 4s',
          'Shallow rapid breathing'
        ],
        'correctIndex': 0,
        'motivation': 'Perfect! Box breathing slows your heart rate, instantly clearing exam anxiety.'
      };
    }
    
    // --- OLYMPIADS & ACADEMIC PREP ---
    else if (clean.contains('logical math') || clean.contains('math worksheets') || clean.contains('riddles')) {
      return {
        'explanation': 'Analytical math checks patterns. Look at this logical progression: 2, 6, 12, 20, 30... The differences are +4, +6, +8, +10. The next term is +12!',
        'options': [
          '42',
          '38'
        ],
        'correctIndex': 0,
        'motivation': 'Splendid! 30 + 12 equals 42. Pattern recognition is highly valued in competitive worksheets.'
      };
    } else if (clean.contains('science concepts') || clean.contains('olympiad worksheets')) {
      return {
        'explanation': 'Thermodynamics dictates that energy can never be created or destroyed—it only changes from one form to another. This is the law of energy conservation.',
        'options': [
          'Conservation of Energy (First Law of Thermodynamics)',
          'Newton\'s Third Law'
        ],
        'correctIndex': 0,
        'motivation': 'Spot on! This bedrock scientific law explains mechanical, chemical, and electrical operations.'
      };
    } else if (clean.contains('exam strategies') || clean.contains('readiness') || clean.contains('time management') || clean.contains('mock')) {
      return {
        'explanation': 'High-stakes test strategy requires time management: eliminate obvious wrong answers, answer high-confidence questions first, and flag tough ones to review later.',
        'options': [
          'Answer high-confidence items first, flagging hard blocks for review',
          'Spend 15 minutes trying to solve the very first hard question'
        ],
        'correctIndex': 0,
        'motivation': 'Awesome! Controlled pacing prevents leaving high-confidence questions unanswered at the end.'
      };
    } else if (clean.contains('career') || clean.contains('degree') || clean.contains('counselling') || clean.contains('portfolio') || clean.contains('admission')) {
      return {
        'explanation': 'Modern careers value interdisciplinary skills. Combining technical skills (like coding) with communication or finance builds a powerful career portfolio.',
        'options': [
          'Interdisciplinary skill portfolios with real project examples',
          'Relying solely on paper grades with zero practical projects'
        ],
        'correctIndex': 0,
        'motivation': 'Brilliant! Real projects prove execution capability and make you stand out to top universities.'
      };
    } else if (clean.contains('cells') || clean.contains('columns')) {
      return {
        'explanation': 'Excel cells are referenced using their column letters first, followed by the row numbers. Cell D15 resides at Column D, Row 15.',
        'options': [
          'D15',
          '15D'
        ],
        'correctIndex': 0,
        'motivation': 'Exactly! Letter-first notation is the universal spreadsheet coordinate reference.'
      };
    } else if (clean.contains('formulas') && clean.contains('math')) {
      return {
        'explanation': 'Spreadsheet formulas must begin with an equals sign (=). The range operator is a colon (:). Example: =SUM(A1:A10).',
        'options': [
          '=SUM(A1:A10)',
          'SUM(A1-A10)'
        ],
        'correctIndex': 0,
        'motivation': 'Brilliant! The equals sign tells Excel to process a mathematical function.'
      };
    }
    
    // --- PRIMARY / LOWER GRADE MODULES (Spoken English, Puzzles, Habit, Solar System, etc.) ---
    else if (clean.contains('greeting') || clean.contains('everyday')) {
      return {
        'explanation': 'Polite everyday greetings set a cheerful, respectful tone. Greet with a warm smile and standard phrases like "Good morning!" or "How are you?".',
        'options': [
          'Saying "Good morning, ma\'am!" with a happy smile',
          'Running inside the class without looking'
        ],
        'correctIndex': 0,
        'motivation': 'Perfect! Respectful greetings spread positive energy in class.'
      };
    } else if (clean.contains('pronunciation') || clean.contains('phonet')) {
      return {
        'explanation': 'Phonics helps us read by blending letter sounds. For example, blending /c/ /a/ /t/ sounds makes the word "cat"!',
        'options': [
          'Blending letter sounds together',
          'Memorizing entire dictionary words'
        ],
        'correctIndex': 0,
        'motivation': 'Splendid! Phonics empowers children to decode and read unknown words easily.'
      };
    } else if (clean.contains('visual match') || clean.contains('puzzle')) {
      return {
        'explanation': 'Puzzles build visual logic: inspect shapes, colors, and repeating sequences carefully to find the odd one out or the next puzzle block.',
        'options': [
          '🔴 🔵 🔴 🔵 🔴',
          '🔴 🔵 🔵 🔴 🔵'
        ],
        'correctIndex': 0,
        'motivation': 'Perfect! Alternating red and blue circles forms a symmetrical, logical pattern.'
      };
    } else if (clean.contains('reading') || clean.contains('habit')) {
      return {
        'explanation': 'Building a daily reading habit expands vocabulary: read just 15 minutes before bedtime every day to accumulate 1 Million words a year!',
        'options': [
          '15 minutes of quiet, daily reading',
          'Reading a textbook only on exam morning'
        ],
        'correctIndex': 0,
        'motivation': 'Awesome! Small daily habits create massive compound intelligence over time.'
      };
    } else if (clean.contains('desk') || clean.contains('clean')) {
      return {
        'explanation': 'A clean desk declutters the mind: clear away unnecessary papers and toys, leaving only your textbook and notebook to maximize study concentration.',
        'options': [
          'A clear table with only your active textbook and notebook',
          'A desk cluttered with toys, snacks, and comic books'
        ],
        'correctIndex': 0,
        'motivation': 'Splendid! Decluttered workspaces minimize distraction and keep your focus locked.'
      };
    } else if (clean.contains('solar') || clean.contains('system')) {
      return {
        'explanation': 'Our Solar System has 8 planets orbiting the Sun. Mercury sits closest to the Sun, while massive Jupiter is the largest of all planets.',
        'options': [
          'Jupiter',
          'Mercury',
          'Earth'
        ],
        'correctIndex': 0,
        'motivation': 'Amazing! Jupiter is so gigantic that over 1,300 Earths could fit inside it.'
      };
    }
    
    // Default Fallback
    return {
      'explanation': 'Master high-stakes 21st century capabilities through structured practice modules: read interactive summaries, test your logic, and earn study XP!',
      'options': [
        'Read text passively without any self-testing',
        'Learn actively by practicing, quizzing, and applying concepts'
      ],
      'correctIndex': 1,
      'motivation': 'Splendid! Active learning and retrieval consolidates memory pathways.'
    };
  }

  // Immersive Active Study Console with Custom Lessons and Interactive Quizzes
  void _openActiveStudyConsole(int index, String moduleTitle) {
    final state = Provider.of<AppState>(context, listen: false);
    
    // Get customized data from database mapping
    final studyData = _getModuleStudyData(moduleTitle);
    final String explanation = studyData['explanation'];
    final List<String> options = List<String>.from(studyData['options']);
    final int correctIndex = studyData['correctIndex'];
    final String motivation = studyData['motivation'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        int? selectedAnswer;
        bool isSubmitted = false;
        
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final isCorrect = selectedAnswer == correctIndex;
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top drag handle
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _accentColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.psychology_alt_rounded, color: _accentColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.translate("ACTIVE STUDY MODULE"),
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _accentColor,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Text(
                                state.translate(moduleTitle),
                                style: GoogleFonts.fredoka(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AdyapanTheme.textMain,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Explanation Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _accentColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _accentColor.withValues(alpha: 0.15), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('💡', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Text(
                                state.translate("Interactive Lesson"),
                                style: GoogleFonts.fredoka(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _accentColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.translate(explanation),
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AdyapanTheme.textMain,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Practice Question Label
                    Text(
                      '📝 ' + state.translate("Practice Question"),
                      style: GoogleFonts.fredoka(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AdyapanTheme.textMain,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Options List
                    ...List.generate(options.length, (optIdx) {
                      final optText = options[optIdx];
                      final isSelected = selectedAnswer == optIdx;
                      
                      Color optionBorderColor = const Color(0xFFE2E8F0);
                      Color optionBgColor = Colors.white;
                      if (isSelected) {
                        optionBorderColor = _accentColor;
                        optionBgColor = _accentColor.withValues(alpha: 0.05);
                      }
                      if (isSubmitted) {
                        if (optIdx == correctIndex) {
                          optionBorderColor = const Color(0xFF10B981);
                          optionBgColor = const Color(0xFFECFDF5);
                        } else if (isSelected) {
                          optionBorderColor = Colors.redAccent;
                          optionBgColor = const Color(0xFFFEF2F2);
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: isSubmitted
                              ? null
                              : () {
                                  setModalState(() {
                                    selectedAnswer = optIdx;
                                  });
                                },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: optionBgColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: optionBorderColor, width: isSelected ? 2.0 : 1.2),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? _accentColor : Colors.white,
                                    border: Border.all(
                                      color: isSelected ? _accentColor : const Color(0xFFCBD5E1),
                                      width: 1.5,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: isSelected
                                      ? const Icon(Icons.check, color: Colors.white, size: 12)
                                      : Text(
                                          String.fromCharCode(65 + optIdx),
                                          style: GoogleFonts.fredoka(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    state.translate(optText),
                                    style: GoogleFonts.outfit(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: AdyapanTheme.textMain,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 12),

                    // Submitted Feedback
                    if (isSubmitted) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isCorrect ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCorrect ? const Color(0xFFA7F3D0) : const Color(0xFFFECDD3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isCorrect ? '🎉' : '❌', style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isCorrect 
                                        ? state.translate("Correct Answer!") 
                                        : state.translate("Try Again!"),
                                    style: GoogleFonts.fredoka(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isCorrect ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    state.translate(isCorrect ? motivation : "Double check the options above and try again!"),
                                    style: GoogleFonts.outfit(
                                      fontSize: 11.5,
                                      color: isCorrect ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Bottom Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: selectedAnswer == null
                            ? null
                            : () {
                                if (!isSubmitted) {
                                  setModalState(() {
                                    isSubmitted = true;
                                  });
                                } else {
                                  if (isCorrect) {
                                    // Mark module as complete!
                                    final previouslyCompleted = _moduleChecked.where((v) => v).length;
                                    setState(() {
                                      _moduleChecked[index] = true;
                                    });
                                    final nowCompleted = _moduleChecked.where((v) => v).length;
                                    final allCompleted = nowCompleted == _moduleChecked.length;
                                    
                                    Navigator.pop(modalCtx);
                                    
                                    if (allCompleted && previouslyCompleted < _moduleChecked.length) {
                                      state.addXp(150);
                                      showDialog(
                                        context: this.context,
                                        barrierDismissible: false,
                                        builder: (dialogCtx) => Dialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                                          elevation: 10,
                                          child: Container(
                                            padding: const EdgeInsets.all(24),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(28),
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text('🎉🏆👑', style: TextStyle(fontSize: 48)),
                                                const SizedBox(height: 16),
                                                Text(
                                                  state.translate("SKILL MASTERED!"),
                                                  style: GoogleFonts.fredoka(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                    letterSpacing: 1.0,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  state.translate("Outstanding work! You have successfully mastered all modules of this skill and earned a massive Mastery Bonus!"),
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 13,
                                                    color: Colors.white.withOpacity(0.9),
                                                    height: 1.5,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 20),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(18),
                                                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.flash_on_rounded, color: Colors.amberAccent, size: 24),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        "+150 XP ${state.translate("Bonus Earned!")}",
                                                        style: GoogleFonts.fredoka(
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 24),
                                                SizedBox(
                                                  width: double.infinity,
                                                  height: 48,
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.pop(dialogCtx);
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.white,
                                                      foregroundColor: const Color(0xFF4F46E5),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                      elevation: 0,
                                                    ),
                                                    child: Text(
                                                      state.translate("Awesome! 🚀"),
                                                      style: GoogleFonts.fredoka(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '🌟 ' + state.translate("Module mastered! Complete all modules to earn 150 Mastery XP!"),
                                            style: GoogleFonts.fredoka(color: Colors.white, fontSize: 13),
                                          ),
                                          backgroundColor: const Color(0xFF10B981),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        ),
                                      );
                                    }
                                  } else {
                                    // Reset to try again
                                    setModalState(() {
                                      selectedAnswer = null;
                                      isSubmitted = false;
                                    });
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSubmitted && !isCorrect ? Colors.orangeAccent : _accentColor,
                          disabledBackgroundColor: const Color(0xFFE2E8F0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Text(
                          !isSubmitted
                              ? state.translate("Submit Answer")
                              : isCorrect
                                  ? state.translate("Complete Module ✅")
                                  : state.translate("Retry Quiz"),
                          style: GoogleFonts.fredoka(
                            color: selectedAnswer == null ? const Color(0xFF94A3B8) : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
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

  void _openChapterDetailPreview(String chapter) {
    final state = Provider.of<AppState>(context, listen: false);
    final accentColor = _accentColor;
    
    // Parse chapter number and title
    String chapterBadge = "PRACTICAL LAB";
    String chapterTitle = chapter;
    if (chapter.toLowerCase().startsWith('chapter')) {
      final parts = chapter.split(':');
      if (parts.length > 1) {
        chapterBadge = parts[0].toUpperCase();
        chapterTitle = parts.sublist(1).join(':').trim();
      }
    } else if (chapter.toLowerCase().startsWith('interactive practice')) {
      final parts = chapter.split(':');
      if (parts.length > 1) {
        chapterBadge = "PRACTICE LAB";
        chapterTitle = parts.sublist(1).join(':').trim();
      }
    } else if (chapter.toLowerCase().startsWith('practical lab')) {
      final parts = chapter.split(':');
      if (parts.length > 1) {
        chapterBadge = "PRACTICAL LAB";
        chapterTitle = parts.sublist(1).join(':').trim();
      }
    } else if (chapter.toLowerCase().startsWith('project')) {
      final parts = chapter.split(':');
      if (parts.length > 1) {
        chapterBadge = "PRACTICAL LAB";
        chapterTitle = parts.sublist(1).join(':').trim();
      }
    }

    // Dynamic topic details generator
    final clean = chapter.toLowerCase();
    String desc = "In this session, you will explore the foundational principles of this module. Engage in active classroom smartboard simulations, practice real-world problem-solving, and complete diagnostic worksheets designed by specialists.";
    List<String> subtopics = ["Key core concepts & applications", "Interactive classroom simulations", "Diagnostic reviews & diagnostic checkpoints"];
    String duration = "⏱️ 45 Mins Focus Session";

    if (clean.contains('logic') || clean.contains('flowchart')) {
      desc = "Learn how to structure logical step-by-step algorithms. Master computational sequence design, terminal structures, flowchart loops, and conditional decision logic paths.";
      subtopics = ["Logic Sequence Terminals", "Decision Diamonds & Paths", "Loop Condition Integrations", "Flowchart Debugging Drills"];
      duration = "⏱️ 40 Mins Algorithmic Lab";
    } else if (clean.contains('variable') || clean.contains('data type') || clean.contains('memory')) {
      desc = "Discover how computers store and allocate values in memory. Explore integer values, floating-point decimals, alphanumeric strings, booleans, and RAM storage mechanics.";
      subtopics = ["Primitive Variables & Allocations", "Dynamic Data Sizing", "Constants & Assignments", "RAM Data Operations"];
      duration = "⏱️ 45 Mins Coding Workspace";
    } else if (clean.contains('loop') || clean.contains('array') || clean.contains('conditional')) {
      desc = "Understand automated repeating algorithms. Learn how to loop through arrays, apply break/continue rules, and run multi-tier conditional blocks.";
      subtopics = ["For & While Loop Execution", "Array Index Slices", "Multi-Tier Conditional Checks", "Index Boundary Security"];
      duration = "⏱️ 50 Mins Logic Workshop";
    } else if (clean.contains('database') || clean.contains('sql') || clean.contains('query')) {
      desc = "Master the global key to databases. Design table structures, relate tables using primary/foreign keys, and compose efficient SELECT filters to extract records.";
      subtopics = ["Relational Table Structures", "Primary vs Foreign Keys", "SQL SELECT & WHERE Queries", "Data Sort & Limit Constraints"];
      duration = "⏱️ 55 Mins Database Sandbox";
    } else if (clean.contains('stage fear') || clean.contains('open-mic') || clean.contains('public speaking')) {
      desc = "Overcome stage anxiety using simple visual anchors. Design engaging introductory hooks, modulate your voice speed/pitch, and capture any audience from the first word.";
      subtopics = ["Anxiety Control Anchor Points", "Interactive Speech Hook Styles", "Posture & Body Language Guides", "Impression Building Rules"];
      duration = "⏱️ 40 Mins Auditory Session";
    } else if (clean.contains('voice') || clean.contains('articulation') || clean.contains('modulation')) {
      desc = "Shape your leadership profile by refining voice projection. Master tone control, emotional styling, and adding 2-second silent pauses before major punchlines.";
      subtopics = ["Pitch & Tone Slices", "Pacing & Speech Rhythms", "Adding Strategic Vocal Pauses", "Correct Phonic Pronunciations"];
      duration = "⏱️ 45 Mins Presentation Studio";
    } else if (clean.contains('debating') || clean.contains('parliamentary') || clean.contains('format')) {
      desc = "Learn democratic rules of engagement. Master British Parliamentary debating formats, construct convincing logical refutations, and present Points of Information (POIs).";
      subtopics = ["Debate Timing & Speaker Roles", "Points of Information (POIs) Timing", "Constructive Argument Formats", "Refutation Logic Maps"];
      duration = "⏱️ 50 Mins Debate Tournament";
    } else if (clean.contains('mun') || clean.contains('un delegate') || clean.contains('protocol')) {
      desc = "Step into international diplomacy. Represent your assigned country's foreign policy guidelines, write resolutions, and negotiate with foreign delegates.";
      subtopics = ["UN Moderated Caucus Formats", "Bilateral Negotiating Tactics", "Country Policy Stance Research", "Diplomatic Speech Etiquettes"];
      duration = "⏱️ 60 Mins Diplomacy Lab";
    } else if (clean.contains('budget') || clean.contains('income') || clean.contains('household')) {
      desc = "Build lifetime financial resilience early. Learn how to divide income using the standard 50/30/20 rule: allocating 50% for Needs, 30% for Wants, and 20% for early Savings.";
      subtopics = ["Needs vs Wants Categorization", "50/30/20 Budget Allocations", "Expense Tracking Dashboards", "Personal Savings Benchmarks"];
      duration = "⏱️ 45 Mins Wealth Foundation";
    } else if (clean.contains('banking') || clean.contains('savings') || clean.contains('card')) {
      desc = "Demystify modern commercial banking systems. Learn about savings vs current accounts, debit card security parameters, and how online bank transfers operate.";
      subtopics = ["Account Skeletons & Sizing", "OTP & Card Security Rules", "Interest Accrual Basics", "Safe Online Transaction Flow"];
      duration = "⏱️ 40 Mins Banking Simulation";
    } else if (clean.contains('compound') || clean.contains('interest') || clean.contains('compounding')) {
      desc = "Understand the exponential multiplier of wealth. Master simple vs compound interest mathematical models, compound calculations, and the rule of 72.";
      subtopics = ["Compounding Formula Expansions", "Simple vs Compound Growth Lines", "The Rule of 72 Sizing Hacks", "Patience and Exponential Scales"];
      duration = "⏱️ 50 Mins Financial Math Sandbox";
    } else if (clean.contains('invest') || clean.contains('stock') || clean.contains('mutual') || clean.contains('share')) {
      desc = "Learn how corporations raise capital and build value. Understand stock markets, indices, fractional business ownership, and mutual fund risk diversification.";
      subtopics = ["Shares & Public Trading Skeletons", "Stock Exchanges & Operations", "Mutual Funds Risk Splits", "Asset Diversification Guidelines"];
      duration = "⏱️ 55 Mins Stock Market Lab";
    } else if (clean.contains('html') || clean.contains('nested') || clean.contains('tags')) {
      desc = "Code structural outlines for responsive web designs. Master structural HTML tags, nesting rules, link parameters, and content tags.";
      subtopics = ["Root, Head & Body Nestings", "Main Headers & Formatting Tags", "Hyperlinks & Image Anchors", "Form Fields & Input Skeletons"];
      duration = "⏱️ 45 Mins Web Design Sandbox";
    } else if (clean.contains('css') || clean.contains('padding') || clean.contains('margin') || clean.contains('style')) {
      desc = "Decorate structural skeletal layouts with vibrant styling. Master class selectors, padding vs margin spacings, border styling, and responsive backgrounds.";
      subtopics = ["CSS Class & ID Selectors", "Box Model: Padding & Margin rules", "Harmonized Color Gradients", "Flexbox Symmetrical Grids"];
      duration = "⏱️ 50 Mins CSS Stylist Studio";
    } else if (clean.contains('flexbox') || clean.contains('grid') || clean.contains('layout')) {
      desc = "Design highly responsive and premium symmetrical grids. Learn flexbox direction axes, element alignments, grid ratios, and flexible columns.";
      subtopics = ["Flex Direction & Axes Slices", "Justify Content & Align Items", "Responsive Sizing Fractions", "Fluid Grid System Rules"];
      duration = "⏱️ 45 Mins Layout Workshop";
    } else if (clean.contains('german') || clean.contains('french') || clean.contains('language') || clean.contains('greeting')) {
      desc = "Attain conversational confidence in a new global language. Practice everyday greetings, cardinal numbers, Masculine/Feminine articles, and cafe dialogs.";
      subtopics = ["Common Polite Everyday Greetings", "Nouns & Gender Slices", "Food & Shopping Scenario Dialogs", "Pronunciation Phonic Rules"];
      duration = "⏱️ 40 Mins Language Studio";
    } else if (clean.contains('color wheel') || clean.contains('palette') || clean.contains('art')) {
      desc = "Master color wheel science to construct visual interest. Explore primary, secondary, and complementary color schemes to create premium high-contrast artwork.";
      subtopics = ["Color Matching Wheel Systems", "Complementary Contrast Layouts", "Analogous Balance Guidelines", "Aesthetic Palette Ratios"];
      duration = "⏱️ 45 Mins Art Gallery Studio";
    } else if (clean.contains('pencil') || clean.contains('shading') || clean.contains('sketch')) {
      desc = "Elevate physical sketching techniques. Understand lead pencil grades (HB, 2B, 4B, 6B) and apply realistic directional shading gradients to 3D drawings.";
      subtopics = ["Pencil Lead Hardness Grades", "Directional Shadowing Ratios", "Perspective Line Alignments", "Texture & Contrast Building"];
      duration = "⏱️ 50 Mins Fine Arts Studio";
    } else if (clean.contains('prompt engineering') || clean.contains('prompt') || clean.contains('ai')) {
      desc = "Structure optimal text prompts to instruct Generative AI models. Learn the Role-Task-Context structural guidelines and iterative loop corrections.";
      subtopics = ["Role-Task-Context Prompts", "Setting Context Parameters", "Iterative Prompts Debugging", "Ethical AI Citation Rules"];
      duration = "⏱️ 50 Mins Prompt Lab";
    } else if (clean.contains('automation') || clean.contains('zapier') || clean.contains('workflow')) {
      desc = "Link separate applications to trigger background routines automatically. Setup Zapier workflows, coordinate triggers, actions, and loop filters.";
      subtopics = ["Trigger-Action Loops Setup", "Application API Integrations", "Data Mapping Columns", "Multi-Step Workflow Automations"];
      duration = "⏱️ 55 Mins Automation Sandbox";
    } else if (clean.contains('practical lab') || clean.contains('practice:') || clean.contains('project:')) {
      desc = "Apply every lesson learned to execute a real-world sandbox challenge! Build prototypes, present findings, and showcase execution proof to earn top standing.";
      subtopics = ["Challenge Blueprint Analysis", "Hands-on Sandbox Execution", "Prototype Review Checklist", "Final Pitch Presentation Drills"];
      duration = "⏱️ 60 Mins Practical Sandbox Challenge";
    } else {
      // Dynamic subtitle generation for others
      final words = chapterTitle.split(' ');
      if (words.length > 2) {
        subtopics = [
          "Foundational introduction to ${words.sublist(0, 2).join(' ')}",
          "Interactive practical scenario simulations",
          "Diagnostic reviews & custom self-testing worksheets"
        ];
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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

              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  chapterBadge,
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                state.translate(chapterTitle),
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),

              // Duration Badge
              Wrap(
                spacing: 4,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(Icons.timer_outlined, size: 13, color: Color(0xFF64748B)),
                  Text(
                    duration.replaceAll(RegExp(r'[^\x00-\x7F]'), '').trim(),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const Text('•', style: TextStyle(color: Color(0xFF94A3B8))),
                  Text(
                    state.translate("Interactive Lecture Summary"),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: Color(0xFFF1F5F9)),

              // Objective description
              Text(
                state.translate("What we are going to learn:"),
                style: GoogleFonts.fredoka(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                state.translate(desc),
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  color: const Color(0xFF475569),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              // Subtopics checklist
              Text(
                state.translate("Target Lecture Checklist:"),
                style: GoogleFonts.fredoka(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              ...subtopics.map((topic) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 10),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          state.translate(topic),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 20),

              // Start button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          state.translate("Lecture guidelines unlocked! Open Smartboard Live Radar to attend."),
                          style: GoogleFonts.fredoka(color: Colors.white, fontSize: 13),
                        ),
                        backgroundColor: accentColor,
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
                    state.translate("Start Studying Module"),
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

  @override
  Widget build(BuildContext context) {
    final skill = widget.skill;
    final state = Provider.of<AppState>(context);
    final emoji = skill['emoji'] as String? ?? '📚';
    final title = skill['title'] as String? ?? '';
    final desc = skill['desc'] as String? ?? '';
    final benefits = skill['benefits'] as String? ?? '';
    final modules = skill['modules'] as List? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: FadeTransition(
        opacity: _fadeIn,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ─── Hero App Bar ───────────────────────────────────────
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              elevation: 0,
              backgroundColor: _accentColor,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _accentColor,
                        _accentColor.withValues(alpha: 0.75),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative circles
                      Positioned(
                        top: -40,
                        right: -40,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -20,
                        left: -30,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      // Content
                      Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 60, bottom: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Icon in white circle
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.18),
                                  border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.35),
                                      width: 2),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  _getSkillIcon(title),
                                  color: Colors.white,
                                  size: 38,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  state.translate(title),
                                  style: GoogleFonts.fredoka(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  state.studentClass,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
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
            ),

            // ─── Body ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── SKILL OVERVIEW ──
                    _sectionLabel('SKILL OVERVIEW'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _accentColor.withValues(alpha: 0.15),
                            width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: _accentColor.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Text(
                        state.translate(desc),
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: AdyapanTheme.textMain,
                          fontWeight: FontWeight.w500,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── SYLLABUS & CURRICULUM ──
                    _sectionLabel('COURSE SYLLABUS & CURRICULUM'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _accentColor.withValues(alpha: 0.15),
                            width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: _accentColor.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Syllabus designed by specialists to build active, hands-on, and real-world skills.',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AdyapanTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._getSkillSyllabus(title).map((chapter) {
                            final isProj = chapter.startsWith('Project:') ||
                                chapter.startsWith('Practical Lab:') ||
                                chapter.startsWith('Interactive Practice:');
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () => _openChapterDetailPreview(chapter),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isProj ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isProj ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      isProj
                                          ? const Icon(Icons.stars_rounded, color: Color(0xFF10B981), size: 16)
                                          : Icon(Icons.radio_button_checked_rounded, color: _accentColor, size: 10),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          state.translate(chapter),
                                          style: GoogleFonts.outfit(
                                            fontSize: 12.5,
                                            fontWeight: isProj ? FontWeight.bold : FontWeight.w500,
                                            color: isProj ? const Color(0xFF10B981) : AdyapanTheme.textMain,
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF94A3B8)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── BENEFITS ──
                    _sectionLabel('ACADEMIC & FUTURE BENEFITS'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFA7F3D0), width: 1.5),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFD1FAE5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              color: Color(0xFF059669),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              state.translate(benefits),
                              style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: const Color(0xFF065F46),
                                  fontWeight: FontWeight.w600,
                                  height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── LIVE SESSION RADAR ──
                    if (_isLiveClassScheduledForSkill()) ...[
                      _sectionLabel('SMARTBOARD LIVE RADAR'),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withOpacity(0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            )
                          ],
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LiveStreamClassPage(
                                  teacherName: 'Mr. Kapoor (Specialist)',
                                  topicName: '🔴 LIVE: Smartboard presentation on ${state.translate(title)}',
                                  onClassFinished: (watchedMinutes) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '🎉 ' + state.translate("Live Skill Session Attendance secured! Great job!"),
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
                          },
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.sensors_rounded, color: Colors.white, size: 22),
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
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'LIVE NOW',
                                            style: GoogleFonts.outfit(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFFDC2626),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Interactive Lab Session',
                                          style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white.withOpacity(0.9),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Join Live Class Stream',
                                      style: GoogleFonts.fredoka(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Learn active project examples with Mr. Kapoor directly on smartboard.',
                                      style: GoogleFonts.outfit(
                                        fontSize: 10.5,
                                        color: Colors.white.withOpacity(0.9),
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── MODULES CHECKLIST ──
                    _sectionLabel('STUDY MODULES CHECKLIST'),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _accentColor.withValues(alpha: 0.15),
                            width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: _accentColor.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(4),
                        itemCount: modules.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: AdyapanTheme.glassBorder,
                          indent: 60,
                          endIndent: 16,
                        ),
                        itemBuilder: (ctx, i) {
                          final done = _moduleChecked[i];
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              if (done) {
                                setState(() {
                                  _moduleChecked[i] = false;
                                });
                              } else {
                                _openActiveStudyConsole(i, modules[i] as String);
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: done
                                    ? _lightBg
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: done
                                          ? _accentColor
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: done
                                            ? _accentColor
                                            : AdyapanTheme.textMuted
                                                .withValues(alpha: 0.4),
                                        width: 2,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: done
                                        ? const Icon(Icons.check_rounded,
                                            color: Colors.white, size: 14)
                                        : Text(
                                            '${i + 1}',
                                            style: GoogleFonts.fredoka(
                                              fontSize: 11,
                                              color: AdyapanTheme.textMuted,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      state.translate(
                                          modules[i] as String),
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: done
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: done
                                            ? _accentColor
                                            : AdyapanTheme.textMain,
                                        decoration: done
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                  if (done)
                                    const Icon(Icons.check_circle_rounded,
                                        color: Color(0xFF10B981), size: 18),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── PROGRESS CHIP ──
                    StatefulBuilder(builder: (ctx, setChipState) {
                      final done =
                          _moduleChecked.where((v) => v).length;
                      final total = _moduleChecked.length;
                      final pct = total == 0 ? 0.0 : done / total;
                      return Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _accentColor,
                              _accentColor.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Your Progress',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '$done / $total modules',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color:
                                        Colors.white.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 8,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.25),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              pct == 0
                                  ? 'Tap modules above to track progress'
                                  : pct == 1.0
                                      ? '🎉 Skill Mastered! Excellent work!'
                                      : '${(pct * 100).round()}% completed — Keep going!',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color:
                                    Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 32),

                    // ── ENROLL BUTTON ──
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '🚀 Starting: ${state.translate(title)}',
                                style: GoogleFonts.fredoka(
                                    color: Colors.white, fontSize: 13),
                              ),
                              backgroundColor: _accentColor,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          shadowColor: _accentColor.withValues(alpha: 0.4),
                        ),
                        icon: const Icon(Icons.rocket_launch_rounded,
                            size: 18),
                        label: Text(
                          'Start Learning',
                          style: GoogleFonts.fredoka(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AdyapanTheme.textMuted,
        letterSpacing: 1.0,
      ),
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
