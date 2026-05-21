import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminFeedbackPage extends StatelessWidget {
  const AdminFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
       
        automaticallyImplyLeading: true, 
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("support_requests")
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final feedbacks = snapshot.data!.docs;

          if (feedbacks.isEmpty) {
            return const Center(child: Text("No feedback yet."));
          }

          return ListView.builder(
            itemCount: feedbacks.length,
            itemBuilder: (context, index) {
              var feedback = feedbacks[index].data() as Map<String, dynamic>;
              var docId = feedbacks[index].id;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(
                    feedback["subject"] ?? "No Subject",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(feedback["message"] ?? ""),
                      const SizedBox(height: 4),
                      Text("From: ${feedback["email"] ?? "Unknown"}"),
                      Text("Status: ${feedback["status"] ?? "Pending"}"),
                      Text("Category: ${feedback["category"] ?? "Not set"}"),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FeedbackDetailPage(
                            docId: docId,
                            data: feedback,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class FeedbackDetailPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const FeedbackDetailPage({
    super.key,
    required this.docId,
    required this.data,
  });

  @override
  State<FeedbackDetailPage> createState() => _FeedbackDetailPageState();
}

class _FeedbackDetailPageState extends State<FeedbackDetailPage> {
  late String selectedStatus;
  late String selectedCategory;
  final TextEditingController replyController = TextEditingController();
  bool _isUpdating = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.data['status'] ?? 'Pending';
    selectedCategory = widget.data['category'] ?? 'General';
    replyController.text = widget.data['adminReply'] ?? '';
  }

  String _formatTimestamp(dynamic ts) {
    try {
      if (ts == null) return 'Unknown';
      if (ts is Timestamp) {
        final dt = ts.toDate().toLocal();
        return '${dt.year}-${_two(dt.month)}-${_two(dt.day)} ${_two(dt.hour)}:${_two(dt.minute)}';
      }
      return ts.toString();
    } catch (e) {
      return ts.toString();
    }
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  Future<void> _updateFeedback({bool sendEmail = false}) async {
    setState(() => _isUpdating = true);
    try {
      await FirebaseFirestore.instance
          .collection('support_requests')
          .doc(widget.docId)
          .update({
        'status': selectedStatus,
        'category': selectedCategory,
        'adminReply': replyController.text.trim(),
        'adminRespondedAt': FieldValue.serverTimestamp(),
        'userStatus': 'Unread', // always unread for user
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Feedback updated')),
      );

      if (sendEmail) {
        final email = widget.data['email'] ?? '';
        if (email.isNotEmpty) {
          final subject = Uri.encodeComponent(
              'Reply to your feedback: ${widget.data['subject'] ?? ''}');
          final body = Uri.encodeComponent(replyController.text.trim());
          final mailUri = Uri.parse('mailto:$email?subject=$subject&body=$body');

          if (await canLaunchUrl(mailUri)) {
            await launchUrl(mailUri);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open email client')),
            );
          }
        }
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating feedback: $e')),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _deleteFeedback() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete feedback?'),
        content: const Text('This will permanently delete the feedback.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);
    try {
      await FirebaseFirestore.instance
          .collection('support_requests')
          .doc(widget.docId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback deleted')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting: $e')),
      );
    } finally {
      setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final subject = data['subject'] ?? 'No subject';
    final message = data['message'] ?? '';
    final email = data['email'] ?? 'Unknown';
    final userId = data['userId'] ?? 'Unknown';
    final ts = data['timestamp'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Feedback'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isDeleting ? null : _deleteFeedback,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subject,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text(message),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "User: $userId",
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.email_outlined,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            email,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Submitted: ${_formatTimestamp(ts)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    if ((data['adminReply'] ?? '').toString().isNotEmpty) ...[
                      const Divider(),
                      const Text('Admin Reply:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(data['adminReply']),
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: selectedStatus,
              items: ['Pending', 'InProgress', 'Resolved']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => selectedStatus = v ?? 'Pending'),
              decoration: const InputDecoration(labelText: 'Status'),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              items: ['Bug', 'Suggestion', 'Complaint', 'General']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => selectedCategory = v ?? 'General'),
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: replyController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Reply to user (optional)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUpdating
                        ? null
                        : () => _updateFeedback(sendEmail: false),
                    icon: _isUpdating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Update'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
