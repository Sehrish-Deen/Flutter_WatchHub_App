// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'cart_page.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;
  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with SingleTickerProviderStateMixin {
  bool isFavorite = false;
  bool _animate = false;
  User? currentUser;
  late PhotoViewController photoViewController;
  double _scale = 1.0;

  int _selectedRating = 0;
  final TextEditingController _reviewController = TextEditingController();

  // Review Filter Variables
  String _selectedFilter = 'all'; // 'all', '5_star', '4_star', '3_star', '2_star', '1_star', 'with_comment'
  String _selectedSort = 'newest'; // 'newest', 'oldest', 'highest_rating', 'lowest_rating'

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    photoViewController = PhotoViewController(initialScale: 1.0);
    _checkWishlist();

    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() => _animate = true);
    });

    photoViewController.outputStateStream.listen((value) {
      if (mounted) {
        setState(() {
          _scale = value.scale ?? 1.0;
        });
      }
    });
  }

  @override
  void dispose() {
    photoViewController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _checkWishlist() async {
    if (currentUser == null) return;
    final docRef =
        FirebaseFirestore.instance.collection("wishlists").doc(currentUser!.uid);
    final docSnap = await docRef.get();

    if (docSnap.exists) {
      final items = List<Map<String, dynamic>>.from(docSnap.get("items") ?? []);
      setState(() {
        isFavorite = items.any((item) => item["name"] == widget.product["name"]);
      });
    }
  }

  Future<void> _toggleWishlist() async {
    if (currentUser == null) return;

    final docRef =
        FirebaseFirestore.instance.collection("wishlists").doc(currentUser!.uid);
    final docSnap = await docRef.get();

    List<Map<String, dynamic>> items = [];
    if (docSnap.exists) {
      items = List<Map<String, dynamic>>.from(docSnap.get("items") ?? []);
    }

    setState(() {
      if (isFavorite) {
        items.removeWhere((item) => item["name"] == widget.product["name"]);
        isFavorite = false;
      } else {
        items.add(widget.product);
        isFavorite = true;
      }
    });

    await docRef.set({"items": items});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isFavorite
            ? "${widget.product["name"]} added to wishlist"
            : "${widget.product["name"]} removed from wishlist"),
      ),
    );
  }

  Future<void> _addToCart() async {
    if (currentUser == null) return;

    final docRef =
        FirebaseFirestore.instance.collection("carts").doc(currentUser!.uid);
    final docSnap = await docRef.get();

    List<Map<String, dynamic>> items = [];
    if (docSnap.exists) {
      items = List<Map<String, dynamic>>.from(docSnap.get("items") ?? []);
    }

    final productData = {
      "name": widget.product["name"],
      "image": widget.product["image"],
      "description": widget.product["description"],
      "price": widget.product["salePrice"] ?? widget.product["price"],
      "rating": widget.product["rating"] ?? 0,
    };

    if (!items.any((item) => item["name"] == widget.product["name"])) {
      items.add(productData);
      await docRef.set({
        "email": currentUser!.email,
        "items": items,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${widget.product["name"]} added to cart")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Already in cart")),
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartPage()),
    );
  }

  /// 🔹 Updated _submitReview to duplicate in 'reviews' collection
  Future<void> _submitReview() async {
    if (currentUser == null || _selectedRating == 0) return;

    final productId = widget.product["id"];
    if (productId == null) return;

    final reviewData = {
      "userId": currentUser!.uid,
      "userName": currentUser!.email,
      "rating": _selectedRating,
      "comment": _reviewController.text.trim(),
      "productId": productId,
      "createdAt": FieldValue.serverTimestamp(),
    };

    // Add to nested collection
    await FirebaseFirestore.instance
        .collection("products")
        .doc(productId)
        .collection("reviews")
        .add(reviewData);

    // Duplicate to separate 'reviews' collection
    await FirebaseFirestore.instance
        .collection("reviews")
        .add(reviewData);

    _reviewController.clear();
    setState(() => _selectedRating = 0);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Review submitted")),
    );
  }

  void _handleZoomIn() {
    final currentScale = photoViewController.scale;
    if (currentScale != null) {
      photoViewController.scale = currentScale * 1.5;
    }
  }

  void _handleZoomOut() {
    final currentScale = photoViewController.scale;
    if (currentScale != null) {
      photoViewController.scale = currentScale / 1.5;
    }
  }

  /// 🔹 Show Filter Dialog
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Filter & Sort Reviews"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Filter by Rating:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChip('All Ratings', 'all'),
                      _buildFilterChip('⭐⭐⭐⭐⭐', '5_star'),
                      _buildFilterChip('⭐⭐⭐⭐', '4_star'),
                      _buildFilterChip('⭐⭐⭐', '3_star'),
                      _buildFilterChip('⭐⭐', '2_star'),
                      _buildFilterChip('⭐', '1_star'),
                      _buildFilterChip('With Comments', 'with_comment'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text("Sort by:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildSortChip('Newest First', 'newest'),
                      _buildSortChip('Oldest First', 'oldest'),
                      _buildSortChip('Highest Rating', 'highest_rating'),
                      _buildSortChip('Lowest Rating', 'lowest_rating'),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {}); // Refresh the reviews list
                },
                child: const Text("Apply"),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _selectedFilter == value,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
    );
  }

  Widget _buildSortChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _selectedSort == value,
      onSelected: (selected) {
        setState(() {
          _selectedSort = value;
        });
      },
    );
  }

  /// 🔹 Filter and Sort Reviews
  List<QueryDocumentSnapshot> _processReviews(List<QueryDocumentSnapshot> reviews) {
    // Filter reviews
    List<QueryDocumentSnapshot> filteredReviews = reviews.where((review) {
      final data = review.data() as Map<String, dynamic>;
      
      switch (_selectedFilter) {
        case '5_star':
          return data['rating'] == 5;
        case '4_star':
          return data['rating'] == 4;
        case '3_star':
          return data['rating'] == 3;
        case '2_star':
          return data['rating'] == 2;
        case '1_star':
          return data['rating'] == 1;
        case 'with_comment':
          final comment = data['comment']?.toString().trim() ?? '';
          return comment.isNotEmpty;
        default:
          return true; // 'all'
      }
    }).toList();

    // Sort reviews
    filteredReviews.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      
      switch (_selectedSort) {
        case 'oldest':
          final aTime = aData['createdAt'] ?? Timestamp.now();
          final bTime = bData['createdAt'] ?? Timestamp.now();
          return (aTime as Timestamp).compareTo(bTime as Timestamp);
        case 'highest_rating':
          final aRating = aData['rating'] ?? 0;
          final bRating = bData['rating'] ?? 0;
          return bRating.compareTo(aRating);
        case 'lowest_rating':
          final aRating = aData['rating'] ?? 0;
          final bRating = bData['rating'] ?? 0;
          return aRating.compareTo(bRating);
        default: // 'newest'
          final aTime = aData['createdAt'] ?? Timestamp.now();
          final bTime = bData['createdAt'] ?? Timestamp.now();
          return (bTime as Timestamp).compareTo(aTime as Timestamp);
      }
    });

    return filteredReviews;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final List<String> images = product["images"] != null
        ? List<String>.from(product["images"])
        : [product["image"]];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: PhotoViewGallery.builder(
              itemCount: images.length,
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: NetworkImage(images[index]),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 3,
                  controller: photoViewController,
                );
              },
              scrollPhysics: const BouncingScrollPhysics(),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              loadingBuilder: (context, event) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),

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
                      onPressed: _toggleWishlist,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🔹 UPDATED: Removed the reload/reset button from zoom controls
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).size.height * 0.5 + 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoomIn',
                  backgroundColor: Colors.black.withOpacity(0.5),
                  onPressed: _handleZoomIn,
                  child: const Icon(Icons.zoom_in, color: Colors.white),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoomOut',
                  backgroundColor: Colors.black.withOpacity(0.5),
                  onPressed: _handleZoomOut,
                  child: const Icon(Icons.zoom_out, color: Colors.white),
                ),
              ],
            ),
          ),

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
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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

                        /// ⭐ Average Rating Section
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection("products")
                              .doc(product["id"])
                              .collection("reviews")
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Row(
                                children: [
                                  Spacer(),
                                  Text("⭐ No ratings",
                                      style: TextStyle(color: Colors.black54)),
                                ],
                              );
                            }

                            var reviews = snapshot.data!.docs;
                            double totalRating = 0;
                            for (var r in reviews) {
                              totalRating += (r["rating"] ?? 0).toDouble();
                            }
                            double avgRating = totalRating / reviews.length;

                            return Row(
                              children: [
                                const Spacer(),
                                Row(
                                  children: List.generate(5, (index) {
                                    return Icon(
                                      index < avgRating
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 22,
                                    );
                                  }),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  avgRating.toStringAsFixed(1),
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "(${reviews.length} reviews)",
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 14),
                        Text(
                          "\$${product["salePrice"] ?? product["price"]}",
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
                          product["description"] ?? "No description available.",
                          style: const TextStyle(
                              fontSize: 15, color: Colors.black87, height: 1.5),
                        ),
                        const SizedBox(height: 24),

                        /// ⭐ Review Section
                        Row(
                          children: [
                            const Text(
                              "Reviews",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.filter_list),
                              onPressed: _showFilterDialog,
                              tooltip: "Filter Reviews",
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Show active filters
                        if (_selectedFilter != 'all' || _selectedSort != 'newest')
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                if (_selectedFilter != 'all')
                                  Chip(
                                    label: Text(
                                      _selectedFilter == '5_star' ? '⭐⭐⭐⭐⭐' :
                                      _selectedFilter == '4_star' ? '⭐⭐⭐⭐' :
                                      _selectedFilter == '3_star' ? '⭐⭐⭐' :
                                      _selectedFilter == '2_star' ? '⭐⭐' :
                                      _selectedFilter == '1_star' ? '⭐' :
                                      'With Comments',
                                    ),
                                    onDeleted: () {
                                      setState(() {
                                        _selectedFilter = 'all';
                                      });
                                    },
                                  ),
                                if (_selectedSort != 'newest')
                                  Chip(
                                    label: Text(
                                      _selectedSort == 'oldest' ? 'Oldest First' :
                                      _selectedSort == 'highest_rating' ? 'Highest Rating' :
                                      'Lowest Rating',
                                    ),
                                    onDeleted: () {
                                      setState(() {
                                        _selectedSort = 'newest';
                                      });
                                    },
                                  ),
                              ],
                            ),
                          ),

                        // Rating Stars for new review
                        Row(
                          children: List.generate(
                            5,
                            (index) => IconButton(
                              icon: Icon(
                                index < _selectedRating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                              ),
                              onPressed: () {
                                setState(() => _selectedRating = index + 1);
                              },
                            ),
                          ),
                        ),

                        TextField(
                          controller: _reviewController,
                          decoration: const InputDecoration(
                            hintText: "Write your review...",
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _submitReview,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Submit Review"),
                        ),

                        const SizedBox(height: 20),

                        /// Reviews List with Filtering
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection("products")
                              .doc(product["id"])
                              .collection("reviews")
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Text("No reviews yet.");
                            }

                            final processedReviews = _processReviews(snapshot.data!.docs);

                            if (processedReviews.isEmpty) {
                              return const Text("No reviews match your filters.");
                            }

                            return Column(
                              children: processedReviews.map((doc) {
                                final data =
                                    doc.data() as Map<String, dynamic>;
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      child: Icon(Icons.person),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            data["userName"] ?? "User",
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Row(
                                          children: List.generate(
                                            5,
                                            (index) => Icon(
                                              index < (data["rating"] ?? 0)
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: Colors.amber,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (data["comment"]?.isNotEmpty == true) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            data["comment"] ?? "",
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatTimestamp(data["createdAt"]),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),

                        const SizedBox(height: 30),
                        
                        /// 🔹 UPDATED: Removed the "Buy Now" button, only keeping "Add to Cart"
                        ElevatedButton.icon(
                          icon: const Icon(Icons.shopping_cart_outlined),
                          onPressed: _addToCart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 6,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          label: const Text("Add to Cart"),
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

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Recently";
    
    try {
      final date = (timestamp as Timestamp).toDate();
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 365) {
        return "${difference.inDays ~/ 365} years ago";
      } else if (difference.inDays > 30) {
        return "${difference.inDays ~/ 30} months ago";
      } else if (difference.inDays > 0) {
        return "${difference.inDays} days ago";
      } else if (difference.inHours > 0) {
        return "${difference.inHours} hours ago";
      } else if (difference.inMinutes > 0) {
        return "${difference.inMinutes} minutes ago";
      } else {
        return "Just now";
      }
    } catch (e) {
      return "Recently";
    }
  }
}