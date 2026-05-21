import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:watchhub/pages/about_page.dart';
import 'package:watchhub/pages/support_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void showModal(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey.shade100,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const Divider(),
                const SizedBox(height: 10),
                Text(
                  content,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.grey.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.grey.shade200,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Account
            Card(
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: ListTile(
                leading: const Icon(Icons.person, color: Colors.blue),
                title: const Text(
                  "Account Information",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                void showModal(BuildContext context) {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final firestore = FirebaseFirestore.instance;

  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.grey.shade100,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return StreamBuilder<DocumentSnapshot>(
        stream: firestore.collection("users").doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final userData = snapshot.data!.data() as Map<String, dynamic>;

          nameController.text = userData["name"] ?? "";
          mobileController.text = userData["phone"] ?? "";
          emailController.text = userData["email"] ?? "";
          bool quickLogin = userData["quickLogin"] ?? false;

          return StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 50,
                        height: 5,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const Text(
                        "Account Information",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      // Full Name
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: "Full Name",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Mobile
                      TextField(
                        controller: mobileController,
                        decoration: const InputDecoration(
                          labelText: "Mobile Number",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Email
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Enable Quick Login switch
                      SwitchListTile(
                        title: const Text("Enable Quick Login"),
                        value: quickLogin,
                        onChanged: (val) {
                          setState(() {
                            quickLogin = val;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Save Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        onPressed: () async {
                          await firestore.collection("users").doc(uid).update({
                            "name": nameController.text,
                            "phone": mobileController.text,
                            "email": emailController.text,
                            "quickLogin": quickLogin,
                          });

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Account updated successfully")),
                          );
                        },
                        child: const Text(
                          "Save",
                          style: TextStyle(color: Colors.white),
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
    },
  );
}

                showModal(context);
                },
              ),
            ),
            const SizedBox(height: 16),
            // Privacy
            Card(
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: ListTile(
                leading: const Icon(Icons.lock, color: Colors.redAccent),
                title: const Text(
                  "Privacy & Policies",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                void showPrivacyModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.grey.shade100,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return DefaultTabController(
        length: 2, // 2 tabs
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Tabs
              const TabBar(
                labelColor: Colors.black,
                indicatorColor: Colors.orange,
                tabs: [
                  Tab(text: "Privacy Policy"),
                  Tab(text: "Terms & Conditions"),
                ],
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  children: [
                    // Privacy Policy content
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                     child: const SingleChildScrollView(
  child: Text(
    "At WatchHub, we respect your privacy and are committed to protecting your personal data. "
    "This Privacy Policy explains how we collect, use, and safeguard your information when you use our mobile application.\n\n"

    "1. Information We Collect\n\n"
    "• Personal Information: Name, email, contact number, shipping address, billing address.\n"
    "• Account Information: Username, password (encrypted).\n"
    "• Transaction Data: Purchase history, order details, payment method (Note: we do not store payment card details; payments are processed securely by third-party providers).\n"
    "• Device Information: Device type, operating system, IP address, app usage statistics.\n"
    "• User-Generated Content: Reviews, ratings, and feedback provided on the platform.\n\n"

    "2. How We Use Your Information\n\n"
    "• To provide, manage, and improve our services.\n"
    "• To process orders, payments, and deliveries.\n"
    "• To communicate about orders, promotions, or updates.\n"
    "• To personalize user experience through recommendations and filters.\n"
    "• For fraud prevention, security monitoring, and legal compliance.\n\n"

    "3. Sharing of Information\n\n"
    "We do not sell or rent your personal data. However, we may share information with:\n"
    "• Service Providers: Payment gateways, delivery partners, and technical support.\n"
    "• Legal Authorities: If required by law or to protect the rights of WatchHub.\n\n"

    "4. Data Security\n\n"
    "• Your passwords are encrypted and never shared.\n"
    "• Secure Socket Layer (SSL) technology is used for transactions.\n"
    "• Regular audits and monitoring are conducted to protect user data.\n\n"

    "5. Your Rights\n\n"
    "• Access and update your personal details in your profile.\n"
    "• Request deletion of your account.\n"
    "• Opt-out of marketing emails at any time.\n\n"

    "6. Cookies & Tracking\n\n"
    "We may use cookies and similar technologies to enhance your browsing experience, "
    "improve functionality, and analyze app usage.\n\n"

    "7. Changes to Privacy Policy\n\n"
    "We may update this Privacy Policy from time to time. "
    "Users will be notified of significant changes via email or app notifications.\n\n"

    "8. Contact Us\n\n"
    "For any privacy-related queries, contact us at:\n"
    "📧 support@watchhub.com",
    style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
  ),
),

                    ),

                    // Terms & Conditions content
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                     child: const SingleChildScrollView(
  child: Text(
    "Welcome to WatchHub! By accessing or using our mobile application, you agree to comply with and be bound by these Terms & Conditions. "
    "Please read them carefully before using the app.\n\n"

    "1. Acceptance of Terms\n\n"
    "By downloading, accessing, or using WatchHub, you agree to these Terms & Conditions. "
    "If you do not agree, you must discontinue using the application.\n\n"

    "2. User Responsibilities\n\n"
    "• Provide accurate and up-to-date information when registering.\n"
    "• Keep your login credentials confidential.\n"
    "• Do not engage in fraudulent, abusive, or unlawful activities on the platform.\n\n"

    "3. Purchases & Payments\n\n"
    "• All payments are processed securely via third-party providers.\n"
    "• WatchHub does not store credit/debit card details.\n"
    "• Orders are subject to availability and confirmation of payment.\n\n"

    "4. Intellectual Property\n\n"
    "• All content, trademarks, and designs available on WatchHub are owned by or licensed to WatchHub.\n"
    "• Users may not copy, modify, distribute, or exploit any content without prior permission.\n\n"

    "5. Limitation of Liability\n\n"
    "• WatchHub is not responsible for delays, losses, or damages caused by third-party services (delivery, payment gateways, etc.).\n"
    "• The app is provided 'as is' without warranties of any kind.\n\n"

    "6. Account Termination\n\n"
    "• WatchHub reserves the right to suspend or terminate accounts for violations of these Terms & Conditions.\n"
    "• Users may request account deletion at any time.\n\n"

    "7. Changes to Terms\n\n"
    "• WatchHub may update these Terms & Conditions periodically.\n"
    "• Continued use of the app after updates constitutes acceptance of the revised terms.\n\n"

    "8. Governing Law\n\n"
    "• These Terms & Conditions shall be governed by and interpreted under the laws of your jurisdiction.\n\n"

    "9. Contact Us\n\n"
    "For questions or concerns regarding these Terms & Conditions, contact us at:\n"
    "📧 support@watchhub.com",
    style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
  ),
),

                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
 showPrivacyModal(context);
                },
              ),
            ),
            const SizedBox(height: 16),
            // Help & Support
          Card(
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  child: ListTile(
    leading: const Icon(Icons.help, color: Colors.green),
    title: const Text(
      "Help & Support",
      style: TextStyle(fontWeight: FontWeight.bold),
    ),
    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SupportPage()),
      );
    },
  ),
),

            const SizedBox(height: 16),
            // About / App Info
           Card(
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  child: ListTile(
    leading: const Icon(Icons.info, color: Colors.orange),
    title: const Text(
      "About / App Info",
      style: TextStyle(fontWeight: FontWeight.bold),
    ),
    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AboutPage()),
      );
    },
  ),
),
            const SizedBox(height: 16),

// Feedback Card
Card(
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  child: ListTile(
    leading: const Icon(Icons.feedback, color: Colors.orange),
    title: const Text(
      "Feedback",
      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
    ),
    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
    onTap: () {
      void showFeedbackModal(BuildContext context) {
        final formKey = GlobalKey<FormState>();
        final subjectController = TextEditingController();
        final messageController = TextEditingController();
        final user = FirebaseAuth.instance.currentUser;
        String? selectedCategory;

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            bool isSubmitting = false;

            return StatefulBuilder(
              builder: (context, setState) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Drag Handle
                          Container(
                            width: 50,
                            height: 5,
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const Text(
                            "Send Feedback",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Subject
                          TextFormField(
                            controller: subjectController,
                            decoration: InputDecoration(
                              labelText: "Subject",
                              labelStyle: const TextStyle(color: Colors.orange),
                              prefixIcon:
                                  const Icon(Icons.subject, color: Colors.orange),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: Colors.orange, width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) =>
                                value!.isEmpty ? "Enter a subject" : null,
                          ),
                          const SizedBox(height: 12),

                          // Message
                          TextFormField(
                            controller: messageController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: "Message",
                              labelStyle: const TextStyle(color: Colors.orange),
                              alignLabelWithHint: true,
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(bottom: 60),
                                child: const Icon(Icons.message,
                                    color: Colors.orange),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 0,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: Colors.orange, width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) =>
                                value!.isEmpty ? "Enter your message" : null,
                          ),
                          const SizedBox(height: 12),

                          // Category Dropdown
                          DropdownButtonFormField<String>(
                            initialValue: selectedCategory,
                            items: ["Bug", "Suggestion", "Complaint", "General"]
                                .map((cat) => DropdownMenuItem(
                                      value: cat,
                                      child: Text(cat),
                                    ))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => selectedCategory = val),
                            decoration: InputDecoration(
                              labelText: "Category",
                              labelStyle: const TextStyle(color: Colors.orange),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: Colors.orange, width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) =>
                                value == null ? "Select a category" : null,
                          ),
                          const SizedBox(height: 20),

                          // Submit Button
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 30,
                              ),
                            ),
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (formKey.currentState!.validate()) {
                                      setState(() => isSubmitting = true);

                                      await FirebaseFirestore.instance
                                          .collection("support_requests")
                                          .add({
                                        "userId": user?.uid ?? "",
                                        "email": user?.email ?? "",
                                        "subject": subjectController.text.trim(),
                                        "message": messageController.text.trim(),
                                        "category": selectedCategory,
                                        "status": "Pending",
                                        "adminReply": "",
                                        "timestamp":
                                            FieldValue.serverTimestamp(),
                                      });

                                      setState(() => isSubmitting = false);
                                      Navigator.pop(context);

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              "✅ Feedback submitted successfully"),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    }
                                  },
                            icon: isSubmitting
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send, color: Colors.white),
                            label: Text(
                              isSubmitting ? "Submitting..." : "Submit",
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16),
                            ),
                          ),
                          const SizedBox(height: 20),

                         /// ===== SHOW ADMIN REPLY & STATUS =====

                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      }

      showFeedbackModal(context);
    },
  ),
),


            const SizedBox(height: 30),
            const Center(
              child: Text(
                "App Version 1.0.0",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
