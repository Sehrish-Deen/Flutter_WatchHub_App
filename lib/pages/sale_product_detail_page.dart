import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'wishlist_data.dart';
import 'cart_data.dart';
import 'cart_page.dart';

class SaleProductDetailPage extends StatefulWidget {
  final String productId; // Firestore document ID
  const SaleProductDetailPage({super.key, required this.productId});

  @override
  State<SaleProductDetailPage> createState() => _SaleProductDetailPageState();
}

class _SaleProductDetailPageState extends State<SaleProductDetailPage>
    with SingleTickerProviderStateMixin {
  final CollectionReference saleProducts =
      FirebaseFirestore.instance.collection('sale_product');

  Map<String, dynamic>? productData;
  bool isFavorite = false;
  bool _animate = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProduct();
  }

  Future<void> fetchProduct() async {
    final doc = await saleProducts.doc(widget.productId).get();
    if (doc.exists) {
      setState(() {
        productData = doc.data() as Map<String, dynamic>;
        isFavorite =
            wishlist.any((item) => item["name"] == productData!["name"]);
        isLoading = false;
      });

      Future.delayed(const Duration(milliseconds: 200), () {
        setState(() {
          _animate = true;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator()));
    }

    final product = productData!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 🔹 Hero + Tap to Fullscreen
          Hero(
            tag: product["imageUrl"],
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        FullScreenImagePage(imageUrl: product["imageUrl"]),
                  ),
                );
              },
              child: Container(
                height: MediaQuery.of(context).size.height * 0.5,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(product["imageUrl"]),
                    fit: BoxFit.cover,
                  ),
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
              ),
            ),
          ),

          // 🔹 Gradient Overlay
          Container(
            height: MediaQuery.of(context).size.height * 0.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 🔹 AppBar Buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.5),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.5),
                    child: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          isFavorite = !isFavorite;
                          if (isFavorite) {
                            wishlist.add(product);
                          } else {
                            wishlist.removeWhere(
                                (item) => item["name"] == product["name"]);
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🔹 Product Info Section
          AnimatedSlide(
            offset: _animate ? Offset.zero : const Offset(0, 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              opacity: _animate ? 1 : 0,
              duration: const Duration(milliseconds: 600),
              child: DraggableScrollableSheet(
                initialChildSize: 0.55,
                minChildSize: 0.55,
                maxChildSize: 0.95,
                builder: (_, controller) => Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: SingleChildScrollView(
                    controller: controller,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product["name"],
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Spacer(),
                            Row(
                              children: List.generate(
                                5,
                                (index) => Icon(
                                  index < (product["rating"] ?? 0)
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          "\$${product["salePrice"] ?? product["originalPrice"]}",
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.green),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          "Description",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product["description"] ??
                              "No description available.",
                          style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.5),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon:
                                    const Icon(Icons.shopping_cart_outlined),
                                onPressed: () async {
                                  final priceToAdd =
                                      product["salePrice"] ??
                                          product["originalPrice"];

                                  final cartItem = {
                                    "name": product["name"],
                                    "price": priceToAdd,
                                    "quantity": 1,
                                    "image": product["imageUrl"],
                                    "type": product["type"] ?? "",
                                  };

                                  final index = cart.indexWhere((item) =>
                                      item["name"] == product["name"]);
                                  if (index >= 0) {
                                    cart[index]["quantity"] += 1;
                                  } else {
                                    cart.add(cartItem);
                                  }

                                  final user =
                                      FirebaseAuth.instance.currentUser;
                                  if (user != null) {
                                    final docRef = FirebaseFirestore.instance
                                        .collection("carts")
                                        .doc(user.uid);
                                    await docRef.set({
                                      "email": user.email,
                                      "items": cart
                                    });
                                  }

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const CartPage()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14)),
                                  elevation: 6,
                                ),
                                label: const Text("Add to Cart"),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.payment),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text("Proceed to Buy")));
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrange,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14)),
                                  elevation: 6,
                                ),
                                label: const Text("Buy Now"),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 🔹 FullScreen Zoom Page (same as existing)
class FullScreenImagePage extends StatefulWidget {
  final String imageUrl;
  const FullScreenImagePage({super.key, required this.imageUrl});

  @override
  State<FullScreenImagePage> createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<FullScreenImagePage> {
  final TransformationController _controller = TransformationController();
  TapDownDetails? _doubleTapDetails;

  void _handleDoubleTap() {
    if (_controller.value != Matrix4.identity()) {
      _controller.value = Matrix4.identity();
    } else if (_doubleTapDetails != null) {
      final pos = _doubleTapDetails!.localPosition;
      _controller.value = Matrix4.identity()
        ..translate(-pos.dx * 1.5, -pos.dy * 1.5)
        ..scale(2.5);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onDoubleTapDown: (details) => _doubleTapDetails = details,
            onDoubleTap: _handleDoubleTap,
            child: InteractiveViewer(
              transformationController: _controller,
              panEnabled: true,
              scaleEnabled: true,
              minScale: 1.0,
              maxScale: 4.0,
              child: Center(
                child: Hero(
                  tag: widget.imageUrl,
                  child: Image.network(widget.imageUrl, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
