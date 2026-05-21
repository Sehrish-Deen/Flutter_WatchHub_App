import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; // for opening web URLs

class CheckoutPage extends StatefulWidget {
  final double total;
  final List<Map<String, dynamic>> cartItems;

  const CheckoutPage({super.key, required this.total, required this.cartItems});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();

  String _selectedPayment = "Cash on Delivery";

  double get deliveryCharges => 200;
  double get tax => widget.total * 0.15;
  double _discount = 0;
  String? _appliedCoupon;

  double get grandTotal => widget.total + deliveryCharges + tax - _discount;

  final CollectionReference couponsRef =
      FirebaseFirestore.instance.collection('coupons');

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderSummary(),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Customer Information",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    _buildCustomerForm(),
                    const SizedBox(height: 20),

                    // Coupon Section
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _couponController,
                            decoration: const InputDecoration(
                                labelText: "Coupon Code (optional)",
                                border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _applyCoupon,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange),
                          child: const Text("Apply"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    const Text("Payment Method",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    RadioListTile(
                      value: "Cash on Delivery",
                      groupValue: _selectedPayment,
                      title: const Text("Cash on Delivery"),
                      onChanged: (v) =>
                          setState(() => _selectedPayment = v!),
                    ),
                    RadioListTile(
                      value: "Online Payment",
                      groupValue: _selectedPayment,
                      title: const Text("Online Payment"),
                      onChanged: (v) =>
                          setState(() => _selectedPayment = v!),
                    ),

                    if (_selectedPayment == "Online Payment") ...[
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _paymentButtonWithIcon(
                                "EasyPaisa",
                                "https://www.easypaisa.com.pk",
                                Colors.green,
                                Icons.mobile_friendly),
                            const SizedBox(width: 8),
                            _paymentButtonWithIcon(
                                "JazzCash",
                                "https://www.jazzcash.com.pk",
                                Colors.orange,
                                Icons.payment),
                            const SizedBox(width: 8),
                            _paymentButtonWithIcon(
                                "PayPal",
                                "https://www.paypal.com",
                                Colors.blue,
                                Icons.account_balance_wallet),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  if (_selectedPayment == "Cash on Delivery") {
                    _placeOrder();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            "Please select an online payment method above")));
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                      child: Text("Place Order",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerForm() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return "Enter your full name";
            if (v.trim().length < 3) return "Name must be at least 3 characters";
            return null;
          },
          decoration: const InputDecoration(
            labelText: "Full Name",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return "Enter phone number";
            if (!RegExp(r'^\d{10,13}$').hasMatch(v.trim())) {
              return "Enter valid phone number (10-13 digits)";
            }
            return null;
          },
          decoration: const InputDecoration(
            labelText: "Phone Number",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _addressController,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return "Enter delivery address";
            if (v.trim().length < 5) return "Address too short";
            return null;
          },
          decoration: const InputDecoration(
            labelText: "Delivery Address",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _cityController,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return "Enter your city";
            if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(v.trim())) {
              return "City must contain only letters";
            }
            return null;
          },
          decoration: const InputDecoration(
            labelText: "City",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _notesController,
          maxLines: 2,
          decoration: const InputDecoration(
              labelText: "Delivery Notes (optional)",
              border: OutlineInputBorder()),
        ),
      ],
    );
  }

  Widget _paymentButtonWithIcon(
      String title, String url, Color color, IconData icon) {
    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 20),
        label: Text(title, style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        onPressed: () async {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url),
                mode: LaunchMode.externalApplication);
            Future.delayed(const Duration(seconds: 3), () {
              _placeOrder(paymentMethod: title);
            });
          }
        },
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Order Summary",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.cartItems.length,
            itemBuilder: (context, index) {
              final item = widget.cartItems[index];
              final subtotal =
                  (double.tryParse(item["price"].toString()) ?? 0) *
                      (item["quantity"] ?? 1);
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(item["name"]),
                subtitle: Text(item["type"] ?? ""),
                trailing: Text(
                  "\$ ${subtotal.toStringAsFixed(2)}",
                  style: const TextStyle(
                      color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
          const Divider(),
          _row("Subtotal", "\$ ${widget.total.toStringAsFixed(2)}"),
          _row("Delivery", "\$ ${deliveryCharges.toStringAsFixed(2)}"),
          _row("Tax (15%)", "\$ ${tax.toStringAsFixed(2)}"),
          if (_discount > 0)
            _row("Discount", "-\$ ${_discount.toStringAsFixed(2)}"),
          const Divider(),
          _row("Grand Total", "\$ ${grandTotal.toStringAsFixed(2)}", bold: true),
        ],
      ),
    );
  }

  Widget _row(String left, String right, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(left,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(right,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  String _generateOrderId() {
    final rand = Random();
    return "ORD-${DateTime.now().millisecondsSinceEpoch}-${rand.nextInt(9999)}";
  }

Future<void> _placeOrder({String? paymentMethod}) async {
  if (!_formKey.currentState!.validate()) return;

  final user = FirebaseAuth.instance.currentUser;
  final orderId = _generateOrderId();

  await FirebaseFirestore.instance.collection("orders").doc(orderId).set({
    "orderId": orderId,
    "userId": user?.uid,
    "email": user?.email ?? "",
    "name": _nameController.text,
    "phone": _phoneController.text,
    "address": _addressController.text,
    "city": _cityController.text,
    "notes": _notesController.text,
    "coupon": _appliedCoupon ?? "",
    "discount": _discount,
    "payment": paymentMethod ?? _selectedPayment,
    "subtotal": widget.total,
    "delivery": deliveryCharges,
    "tax": tax,
    "grandTotal": grandTotal,
    "items": widget.cartItems,
    "status": "Processing", // ✅ initial status
    "timestamp": FieldValue.serverTimestamp(),
  });

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("🎉 Payment Successful!"),
      content: const Text(
        "Your order has been placed successfully.\nWe’ll contact you soon.",
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context); // close dialog
            Navigator.pop(context, true); // return true to CartPage
          },
          child: const Text("OK"),
        )
      ],
    ),
  );
}


  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    try {
      final query =
          await couponsRef.where('code', isEqualTo: code).limit(1).get();

      if (query.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Invalid coupon code")),
        );
        return;
      }

      final doc = query.docs.first;
      final status = doc['status'] ?? 'active';
      if (status.toLowerCase() != 'active') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Coupon is $status")),
        );
        return;
      }

      final discountValue = (doc['discountValue'] as num).toDouble();
      setState(() {
        _discount = (discountValue / 100) * widget.total;
        _appliedCoupon = code;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Coupon '$code' applied! $discountValue% off")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
}
