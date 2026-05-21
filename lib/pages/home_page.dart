// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:marquee/marquee.dart';
import 'package:watchhub/pages/ProductDetailPage.dart';

import 'sale_page.dart';
import 'category_products_page.dart';
import 'support_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ✅ Add to Cart
  Future<void> _addToCart(Map<String, dynamic> productData) async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to add items to cart")),
      );
      return;
    }

    try {
      final docRef =
          FirebaseFirestore.instance.collection("carts").doc(currentUser!.uid);

      final docSnap = await docRef.get();

      List<Map<String, dynamic>> cartItems = [];

      if (docSnap.exists) {
        final data = docSnap.data() as Map<String, dynamic>;
        if (data.containsKey("items") && data["items"] is List) {
          cartItems = List<Map<String, dynamic>>.from(data["items"]);
        }
      }

      bool exists = cartItems.any((item) => item["id"] == productData["id"]);

      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${productData["name"]} already in cart")),
        );
        return;
      }

      cartItems.add(productData);

      await docRef.set({
        "email": currentUser!.email,
        "items": cartItems,
        "lastUpdated": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${productData["name"]} added to cart")),
      );
    } catch (e) {
      debugPrint("🔥 Error adding to cart: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to add item to cart")),
      );
    }
  }

  // ✅ Wishlist toggle
  Future<void> _toggleWishlist(Map<String, dynamic> productData) async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to add items to wishlist")),
      );
      return;
    }

    try {
      final docRef = FirebaseFirestore.instance
          .collection("wishlists")
          .doc(currentUser!.uid);

      final docSnap = await docRef.get();
      List<Map<String, dynamic>> wishlistItems = [];

      if (docSnap.exists) {
        final data = docSnap.data() as Map<String, dynamic>;
        if (data.containsKey("items") && data["items"] is List) {
          wishlistItems = List<Map<String, dynamic>>.from(data["items"]);
        }
      }

      final exists =
          wishlistItems.any((item) => item["id"] == productData["id"]);

      if (exists) {
        wishlistItems.removeWhere((item) => item["id"] == productData["id"]);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${productData["name"]} removed from wishlist")),
        );
      } else {
        wishlistItems.add(productData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${productData["name"]} added to wishlist")),
        );
      }

      await docRef.set({
        "email": currentUser!.email,
        "items": wishlistItems,
        "lastUpdated": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("🔥 Error updating wishlist: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update wishlist")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== SALE MARQUEE =====
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SalePage()),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.redAccent, Colors.deepOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                height: 42,
                width: double.infinity,
                alignment: Alignment.center,
                child: Marquee(
                  text:
                      "🔥 BIG SALE — Up to 50% OFF on select watches! Tap to explore →     ",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.8,
                  ),
                  scrollAxis: Axis.horizontal,
                  blankSpace: 60.0,
                  velocity: 80.0,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildBanners(),
            const SizedBox(height: 28),
            _buildDynamicCategories(context),
            const SizedBox(height: 32),
            // Popular Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "POPULAR",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      size: 20,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildPopular(),
            const SizedBox(height: 32),
            // Trending Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "TRENDING COLLECTIONS",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Colors.grey[800],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildTrending(),
            const SizedBox(height: 40),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -_animation.value),
            child: child,
          );
        },
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SupportPage()),
            );
          },
          backgroundColor: Colors.orange,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Icon(Icons.chat, size: 30),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ================== Dynamic Categories ==================
  Widget _buildDynamicCategories(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("product_categories")
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final categories = snapshot.data!.docs;

        return SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final data = categories[index].data() as Map<String, dynamic>;
              final imageUrl = (data["image"] ?? "").toString().isNotEmpty
                  ? data["image"]
                  : "https://via.placeholder.com/100";
              final name = data["name"] ?? "Unnamed";
              final categoryId = categories[index].id;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryProductsPage(
                        categoryId: categoryId,
                        categoryName: name,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 90,
                  margin: const EdgeInsets.only(right: 16),
                  child: Column(
                    children: [
                      Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: ClipOval(
                            child: Image.network(
                              imageUrl,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.watch,
                                    size: 40, color: Colors.grey[400]);
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 34,
                        child: Text(
                          name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

// ================== Banners ==================
Widget _buildBanners() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection("home_page")
        .where("type", isEqualTo: "Banner")
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const SizedBox();
      final banners = snapshot.data!.docs;

      return CarouselSlider(
        options: CarouselOptions(
          height: 200,
          autoPlay: true,
          enlargeCenterPage: true,
          viewportFraction: 0.85,
          autoPlayInterval: const Duration(seconds: 4),
          autoPlayAnimationDuration: const Duration(milliseconds: 800),
        ),
        items: banners.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final imageUrl = (data["image"] ?? "").toString().isNotEmpty
              ? data["image"]
              : "https://via.placeholder.com/400";
          final title = data["title"] ?? "";
          final subtitle = data["subtitle"] ?? "";

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                  ),
                  // Overlay gradient for text visibility
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                  // Text
                  Positioned(
                    left: 16,
                    bottom: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    },
  );
}


  // ================== Trending (Updated with Subtitle) ==================
  Widget _buildTrending() {
    return SizedBox(
      height: 200,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("home_page")
            .where("type", isEqualTo: "Trending")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();
          final items = snapshot.data!.docs;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final data = items[index].data() as Map<String, dynamic>;
              final imageUrl = (data["image"] ?? "").toString().isNotEmpty
                  ? data["image"]
                  : "https://via.placeholder.com/200";

              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 16),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Image.network(
                          imageUrl,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Text(
                              data["title"] ?? "",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data["subtitle"] ?? "",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
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
    );
  }

  // ================== Popular ==================
  Widget _buildPopular() {
    return SizedBox(
      height: 280,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("home_page")
            .where("type", isEqualTo: "Popular")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();
          final items = snapshot.data!.docs;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final data = items[index].data() as Map<String, dynamic>;
              final imageUrl = (data["image"] ?? "").toString().isNotEmpty
                  ? data["image"]
                  : "https://via.placeholder.com/200";

              final product = {
                "id": items[index].id,
                "name": data["name"] ?? "Unnamed",
                "description": data["description"] ?? "",
                "price": data["price"] ?? 0,
                "image": data["image"] ?? "",
                "type": "Popular",
              };

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailPage(product: product),
                    ),
                  );
                },
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20)),
                          image: DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product["name"],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text(
                              product["description"],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "\$${product["price"]}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepOrange,
                                      fontSize: 16),
                                ),
                                // ✅ Heart with realtime wishlist state
                                StreamBuilder<DocumentSnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection("wishlists")
                                      .doc(currentUser?.uid)
                                      .snapshots(),
                                  builder: (context, wishSnap) {
                                    bool isWishlisted = false;
                                    if (wishSnap.hasData &&
                                        wishSnap.data!.exists) {
                                      final wishData =
                                          wishSnap.data!.data()
                                              as Map<String, dynamic>;
                                      if (wishData.containsKey("items")) {
                                        final items =
                                            List<Map<String, dynamic>>.from(
                                                wishData["items"]);
                                        isWishlisted = items.any((item) =>
                                            item["id"] == product["id"]);
                                      }
                                    }
                                    return IconButton(
                                      onPressed: () {
                                        _toggleWishlist(product);
                                      },
                                      icon: Icon(
                                        isWishlisted
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isWishlisted
                                            ? Colors.red
                                            : Colors.grey,
                                      ),
                                                                      );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                _addToCart(product);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrangeAccent,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Add to Cart",
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
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
    );
  }
}

