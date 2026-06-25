import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../core/app_state.dart';

class NotesLibraryScreen extends StatefulWidget {
  const NotesLibraryScreen({Key? key}) : super(key: key);

  @override
  State<NotesLibraryScreen> createState() => _NotesLibraryScreenState();
}

class _NotesLibraryScreenState extends State<NotesLibraryScreen> {
  String _selectedFilter = 'All';
  final Map<int, double> _downloadProgress = {};
  final Map<int, bool> _isDownloaded = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).syncHomeworkAndNotesFromDb();
    });
  }

  final List<String> _subjects = [
    'All',
    'Mathematics',
    'Science',
    'English',
    'Computer Science',
    'Social Studies',
  ];

  Color _subjectColor(String subject) {
    if (subject.contains('Math')) return const Color(0xFF2563EB);
    if (subject.contains('Science')) return const Color(0xFF10B981);
    if (subject.contains('English')) return const Color(0xFF8B5CF6);
    if (subject.contains('Computer')) return const Color(0xFFF59E0B);
    if (subject.contains('Social')) return const Color(0xFFEF4444);
    return const Color(0xFFEC4899);
  }

  Color _subjectBg(String subject) {
    if (subject.contains('Math')) return const Color(0xFFEFF6FF);
    if (subject.contains('Science')) return const Color(0xFFECFDF5);
    if (subject.contains('English')) return const Color(0xFFF5F3FF);
    if (subject.contains('Computer')) return const Color(0xFFFFFBEB);
    if (subject.contains('Social')) return const Color(0xFFFEF2F2);
    return const Color(0xFFFDF4FF);
  }

  void _simulateDownload(int id, String fileName, AppState state) {
    if (_isDownloaded[id] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📂 Opening $fileName...'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _downloadProgress[id] = 0.0);

    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted) return false;
      setState(() {
        double current = _downloadProgress[id] ?? 0.0;
        _downloadProgress[id] = (current + 0.1).clamp(0.0, 1.0);
      });
      if ((_downloadProgress[id] ?? 0.0) >= 1.0) {
        setState(() {
          _isDownloaded[id] = true;
          _downloadProgress.remove(id);
        });
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $fileName downloaded successfully!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return false;
      }
      return true;
    });
  }

  Future<void> _openNoteFile(BuildContext context, String fileUrl, String title) async {
    if (fileUrl.startsWith('http')) {
      final uri = Uri.tryParse(fileUrl);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } else {
      final file = File(fileUrl);
      if (file.existsSync()) {
        final uri = Uri.file(fileUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open file URL: $fileUrl')),
    );
  }

  void _showNoteReader(Map<String, dynamic> note) {
    final state = Provider.of<AppState>(context, listen: false);
    final fileUrl = note['filePath'] as String? ?? '';
    final fileName = note['fileName'] as String? ?? '';
    final isImage = fileUrl.toLowerCase().endsWith('.png') ||
                    fileUrl.toLowerCase().endsWith('.jpg') ||
                    fileUrl.toLowerCase().endsWith('.jpeg') ||
                    fileName.toLowerCase().endsWith('.png') ||
                    fileName.toLowerCase().endsWith('.jpg') ||
                    fileName.toLowerCase().endsWith('.jpeg');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scroll) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFAFAFA),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle + header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(note['title'], style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain), maxLines: 2, overflow: TextOverflow.ellipsis),
                              Text('${note['pages']} pages • ${note['fileSize']}', style: GoogleFonts.outfit(fontSize: 10, color: AdyapanTheme.textMuted, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 16, color: Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // PDF "pages" content simulation
              Expanded(
                child: SingleChildScrollView(
                  controller: scroll,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('About this note', style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain)),
                            const SizedBox(height: 6),
                            Text(note['description'], style: GoogleFonts.outfit(fontSize: 12, color: AdyapanTheme.textSub, height: 1.6)),
                            const SizedBox(height: 12),
                            // Safe Wrap layout to prevent horizontal chip overflows
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _infoChip('Teacher: ${note['uploadedBy']}'),
                                _infoChip('Date: ${note['uploadedAt']}'),
                                _infoChip('Subject: ${note['subject']}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Preview (Real image if it's an image note, simulated pages if PDF)
                      Text('Preview', style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain)),
                      const SizedBox(height: 10),
                      if (isImage && fileUrl.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: fileUrl.startsWith('http')
                                ? Image.network(
                                    fileUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 40),
                                        child: Center(
                                          child: Text(
                                            state.translate('Image could not be loaded.'),
                                            style: GoogleFonts.outfit(color: Colors.grey),
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : (File(fileUrl).existsSync()
                                    ? Image.file(File(fileUrl), fit: BoxFit.contain)
                                    : Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 40),
                                        child: Center(
                                          child: Text(
                                            state.translate('Local file does not exist.'),
                                            style: GoogleFonts.outfit(color: Colors.grey),
                                          ),
                                        ),
                                      )),
                          ),
                        )
                      else
                        ...List.generate(note['pages'] > 3 ? 3 : note['pages'], (pageIndex) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Page header bar
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _subjectBg(note['subject']),
                                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                                    border: Border(bottom: BorderSide(color: _subjectColor(note['subject']).withOpacity(0.2))),
                                  ),
                                  child: Row(
                                    children: [
                                      Text('Page ${pageIndex + 1}', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: _subjectColor(note['subject']))),
                                      const Spacer(),
                                      Expanded(
                                        child: Text(note['fileName'], style: GoogleFonts.outfit(fontSize: 9, color: AdyapanTheme.textMuted), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis),
                                      ),
                                    ],
                                  ),
                                ),
                                // Simulated text lines
                                Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (pageIndex == 0) ...[
                                      Text(note['title'], style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain)),
                                      const SizedBox(height: 8),
                                    ],
                                    ...List.generate(6, (lineIndex) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Container(
                                        height: 10,
                                        width: lineIndex == 5 ? 120 : double.infinity,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    )),
                                    if (pageIndex % 2 == 0) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: _subjectBg(note['subject']),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: _subjectColor(note['subject']).withOpacity(0.2)),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text('[ Diagram / Formula Box ]', style: GoogleFonts.outfit(fontSize: 10, color: _subjectColor(note['subject']), fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      // "More pages" hint
                      if (note['pages'] > 3)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('${note['pages'] - 3} more pages — Download to read full document', style: GoogleFonts.outfit(fontSize: 11, color: AdyapanTheme.textMuted, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),

              // Download button fixed at bottom
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -4))],
                ),
                child: Consumer<AppState>(
                  builder: (context, state, _) {
                    final id = note['id'] as int;
                    final isDone = _isDownloaded[id] == true;
                    final progress = _downloadProgress[id];

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (progress != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: const Color(0xFFF1F5F9),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                              ),
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (isDone) {
                                final fileUrl = note['filePath'] as String? ?? '';
                                if (fileUrl.isNotEmpty) {
                                  _openNoteFile(context, fileUrl, note['title'] ?? 'Document');
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('No file url found for this note.')),
                                  );
                                }
                              } else {
                                _simulateDownload(id, note['fileName'], state);
                              }
                            },
                            icon: Icon(isDone ? Icons.folder_open_rounded : Icons.download_rounded, size: 18, color: Colors.white),
                            label: Text(
                              isDone ? 'Open Downloaded File' : (progress != null ? 'Downloading ${(progress * 100).toInt()}%...' : 'Download PDF (${note['fileSize']})'),
                              style: GoogleFonts.fredoka(color: Colors.white, fontSize: 14),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDone ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
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

  Widget _infoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(text, style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: AdyapanTheme.textSub)),
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note) {
    final subColor = _subjectColor(note['subject']);
    final subBg = _subjectBg(note['subject']);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: subColor.withOpacity(0.12), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: subColor.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject header stripe
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: subBg,
              width: double.infinity,
              child: Row(
                children: [
                  const Icon(Icons.folder_rounded, size: 12, color: Colors.blueAccent),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      note['subject'],
                      style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: subColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Card Body details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note['title'],
                      style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        note['description'],
                        style: GoogleFonts.outfit(fontSize: 10, color: AdyapanTheme.textSub, height: 1.3),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Card Bottom actions row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: const Color(0xFFF8FAFC),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${note['pages']} pages',
                      style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: AdyapanTheme.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _showNoteReader(note),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.2), offset: const Offset(0, 2), blurRadius: 4)],
                      ),
                      child: Text('Read', style: GoogleFonts.fredoka(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    
    // Filter logic
    final filteredNotes = state.notesList.where((n) {
      if (_selectedFilter == 'All') return true;
      return n['subject'].trim().toLowerCase().contains(_selectedFilter.trim().toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          // ── HEADER ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Learning Library',
                                style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Text(
                                'Access notes & study PDFs shared by your school',
                                style: GoogleFonts.outfit(fontSize: 10, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── FILTER CHIPS ──
          Container(
            height: 48,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _subjects.length,
              itemBuilder: (context, i) {
                final isSelected = _selectedFilter == _subjects[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      _subjects[i],
                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AdyapanTheme.textSub),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedFilter = _subjects[i]);
                    },
                    selectedColor: const Color(0xFF2563EB),
                    backgroundColor: const Color(0xFFF1F5F9),
                    elevation: 0,
                    pressElevation: 0,
                    checkmarkColor: Colors.white,
                  ),
                );
              },
            ),
          ),

          // ── NOTES GRID ──
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => state.syncHomeworkAndNotesFromDb(),
              color: const Color(0xFF2563EB),
              child: filteredNotes.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.folder_off_rounded, size: 56, color: AdyapanTheme.textMuted),
                              const SizedBox(height: 14),
                              Text('No study notes found', style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain)),
                              Text('Try selecting another subject filter', style: GoogleFonts.outfit(fontSize: 11, color: AdyapanTheme.textMuted)),
                            ],
                          ),
                        ),
                      ),
                    )
                  : GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: filteredNotes.length,
                      itemBuilder: (context, i) => _buildNoteCard(filteredNotes[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
