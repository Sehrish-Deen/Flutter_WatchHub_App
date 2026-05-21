import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:watchhub/admin/responsive_admin_panel.dart';
import 'login_page.dart';
import '../main.dart';
 // import your admin page

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  User? currentUser;
  bool loading = true;

  @override
  void initState() {
    super.initState();

    FirebaseAuth.instance.idTokenChanges().listen((user) {
      setState(() {
        currentUser = user;
        loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }

    if (currentUser != null) {
      // 👑 Check if admin
      if (currentUser!.email == "admin@watchhub.com") {
        print("👑 Admin logged in");
        return const ResponsiveAdminPanel();
      }

      // ✅ Normal user
      print("✅ User logged in: ${currentUser!.email}");
      return const MainPage();
    }

    // 🚪 No user logged in
    print("🚪 No user -> LoginPage");
    return const LoginPage();
  }
}
