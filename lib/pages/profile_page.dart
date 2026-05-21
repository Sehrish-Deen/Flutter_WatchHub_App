import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_page.dart';
import '../auth/login_page.dart'; // 👈 zaroor import karna

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isLoading = true;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _loadUserData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 🔹 Firestore se user data load karna
  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore
          .instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          userData = doc.data();
          _isLoading = false;
        });
      } else {
        setState(() {
          userData = {
            "name": user.displayName ?? "User",
            "email": user.email ?? "Not Available",
            "phone": "",
            "address": "",
            "city": "",
            "country": "",
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("⚠️ Error loading profile: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Profile",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ✅ Profile Avatar + Name
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundImage:
                              const AssetImage("assets/images/profile_avatar.png"),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          userData?["name"] ?? "User",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          userData?["email"] ?? "user@example.com",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ✅ Personal Information
                  _buildSectionTitle("Personal Information"),
                  _buildInfoTile(Icons.person, "Full Name",
                      userData?["name"] ?? "N/A"),
                  _buildInfoTile(
                      Icons.email, "Email", userData?["email"] ?? "N/A"),
                  _buildInfoTile(
                      Icons.phone, "Phone", userData?["phone"] ?? "N/A"),

                  const SizedBox(height: 20),

                  // ✅ Shipping Address
                  _buildSectionTitle("Shipping Address"),
                  _buildInfoTile(
                      Icons.home, "Address", userData?["address"] ?? "N/A"),
                  _buildInfoTile(
                      Icons.location_city, "City", userData?["city"] ?? "N/A"),
                  _buildInfoTile(
                      Icons.public, "Country", userData?["country"] ?? "N/A"),

                  const SizedBox(height: 35),

                  // ✅ Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildButton(
                        text: "Edit Profile",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const EditProfilePage()),
                          ).then((_) => _loadUserData()); // 👈 edit ke baad refresh
                        },
                      ),
                      _buildButton(
                        text: "Logout",
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Confirm Logout"),
                              content: const Text(
                                  "Are you sure you want to logout?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    FirebaseAuth.instance.signOut();
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const LoginPage()),
                                      (route) => false,
                                    );
                                  },
                                  child: const Text(
                                    "Logout",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  // 🔹 Section Title
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  // 🔹 Info Card
  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    )),
                const SizedBox(height: 3),
                Text(value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Button
  Widget _buildButton({required String text, required VoidCallback onTap}) {
    return Material(
      color: Colors.black,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.orange.withOpacity(0.3),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          width: 140,
          height: 45,
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
