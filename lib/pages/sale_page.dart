import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sale_product_detail_page.dart';
import 'cart_page.dart';
import 'cart_data.dart';

class SalePage extends StatefulWidget {
  const SalePage({super.key});

  @override
  State<SalePage> createState() => _SalePageState();
}

class _SalePageState extends State<SalePage> {
  final CollectionReference saleProducts =
      FirebaseFirestore.instance.collection('sale_product');

  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text("🔥 Sale"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search products...",
                prefixIcon: const Icon(Icons.search, color: Colors.red),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          const SizedBox(height: 12),

          // 🔥 Products Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: saleProducts.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                final filteredDocs = docs.where((doc) {
                  final name = (doc["name"] ?? "").toString().toLowerCase();
                  return name.contains(_searchQuery.toLowerCase());
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text("No products found"));
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filteredDocs.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.65,
                  ),
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final product = doc.data() as Map<String, dynamic>;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SaleProductDetailPage(
                              productId: doc.id,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Image with Discount
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                  child: Image.network(
                                    product["imageUrl"],
                                    height: 100,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                if (product["originalPrice"] != null &&
                                    product["salePrice"] != null)
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        "-${(((product["originalPrice"] - product["salePrice"]) / product["originalPrice"]) * 100).round()}%",
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12),
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product["name"],
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    product["description"] ?? "No description",
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        "\$${product["salePrice"] ?? product["originalPrice"]}",
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red),
                                      ),
                                      const SizedBox(width: 6),
                                      if (product["originalPrice"] != null)
                                        Text(
                                          "\$${product["originalPrice"]}",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ElevatedButton(
                                    onPressed: () async {
                                      final priceToAdd = product["salePrice"] ??
                                          product["originalPrice"];

                                      final cartItem = {
                                        "name": product["name"],
                                        "price": priceToAdd,
                                        "quantity": 1,
                                        "image": product["imageUrl"],
                                        "type": product["type"] ?? "",
                                      };

                                      final user =
                                          FirebaseAuth.instance.currentUser;

                                      if (user != null) {
                                        final docRef = FirebaseFirestore
                                            .instance
                                            .collection("carts")
                                            .doc(user.uid);

                                        final snapshot = await docRef.get();

                                        if (snapshot.exists) {
                                          final existingData =
                                              snapshot.data() as Map<String, dynamic>;
                                          final items =
                                              List<Map<String, dynamic>>.from(
                                                  existingData["items"] ?? []);

                                          final index = items.indexWhere((item) =>
                                              item["name"] ==
                                              product["name"]);

                                          if (index >= 0) {
                                            items[index]["quantity"] += 1;
                                          } else {
                                            items.add(cartItem);
                                          }

                                          await docRef.set({
                                            "userEmail": user.email,
                                            "items": items,
                                          });
                                        } else {
                                          await docRef.set({
                                            "userEmail": user.email,
                                            "items": [cartItem],
                                          });
                                        }
                                      }

                                      // ✅ Local cart update bhi karein
                                      final index = cart.indexWhere(
                                          (item) => item["name"] == product["name"]);
                                      if (index >= 0) {
                                        cart[index]["quantity"] += 1;
                                      } else {
                                        cart.add(cartItem);
                                      }

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => const CartPage()),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text("Add to Cart"),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
