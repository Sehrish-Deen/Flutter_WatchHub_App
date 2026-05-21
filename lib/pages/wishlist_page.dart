import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_page.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  User? currentUser;
  List<Map<String, dynamic>> wishlistItems = [];
  List<Map<String, dynamic>> cartItems = [];

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    _fetchWishlist();
    _fetchCart();
  }

  Future<void> _fetchWishlist() async {
    if (currentUser == null) return;
    final docRef = FirebaseFirestore.instance
        .collection("wishlists")
        .doc(currentUser!.uid);
    final docSnap = await docRef.get();
    if (docSnap.exists) {
      final items = List<Map<String, dynamic>>.from(docSnap.get("items") ?? []);
      setState(() {
        wishlistItems = items;
      });
    }
  }

  Future<void> _fetchCart() async {
    if (currentUser == null) return;
    final docRef = FirebaseFirestore.instance
        .collection("carts")
        .doc(currentUser!.uid);
    final docSnap = await docRef.get();
    if (docSnap.exists) {
      final items = List<Map<String, dynamic>>.from(docSnap.get("items") ?? []);
      setState(() {
        cartItems = items;
      });
    }
  }

  Future<void> _removeFromWishlist(int index) async {
    if (currentUser == null) return;

    final docRef = FirebaseFirestore.instance
        .collection("wishlists")
        .doc(currentUser!.uid);

    setState(() {
      wishlistItems.removeAt(index);
    });

    await docRef.set({"items": wishlistItems});
  }

  Future<void> _addToCart(Map<String, dynamic> product) async {
    if (currentUser == null) return;

    final cartRef = FirebaseFirestore.instance
        .collection("carts")
        .doc(currentUser!.uid);
    final docSnap = await cartRef.get();

    if (docSnap.exists) {
      List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(
        docSnap.get("items") ?? [],
      );

      // Check agar product already hai
      int index = items.indexWhere((item) => item["name"] == product["name"]);

      if (index != -1) {
        // Agar already hai to quantity increase + subtotal update
        items[index]["quantity"] = (items[index]["quantity"] ?? 1) + 1;
        double price = double.tryParse(items[index]["price"].toString()) ?? 0;
        items[index]["subtotal"] = price * items[index]["quantity"];
      } else {
        // Agar new product hai to add karo
        items.add({
          "name": product["name"],
          "price": product["price"],
          "image": product["image"],
          "type": product["type"],
          "quantity": 1,
          "subtotal": product["price"],
        });
      }

      await cartRef.set({"userEmail": currentUser!.email, "items": items});

      setState(() {
        cartItems = items;
      });
    } else {
      // Agar new cart create karna hai
      await cartRef.set({
        "userEmail": currentUser!.email,
        "items": [
          {
            "name": product["name"],
            "price": product["price"],
            "image": product["image"],
            "type": product["type"],
            "quantity": 1,
            "subtotal": product["price"],
          },
        ],
      });

      setState(() {
        cartItems = [
          {
            "name": product["name"],
            "price": product["price"],
            "image": product["image"],
            "type": product["type"],
            "quantity": 1,
            "subtotal": product["price"],
          },
        ];
      });
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("${product["name"]} added to cart")));

    // Redirect to CartPage
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        elevation: 0,
        title: const Text(
          "Wishlist",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      backgroundColor: Colors.grey[200],
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: wishlistItems.isEmpty
            ? const Center(
                child: Text(
                  "Your wishlist is empty.",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              )
            : GridView.builder(
                itemCount: wishlistItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.65,
                ),
                itemBuilder: (context, index) {
                  final item = wishlistItems[index];
                  return _WishlistCard(
                    name: item["name"] ?? "",
                    image: item["image"] ?? "",
                    type: item["type"] ?? "",
                    price: item["price"] != null
                        ? "\$${item["price"].toString()}"
                        : "",
                    onRemove: () => _removeFromWishlist(index),
                    onAddToCart: () => _addToCart(item),
                  );
                },
              ),
      ),
    );
  }
}

class _WishlistCard extends StatelessWidget {
  final String image;
  final String name;
  final String type;
  final String price;
  final VoidCallback onRemove;
  final VoidCallback onAddToCart;

  const _WishlistCard({
    required this.image,
    required this.name,
    required this.type,
    required this.price,
    required this.onRemove,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + delete button
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: image.isNotEmpty
                    ? Image.network(
                        image,
                        height: 130,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 130,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 50),
                      ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Details + Add to Cart
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  type,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: onAddToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(double.infinity, 36),
                  ),
                  child: const Text(
                    "Add to Cart",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
