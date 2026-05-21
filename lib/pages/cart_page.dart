import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> with TickerProviderStateMixin {
  User? currentUser;
  List<Map<String, dynamic>> cartItems = [];

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    _fetchCart();
  }

  Future<void> _fetchCart() async {
    if (currentUser == null) return;

    final docRef =
        FirebaseFirestore.instance.collection("carts").doc(currentUser!.uid);
    final docSnap = await docRef.get();

    if (docSnap.exists) {
      final rawItems = docSnap.data()?["items"] ?? [];
      final items = List<Map<String, dynamic>>.from(
          rawItems.map((item) => Map<String, dynamic>.from(item)));

      setState(() {
        cartItems = items.map((item) {
          item["quantity"] = item["quantity"] ?? 1;
          item["price"] = item["price"] ?? 0.0;
          item["name"] = item["name"] ?? "Unnamed";
          item["image"] = item["image"] ?? "";
          item["type"] = item["type"] ?? "Unknown";
          return item;
        }).toList();
      });
    }
  }

  Future<void> _updateCartInFirebase() async {
    if (currentUser == null) return;

    final userCartRef =
        FirebaseFirestore.instance.collection("carts").doc(currentUser!.uid);
    final adminCartRef =
        FirebaseFirestore.instance.collection("admin_carts").doc(currentUser!.uid);

    final cartData = {
      "userEmail": currentUser!.email ?? "Unknown",
      "items": cartItems,
      "updatedAt": FieldValue.serverTimestamp(),
    };

    await userCartRef.set(cartData);
    await adminCartRef.set(cartData);
  }

  Future<void> _clearCart() async {
    if (currentUser == null) return;

    final userCartRef =
        FirebaseFirestore.instance.collection("carts").doc(currentUser!.uid);
    final adminCartRef =
        FirebaseFirestore.instance.collection("admin_carts").doc(currentUser!.uid);

    setState(() {
      cartItems.clear();
    });

    await userCartRef.set({
      "userEmail": currentUser!.email ?? "Unknown",
      "items": [],
      "updatedAt": FieldValue.serverTimestamp(),
    });

    await adminCartRef.set({
      "userEmail": currentUser!.email ?? "Unknown",
      "items": [],
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  void _removeFromCart(int index) {
    if (index < 0 || index >= cartItems.length) return;

    final removedItem = cartItems[index];
    setState(() => cartItems.removeAt(index));
    _updateCartInFirebase();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${removedItem["name"]} removed"),
        action: SnackBarAction(
          label: "Undo",
          onPressed: () {
            setState(() => cartItems.insert(index, removedItem));
            _updateCartInFirebase();
          },
        ),
      ),
    );
  }

  void _changeQuantity(int index, int delta) {
    if (index < 0 || index >= cartItems.length) return;

    setState(() {
      final currentQty = cartItems[index]["quantity"] ?? 1;
      final newQty = currentQty + delta;
      if (newQty >= 1) {
        cartItems[index]["quantity"] = newQty;
      }
    });
    _updateCartInFirebase();
  }

  double get totalPrice {
    return cartItems.fold(0.0, (sum, item) {
      final price = (item["price"] ?? 0.0).toDouble();
      final qty = item["quantity"] ?? 1;
      return sum + (price * qty);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        elevation: 0,
        title: const Text(
          "My Cart",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      backgroundColor: Colors.grey[200],
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: cartItems.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/empty_cart.png',
                      height: 120,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Your cart is empty.",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        final subtotal =
                            (item["price"] ?? 0.0) * (item["quantity"] ?? 1);

                        return Dismissible(
                          key: Key(item["id"] ?? item["name"] + index.toString()),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => _removeFromCart(index),
                          background: Container(
                            padding: const EdgeInsets.only(right: 20),
                            alignment: Alignment.centerRight,
                            color: Colors.redAccent,
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [Colors.white, Colors.grey.shade100],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: item["image"] != null &&
                                            item["image"] != ""
                                        ? Image.network(
                                            item["image"],
                                            height: 80,
                                            width: 80,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            height: 80,
                                            width: 80,
                                            color: Colors.grey[300],
                                            child: const Icon(
                                                Icons.image_not_supported),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item["name"] ?? "Unnamed",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item["type"] ?? "Unknown",
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          "\$${item["price"]?.toStringAsFixed(2) ?? "0.00"} | Subtotal: \$${subtotal.toStringAsFixed(2)}",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade200,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                children: [
                                                  IconButton(
                                                    onPressed: () =>
                                                        _changeQuantity(
                                                            index, -1),
                                                    icon: const Icon(Icons.remove),
                                                    iconSize: 18,
                                                  ),
                                                  Text(
                                                    (item["quantity"] ?? 1)
                                                        .toString(),
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  IconButton(
                                                    onPressed: () =>
                                                        _changeQuantity(
                                                            index, 1),
                                                    icon: const Icon(Icons.add),
                                                    iconSize: 18,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            GestureDetector(
                                              onTap: () =>
                                                  _removeFromCart(index),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.redAccent
                                                      .withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.delete,
                                                  color: Colors.redAccent,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Total + Checkout
                  Container(
                    padding: const EdgeInsets.all(16),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total: \$${totalPrice.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        GestureDetector(
                          onTap: () async {
                            if (cartItems.isNotEmpty) {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CheckoutPage(
                                    total: totalPrice,
                                    cartItems: cartItems,
                                  ),
                                ),
                              );

                              if (result == true) {
                                await _clearCart();
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.black87, Colors.grey],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            child: const Text(
                              "Checkout",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
