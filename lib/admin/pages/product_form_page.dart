import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductFormPage extends StatefulWidget {
  final String? docId; // null → Add mode, not null → Edit mode
  final Map<String, dynamic>? productData;

  const ProductFormPage({super.key, this.docId, this.productData});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _imageController;
  late TextEditingController _descriptionController; // ✅ Description

  String? _selectedCategoryId;
  String? _selectedCategoryName;

  bool get isEditMode => widget.docId != null;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.productData?["name"] ?? "");
    _priceController = TextEditingController(
        text: widget.productData?["price"]?.toString() ?? "");
    _imageController =
        TextEditingController(text: widget.productData?["image"] ?? "");
    _descriptionController =
        TextEditingController(text: widget.productData?["description"] ?? ""); // ✅ prefill

    // agar edit mode hai to purane category values set karo
    _selectedCategoryId = widget.productData?["categoryId"];
    _selectedCategoryName = widget.productData?["categoryName"];
  }

  Future<void> _saveProduct() async {
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _imageController.text.isEmpty ||
        _descriptionController.text.isEmpty || // ✅ check description
        _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please fill all fields")),
      );
      return;
    }

    final productData = {
      "name": _nameController.text,
      "price": double.tryParse(_priceController.text) ?? 0,
      "image": _imageController.text,
      "description": _descriptionController.text, // ✅ save description
      "categoryId": _selectedCategoryId,
      "categoryName": _selectedCategoryName,
      "updatedAt": FieldValue.serverTimestamp(),
    };

    final productsRef = FirebaseFirestore.instance.collection("products");

    if (isEditMode) {
      // 🔹 Update existing product
      await productsRef.doc(widget.docId).update(productData);
    } else {
      // 🔹 Add new product
      await productsRef.add({
        ...productData,
        "createdAt": FieldValue.serverTimestamp(),
      });
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(isEditMode ? "Edit Product" : "Add Product"),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Product Name
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Product Name",
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepOrangeAccent),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Product Price
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Price",
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepOrangeAccent),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Product Image
            TextField(
              controller: _imageController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Image URL",
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepOrangeAccent),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ✅ Product Description
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Description",
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepOrangeAccent),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Dropdown for categories
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("product_categories")
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator(
                      color: Colors.deepOrangeAccent);
                }

                final categories = snapshot.data!.docs;

                return DropdownButtonFormField<String>(
                  dropdownColor: Colors.grey[900],
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Select Category",
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.deepOrangeAccent),
                    ),
                  ),
                  initialValue: _selectedCategoryId, // ✅ Fixed
                  items: categories.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(data["name"] ?? "Unnamed"),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                      final selectedDoc =
                          categories.firstWhere((doc) => doc.id == value);
                      _selectedCategoryName =
                          (selectedDoc.data() as Map<String, dynamic>)["name"];
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            // Save Button
            ElevatedButton(
              onPressed: _saveProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrangeAccent,
              ),
              child: Text(isEditMode ? "Update Product" : "Add Product"),
            )
          ],
        ),
      ),
    );
  }
}
