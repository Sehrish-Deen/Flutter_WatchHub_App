import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final List<String> _notifications = [];
  final TextEditingController _notificationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch existing notifications from Firestore on load
    FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _notifications.clear();
        for (var doc in snapshot.docs) {
          _notifications.add(doc['message']);
        }
      });
    });
  }

  // Add notification
  void _addNotification() async {
    if (_notificationController.text.isNotEmpty) {
      String message = _notificationController.text;

      // 1. Local list update
      setState(() {
        _notifications.add(message);
      });

      // 2. Firestore me save with status
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'Admin Alert',
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': 'all', 
        'status': 'Unread', 
      });

      _notificationController.clear();
    }
  }

  // Edit notification
  void _editNotification(int index, String docId) async {
    _notificationController.text = _notifications[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Edit Notification"),
        content: TextField(
          controller: _notificationController,
          decoration: const InputDecoration(
            labelText: "Message",
            prefixIcon: Icon(Icons.notifications),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrangeAccent),
            onPressed: () async {
              String updatedMessage = _notificationController.text;
              // Local update
              setState(() {
                _notifications[index] = updatedMessage;
              });

              // Firestore update
              await FirebaseFirestore.instance
                  .collection('notifications')
                  .doc(docId)
                  .update({'message': updatedMessage});

              Navigator.pop(ctx);
            },
            child: const Text("Update"),
          )
        ],
      ),
    );
  }

  // Delete notification
  void _deleteNotification(int index, String docId) async {
    setState(() {
      _notifications.removeAt(index);
    });

    await FirebaseFirestore.instance.collection('notifications').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Notifications",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepOrangeAccent)),
            const SizedBox(height: 20),
            TextField(
              controller: _notificationController,
              decoration: InputDecoration(
                labelText: "Notification Message",
                prefixIcon: const Icon(Icons.notifications),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _addNotification,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrangeAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              icon: const Icon(Icons.add_alert),
              label: const Text("Add Notification"),
            ),
            const SizedBox(height: 16),
            // Notifications List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (ctx, index) => Card(
                      color: Colors.grey[900],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const Icon(Icons.notifications_active, color: Colors.deepOrangeAccent),
                        title: Text(
                          docs[index]['message'],
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                                icon: const Icon(Icons.edit, color: Colors.orange),
                                onPressed: () => _editNotification(index, docs[index].id)),
                            IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteNotification(index, docs[index].id)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
