import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> signUp() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    // Empty fields check
    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      showMessage("Please fill all fields");
      return;
    }

    // Username length check
    if (name.length < 3) {
      showMessage("Username must be at least 3 characters");
      return;
    }

    // Username should not contain numbers
    if (RegExp(r'[0-9]').hasMatch(name)) {
      showMessage("Username cannot contain numbers");
      return;
    }

    // Username should contain only letters and spaces
    if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(name)) {
      showMessage("Username can only contain letters");
      return;
    }

    // Email validation
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(email)) {
      showMessage("Enter a valid email");
      return;
    }

    // Password minimum length
    if (password.length < 6) {
      showMessage("Password must be at least 6 characters");
      return;
    }

    // Strong password validation
    if (!RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9]).+$')
        .hasMatch(password)) {
      showMessage(
        "Password must contain uppercase, lowercase and number",
      );
      return;
    }

    // Password match check
    if (password != confirmPassword) {
      showMessage("Passwords do not match");
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCred.user!.uid)
          .set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      showMessage("Account created successfully!");

      await Future.delayed(const Duration(milliseconds: 200));

      if (mounted) {
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? "Signup failed");
    } catch (e) {
      showMessage("Unexpected error: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void showMessage(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 80),

            const Text(
              "Create Account",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Sign up to get started",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 40),

            _buildInputField(
              controller: nameController,
              label: "Full Name",
              icon: Icons.person,
            ),

            const SizedBox(height: 15),

            _buildInputField(
              controller: emailController,
              label: "Email",
              icon: Icons.email,
            ),

            const SizedBox(height: 15),

            _buildInputField(
              controller: passwordController,
              label: "Password",
              icon: Icons.lock,
              obscure: _obscurePassword,
              toggleObscure: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),

            const SizedBox(height: 15),

            _buildInputField(
              controller: confirmPasswordController,
              label: "Confirm Password",
              icon: Icons.lock_outline,
              obscure: _obscureConfirmPassword,
              toggleObscure: () {
                setState(() {
                  _obscureConfirmPassword =
                      !_obscureConfirmPassword;
                });
              },
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  side: const BorderSide(
                    color: Colors.orange,
                    width: 2,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isLoading ? null : signUp,
                child: isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.orange,
                      )
                    : const Text(
                        "Sign Up",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    VoidCallback? toggleObscure,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(
          icon,
          color: Colors.orange,
        ),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.orange,
                ),
                onPressed: toggleObscure,
              )
            : null,
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}