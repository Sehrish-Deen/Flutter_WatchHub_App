import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'track_order_page.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  // 🔹 Status ke liye colors
  Color getStatusColor(String status) {
    final s = status.trim().toLowerCase();
    switch (s) {
      case "delivered":
        return Colors.green;
      case "processing":
        return Colors.orange;
      case "approved":
        return Colors.lightBlue;
      case "declined":
        return Colors.red;
      case "cancelled":
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  // 🔹 Track Order button visibility
  bool canTrack(String status) {
    final s = status.trim().toLowerCase();
    return s == "processing" || s == "approved" || s == "delivered";
  }

  // 🔹 Rs to Dollar conversion
  String convertPriceToDollar(dynamic price) {
    if (price == null) return "\$0.00";
    String priceStr = price.toString();

    if (priceStr.contains("Rs")) {
      String numericPart =
          priceStr.replaceAll("Rs", "").replaceAll(",", "").trim();
      double? amount = double.tryParse(numericPart);
      if (amount != null) {
        return "\$${amount.toStringAsFixed(2)}";
      }
    }

    double? amount = double.tryParse(priceStr);
    if (amount != null) {
      return "\$${amount.toStringAsFixed(2)}";
    }

    return "\$0.00";
  }

  // 🔹 Cancel Order Firestore Update
  Future<void> _cancelOrder(String orderId, String reason) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': 'Cancelled',
        'cancelReason': reason,
      });
    } catch (e) {
      print("Error cancelling order: $e");
    }
  }

  // 🔹 Show reason dialog
  void _showCancelDialog(BuildContext context, String orderId) {
    String selectedReason = "";
    List<String> reasons = [
      "Ordered by mistake",
      "Found a better price",
      "Delivery time is too long",
      "Need to change address",
      "Payment issue",
      "Product not needed",
      "Ordered wrong item",
      "Other"
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Why do you want to cancel?"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: reasons.map((reason) {
                    return RadioListTile(
                      title: Text(reason),
                      value: reason,
                      groupValue: selectedReason,
                      onChanged: (value) {
                        setState(() {
                          selectedReason = value.toString();
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
                ElevatedButton(
                  onPressed: selectedReason.isEmpty
                      ? null
                      : () {
                          Navigator.pop(context);
                          _showConfirmDialog(context, orderId, selectedReason);
                        },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 🔹 Confirmation dialog
  void _showConfirmDialog(
      BuildContext context, String orderId, String reason) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Cancellation"),
          content: Text(
              "Are you sure you want to cancel this order?\n\nReason: $reason"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("No"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                _cancelOrder(orderId, reason);
                Navigator.pop(context);
              },
              child: const Text("Yes, Cancel"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.grey.shade200,
          elevation: 0,
          title: const Text(
            "My Orders",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        backgroundColor: Colors.grey[200],
        body: const Center(
          child: Text("Please log in to see your orders."),
        ),
      );
    }

    final currentUserId = user.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        elevation: 0,
        title: const Text(
          "My Orders",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      backgroundColor: Colors.grey[200],
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('userId', isEqualTo: currentUserId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                  child: Text(
                      "Something went wrong: ${snapshot.error.toString()}"));
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final orders = snapshot.data!.docs;

            if (orders.isEmpty) {
              return const Center(
                child: Text(
                  "No orders yet.",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              );
            }

            return ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final data = orders[index].data() as Map<String, dynamic>;
                final orderId = orders[index].id;

                final items = (data['items'] != null &&
                        data['items'] is List &&
                        data['items'].isNotEmpty)
                    ? data['items'] as List
                    : [];

                final status = (data['status'] ?? 'Processing').toString();
                final price = convertPriceToDollar(data['grandTotal']);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔹 Product List with Image + Name + Qty + Price
                          Column(
                            children: items.map((item) {
                              final name = item['name'] ?? '';
                              final imageUrl = item['image'] ?? '';
                              final quantity =
                                  item['quantity']?.toString() ?? '1';
                              final itemPrice =
                                  item['price']?.toString() ?? '0';

                              return ListTile(
                                leading: imageUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          imageUrl,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                                  Icons.image_not_supported),
                                        ),
                                      )
                                    : const Icon(Icons.image,
                                        size: 40, color: Colors.grey),
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Quantity: $quantity",
                                        style: const TextStyle(
                                            color: Colors.grey)),
                                    Text("Price: Rs. $itemPrice",
                                        style: TextStyle(
                                            color: Colors.orange.shade700,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 8),
                          Text(
                            "Order ID: $orderId",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Total: $price",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange),
                          ),
                          const SizedBox(height: 12),

                          // 🔹 Status + Cancel Reason (if any)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color:
                                        getStatusColor(status).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                        color: getStatusColor(status),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12),
                                  ),
                                ),
                                if (status.toLowerCase() == "cancelled" &&
                                    data['cancelReason'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      "Reason: ${data['cancelReason']}",
                                      style: const TextStyle(
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic,
                                          fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // 🔹 Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (canTrack(status))
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              TrackOrderPage(orderId: orderId)),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    minimumSize: const Size(120, 35),
                                  ),
                                  child: const Text("Track Order"),
                                ),

                              if (status.toLowerCase() != "cancelled" &&
                                  status.toLowerCase() != "delivered")
                                ElevatedButton(
                                  onPressed: () =>
                                      _showCancelDialog(context, orderId),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    minimumSize: const Size(120, 35),
                                  ),
                                  child: const Text("Cancel Order"),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
