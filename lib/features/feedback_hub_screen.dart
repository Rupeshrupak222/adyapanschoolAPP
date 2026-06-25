import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/app_state.dart';

class FeedbackHubScreen extends StatefulWidget {
  const FeedbackHubScreen({Key? key}) : super(key: key);

  @override
  State<FeedbackHubScreen> createState() => _FeedbackHubScreenState();
}

class _FeedbackHubScreenState extends State<FeedbackHubScreen> {
  // Manual feedback entry form state
  String _selectedTeacher = 'Mrs. Sharma';
  String _selectedSubject = 'Mathematics';
  double _selectedRating = 5.0;
  final List<String> _selectedTags = [];
  final TextEditingController _commentController = TextEditingController();

  final List<Map<String, String>> _availableTeachers = const [
    {'name': 'Mrs. Sharma', 'subject': 'Mathematics'},
    {'name': 'Mr. Verma', 'subject': 'Science'},
    {'name': 'Miss Anjali', 'subject': 'English'},
    {'name': 'Mr. Kapoor', 'subject': 'Social Studies'},
  ];

  final List<String> _feedbackTags = const [
    'Clear Explanations',
    'Interactive Smartboard',
    'Fun Activities',
    'Very Engaging',
    'Doubt Solved',
    'Too Fast',
    'Needs More Examples',
  ];

  // Modern Vector Icons corresponding to ratings 1 to 5
  IconData _getRatingIcon(double rating) {
    if (rating <= 1) return Icons.sentiment_very_dissatisfied_rounded;
    if (rating <= 2) return Icons.sentiment_dissatisfied_rounded;
    if (rating <= 3) return Icons.sentiment_neutral_rounded;
    if (rating <= 4) return Icons.sentiment_satisfied_rounded;
    return Icons.sentiment_very_satisfied_rounded;
  }

  Color _getRatingColor(double rating) {
    if (rating <= 1) return Colors.redAccent;
    if (rating <= 2) return Colors.orangeAccent;
    if (rating <= 3) return Colors.amber;
    if (rating <= 4) return Colors.blueAccent;
    return const Color(0xFF10B981);
  }

  String _getRatingLabel(double rating) {
    if (rating <= 1) return 'Boring / Sleepy';
    if (rating <= 2) return 'Just Okay';
    if (rating <= 3) return 'Good / Clear';
    if (rating <= 4) return 'Super Engaging!';
    return 'Absolutely Next-Level!';
  }

  void _submitManualFeedback(AppState state) {
    if (_selectedTags.isEmpty && _commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select at least one feedback tag or write a short note!',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.amber[700],
        ),
      );
      return;
    }

    state.addTeacherFeedback(
      teacherName: _selectedTeacher.split(' (')[0],
      subjectName: _selectedSubject,
      lectureTitle: 'Classroom Session',
      rating: _selectedRating,
      tags: List.from(_selectedTags),
      comments: _commentController.text.trim(),
    );

    // Reset Form
    setState(() {
      _selectedRating = 5.0;
      _selectedTags.clear();
      _commentController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Feedback logged! Thank you for helping us improve.',
                style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        backgroundColor: AdyapanTheme.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final feedbacks = state.teacherFeedbacks.reversed.toList(); // Newest first

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          'Teacher Feedback Hub',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
      ),
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
        child: Column(
          children: [
            // Top Tab Toggle (Submit Feedback vs History Logs)
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        labelColor: AdyapanTheme.blueAccent,
                        unselectedLabelColor: const Color(0xFF64748B),
                        labelStyle: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 13),
                        indicatorColor: AdyapanTheme.blueAccent,
                        indicatorWeight: 3,
                        tabs: [
                          Tab(text: state.translate('Submit New Feedback'), icon: const Icon(Icons.rate_review_rounded, size: 20)),
                          Tab(text: state.translate('Feedback History'), icon: const Icon(Icons.history_edu_rounded, size: 20)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Tab 1: Feedback Form
                          SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.all(20),
                            child: _buildFeedbackForm(state),
                          ),
                          
                          // Tab 2: Feedback History logs
                          _buildHistoryTab(feedbacks),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackForm(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Intro Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.82),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.15)),
          ),
          child: Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Voice Matters!',
                      style: GoogleFonts.fredoka(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rate recorded or live sessions. All ratings are securely logged for quality improvement.',
                      style: GoogleFonts.outfit(fontSize: 11, color: AdyapanTheme.textSub),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Select Teacher & Subject Row
        Text(
          'Select Class Teacher',
          style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedTeacher,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
              onChanged: (String? val) {
                if (val != null) {
                  final teacherData = _availableTeachers.firstWhere((t) => t['name'] == val);
                  setState(() {
                    _selectedTeacher = val;
                    _selectedSubject = teacherData['subject']!;
                  });
                }
              },
              items: _availableTeachers.map((t) {
                final displayVal = '${t['name']} (${t['subject']})';
                return DropdownMenuItem<String>(
                  value: t['name'],
                  child: Text(
                    displayVal,
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Interactive Rating Scale (Emoji Free!)
        Text(
          'How was the teaching speed and style?',
          style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)),
        ),
        const SizedBox(height: 14),
        Center(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                // Big Interactive Rating Icon
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _getRatingIcon(_selectedRating),
                    color: _getRatingColor(_selectedRating),
                    size: 64,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _getRatingLabel(_selectedRating),
                  style: GoogleFonts.fredoka(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AdyapanTheme.blueAccent,
                  ),
                ),
                const SizedBox(height: 14),
                // Slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AdyapanTheme.blueAccent.withOpacity(0.8),
                    inactiveTrackColor: const Color(0xFFF1F5F9),
                    thumbColor: AdyapanTheme.blueAccent,
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  ),
                  child: Slider(
                    value: _selectedRating,
                    min: 1.0,
                    max: 5.0,
                    divisions: 4,
                    onChanged: (val) {
                      setState(() {
                        _selectedRating = val;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(5, (idx) {
                      return Text(
                        '${idx + 1}',
                        style: GoogleFonts.fredoka(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: (idx + 1) == _selectedRating.toInt()
                              ? AdyapanTheme.blueAccent
                              : const Color(0xFF94A3B8),
                        ),
                      );
                    }),
                  ),
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Selectable Feedback Quick Tags
        Text(
          'Select Feedback Tags',
          style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _feedbackTags.map((tag) {
            bool isSelected = _selectedTags.contains(tag);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedTags.remove(tag);
                  } else {
                    _selectedTags.add(tag);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AdyapanTheme.blueAccent.withOpacity(0.08) : Colors.white,
                  border: Border.all(
                    color: isSelected ? AdyapanTheme.blueAccent : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  tag,
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AdyapanTheme.blueAccent : const Color(0xFF475569),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Optional Written Message
        Text(
          'Write a Message (Optional)',
          style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _commentController,
          maxLines: 3,
          style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF1E293B), fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'Share doubts, suggestions, or praise for your teacher here...',
            hintStyle: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF94A3B8)),
            fillColor: Colors.white,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AdyapanTheme.blueAccent, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Submit Button
        GestureDetector(
          onTap: () => _submitManualFeedback(state),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Submit Feedback to Admin',
                  style: GoogleFonts.fredoka(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildHistoryTab(List<Map<String, dynamic>> feedbacks) {
    if (feedbacks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_edu_rounded, color: Color(0xFF64748B), size: 48),
            const SizedBox(height: 14),
            Text(
              'No feedback logged yet!',
              style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 4),
            Text(
              'Your class evaluations will appear here.',
              style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: feedbacks.length,
      itemBuilder: (context, idx) {
        final fb = feedbacks[idx];
        final teacher = fb['teacherName'] as String;
        final subject = fb['subjectName'] as String;
        final source = fb['lectureTitle'] as String;
        final rating = (fb['rating'] as num).toDouble();
        final tags = fb['tags'] as List? ?? [];
        final comments = fb['comments'] as String? ?? '';
        final timestamp = DateTime.tryParse(fb['timestamp'] as String? ?? '') ?? DateTime.now();

        final dateStr = '${timestamp.day}/${timestamp.month}/${timestamp.year} • ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';

        return Padding(
          padding: const EdgeInsets.only(bottom: 14.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Teacher Name & Modern Rating Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            teacher,
                            style: GoogleFonts.fredoka(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            '$subject • $source',
                            style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF64748B), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getRatingIcon(rating),
                            color: _getRatingColor(rating),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${rating.toInt()}/5',
                            style: GoogleFonts.fredoka(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E3A8A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Tags
                if (tags.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tags.map((t) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          t as String,
                          style: GoogleFonts.outfit(fontSize: 9.5, color: const Color(0xFF475569), fontWeight: FontWeight.w600),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Comments
                if (comments.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEFF6FF)),
                    ),
                    child: Text(
                      '"$comments"',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Timestamp
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cloud_done_rounded, color: Color(0xFF10B981), size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'Synced to Admin DB',
                          style: GoogleFonts.outfit(fontSize: 9, color: const Color(0xFF10B981), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Text(
                      dateStr,
                      style: GoogleFonts.outfit(fontSize: 9, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 🌟 REUSABLE POP-UP MODAL TRIGGER FOR RATINGS AFTER VIDEOS OR LECTURES
class VideoLectureFeedbackModal extends StatefulWidget {
  final String videoTitle;
  final String teacherName;

  const VideoLectureFeedbackModal({
    Key? key,
    required this.videoTitle,
    required this.teacherName,
  }) : super(key: key);

  static void show(BuildContext context, String videoTitle, String teacherName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VideoLectureFeedbackModal(
        videoTitle: videoTitle,
        teacherName: teacherName,
      ),
    );
  }

  @override
  State<VideoLectureFeedbackModal> createState() => _VideoLectureFeedbackModalState();
}

class _VideoLectureFeedbackModalState extends State<VideoLectureFeedbackModal> {
  double _rating = 5.0;
  final List<String> _selectedTags = [];
  final TextEditingController _commentController = TextEditingController();

  final List<String> _quickTags = const [
    'Amazing Explanation',
    'Interactive & Fun',
    'Clear Pronunciation',
    'Too Fast',
    'Difficult Words',
  ];

  IconData _getRatingIcon(double rating) {
    if (rating <= 1) return Icons.sentiment_very_dissatisfied_rounded;
    if (rating <= 2) return Icons.sentiment_dissatisfied_rounded;
    if (rating <= 3) return Icons.sentiment_neutral_rounded;
    if (rating <= 4) return Icons.sentiment_satisfied_rounded;
    return Icons.sentiment_very_satisfied_rounded;
  }

  Color _getRatingColor(double rating) {
    if (rating <= 1) return Colors.redAccent;
    if (rating <= 2) return Colors.orangeAccent;
    if (rating <= 3) return Colors.amber;
    if (rating <= 4) return Colors.blueAccent;
    return const Color(0xFF10B981);
  }

  String _getRatingLabel(double rating) {
    if (rating <= 1) return 'Boring / Slow';
    if (rating <= 2) return 'Just Okay';
    if (rating <= 3) return 'Clear & Good';
    if (rating <= 4) return 'Super Engaging!';
    return 'Next-Level Video!';
  }

  void _submitFeedback(AppState state) {
    state.addTeacherFeedback(
      teacherName: widget.teacherName,
      subjectName: _getSubjectFromTopic(widget.videoTitle),
      lectureTitle: widget.videoTitle,
      rating: _rating,
      tags: _selectedTags,
      comments: _commentController.text.trim(),
    );

    Navigator.pop(context); // Close bottom sheet

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Review synced to Admin app. Thank you! (+25 XP)',
                style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        backgroundColor: AdyapanTheme.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getSubjectFromTopic(String title) {
    if (title.contains('Math')) return 'Mathematics';
    if (title.contains('Science')) return 'Science';
    if (title.contains('English')) return 'English';
    if (title.contains('Social')) return 'Social Studies';
    return 'Mathematics';
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Container(
      padding: EdgeInsets.only(
        top: 14,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Center drag handle
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header Info
            Row(
              children: [
                const Icon(Icons.class_rounded, color: Color(0xFF2563EB), size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Class Lecture Feedback',
                        style: GoogleFonts.fredoka(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                      Text(
                        'Rate ${widget.teacherName}\'s speed & explanation style',
                        style: GoogleFonts.outfit(fontSize: 11, color: AdyapanTheme.textSub, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: Color(0xFFE2E8F0)),

            if (!isKeyboardOpen) ...[
              // Big Sentiment Rating Icon Selector
              Center(
                child: Icon(
                  _getRatingIcon(_rating),
                  color: _getRatingColor(_rating),
                  size: 64,
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  _getRatingLabel(_rating),
                  style: GoogleFonts.fredoka(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AdyapanTheme.blueAccent,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Rating slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AdyapanTheme.blueAccent.withOpacity(0.8),
                  inactiveTrackColor: const Color(0xFFF1F5F9),
                  thumbColor: AdyapanTheme.blueAccent,
                  trackHeight: 6,
                ),
                child: Slider(
                  value: _rating,
                  min: 1.0,
                  max: 5.0,
                  divisions: 4,
                  onChanged: (val) {
                    setState(() {
                      _rating = val;
                    });
                  },
                ),
              ),
              const SizedBox(height: 14),

              // Quick tags
              Text(
                'What did you like the most?',
                style: GoogleFonts.fredoka(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _quickTags.map((tag) {
                  bool isSelected = _selectedTags.contains(tag);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedTags.remove(tag);
                        } else {
                          _selectedTags.add(tag);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AdyapanTheme.blueAccent.withOpacity(0.08) : Colors.white,
                        border: Border.all(
                          color: isSelected ? AdyapanTheme.blueAccent : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AdyapanTheme.blueAccent : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
            ],

            // Input field
            TextField(
              controller: _commentController,
              maxLines: 2,
              style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF1E293B), fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Any message for the teacher or principal? (Optional)',
                hintStyle: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8)),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AdyapanTheme.blueAccent, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Submit Button
            GestureDetector(
              onTap: () => _submitFeedback(state),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  'Submit Evaluation to Admin',
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
