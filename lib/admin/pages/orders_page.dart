import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  String _searchQuery = "";

  // ✅ Admin ke liye allowed statuses
  final List<String> statuses = [
    'Processing',
    'Approved',
    'Delivered',
    'Declined',
    'Cancelled', // 👈 Added for display, but disabled
  ];

  // Status colors
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'approved':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
      case 'declined':
        return Colors.red;
      case 'cancelled':
        return Colors.grey; // 👈 Cancelled ka color
      default:
        return Colors.black54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "All Orders",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: "Search by Order ID, Email, or Product...",
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey),
                  suffixIcon: Icon(Icons.filter_list, color: Colors.grey),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // 🔹 Orders Count
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('orders').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox();
                }
                final totalOrders = snapshot.data!.docs.length;
                final filteredCount = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String orderId = doc.id.toLowerCase();
                  String email = (data['email'] ?? '').toString().toLowerCase();
                  String products = "";
                  if (data['items'] != null && data['items'] is List) {
                    products = (data['items'] as List)
                        .map((item) => item['name']?.toString() ?? "")
                        .join(", ")
                        .toLowerCase();
                  }
                  return orderId.contains(_searchQuery) ||
                      email.contains(_searchQuery) ||
                      products.contains(_searchQuery);
                }).length;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Showing $filteredCount of $totalOrders orders",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "Total: \$${snapshot.data!.docs.fold(0.0, (sum, doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return sum + (data['grandTotal'] ?? 0.0);
                        }).toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // 🔹 Orders Cards List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .orderBy("timestamp", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var orders = snapshot.data!.docs;

                  // 🔹 Apply Search Filter
                  var filteredOrders = orders.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String orderId = doc.id.toLowerCase();
                    String email = (data['email'] ?? '').toString().toLowerCase();
                    String products = "";
                    if (data['items'] != null && data['items'] is List) {
                      products = (data['items'] as List)
                          .map((item) => item['name']?.toString() ?? "")
                          .join(", ")
                          .toLowerCase();
                    }
                    return orderId.contains(_searchQuery) ||
                        email.contains(_searchQuery) ||
                        products.contains(_searchQuery);
                  }).toList();

                  if (filteredOrders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? "No orders found"
                                : "No orders matching '$_searchQuery'",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      var doc = filteredOrders[index];
                      var data = doc.data() as Map<String, dynamic>;

                      // 🔹 All items names
                      String allProducts = "";
                      if (data['items'] != null && data['items'] is List) {
                        allProducts = (data['items'] as List)
                            .map((item) => item['name']?.toString() ?? "")
                            .join(", ");
                      }

                      // 🔹 Safe status handling
                      String currentStatus =
                          (data['status'] ?? 'Processing').toString();

                      // 🔹 Date formatting
                      String orderDate = "Unknown date";
                      if (data['timestamp'] != null) {
                        final timestamp = data['timestamp'] as Timestamp;
                        orderDate =
                            "${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}";
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🔹 Header Row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      "Order #${doc.id.substring(0, 8)}...",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: getStatusColor(currentStatus)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: getStatusColor(currentStatus),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      currentStatus,
                                      style: TextStyle(
                                        color: getStatusColor(currentStatus),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // 🔹 Customer Info
                              Text(
                                data['email']?.toString() ?? "No email",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "User ID: ${data['userId']?.toString().substring(0, 10)}...",
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // 🔹 Products
                              Text(
                                "Products:",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                allProducts.isNotEmpty
                                    ? allProducts
                                    : "No products",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),

                              // 🔹 Footer Row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Date: $orderDate",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Items: ${data['items'] != null && data['items'] is List ? (data['items'] as List).length : 0}",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "\$${data['grandTotal']?.toStringAsFixed(2) ?? '0.00'}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.orange,
                                        ),
                                      ),
                                      const SizedBox(height: 4),

                                      // 🔹 Status Dropdown ya Cancelled Badge + Reason
                                      currentStatus.toLowerCase() == 'cancelled'
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                const Text(
                                                  "Cancelled",
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                if (data['cancelReason'] !=
                                                        null &&
                                                    data['cancelReason']
                                                        .toString()
                                                        .isNotEmpty)
                                                  Text(
                                                    "Reason: ${data['cancelReason']}",
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                              ],
                                            )
                                          : SizedBox(
                                              height: 32,
                                              child: DropdownButton<String>(
                                                value: currentStatus,
                                                underline: const SizedBox(),
                                                isDense: true,
                                                items: statuses.map((status) {
                                                  final isCancelled =
                                                      status == 'Cancelled';
                                                  return DropdownMenuItem<
                                                      String>(
                                                    value: status,
                                                    enabled:
                                                        !isCancelled, // 👈 Disabled for admin
                                                    child: Text(
                                                      status,
                                                      style: TextStyle(
                                                        color: isCancelled
                                                            ? Colors.grey
                                                            : getStatusColor(
                                                                status),
                                                        fontStyle: isCancelled
                                                            ? FontStyle.italic
                                                            : FontStyle.normal,
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                                onChanged: (value) {
                                                  if (value != null &&
                                                      value != 'Cancelled') {
                                                    FirebaseFirestore.instance
                                                        .collection('orders')
                                                        .doc(doc.id)
                                                        .update(
                                                            {'status': value});
                                                  }
                                                },
                                              ),
                                            ),
                                    ],
                                  ),
                                ],
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
      ),
    );
  }
}
