import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'category_products_page.dart'; // ✅ page for products inside category

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Categories",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // 🔍 Search bar
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.grey.shade200],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Search categories...',
                  prefixIcon: Icon(Icons.search, color: Colors.black54),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // 📦 Firestore Categories Grid
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("product_categories")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error loading categories"));
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Colors.black));
                  }

                  final docs = snapshot.data!.docs;

                  // 🔎 Search filter apply
                  final filteredCategories = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title = (data["name"] ?? "").toString();
                    return title
                        .toLowerCase()
                        .contains(searchQuery.toLowerCase());
                  }).toList();

                  if (filteredCategories.isEmpty) {
                    return const Center(child: Text("No categories found"));
                  }

                  return GridView.builder(
                    itemCount: filteredCategories.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemBuilder: (context, index) {
                      final doc = filteredCategories[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return buildCategoryCard(
                        context,
                        doc.id,               // ✅ Pass document ID
                        data["image"] ?? "",
                        data["name"] ?? "",
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Category Card
  Widget buildCategoryCard(
      BuildContext context, String categoryId, String imgPath, String title) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: imgPath.isNotEmpty
                ? Image.network(imgPath,
                    fit: BoxFit.contain,
                    height: 80,
                    errorBuilder: (context, error, stack) =>
                        const Icon(Icons.broken_image, size: 40))
                : const Icon(Icons.image_not_supported, size: 40),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              // ✅ Pass both categoryId & categoryName
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryProductsPage(
                    categoryId: categoryId,
                    categoryName: title,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: const Size(100, 32),
              elevation: 3,
            ),
            child: const Text(
              "View",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
