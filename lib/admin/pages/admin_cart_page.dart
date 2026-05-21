import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminCartPage extends StatefulWidget {
  const AdminCartPage({super.key});

  @override
  State<AdminCartPage> createState() => _AdminCartPageState();
}

class _AdminCartPageState extends State<AdminCartPage> {
  final CollectionReference carts =
      FirebaseFirestore.instance.collection('carts'); // user carts collection

  // Clear all cart items for a specific user
  Future<void> clearUserCart(String userId) async {
    await carts.doc(userId).delete();
  }

  double calculateTotal(List<Map<String, dynamic>> items) {
    double total = 0;
    for (var item in items) {
      final price = double.tryParse(item['price'].toString()) ?? 0;
      final qty = item['quantity'] ?? 1;
      total += price * qty;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "All User Carts",
          style: TextStyle(color: Colors.deepOrangeAccent),
        ),
        iconTheme: const IconThemeData(color: Colors.deepOrangeAccent),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: carts.orderBy("updatedAt", descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  "Error loading carts",
                  style: TextStyle(color: Colors.white),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.deepOrangeAccent,
                ),
              );
            }

            final data = snapshot.data!.docs;

            if (data.isEmpty) {
              return const Center(
                child: Text(
                  "No carts found",
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            return ListView(
              children: data.map((doc) {
                final cart = doc.data() as Map<String, dynamic>;
                final userEmail = cart['userEmail'] ?? "Unknown";
                final items = List<Map<String, dynamic>>.from(cart['items'] ?? []);
                final totalPrice = calculateTotal(items);

                return Card(
                  color: Colors.grey[900],
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row (User + Clear)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Cart of: $userEmail",
                              style: const TextStyle(
                                color: Colors.deepOrangeAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.clear_all,
                                color: Colors.orangeAccent,
                              ),
                              onPressed: () => clearUserCart(doc.id),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Table of cart items
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor:
                                WidgetStateProperty.all(Colors.deepOrangeAccent),
                            columns: const [
                              DataColumn(
                                label: Text("Product",
                                    style: TextStyle(color: Colors.white)),
                              ),
                              DataColumn(
                                label: Text("Quantity",
                                    style: TextStyle(color: Colors.white)),
                              ),
                              DataColumn(
                                label: Text("Price",
                                    style: TextStyle(color: Colors.white)),
                              ),
                              DataColumn(
                                label: Text("Subtotal",
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                            rows: items.map((item) {
                              final productName = item['name'] ?? "No Name";
                              final qty = item['quantity'] ?? 0;
                              final price =
                                  double.tryParse(item['price'].toString()) ?? 0.0;
                              final subtotal = price * qty;

                              return DataRow(cells: [
                                DataCell(Text(productName,
                                    style: const TextStyle(color: Colors.white))),
                                DataCell(Text("$qty",
                                    style: const TextStyle(color: Colors.white))),
                                DataCell(Text("\$$price",
                                    style: const TextStyle(color: Colors.white))),
                                DataCell(Text("\$${subtotal.toStringAsFixed(2)}",
                                    style: const TextStyle(color: Colors.white))),
                              ]);
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 10),
                        // Total Price
                        Text(
                          "Total: \$${totalPrice.toStringAsFixed(2)}",
                          style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
