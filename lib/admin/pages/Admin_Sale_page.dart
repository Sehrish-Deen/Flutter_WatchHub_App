import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSalePage extends StatefulWidget {
  const AdminSalePage({super.key});

  @override
  State<AdminSalePage> createState() => _AdminSalePageState();
}

class _AdminSalePageState extends State<AdminSalePage> {
  // Use "sale_product" collection instead of "products"
  final CollectionReference saleProducts =
      FirebaseFirestore.instance.collection('sale_product');

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController originalPriceController = TextEditingController();
  final TextEditingController salePriceController = TextEditingController();
  final TextEditingController imageController = TextEditingController();

  String? editingDocId;

  void clearFields() {
    nameController.clear();
    descriptionController.clear();
    originalPriceController.clear();
    salePriceController.clear();
    imageController.clear();
    editingDocId = null;
  }

  void showProductDialog({bool isEdit = false}) {
    if (!isEdit) clearFields();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          isEdit ? 'Edit Product' : 'Add Product',
          style: const TextStyle(color: Colors.deepOrangeAccent),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField("Name", nameController),
              const SizedBox(height: 10),
              _buildTextField("Description", descriptionController),
              const SizedBox(height: 10),
              _buildTextField("Original Price", originalPriceController,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              _buildTextField("Sale Price", salePriceController,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              _buildTextField("Image URL", imageController),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () {
                clearFields();
                Navigator.pop(context);
              },
              child: const Text("Cancel", style: TextStyle(color: Colors.white))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrangeAccent),
            onPressed: () async {
              final data = {
                "name": nameController.text.trim(),
                "description": descriptionController.text.trim(),
                "originalPrice": double.tryParse(originalPriceController.text) ?? 0,
                "salePrice": double.tryParse(salePriceController.text) ?? 0,
                "imageUrl": imageController.text.trim(),
                "updatedAt": FieldValue.serverTimestamp(),
              };

              if (isEdit && editingDocId != null) {
                await saleProducts.doc(editingDocId).update(data);
              } else {
                await saleProducts.add({
                  ...data,
                  "createdAt": FieldValue.serverTimestamp(),
                });
              }

              clearFields();
              Navigator.pop(context);
            },
            child: Text(isEdit ? "Update" : "Add"),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.deepOrangeAccent),
        ),
      ),
    );
  }

  Future<void> deleteProduct(String id) async {
    await saleProducts.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Admin Sale Page"),
        backgroundColor: Colors.black,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepOrangeAccent,
        onPressed: () => showProductDialog(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: saleProducts.orderBy("createdAt", descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
                child: Text("No products yet",
                    style: TextStyle(color: Colors.white70)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: data["imageUrl"] != null && data["imageUrl"].isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            data["imageUrl"],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.image, size: 60, color: Colors.white54),
                  title: Text(
                    data["name"] ?? "Unnamed",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data["description"] ?? "",
                        style: const TextStyle(color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            "\$${data["originalPrice"]}",
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "\$${data["salePrice"]}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        onPressed: () {
                          editingDocId = doc.id;
                          nameController.text = data["name"];
                          descriptionController.text = data["description"];
                          originalPriceController.text = data["originalPrice"].toString();
                          salePriceController.text = data["salePrice"].toString();
                          imageController.text = data["imageUrl"];
                          showProductDialog(isEdit: true);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => deleteProduct(doc.id),
                      ),
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
