import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';
import '../core/api_service.dart';
import '../core/theme.dart';

/// Messages Screen — Inbox + Compose
/// Teachers can send messages to admins, principals, and students.
/// Students can only view received messages (no compose).
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    // Poll for new messages every 15 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _fetchMessages());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    try {
      final state = Provider.of<AppState>(context, listen: false);
      List<Map<String, dynamic>> msgs;

      if (state.userRole == 'student') {
        msgs = await _api.fetchStudentMessages(state.studentEmail);
      } else {
        msgs = await _api.fetchMessages();
      }

      if (mounted) {
        setState(() {
          _messages = msgs;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showComposeDialog() {
    final state = Provider.of<AppState>(context, listen: false);
    if (state.userRole == 'student') return; // Students can't send

    String recipientRole = 'admin';
    final msgController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.send_rounded, color: Color(0xFF4F46E5)),
                    const SizedBox(width: 8),
                    Text('Compose Message',
                        style: AdyapanTheme.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Send to:', style: AdyapanTheme.outfit(fontSize: 14, color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _roleChip('Admin', 'admin', recipientRole, (v) {
                      setSheetState(() => recipientRole = v);
                    }),
                    _roleChip('Principal', 'principal', recipientRole, (v) {
                      setSheetState(() => recipientRole = v);
                    }),
                    if (state.userRole == 'teacher')
                      _roleChip('Students', 'student', recipientRole, (v) {
                        setSheetState(() => recipientRole = v);
                      }),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: msgController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final msg = msgController.text.trim();
                      if (msg.isEmpty) return;

                      final sent = await _api.sendMessage(
                        recipientEmail: recipientRole, // Backend resolves by role
                        recipientRole: recipientRole,
                        message: msg,
                        senderName: state.studentName,
                      );

                      if (sent && mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ Message sent to $recipientRole'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _fetchMessages();
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('❌ Failed to send message'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text('Send Message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _roleChip(String label, String value, String selected, ValueChanged<String> onTap) {
    final isActive = selected == value;
    return FilterChip(
      label: Text(label),
      selected: isActive,
      onSelected: (_) => onTap(value),
      selectedColor: const Color(0xFF4F46E5).withOpacity(0.15),
      checkmarkColor: const Color(0xFF4F46E5),
      labelStyle: TextStyle(
        color: isActive ? const Color(0xFF4F46E5) : Colors.grey.shade700,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final isStudent = state.userRole == 'student';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Messages', style: AdyapanTheme.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchMessages,
          ),
        ],
      ),
      floatingActionButton: isStudent
          ? null
          : FloatingActionButton.extended(
              onPressed: _showComposeDialog,
              icon: const Icon(Icons.edit),
              label: const Text('Compose'),
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No messages yet',
                        style: AdyapanTheme.outfit(fontSize: 16, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isStudent
                            ? 'Messages from your teachers will appear here'
                            : 'Tap Compose to send a message',
                        style: AdyapanTheme.outfit(fontSize: 13, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchMessages,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isRead = msg['is_read'] == 1 || msg['is_read'] == true;
                      final senderName = msg['sender_name'] ?? msg['sender_email'] ?? 'Unknown';
                      final messageText = msg['message'] ?? '';
                      final createdAt = msg['created_at'] ?? '';
                      final id = msg['id']?.toString() ?? '';

                      return Card(
                        elevation: isRead ? 0 : 2,
                        color: isRead ? Colors.white : const Color(0xFFF0F0FF),
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          leading: CircleAvatar(
                            backgroundColor: isRead
                                ? Colors.grey.shade200
                                : const Color(0xFF4F46E5).withOpacity(0.1),
                            child: Icon(
                              isRead ? Icons.mail_outline : Icons.mark_email_unread,
                              color: isRead ? Colors.grey : const Color(0xFF4F46E5),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            senderName,
                            style: AdyapanTheme.outfit(
                              fontSize: 14,
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              messageText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AdyapanTheme.outfit(fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ),
                          trailing: Text(
                            _formatTime(createdAt),
                            style: AdyapanTheme.outfit(fontSize: 11, color: Colors.grey.shade400),
                          ),
                          onTap: () {
                            // Mark as read on tap
                            if (!isRead && id.isNotEmpty) {
                              _api.markMessageRead(id);
                              setState(() {
                                _messages[index]['is_read'] = true;
                              });
                            }
                            _showMessageDetail(msg);
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  void _showMessageDetail(Map<String, dynamic> msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.message, color: Color(0xFF4F46E5), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg['sender_name'] ?? 'Message',
                style: AdyapanTheme.outfit(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg['message'] ?? '',
              style: AdyapanTheme.outfit(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              _formatTime(msg['created_at'] ?? ''),
              style: AdyapanTheme.outfit(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatTime(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
