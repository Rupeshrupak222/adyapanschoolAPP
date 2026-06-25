import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../core/theme.dart';
import '../core/app_state.dart';

class DoubtSolverScreen extends StatefulWidget {
  const DoubtSolverScreen({Key? key}) : super(key: key);

  @override
  State<DoubtSolverScreen> createState() => _DoubtSolverScreenState();
}

class _DoubtSolverScreenState extends State<DoubtSolverScreen> {
  String activeSubject = 'Mathematics';
  final TextEditingController doubtController = TextEditingController();
  
  // Attachments State
  String selectedAttachmentType = 'None'; // 'None', 'Image', 'PDF'
  String selectedAttachmentName = '';
  String selectedAttachmentPath = '';
  
  bool isSubmitting = false;
  bool chatSimulated = false;
  List<Map<String, String>> chatMessages = [];
  String activeLiveRoomName = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).syncDoubtsFromDb();
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: source, imageQuality: 80);
      if (image != null) {
        setState(() {
          selectedAttachmentType = 'Image';
          selectedAttachmentName = image.name;
          selectedAttachmentPath = image.path;
        });
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.image_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Photo Attached: ${image.name}',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blueAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload Photo Doubt',
                style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF2563EB)),
                title: Text('Take Photo from Camera', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF10B981)),
                title: Text('Choose Photo from Gallery', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickPDF() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );
      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        setState(() {
          selectedAttachmentType = 'PDF';
          selectedAttachmentName = file.name;
          selectedAttachmentPath = file.path!;
        });
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'PDF Attached: ${file.name}',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      print('Error picking PDF: $e');
    }
  }

  void _clearAttachment() {
    setState(() {
      selectedAttachmentType = 'None';
      selectedAttachmentName = '';
      selectedAttachmentPath = '';
    });
  }

  void _showAttachmentDialog(BuildContext context, Map<String, dynamic> doubt, {bool isReply = false}) {
    final name = isReply 
        ? (doubt['replyAttachmentName'] ?? 'attachment.png')
        : (doubt['attachmentName'] ?? 'attachment.png');
    final path = isReply
        ? (doubt['replyAttachmentPath'] ?? '')
        : (doubt['attachmentPath'] ?? '');
    final type = isReply
        ? (doubt['replyAttachmentType'] ?? 'Image')
        : (doubt['attachmentType'] ?? 'Image');
    final isImage = type == 'Image';

    showDialog(
      context: context,
      builder: (context) {
        Widget previewWidget;
        
        if (isImage) {
          if (path.startsWith('http') || path.startsWith('https')) {
            previewWidget = Image.network(
              path,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _buildSimulatedNotebook(name),
            );
          } else if (path.isNotEmpty && File(path).existsSync()) {
            previewWidget = Image.file(
              File(path),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _buildSimulatedNotebook(name),
            );
          } else {
            previewWidget = _buildSimulatedNotebook(name);
          }
        } else {
          if (path.startsWith('http') || path.startsWith('https')) {
            previewWidget = Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, size: 64, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  Text(name, style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri.tryParse(path);
                      if (uri != null && await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 16),
                    label: Text('Open PDF Document', style: GoogleFonts.fredoka(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                  ),
                ],
              ),
            );
          } else {
            previewWidget = _buildSimulatedPdf(name);
          }
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(isImage ? Icons.image_rounded : Icons.picture_as_pdf_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                    ),
                  ],
                ),
              ),
              
              Container(
                color: Colors.white,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                  minHeight: 250,
                ),
                width: double.infinity,
                child: SingleChildScrollView(
                  child: previewWidget,
                ),
              ),
              
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      isReply ? 'Teacher uploaded solution' : 'Student uploaded via mobile app',
                      style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                      label: Text('Done Reading', style: GoogleFonts.fredoka(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimulatedNotebook(String filename) {
    return Container(
      color: const Color(0xFFFFFDF3),
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('STUDENT NOTEBOOK SHEET', style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.red[300], letterSpacing: 1)),
              Text('PAGE 12', style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey[400])),
            ],
          ),
          const Divider(color: Colors.redAccent, thickness: 1),
          const SizedBox(height: 12),
          
          Text(
            'Q. Solve the given expression:',
            style: GoogleFonts.coveredByYourGrace(fontSize: 20, color: const Color(0xFF1E3A8A)),
          ),
          const SizedBox(height: 6),
          Text(
            '   20 - [ 5 + 3 * ( 8 - 5 ) ]',
            style: GoogleFonts.coveredByYourGrace(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)),
          ),
          const SizedBox(height: 14),
          Text(
            'Step 1: Parentheses first (8 - 5) = 3',
            style: GoogleFonts.coveredByYourGrace(fontSize: 18, color: const Color(0xFF1E3A8A)),
          ),
          Text(
            '        => 20 - [ 5 + 3 * 3 ]',
            style: GoogleFonts.coveredByYourGrace(fontSize: 18, color: const Color(0xFF1E3A8A)),
          ),
          const SizedBox(height: 8),
          Text(
            'Step 2: Multiplication inside bracket (3 * 3) = 9',
            style: GoogleFonts.coveredByYourGrace(fontSize: 18, color: const Color(0xFF1E3A8A)),
          ),
          Text(
            '        => 20 - [ 5 + 9 ]',
            style: GoogleFonts.coveredByYourGrace(fontSize: 18, color: const Color(0xFF1E3A8A)),
          ),
          const SizedBox(height: 8),
          Text(
            'Step 3: Addition inside bracket (5 + 9) = 14',
            style: GoogleFonts.coveredByYourGrace(fontSize: 18, color: const Color(0xFF1E3A8A)),
          ),
          Text(
            '        => 20 - 14',
            style: GoogleFonts.coveredByYourGrace(fontSize: 18, color: const Color(0xFF1E3A8A)),
          ),
          const SizedBox(height: 8),
          Text(
            'Step 4: Final subtraction (20 - 14) = 6 !',
            style: GoogleFonts.coveredByYourGrace(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.green[800]),
          ),
          const SizedBox(height: 12),
          Text(
            '*DOUBT*: Ma\'am, do we solve the bracket addition first or division if written as 12 / 3 * 2?',
            style: GoogleFonts.coveredByYourGrace(fontSize: 18, color: Colors.red[800]),
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Simulated high-fidelity notebook scan',
                    style: GoogleFonts.outfit(fontSize: 9, color: Colors.amber[800], fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSimulatedPdf(String filename) {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      child: Column(
        children: [
          const Icon(Icons.picture_as_pdf_rounded, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            filename,
            style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'PDF Document • 2 Pages • 245 KB',
            style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[600]),
          ),
          const Divider(height: 32),
          Text(
            'Simulated PDF Document text extraction:',
            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              '1. Quadratic Equations formula derivation:\nax^2 + bx + c = 0\nx = [-b ± sqrt(b^2 - 4ac)] / 2a\n\n2. Question for practice:\nSolve 2x^2 + 5x - 3 = 0 using factorization and verify with the formula.',
              style: GoogleFonts.outfit(fontSize: 11, color: Colors.black87, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  void _submitDoubt(AppState state) {
    final doubtText = doubtController.text.trim();
    if (doubtText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please describe your doubt before submitting.', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: Colors.orange[800],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    // Simulate database network upload latency
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      
      state.addDoubt(
        studentName: state.studentName,
        studentClass: state.studentClass,
        subject: activeSubject,
        question: doubtText,
        attachmentType: selectedAttachmentType,
        attachmentName: selectedAttachmentName,
        attachmentPath: selectedAttachmentPath,
      );

      setState(() {
        isSubmitting = false;
        doubtController.clear();
        selectedAttachmentType = 'None';
        selectedAttachmentName = '';
        selectedAttachmentPath = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.sync_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Doubt submitted! Syncing to your teacher\'s portal.',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          backgroundColor: AdyapanTheme.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    });
  }

  void _joinLiveRoom(String roomName, String tutorName) {
    setState(() {
      chatSimulated = true;
      activeLiveRoomName = roomName;
      chatMessages = [
        {
          'sender': tutorName,
          'msg': 'Welcome to the $roomName! Feel free to ask any active class questions live here. Our mentors are answering instantly!'
        }
      ];
    });
  }

  Widget _buildDoubtTile(String topicName, String meta, String teacher, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.15), width: 1.5),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              offset: const Offset(0, 4),
              blurRadius: 10,
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: const Color(0xFF2563EB), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(topicName, style: GoogleFonts.fredoka(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
                  const SizedBox(height: 2),
                  Text('$meta • $teacher', style: GoogleFonts.outfit(fontSize: 9.5, color: AdyapanTheme.textSub)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _joinLiveRoom(topicName, teacher),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), offset: const Offset(0, 3), blurRadius: 4),
                  ],
                ),
                child: Text(
                  'Join Live',
                  style: GoogleFonts.fredoka(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    // Filter doubts belonging to the active student to avoid leaking other students' doubts
    final myDoubts = state.doubts.where((d) => d['studentName'] == state.studentName).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text('Doubt Solver Room', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A), fontSize: 16)),
        backgroundColor: Colors.white.withOpacity(0.85),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
        leading: chatSimulated
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: () => setState(() => chatSimulated = false),
              )
            : null,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFEEF2F6),
              Color(0xFFE2E8F0),
              Color(0xFFF1F5F9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: chatSimulated
            ? _buildChatRoom()
            : RefreshIndicator(
                onRefresh: () => state.syncDoubtsFromDb(),
                color: const Color(0xFF2563EB),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    // Header card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.18), width: 1.5),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.psychology_rounded, color: Colors.blueAccent, size: 32),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Visual Doubt Solver', style: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
                                Text('Submit text, snapshots, or PDFs. Your mentor will reply with visual step-by-step solutions!', style: GoogleFonts.outfit(fontSize: 11, color: AdyapanTheme.textSub)),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Ask a Doubt Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        border: Border.all(color: const Color(0xFFFF3B70).withOpacity(0.15), width: 1.5),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 6))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ask your Mentor', style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
                          const SizedBox(height: 12),
                          
                          // Subject selector
                          Row(
                            children: ['Mathematics', 'Science', 'English'].map((subject) {
                              bool isSel = activeSubject == subject;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6.0),
                                child: GestureDetector(
                                  onTap: () => setState(() => activeSubject = subject),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSel ? const Color(0xFFFFE4EC) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(color: isSel ? const Color(0xFFFF3B70) : Colors.transparent, width: 1.2),
                                    ),
                                    child: Text(
                                      subject,
                                      style: GoogleFonts.fredoka(fontSize: 10, fontWeight: FontWeight.bold, color: isSel ? const Color(0xFFFF3B70) : AdyapanTheme.textMain),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),

                          // Textarea
                          TextField(
                            controller: doubtController,
                            maxLines: 4,
                            style: GoogleFonts.outfit(fontSize: 12.5),
                            decoration: InputDecoration(
                              hintText: 'Describe your topic, question, or formula issue step-by-step...',
                              hintStyle: GoogleFonts.outfit(fontSize: 12, color: AdyapanTheme.textMuted),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF3B70), width: 1.5)),
                              contentPadding: const EdgeInsets.all(14),
                              fillColor: const Color(0xFFF8FAFC),
                              filled: true,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Attachment state indicator if attached
                          if (selectedAttachmentType != 'None') ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: selectedAttachmentType == 'Image' ? const Color(0xFFEFF6FF) : const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: selectedAttachmentType == 'Image' ? const Color(0xFFBFDBFE) : const Color(0xFFFECACA)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    selectedAttachmentType == 'Image' ? Icons.image_rounded : Icons.picture_as_pdf_rounded,
                                    color: selectedAttachmentType == 'Image' ? Colors.blue : Colors.red,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      selectedAttachmentName,
                                      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _clearAttachment,
                                    child: const Icon(Icons.cancel_rounded, color: Colors.grey, size: 18),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Attachment Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _showImageSourceOptions,
                                  icon: const Icon(Icons.camera_alt_rounded, size: 14),
                                  label: Text('Upload Image', style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blue[700],
                                    side: BorderSide(color: Colors.blue[100]!),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickPDF,
                                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 14),
                                  label: Text('Attach PDF', style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red[700],
                                    side: BorderSide(color: Colors.red[100]!),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isSubmitting ? null : () => _submitDoubt(state),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF3B70),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                elevation: 2,
                              ),
                              child: isSubmitting
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text('Send to Teacher', style: GoogleFonts.fredoka(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Your Submitted Doubts List Section
                    Text('Your Submitted Doubts', style: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
                    const SizedBox(height: 12),
                    
                    if (myDoubts.isEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.5)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.help_outline_rounded, size: 32, color: Colors.blueGrey),
                            const SizedBox(height: 10),
                            Text(
                              'You haven\'t asked any doubts yet!',
                              style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              'Ask formulas, textbook steps, or syllabus questions above.',
                              style: GoogleFonts.outfit(fontSize: 10.5, color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: myDoubts.length,
                        itemBuilder: (context, index) {
                          final doubt = myDoubts[index];
                          final isReplied = doubt['replied'] as bool;
                          final attachmentType = doubt['attachmentType'] ?? 'None';
                          final hasAttachment = attachmentType != 'None';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isReplied ? Icons.check_circle_rounded : Icons.hourglass_empty_rounded,
                                      color: isReplied ? Colors.green : Colors.orange,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isReplied ? 'Solved by Mentor' : 'Pending Review',
                                      style: GoogleFonts.fredoka(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isReplied ? Colors.green[800] : Colors.orange[800],
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      doubt['time'],
                                      style: GoogleFonts.outfit(fontSize: 9, color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  doubt['question'],
                                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.black87),
                                ),
                                
                                // Attached file preview inside list
                                if (hasAttachment) ...[
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () => _showAttachmentDialog(context, doubt),
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF), // soft blue background
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              attachmentType == 'Image' ? Icons.image_rounded : Icons.picture_as_pdf_rounded,
                                              size: 14,
                                              color: attachmentType == 'Image' ? Colors.blue : Colors.red,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              doubt['attachmentName'] ?? 'Attachment',
                                              style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: const Color(0xFFBFDBFE)),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.visibility_rounded, size: 8, color: Color(0xFF2563EB)),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    'VIEW',
                                                    style: GoogleFonts.fredoka(fontSize: 7, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],

                                if (isReplied) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFA7F3D0)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Mentor Solution:',
                                              style: GoogleFonts.fredoka(fontSize: 11, color: Colors.green[900], fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          doubt['replyText'] ?? '',
                                          style: GoogleFonts.outfit(fontSize: 11.5, color: Colors.green[800]),
                                        ),
                                        if (doubt['replyAttachmentType'] != null && doubt['replyAttachmentType'] != 'None') ...[
                                          const SizedBox(height: 8),
                                          GestureDetector(
                                            onTap: () => _showAttachmentDialog(context, doubt, isReply: true),
                                            child: MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: const Color(0xFFA7F3D0)),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.01),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 1),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      doubt['replyAttachmentType'] == 'Image' ? Icons.image_rounded : Icons.picture_as_pdf_rounded,
                                                      size: 14,
                                                      color: doubt['replyAttachmentType'] == 'Image' ? Colors.blue : Colors.red,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      doubt['replyAttachmentName'] ?? 'Attachment',
                                                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFEFF6FF),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          const Icon(Icons.visibility_rounded, size: 8, color: Color(0xFF2563EB)),
                                                          const SizedBox(width: 2),
                                                          Text(
                                                            'VIEW',
                                                            style: GoogleFonts.fredoka(fontSize: 7, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    'Waiting for mentor explanation...',
                                    style: GoogleFonts.outfit(fontSize: 10.5, color: Colors.orange[800], fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Active Live Doubt Rooms Section
                    Text('Active Doubt Live Channels', style: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
                    const SizedBox(height: 12),

                    _buildDoubtTile('Mathematics Doubt Room', 'LIVE • 12 active students • 2 mentors', 'Mrs. Sharma', Icons.calculate_rounded),
                    _buildDoubtTile('Science Doubt Solving Channel', 'LIVE • 8 active students • 1 mentor', 'Mr. Verma', Icons.biotech_rounded),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildChatRoom() {
    final state = Provider.of<AppState>(context, listen: false);
    final chatMsgController = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  radius: 18,
                  child: Icon(Icons.forum_rounded, color: Colors.blueAccent, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activeLiveRoomName, style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
                      Text('Online Session Active • Ask doubts directly', style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[500])),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ListView.builder(
                itemCount: chatMessages.length,
                itemBuilder: (context, index) {
                  final msg = chatMessages[index];
                  bool isMe = msg['sender'] == state.studentName;
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMe ? const Color(0xFFFFE4EC) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                          bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                        ),
                        border: Border.all(color: isMe ? const Color(0xFFFF3B70).withOpacity(0.2) : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg['sender']!,
                            style: GoogleFonts.fredoka(
                              fontSize: 9, 
                              fontWeight: FontWeight.bold, 
                              color: isMe ? const Color(0xFFFF3B70) : Colors.blueGrey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(msg['msg']!, style: GoogleFonts.outfit(fontSize: 11.5)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: chatMsgController,
                  style: GoogleFonts.outfit(fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: 'Type your doubt directly to live mentors...',
                    hintStyle: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[400]),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: const Color(0xFFFF3B70),
                radius: 20,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 16),
                  onPressed: () {
                    final txt = chatMsgController.text.trim();
                    if (txt.isNotEmpty) {
                      setState(() {
                        chatMessages.add({
                          'sender': state.studentName,
                          'msg': txt,
                        });
                        chatMsgController.clear();
                      });
                      
                      // Auto simulated tutor mock reply
                      Future.delayed(const Duration(milliseconds: 1500), () {
                        if (!mounted) return;
                        setState(() {
                          chatMessages.add({
                            'sender': 'Mentor Verified',
                            'msg': 'Got your point on "${txt}". Let\'s solve this live together now! Can you confirm if you have studied the BODMAS rules in Chapter 2?'
                          });
                        });
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
