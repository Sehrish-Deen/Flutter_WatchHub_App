import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class CouponsPage extends StatelessWidget {
  const CouponsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final CollectionReference couponsRef =
        FirebaseFirestore.instance.collection('coupons');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Coupons / Offers",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.grey.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.grey.shade200,

      // ✅ Firestore se realtime fetch
      body: StreamBuilder<QuerySnapshot>(
        stream: couponsRef.snapshots(), // pura collection listen karega
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No coupons available",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              // ✅ Safe fetching with defaults
              final title = data['title'] ?? "Coupon";
              final description = data['description'] ?? "";
              final code = data['code'] ?? "";
              final discount = data['discountValue']?.toString() ?? "0";
              final status = data['status'] ?? "active";
              final expiryTimestamp = data['expiryDate'] as Timestamp?;
              final expiry = expiryTimestamp != null
                  ? "Valid till ${expiryTimestamp.toDate().toLocal().toString().split(' ')[0]}"
                  : "No expiry";

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "$title - $discount%",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (status != "active")
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              color: status == "used"
                                  ? Colors.grey
                                  : Colors.redAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (description.isNotEmpty)
                      Text(
                        description,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.grey),
                      ),
                    const SizedBox(height: 6),
                    if (code.isNotEmpty)
                      Text(
                        "Code: $code",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      expiry,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    if (code.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Material(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(25),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(25),
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: code));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Coupon code '$code' copied!"),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 20,
                              ),
                              child: const Text(
                                "Copy Code",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
