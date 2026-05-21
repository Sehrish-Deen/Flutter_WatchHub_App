// ignore: file_names
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _addressController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  final TextEditingController _cityController =
      TextEditingController();

  final TextEditingController _countryController =
      TextEditingController();

  bool _isLoading = true;

  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;

  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  /// Load existing data
  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return;

      DocumentSnapshot<Map<String, dynamic>> doc =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .get();

      if (doc.exists) {
        final data = doc.data()!;

        _nameController.text = data["name"] ?? "";
        _emailController.text =
            data["email"] ?? user.email ?? "";

        _addressController.text = data["address"] ?? "";

        _phoneController.text = data["phone"] ?? "";

        _cityController.text = data["city"] ?? "";

        _countryController.text = data["country"] ?? "";

        _uploadedImageUrl = data["profileImage"];
      } else {
        _emailController.text = user.email ?? "";
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
    }

    setState(() => _isLoading = false);
  }

  /// Pick image
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();

        setState(() {
          _pickedImage = pickedFile;
          _pickedImageBytes = bytes;
        });
      } else {
        setState(() {
          _pickedImage = pickedFile;
        });
      }
    }
  }

  /// Upload image
  Future<String?> _uploadImage(String uid) async {
    if (_pickedImage == null) return _uploadedImageUrl;

    try {
      String fileExtension =
          _pickedImage!.path.split('.').last;

      final ref = FirebaseStorage.instance
          .ref()
          .child("profile_images/$uid.$fileExtension");

      UploadTask uploadTask;

      if (kIsWeb) {
        uploadTask = ref.putData(_pickedImageBytes!);
      } else {
        uploadTask =
            ref.putFile(File(_pickedImage!.path));
      }

      final snapshot = await uploadTask;

      final downloadUrl =
          await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint("Image upload error: $e");
      return null;
    }
  }

  /// Save updated data
  Future<void> _saveUserData() async {
    try {
      final name = _nameController.text.trim();

      final phone = _phoneController.text.trim();

      final city = _cityController.text.trim();

      final country = _countryController.text.trim();

      // Name empty check
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Name is required"),
          ),
        );
        return;
      }

      // Name minimum length
      if (name.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Name must be at least 3 characters",
            ),
          ),
        );
        return;
      }

      // Name cannot contain numbers
      if (RegExp(r'[0-9]').hasMatch(name)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Name cannot contain numbers",
            ),
          ),
        );
        return;
      }

      // Name only letters/spaces
      if (!RegExp(r'^[a-zA-Z ]+$')
          .hasMatch(name)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Name can only contain letters",
            ),
          ),
        );
        return;
      }

      // Phone validation
      if (phone.isNotEmpty &&
          !RegExp(r'^[0-9]{11}$')
              .hasMatch(phone)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Phone number must be 11 digits",
            ),
          ),
        );
        return;
      }

      // City validation
      if (city.isNotEmpty &&
          RegExp(r'[0-9]').hasMatch(city)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "City name cannot contain numbers",
            ),
          ),
        );
        return;
      }

      // Country validation
      if (country.isNotEmpty &&
          RegExp(r'[0-9]').hasMatch(country)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Country name cannot contain numbers",
            ),
          ),
        );
        return;
      }

      final user =
          FirebaseAuth.instance.currentUser;

      if (user == null) return;

      String? imageUrl =
          await _uploadImage(user.uid);

      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set({
        "name": name,
        "email": _emailController.text.trim(),
        "address":
            _addressController.text.trim(),
        "phone": phone,
        "city": city,
        "country": country,
        "profileImage":
            imageUrl ?? _uploadedImageUrl ?? "",
        "updatedAt":
            FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Profile Updated Successfully"),
        ),
      );

      setState(() {
        _uploadedImageUrl =
            imageUrl ?? _uploadedImageUrl;

        _pickedImage = null;
        _pickedImageBytes = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,

        title: const Text(
          "Edit Profile",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),

        iconTheme:
            const IconThemeData(color: Colors.white),
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.orange,
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.all(16),

                child: Column(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.all(20),

                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(20),

                        color: Colors.white,

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withOpacity(0.05),

                            blurRadius: 10,

                            offset:
                                const Offset(0, 4),
                          ),
                        ],
                      ),

                      child: Column(
                        children: [
                          Stack(
                            alignment:
                                Alignment.bottomRight,

                            children: [
                              CircleAvatar(
                                radius: 50,

                                backgroundImage:
                                    _pickedImage != null
                                        ? (kIsWeb
                                            ? MemoryImage(
                                                _pickedImageBytes!)
                                            : FileImage(
                                                    File(
                                                      _pickedImage!
                                                          .path,
                                                    ),
                                                  )
                                                as ImageProvider)
                                        : (_uploadedImageUrl !=
                                                    null &&
                                                _uploadedImageUrl!
                                                    .isNotEmpty
                                            ? NetworkImage(
                                                _uploadedImageUrl!)
                                            : null),

                                child: (_pickedImage ==
                                            null &&
                                        (_uploadedImageUrl ==
                                                null ||
                                            _uploadedImageUrl!
                                                .isEmpty))
                                    ? const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),

                              GestureDetector(
                                onTap: _pickImage,

                                child: Container(
                                  decoration:
                                      const BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                  ),

                                  padding:
                                      const EdgeInsets.all(
                                          6),

                                  child: const Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          _buildTextField(
                            controller:
                                _nameController,
                            label: "Name",
                            icon: Icons.person,
                          ),

                          const SizedBox(height: 15),

                          _buildTextField(
                            controller:
                                _emailController,
                            label: "Email",
                            icon: Icons.email,
                            readOnly: true,
                          ),

                          const SizedBox(height: 15),

                          _buildTextField(
                            controller:
                                _addressController,
                            label: "Address",
                            icon:
                                Icons.location_city,
                          ),

                          const SizedBox(height: 15),

                          _buildTextField(
                            controller:
                                _phoneController,
                            label: "Phone",
                            icon: Icons.phone,
                          ),

                          const SizedBox(height: 15),

                          _buildTextField(
                            controller:
                                _cityController,
                            label: "City",
                            icon: Icons.location_on,
                          ),

                          const SizedBox(height: 15),

                          _buildTextField(
                            controller:
                                _countryController,
                            label: "Country",
                            icon: Icons.flag,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 35),

                    Material(
                      color: Colors.black,

                      borderRadius:
                          BorderRadius.circular(20),

                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(20),

                        splashColor: Colors.orange
                            .withOpacity(0.3),

                        onTap: _saveUserData,

                        child: Container(
                          width: double.infinity,
                          height: 50,

                          alignment:
                              Alignment.center,

                          child: const Text(
                            "Save Changes",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// Custom TextField
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,

      decoration: InputDecoration(
        labelText: label,

        prefixIcon:
            Icon(icon, color: Colors.orange),

        filled: true,
        fillColor: Colors.grey[100],

        labelStyle:
            const TextStyle(color: Colors.black54),

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),

          borderSide: BorderSide.none,
        ),
      ),

      style:
          const TextStyle(color: Colors.black87),
    );
  }
}