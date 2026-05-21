import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CouponsPage extends StatefulWidget {
  const CouponsPage({super.key});

  @override
  State<CouponsPage> createState() => _CouponsPageState();
}

class _CouponsPageState extends State<CouponsPage> {
  final CollectionReference couponsRef =
      FirebaseFirestore.instance.collection('coupons');

  // 🔹 Add or Edit Coupon Dialog
  void _showCouponDialog({DocumentSnapshot? doc}) {
    final TextEditingController codeController =
        TextEditingController(text: doc != null ? doc['code'] : '');
    final TextEditingController discountController =
        TextEditingController(text: doc != null ? doc['discountValue'].toString() : '');

    // 🔹 Status dropdown value
    String statusValue = doc != null ? doc['status'] : 'active';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(doc != null ? "Edit Coupon" : "Add Coupon"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: "Coupon Code",
                prefixIcon: Icon(Icons.local_offer),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: discountController,
              decoration: const InputDecoration(
                labelText: "Discount %",
                prefixIcon: Icon(Icons.percent),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: statusValue,
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'expired', child: Text('Expired')),
              ],
              decoration: const InputDecoration(
                labelText: "Status",
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                if (val != null) statusValue = val;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrangeAccent),
            onPressed: () async {
              final code = codeController.text.trim();
              final discount = double.tryParse(discountController.text.trim()) ?? 0;

              if (code.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter coupon code"))
                );
                return;
              }

              if (discount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Discount must be greater than 0"))
                );
                return;
              }

              try {
                if (doc != null) {
                  await couponsRef.doc(doc.id).update({
                    'code': code,
                    'discountValue': discount,
                    'status': statusValue,
                  });
                } else {
                  await couponsRef.add({
                    'code': code,
                    'discountType': 'percentage',
                    'discountValue': discount,
                    'status': statusValue,
                    'usedBy': [],
                    'expiryDate': Timestamp.fromDate(
                        DateTime.now().add(const Duration(days: 30))),
                  });
                }

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(doc != null ? "Coupon updated" : "Coupon added"))
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e"))
                );
              }
            },
            child: Text(doc != null ? "Update" : "Add"),
          ),
        ],
      ),
    );
  }

  // 🔹 Delete Coupon
  Future<void> _deleteCoupon(String docId) async {
    try {
      await couponsRef.doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Coupon deleted"))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Coupons"),
        backgroundColor: Colors.deepOrangeAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: couponsRef.snapshots(),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text("No Coupons Available",
                  style: TextStyle(color: Colors.white70)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: docs.length,
            itemBuilder: (ctx, index) {
              final doc = docs[index];
              final expiry = (doc['expiryDate'] as Timestamp).toDate();
              final now = DateTime.now();
              String status = doc['status'];
              if (expiry.isBefore(now)) status = 'expired';

              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.local_offer, color: Colors.deepOrangeAccent),
                  title: Text(
                    doc['code'],
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Discount: ${doc['discountValue']}%",
                          style: const TextStyle(color: Colors.white70)),
                      Text("Status: ${status.toUpperCase()}",
                          style: TextStyle(
                              color: status == 'active'
                                  ? Colors.green
                                  : (status == 'expired'
                                      ? Colors.red
                                      : Colors.orange),
                              fontWeight: FontWeight.bold)),
                      Text("Expiry: ${expiry.toString().split(' ')[0]}",
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _showCouponDialog(doc: doc)),
                      IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteCoupon(doc.id)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCouponDialog(),
        backgroundColor: Colors.deepOrangeAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
