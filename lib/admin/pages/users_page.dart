import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No users found", style: TextStyle(color: Colors.orange, fontSize: 16)));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white, // 🔹 White background
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Colors.orange, width: 6), // 🔹 Orange accent
                    ),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData['name'] ?? "No Name",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange, // 🔹 Orange Name
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("Email: ${userData['email'] ?? ''}",
                          style: const TextStyle(color: Colors.black87)),
                      Text("Address: ${userData['address'] ?? ''}",
                          style: const TextStyle(color: Colors.black87)),
                      Text("Phone: ${userData['phone'] ?? ''}",
                          style: const TextStyle(color: Colors.black87)),
                      if (userData.containsKey('age'))
                        Text("Age: ${userData['age']}",
                            style: const TextStyle(color: Colors.black87)),
                      if (userData.containsKey('city'))
                        Text("City: ${userData['city']}",
                            style: const TextStyle(color: Colors.black87)),
                    ],
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
