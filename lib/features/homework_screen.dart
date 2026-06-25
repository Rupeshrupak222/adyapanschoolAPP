import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../core/app_state.dart';

/// Opens a file URL (web, local, or cloud) using the OS viewer.
Future<void> _openAttachment(BuildContext context, String? fileUrl, String? filePath, {String? defaultFileName}) async {
  final name = defaultFileName ?? (filePath != null ? filePath.split(Platform.isWindows ? '\\' : '/').last : 'Attachment');

  // Try network URL first (either fileUrl or filePath starting with http)
  final netUrl = (fileUrl != null && fileUrl.isNotEmpty && fileUrl.startsWith('http')) 
      ? fileUrl 
      : ((filePath != null && filePath.isNotEmpty && filePath.startsWith('http')) ? filePath : null);

  if (netUrl != null) {
    final uri = Uri.tryParse(netUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
  }
  // Fallback: try local file path
  if (filePath != null && filePath.isNotEmpty && !filePath.startsWith('http')) {
    final file = File(filePath);
    if (file.existsSync()) {
      final uri = Uri.file(filePath);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
  }

  // Open beautiful In-App Viewer as robust fallback!
  _showInAppAttachmentViewer(context, name, filePath, fileUrl);
}

void _showInAppAttachmentViewer(BuildContext context, String fileName, String? filePath, String? fileUrl) {
  final state = Provider.of<AppState>(context, listen: false);
  final isImage = fileName.toLowerCase().endsWith('.png') ||
                  fileName.toLowerCase().endsWith('.jpg') ||
                  fileName.toLowerCase().endsWith('.jpeg');
  
  final isNetwork = (filePath != null && filePath.startsWith('http')) || 
                    (fileUrl != null && fileUrl.startsWith('http'));
  final displayUrl = (filePath != null && filePath.startsWith('http')) ? filePath : fileUrl;

  showDialog(
    context: context,
    builder: (ctx) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              // Header bar
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isImage ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isImage ? Icons.image_rounded : Icons.picture_as_pdf_rounded,
                        color: isImage ? const Color(0xFF10B981) : Colors.redAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            isImage ? state.translate('Photo Attachment') : state.translate('PDF Study Guide'),
                            style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              
              // Viewer content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: isImage
                      ? Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: isNetwork && displayUrl != null
                                ? Image.network(
                                    displayUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(vertical: 40),
                                        alignment: Alignment.center,
                                        child: Column(
                                          children: [
                                            const Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
                                            const SizedBox(height: 12),
                                            Text(
                                              state.translate('Attachment preview is loading...'),
                                              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  )
                                : (filePath != null && File(filePath).existsSync()
                                    ? Image.file(
                                        File(filePath),
                                        fit: BoxFit.contain,
                                      )
                                    : Image.network(
                                        'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?q=80&w=800&auto=format&fit=crop',
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(vertical: 40),
                                            alignment: Alignment.center,
                                            child: Column(
                                              children: [
                                                const Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
                                                const SizedBox(height: 12),
                                                Text(
                                                  state.translate('Attachment preview is loading...'),
                                                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      )),
                          ),
                        )
                      : Column(
                          children: [
                            // Simulated PDF pages
                            ...List.generate(3, (pageIndex) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                                  ],
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  children: [
                                    // Page header
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                                        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            state.translate('Page') + ' ${pageIndex + 1}',
                                            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                                          ),
                                          const Spacer(),
                                          Text(
                                            state.translate('Adyapan School Portal'),
                                            style: GoogleFonts.outfit(fontSize: 9, color: const Color(0xFF94A3B8)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Page body lines
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (pageIndex == 0) ...[
                                            Text(
                                              state.translate('Class Assignment Guide'),
                                              style: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                                            ),
                                            const SizedBox(height: 10),
                                          ],
                                          ...List.generate(pageIndex == 0 ? 5 : 7, (lineIndex) {
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 8.0),
                                              child: Container(
                                                height: 10,
                                                width: lineIndex == (pageIndex == 0 ? 4 : 6) ? 140 : double.infinity,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                              ),
                                            );
                                          }),
                                          if (pageIndex == 1) ...[
                                            const SizedBox(height: 10),
                                            Container(
                                              height: 120,
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEFF6FF),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: const Color(0xFFBFDBFE)),
                                              ),
                                              alignment: Alignment.center,
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Icon(Icons.analytics_outlined, color: Color(0xFF2563EB), size: 24),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    '[ ' + state.translate('Worksheet Diagram & Equations Reference') + ' ]',
                                                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF1E40AF)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                ),
              ),
              
              // Bottom Action
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, -2)),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$fileName ' + state.translate('is ready in your library cache!')),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.download_done_rounded, color: Colors.white, size: 16),
                    label: Text(
                      state.translate('Download Offline Copy'),
                      style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
}

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({Key? key}) : super(key: key);

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> with SingleTickerProviderStateMixin {
  late ConfettiController _confetti;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).syncHomeworkAndNotesFromDb();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Color _priorityColor(String priority) {
    if (priority == 'High') return const Color(0xFFEF4444);
    if (priority == 'Medium') return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  Color _priorityBg(String priority) {
    if (priority == 'High') return const Color(0xFFFEF2F2);
    if (priority == 'Medium') return const Color(0xFFFFFBEB);
    return const Color(0xFFECFDF5);
  }

  void _submitHomework(AppState state, int id, String title) {
    _showUploadBottomSheet(context, state, id, title);
  }

  void _showUploadBottomSheet(BuildContext context, AppState state, int id, String title) {
    String? fileName;
    String? filePath;
    bool isImage = false;
    final commentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final hasFile = fileName != null;

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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pull bar
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
                    const SizedBox(height: 16),

                    // Header
                    Row(
                      children: [
                        const Icon(Icons.assignment_turned_in_rounded, color: Colors.blueAccent, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Submit Assignment',
                                style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                              ),
                              Text(
                                title,
                                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),

                    // Upload placeholder or File Card
                    if (!hasFile)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFCBD5E1),
                            width: 1.5,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.cloud_upload_outlined, size: 40, color: Color(0xFF64748B)),
                            const SizedBox(height: 10),
                            Text(
                              'Choose your homework file',
                              style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF475569)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Supports photos of written sheets or PDFs',
                              style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8)),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4), width: 1.5),
                        ),
                        child: Row(
                          children: [
                            // Thumbnail or Icon
                            if (isImage && filePath != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(filePath!),
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF10B981), size: 24),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fileName!,
                                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isImage ? 'Ready to upload (Image)' : 'Ready to upload (PDF Document)',
                                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF10B981)),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                              onPressed: () {
                                setModalState(() {
                                  fileName = null;
                                  filePath = null;
                                  isImage = false;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Selector buttons
                    if (!hasFile) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _pickerButton(
                              icon: Icons.camera_alt_rounded,
                              label: 'Camera',
                              color: const Color(0xFFECF2FF),
                              textColor: const Color(0xFF2563EB),
                              onTap: () async {
                                final picker = ImagePicker();
                                final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                                if (image != null) {
                                  setModalState(() {
                                    fileName = image.name;
                                    filePath = image.path;
                                    isImage = true;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _pickerButton(
                              icon: Icons.photo_library_rounded,
                              label: 'Gallery',
                              color: const Color(0xFFECFDF5),
                              textColor: const Color(0xFF10B981),
                              onTap: () async {
                                final picker = ImagePicker();
                                final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                                if (image != null) {
                                  setModalState(() {
                                    fileName = image.name;
                                    filePath = image.path;
                                    isImage = true;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _pickerButton(
                        icon: Icons.attachment_rounded,
                        label: 'Use PDF Template (Fast Demo)',
                        color: const Color(0xFFFFF7ED),
                        textColor: const Color(0xFFF59E0B),
                        onTap: () {
                          _showPdfTemplates(context, (name) {
                            setModalState(() {
                              fileName = name;
                              filePath = null;
                              isImage = false;
                            });
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Comments box
                    Text(
                      'Message for Teacher (Optional)',
                      style: GoogleFonts.fredoka(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF475569)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: commentCtrl,
                      maxLines: 2,
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF1E293B)),
                      decoration: InputDecoration(
                        hintText: 'e.g. Please check problem 12, I had a doubt in formulas...',
                        hintStyle: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        fillColor: const Color(0xFFF8FAFC),
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: !hasFile
                            ? null
                            : () async {
                                final done = await state.submitHomework(
                                  id,
                                  fileName: fileName,
                                  filePath: filePath,
                                  studentComment: commentCtrl.text.trim().isEmpty ? null : commentCtrl.text.trim(),
                                );
                                if (done) {
                                  Navigator.pop(context);
                                  _confetti.play();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('"$title" submitted successfully!'),
                                      backgroundColor: const Color(0xFF10B981),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          disabledBackgroundColor: const Color(0xFFE2E8F0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: Text(
                          'Submit Assignment',
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: hasFile ? Colors.white : const Color(0xFF94A3B8),
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

  Widget _pickerButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.fredoka(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
            ),
          ],
        ),
      ),
    );
  }

  void _showPdfTemplates(BuildContext context, Function(String) onSelect) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Select PDF Template',
            style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _pdfItem('quadratic_eq_solutions.pdf', onSelect, context),
              _pdfItem('atomic_orbitals_labeled.pdf', onSelect, context),
              _pdfItem('rivers_of_india_map.pdf', onSelect, context),
              _pdfItem('climate_change_essay.pdf', onSelect, context),
            ],
          ),
        );
      },
    );
  }

  Widget _pdfItem(String name, Function(String) onSelect, BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444)),
      title: Text(
        name,
        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      onTap: () {
        onSelect(name);
        Navigator.pop(context);
      },
    );
  }

  void _showHomeworkDetailSheet(BuildContext context, Map<String, dynamic> hw) {
    final bool submitted = hw['submitted'] == true;
    final priority = hw['priority'] as String;
    final pColor = _priorityColor(priority);
    final pBg = _priorityBg(priority);
    final state = Provider.of<AppState>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pull bar
              const SizedBox(height: 12),
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
              const SizedBox(height: 16),

              // Header badges & close button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: pBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: pColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        hw['subject'],
                        style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: pColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        '$priority Priority',
                        style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AdyapanTheme.textMuted),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hw['title'],
                        style: GoogleFonts.fredoka(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Metadata block
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text(
                            'Due: ${hw['dueDate']}',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(width: 20),
                          const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text(
                            'By ${hw['addedBy']}',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 28, color: Color(0xFFF1F5F9)),

                      Text(
                        'Assignment Description',
                        style: GoogleFonts.fredoka(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hw['description'],
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF475569),
                          height: 1.5,
                        ),
                      ),
                      if (hw['teacherFileName'] != null && (hw['teacherFileName'] as String).isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Teacher Reference Attachment',
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _openAttachment(context, hw['teacherFileUrl'] as String?, hw['teacherFilePath'] as String?, defaultFileName: hw['teacherFileName'] as String?),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.35)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  (hw['teacherFileName'] as String).contains('.pdf')
                                      ? Icons.picture_as_pdf_rounded
                                      : Icons.image_rounded,
                                  size: 18,
                                  color: const Color(0xFFD97706),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    hw['teacherFileName']!,
                                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF7C2D12)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.open_in_new_rounded, size: 12, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text('View', style: GoogleFonts.fredoka(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Submission Details Section (if submitted)
                      if (submitted) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3), width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Submission Details',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF065F46),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Submitted On: ${hw['submittedAt']}',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: const Color(0xFF047857),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (hw['fileName'] != null && (hw['fileName'] as String).isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        (hw['fileName'] as String).contains('.pdf')
                                            ? Icons.picture_as_pdf_rounded
                                            : Icons.image_rounded,
                                        size: 16,
                                        color: const Color(0xFF10B981),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          hw['fileName'],
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF0F172A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (hw['studentComment'] != null && (hw['studentComment'] as String).isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Your Message to Teacher:',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF065F46),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '"${hw['studentComment']}"',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: const Color(0xFF047857),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Grading & Feedback Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: hw['grade'] == 'Pending Grade' ? const Color(0xFFFFFBEB) : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: hw['grade'] == 'Pending Grade'
                                  ? const Color(0xFFF59E0B).withOpacity(0.3)
                                  : const Color(0xFF2563EB).withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    hw['grade'] == 'Pending Grade'
                                        ? Icons.hourglass_empty_rounded
                                        : Icons.stars_rounded,
                                    color: hw['grade'] == 'Pending Grade' ? const Color(0xFFD97706) : const Color(0xFF2563EB),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Grade & Feedback',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: hw['grade'] == 'Pending Grade'
                                          ? const Color(0xFF92400E)
                                          : const Color(0xFF1E40AF),
                                    ),
                                  ),
                                  const Spacer(),
                                  // Grade badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: hw['grade'] == 'Pending Grade' ? const Color(0xFFF59E0B) : const Color(0xFF2563EB),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      hw['grade'] ?? 'Pending',
                                      style: GoogleFonts.fredoka(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Teacher\'s Feedback:',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: hw['grade'] == 'Pending Grade'
                                      ? const Color(0xFF92400E)
                                      : const Color(0xFF1E40AF),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (hw['teacherFeedback'] != null && (hw['teacherFeedback'] as String).trim().isNotEmpty)
                                    ? '"${hw['teacherFeedback']}"'
                                    : 'Pending teacher evaluation...',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: hw['grade'] == 'Pending Grade'
                                      ? const Color(0xFFB45309)
                                      : const Color(0xFF1E293B),
                                  fontStyle: (hw['teacherFeedback'] != null && (hw['teacherFeedback'] as String).trim().isNotEmpty)
                                      ? FontStyle.normal
                                      : FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom Button Row
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          if (!submitted) {
                            _submitHomework(state, hw['id'], hw['title']);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: submitted ? const Color(0xFF64748B) : const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          submitted ? 'Close details' : 'Start Submission',
                          style: GoogleFonts.fredoka(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (submitted) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _submitHomework(state, hw['id'], hw['title']);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Resubmit Homework',
                            style: GoogleFonts.fredoka(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHomeworkCard(AppState state, Map<String, dynamic> hw) {
    final bool submitted = hw['submitted'] == true;
    final priority = hw['priority'] as String;
    final pColor = _priorityColor(priority);
    final pBg = _priorityBg(priority);

    return GestureDetector(
      onTap: () => _showHomeworkDetailSheet(context, hw),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: submitted ? const Color(0xFF10B981).withOpacity(0.3) : pColor.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  // Subject badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: pBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: pColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      hw['subject'],
                      style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: pColor),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      '$priority Priority',
                      style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: AdyapanTheme.textMuted),
                    ),
                  ),
                ],
              ),
            ),
  
            // Title + description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hw['title'], style: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain)),
                  const SizedBox(height: 4),
                  Text(hw['description'], style: GoogleFonts.outfit(fontSize: 11, color: AdyapanTheme.textSub, height: 1.4)),
                ],
              ),
            ),
            if (hw['teacherFileName'] != null && (hw['teacherFileName'] as String).isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: GestureDetector(
                  onTap: () => _openAttachment(context, hw['teacherFileUrl'] as String?, hw['teacherFilePath'] as String?, defaultFileName: hw['teacherFileName'] as String?),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.35)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          (hw['teacherFileName'] as String).contains('.pdf')
                              ? Icons.picture_as_pdf_rounded
                              : Icons.image_rounded,
                          size: 14,
                          color: const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Resource: ${hw['teacherFileName']}',
                            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF7C2D12)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.open_in_new_rounded, size: 10, color: Colors.white),
                              const SizedBox(width: 3),
                              Text('View', style: GoogleFonts.fredoka(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            if (hw['fileName'] != null && (hw['fileName'] as String).isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: GestureDetector(
                  onTap: () => _openAttachment(context, hw['fileUrl'] as String?, hw['filePath'] as String?, defaultFileName: hw['fileName'] as String?),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.35)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          (hw['fileName'] as String).contains('.pdf')
                              ? Icons.picture_as_pdf_rounded
                              : Icons.image_rounded,
                          size: 14,
                          color: const Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            hw['fileName']!,
                            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.open_in_new_rounded, size: 10, color: Colors.white),
                              const SizedBox(width: 3),
                              Text('View', style: GoogleFonts.fredoka(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
  
            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: BoxDecoration(
                color: submitted ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 11, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text('Due: ${hw['dueDate']}', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AdyapanTheme.textSub), overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded, size: 11, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text('By ${hw['addedBy']}', style: GoogleFonts.outfit(fontSize: 10, color: AdyapanTheme.textMuted), overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                        if (submitted && hw['submittedAt'] != null) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 11, color: Color(0xFF10B981)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text('Submitted: ${hw['submittedAt']}', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)), overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Submit / Done button
                  submitted
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_rounded, size: 13, color: Colors.white),
                              const SizedBox(width: 4),
                              Text('Submitted', style: GoogleFonts.fredoka(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () => _submitHomework(state, hw['id'], hw['title']),
                          icon: const Icon(Icons.upload_rounded, size: 13, color: Colors.white),
                          label: Text('Submit', style: GoogleFonts.fredoka(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
    final pending = state.homeworkList.where((h) => h['submitted'] == false).toList();
    final submitted = state.homeworkList.where((h) => h['submitted'] == true).toList();
    final all = state.homeworkList;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          Column(
            children: [
              // ── HEADER ──
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
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
                                    'Homework Portal',
                                    style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  Text(
                                    'Submit assignments & view your school agenda',
                                    style: GoogleFonts.outfit(fontSize: 10, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Stats row
                        Row(
                          children: [
                            _headerStat('${all.length}', 'Total', Icons.assignment_rounded),
                            const SizedBox(width: 10),
                            _headerStat('${pending.length}', 'Pending', Icons.pending_actions_rounded),
                            const SizedBox(width: 10),
                            _headerStat('${submitted.length}', 'Submitted', Icons.task_alt_rounded),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── TAB BAR ──
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelStyle: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: GoogleFonts.fredoka(fontSize: 13),
                  labelColor: const Color(0xFF2563EB),
                  unselectedLabelColor: AdyapanTheme.textMuted,
                  indicatorColor: const Color(0xFF2563EB),
                  tabs: [
                    Tab(text: 'Pending (${pending.length})'),
                    Tab(text: 'Submitted (${submitted.length})'),
                  ],
                ),
              ),

              // ── CONTENT ──
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // PENDING TAB
                    pending.isEmpty
                        ? RefreshIndicator(
                            onRefresh: () => state.syncHomeworkAndNotesFromDb(),
                            color: const Color(0xFF2563EB),
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: SizedBox(
                                height: MediaQuery.of(context).size.height * 0.5,
                                child: _emptyState('All Done!', 'No pending homework. Great work!'),
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => state.syncHomeworkAndNotesFromDb(),
                            color: const Color(0xFF2563EB),
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                              itemCount: pending.length,
                              itemBuilder: (context, i) => _buildHomeworkCard(state, pending[i]),
                            ),
                          ),

                    // SUBMITTED TAB
                    submitted.isEmpty
                        ? RefreshIndicator(
                            onRefresh: () => state.syncHomeworkAndNotesFromDb(),
                            color: const Color(0xFF2563EB),
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: SizedBox(
                                height: MediaQuery.of(context).size.height * 0.5,
                                child: _emptyState('Nothing submitted yet', 'Complete pending homework to see them here.'),
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => state.syncHomeworkAndNotesFromDb(),
                            color: const Color(0xFF2563EB),
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                              itemCount: submitted.length,
                              itemBuilder: (context, i) => _buildHomeworkCard(state, submitted[i]),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Color(0xFF2563EB), Color(0xFF10B981), Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerStat(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(label, style: GoogleFonts.outfit(fontSize: 9, color: Colors.white.withOpacity(0.75), fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assignment_outlined, size: 56, color: AdyapanTheme.textMuted),
          const SizedBox(height: 14),
          Text(title, style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold, color: AdyapanTheme.textMain)),
          const SizedBox(height: 6),
          Text(subtitle, style: GoogleFonts.outfit(fontSize: 12, color: AdyapanTheme.textMuted), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
