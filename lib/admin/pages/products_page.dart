import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_form_page.dart'; // <- common form page

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  Future<void> _deleteProduct(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection("products")
          .doc(docId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🗑️ Product deleted")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to delete product: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepOrangeAccent,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProductFormPage(), // ➕ Add product
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("products")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepOrangeAccent),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "❌ Error loading products",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final products = snapshot.data?.docs ?? [];

          if (products.isEmpty) {
            return const Center(
              child: Text(
                "No products found",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final doc = products[index];
              final data = doc.data() as Map<String, dynamic>? ?? {};

              final String name = data["name"] ?? "Unnamed";
              final double price = (data["price"] is num)
                  ? (data["price"] as num).toDouble()
                  : 0.0;
              final String category = data["category"] ?? "Uncategorized";
              final String imageUrl = data["image"] ?? "";
              final String description =
                  data["description"] ?? "No description available";

              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image,
                                    color: Colors.white54, size: 40),
                          )
                        : const Icon(Icons.image,
                            color: Colors.white54, size: 40),
                  ),
                  title: Text(
                    name,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Price: \$${price.toStringAsFixed(2)}",
                        style:
                            const TextStyle(color: Colors.deepOrangeAccent),
                      ),
                      Text(
                        "Category: $category",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        description,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.edit, color: Colors.blueAccent),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductFormPage(
                                docId: doc.id,
                                productData: data, // ✏️ Edit product
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            color: Colors.redAccent),
                        onPressed: () => _deleteProduct(doc.id),
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
