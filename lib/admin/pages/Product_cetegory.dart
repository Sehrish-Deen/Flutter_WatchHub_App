import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductCategoryPage extends StatefulWidget {
  const ProductCategoryPage({super.key});

  @override
  State<ProductCategoryPage> createState() => _ProductCategoryPageState();
}

class _ProductCategoryPageState extends State<ProductCategoryPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();

  final CollectionReference categoriesCollection =
      FirebaseFirestore.instance.collection("product_categories");

  // ✅ Add new category dialog
  void _addCategoryDialog() {
    _clearControllers();
    _showCategoryDialog(isUpdate: false);
  }

  // ✅ Update category dialog
  void _updateCategoryDialog(String id, Map<String, dynamic> category) {
    _nameController.text = category["name"] ?? "";
    _descriptionController.text = category["description"] ?? "";
    _imageController.text = category["image"] ?? "";
    _showCategoryDialog(isUpdate: true, docId: id);
  }

  // ✅ Show dialog (add/update)
  void _showCategoryDialog({required bool isUpdate, String? docId}) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isUpdate ? "Update Category" : "Add New Category",
                    style: const TextStyle(
                      color: Colors.deepOrangeAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInputField("Category Name", _nameController),
                  const SizedBox(height: 15),
                  _buildInputField("Description", _descriptionController),
                  const SizedBox(height: 15),
                  _buildInputField("Image URL", _imageController),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        child: const Text("Cancel",
                            style: TextStyle(color: Colors.white70)),
                        onPressed: () {
                          _clearControllers();
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrangeAccent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (_nameController.text.isNotEmpty) {
                            Map<String, dynamic> newCategory = {
                              "name": _nameController.text.trim(),
                              "description": _descriptionController.text.trim(),
                              "image": _imageController.text.trim(),
                            };

                            if (isUpdate && docId != null) {
                              await categoriesCollection.doc(docId).update(newCategory);
                            } else {
                              await categoriesCollection.add(newCategory);
                            }

                            _clearControllers();
                            Navigator.pop(context);
                          }
                        },
                        child: Text(isUpdate ? "Update" : "Add"),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _clearControllers() {
    _nameController.clear();
    _descriptionController.clear();
    _imageController.clear();
  }

  Future<void> _deleteCategory(String id) async {
    await categoriesCollection.doc(id).delete();
  }

  Widget _buildInputField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.black54,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Colors.deepOrangeAccent, width: 2),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
      String id, Map<String, dynamic> category, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepOrangeAccent.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top action row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.deepOrangeAccent),
                onPressed: () => _updateCategoryDialog(id, category),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteCategory(id),
              ),
            ],
          ),

          // Image
          if (category["image"] != null &&
              category["image"].toString().isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                category["image"],
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 100,
                  width: double.infinity,
                  color: Colors.grey[800],
                  child: const Icon(Icons.broken_image,
                      color: Colors.white54, size: 40),
                ),
              ),
            )
          else
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.image_not_supported,
                  color: Colors.white54, size: 40),
            ),

          // Details section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category["name"] ?? "No Name",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  category["description"] ?? "",
                  style: const TextStyle(color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Manage Product Categories"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: categoriesCollection.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                  child: Text("Error loading categories",
                      style: TextStyle(color: Colors.red)));
            }
            if (!snapshot.hasData) {
              return const Center(
                  child: CircularProgressIndicator(
                      color: Colors.deepOrangeAccent));
            }

            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return const Center(
                  child: Text("No categories added yet",
                      style: TextStyle(color: Colors.white70)));
            }

            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                return _buildCategoryCard(doc.id, data, context);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepOrangeAccent,
        onPressed: _addCategoryDialog,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
