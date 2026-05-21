import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 🔹 Confirmation Dialog before Delete
  Future<void> _confirmDelete(String collection, String docId) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Notification"),
          content: const Text("Are you sure you want to delete this notification?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection(collection)
                    .doc(docId)
                    .delete();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Badge widget
  Widget _buildBadge(Widget child, int count) {
    if (count == 0) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -6,
          top: -6,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            constraints: const BoxConstraints(
              minWidth: 18,
              minHeight: 18,
            ),
            child: Text(
              "$count",
              style: const TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black87,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.orangeAccent),
            onPressed: () => Navigator.pop(context),
          ),

          /// 🔹 AppBar title with total badge
          title: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("support_requests")
                .where("userStatus", isEqualTo: "Unread")
                .snapshots(),
            builder: (context, supportSnapshot) {
              int supportCount =
                  supportSnapshot.hasData ? supportSnapshot.data!.size : 0;

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("notifications")
                    .where("status", isEqualTo: "Unread")
                    .snapshots(),
                builder: (context, adminSnapshot) {
                  int adminCount =
                      adminSnapshot.hasData ? adminSnapshot.data!.size : 0;

                  int totalCount = supportCount + adminCount;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Notifications",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      _buildBadge(
                          const Icon(Icons.notifications,
                              color: Colors.orangeAccent),
                          totalCount),
                    ],
                  );
                },
              );
            },
          ),

          /// 🔹 TabBar with badges for both tabs
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("support_requests")
                  .where("userStatus", isEqualTo: "Unread")
                  .snapshots(),
              builder: (context, supportSnapshot) {
                int supportCount =
                    supportSnapshot.hasData ? supportSnapshot.data!.size : 0;

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("notifications")
                      .where("status", isEqualTo: "Unread")
                      .snapshots(),
                  builder: (context, adminSnapshot) {
                    int adminCount =
                        adminSnapshot.hasData ? adminSnapshot.data!.size : 0;

                    return TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.orangeAccent,
                      labelColor: Colors.orangeAccent,
                      unselectedLabelColor: Colors.white70,
                      tabs: [
                        Tab(
                          icon: _buildBadge(
                              const Icon(Icons.support_agent), supportCount),
                          text: "Support",
                        ),
                        Tab(
                          icon: _buildBadge(
                              const Icon(Icons.notifications), adminCount),
                          text: "Admin Alerts",
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),

        /// 🔹 Tab content
        body: TabBarView(
          controller: _tabController,
          children: [
            /// Support Requests
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("support_requests")
                  .orderBy("adminRespondedAt", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final notifs = snapshot.data!.docs;
                if (notifs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No support requests yet!",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: notifs.length,
                  itemBuilder: (context, index) {
                    var data = notifs[index].data() as Map<String, dynamic>;
                    var docId = notifs[index].id;

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        title: Text(
                          data["subject"] ?? "No subject",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Text("Your Message: ${data["message"] ?? "N/A"}"),
                            Text(
                                "Admin Reply: ${data["adminReply"] ?? "No reply"}"),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: data["userStatus"] == "Read"
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                data["userStatus"] == "Read"
                                    ? "Read"
                                    : "Unread",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: data["userStatus"] == "Read"
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          FirebaseFirestore.instance
                              .collection("support_requests")
                              .doc(docId)
                              .update({"userStatus": "Read"});
                        },

                        /// 🔹 Delete button
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _confirmDelete("support_requests", docId);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            /// Admin Alerts
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("notifications")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final notifs = snapshot.data!.docs;
                if (notifs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No admin alerts yet!",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: notifs.length,
                  itemBuilder: (context, index) {
                    var data = notifs[index].data() as Map<String, dynamic>;
                    var docId = notifs[index].id;

                    return Card(
                      color: Colors.grey[900],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.notifications,
                            color: Colors.deepOrangeAccent),
                        title: Text(
                          data["title"] ?? "Admin Alert",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data["message"] ?? "",
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: data["status"] == "Read"
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                data["status"] == "Read" ? "Read" : "Unread",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: data["status"] == "Read"
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          FirebaseFirestore.instance
                              .collection("notifications")
                              .doc(docId)
                              .update({"status": "Read"});
                        },

                        /// 🔹 Delete button
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _confirmDelete("notifications", docId);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
