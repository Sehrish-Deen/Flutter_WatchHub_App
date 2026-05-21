import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'productdetailpage.dart';
import 'cart_page.dart';
import 'wishlist_page.dart';
import 'profile_page.dart';
import 'home_page.dart';

class CategoryProductsPage extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryProductsPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  String searchQuery = "";
  String _selectedSort = 'name_asc';
  String _selectedPriceRange = 'all';
  String _selectedRating = 'all';
  
  User? currentUser;
  List<Map<String, dynamic>> wishlistItems = [];
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    _fetchWishlist();
  }

  Future<void> _fetchWishlist() async {
    if (currentUser == null) return;
    final docRef =
        FirebaseFirestore.instance.collection("wishlists").doc(currentUser!.uid);
    final docSnap = await docRef.get();
    if (docSnap.exists) {
      final items = List<Map<String, dynamic>>.from(docSnap.get("items") ?? []);
      setState(() {
        wishlistItems = items;
      });
    }
  }

  Future<void> _toggleWishlist(Map<String, dynamic> product) async {
    if (currentUser == null) return;
    final docRef =
        FirebaseFirestore.instance.collection("wishlists").doc(currentUser!.uid);

    bool exists = wishlistItems.any((item) => item["name"] == product["name"]);

    if (exists) {
      wishlistItems.removeWhere((item) => item["name"] == product["name"]);
    } else {
      wishlistItems.add(product);
    }

    await docRef.set({"items": wishlistItems});
    setState(() {});
  }

  bool _isInWishlist(String name) {
    return wishlistItems.any((item) => item["name"] == name);
  }

  // 🔹 NEW: Fetch average rating from reviews collection
  // ignore: unused_element
  Future<double> _getAverageRating(String productId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return 0.0;
      }

      double totalRating = 0;
      for (var doc in querySnapshot.docs) {
        final rating = doc['rating'] ?? 0;
        totalRating += (rating is int) ? rating.toDouble() : rating;
      }

      return totalRating / querySnapshot.docs.length;
    } catch (e) {
      debugPrint('Error fetching rating for product $productId: $e');
      return 0.0;
    }
  }

  void _onBottomTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomePage()));
    } else if (index == 1) {
      // Current page
    } else if (index == 2) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const WishlistPage()));
    } else if (index == 3) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const ProfilePage()));
    }
  }

  // 🔹 Show Filter Dialog
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Filter & Sort Products"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Sort By:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  _buildSortOption('Name A-Z', 'name_asc'),
                  _buildSortOption('Name Z-A', 'name_desc'),
                  _buildSortOption('Price: Low to High', 'price_low'),
                  _buildSortOption('Price: High to Low', 'price_high'),
                  _buildSortOption('Highest Rating', 'rating'),
                  
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  
                  const Text(
                    "Price Range:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  _buildPriceOption('All Prices', 'all'),
                  _buildPriceOption('Under \$50', 'under_50'),
                  _buildPriceOption('\$50 - \$100', '50_100'),
                  _buildPriceOption('\$100 - \$200', '100_200'),
                  _buildPriceOption('Above \$200', 'above_200'),
                  
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  
                  const Text(
                    "Rating:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  _buildRatingOption('All Ratings', 'all'),
                  _buildRatingOption('⭐⭐⭐⭐⭐ & up', '4_up'),
                  _buildRatingOption('⭐⭐⭐ & up', '3_up'),
                  _buildRatingOption('⭐⭐ & up', '2_up'),
                  _buildRatingOption('⭐ & up', '1_up'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedSort = 'name_asc';
                    _selectedPriceRange = 'all';
                    _selectedRating = 'all';
                    searchQuery = '';
                  });
                  Navigator.pop(context);
                },
                child: const Text("Reset"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {});
                },
                child: const Text("Apply"),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSortOption(String label, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Radio<String>(
        value: value,
        groupValue: _selectedSort,
        onChanged: (newValue) {
          setState(() {
            _selectedSort = newValue!;
          });
        },
      ),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      onTap: () {
        setState(() {
          _selectedSort = value;
        });
      },
    );
  }

  Widget _buildPriceOption(String label, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Radio<String>(
        value: value,
        groupValue: _selectedPriceRange,
        onChanged: (newValue) {
          setState(() {
            _selectedPriceRange = newValue!;
          });
        },
      ),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      onTap: () {
        setState(() {
          _selectedPriceRange = value;
        });
      },
    );
  }

  Widget _buildRatingOption(String label, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Radio<String>(
        value: value,
        groupValue: _selectedRating,
        onChanged: (newValue) {
          setState(() {
            _selectedRating = newValue!;
          });
        },
      ),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      onTap: () {
        setState(() {
          _selectedRating = value;
        });
      },
    );
  }

  // 🔹 Active Filters Row
  Widget _buildActiveFiltersRow() {
    List<Widget> filterChips = [];

    if (_selectedPriceRange != 'all') {
      filterChips.add(
        Chip(
          label: Text(
            _selectedPriceRange == 'under_50' ? 'Under \$50' :
            _selectedPriceRange == '50_100' ? '\$50-\$100' :
            _selectedPriceRange == '100_200' ? '\$100-\$200' : 'Above \$200',
            style: const TextStyle(fontSize: 12),
          ),
          onDeleted: () {
            setState(() {
              _selectedPriceRange = 'all';
            });
          },
        ),
      );
    }

    if (_selectedRating != 'all') {
      filterChips.add(
        Chip(
          label: Text(
            _selectedRating == '4_up' ? '⭐⭐⭐⭐⭐ & up' :
            _selectedRating == '3_up' ? '⭐⭐⭐ & up' :
            _selectedRating == '2_up' ? '⭐⭐ & up' : '⭐ & up',
            style: const TextStyle(fontSize: 12),
          ),
          onDeleted: () {
            setState(() {
              _selectedRating = 'all';
            });
          },
        ),
      );
    }

    if (searchQuery.isNotEmpty) {
      filterChips.add(
        Chip(
          label: Text('Search: "$searchQuery"', style: const TextStyle(fontSize: 12)),
          onDeleted: () {
            setState(() {
              searchQuery = '';
            });
          },
        ),
      );
    }

    if (filterChips.isEmpty) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text('Filters:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            ...filterChips,
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                setState(() {
                  _selectedSort = 'name_asc';
                  _selectedPriceRange = 'all';
                  _selectedRating = 'all';
                  searchQuery = '';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('Clear All', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Process and filter products
  List<QueryDocumentSnapshot> _processProducts(List<QueryDocumentSnapshot> products) {
    List<QueryDocumentSnapshot> filteredProducts = products.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data["name"] ?? "").toString().toLowerCase();
      return name.contains(searchQuery.toLowerCase());
    }).toList();

    // Apply price range filter
    filteredProducts = filteredProducts.where((doc) {
      if (_selectedPriceRange == 'all') return true;
      
      final data = doc.data() as Map<String, dynamic>;
      final price = (data["price"] ?? 0).toDouble();
      
      switch (_selectedPriceRange) {
        case 'under_50': return price < 50;
        case '50_100': return price >= 50 && price <= 100;
        case '100_200': return price > 100 && price <= 200;
        case 'above_200': return price > 200;
        default: return true;
      }
    }).toList();

    // Apply sorting
    filteredProducts.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      
      switch (_selectedSort) {
        case 'name_desc':
          return (bData["name"] ?? "").toString().compareTo((aData["name"] ?? "").toString());
        case 'price_low':
          final aPrice = (aData["price"] ?? 0).toDouble();
          final bPrice = (bData["price"] ?? 0).toDouble();
          return aPrice.compareTo(bPrice);
        case 'price_high':
          final aPrice = (aData["price"] ?? 0).toDouble();
          final bPrice = (bData["price"] ?? 0).toDouble();
          return bPrice.compareTo(aPrice);
        case 'rating':
          // Note: Rating sorting will be done after fetching average ratings
          return 0; // We'll handle this differently
        default: // 'name_asc'
          return (aData["name"] ?? "").toString().compareTo((bData["name"] ?? "").toString());
      }
    });

    return filteredProducts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 5,
        centerTitle: true,
        title: Text(
          widget.categoryName.toUpperCase(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black87, Colors.grey],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: "Filter & Sort",
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundColor: Colors.orangeAccent.withOpacity(0.2),
              child: IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.orange),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartPage()),
                  );
                },
              ),
            ),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // 🔹 Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: TextField(
                onChanged: (value) => setState(() => searchQuery = value),
                decoration: InputDecoration(
                  hintText: "Search products by name...",
                  prefixIcon: const Icon(Icons.search, color: Colors.black54),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 10),
                  suffixIcon: searchQuery.isNotEmpty ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () => setState(() => searchQuery = ''),
                  ) : null,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // 🔹 Active Filters Row
            _buildActiveFiltersRow(),

            // 🔹 Results Count
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("products")
                  .where("categoryId", isEqualTo: widget.categoryId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                
                final allProducts = snapshot.data!.docs;
                final filteredProducts = _processProducts(allProducts);
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text(
                        '${filteredProducts.length} product${filteredProducts.length != 1 ? 's' : ''} found',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (_selectedSort != 'name_asc')
                        Text(
                          'Sorted by: ${_getSortLabel()}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("products")
                    .where("categoryId", isEqualTo: widget.categoryId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final products = _processProducts(snapshot.data!.docs);

                  if (products.isEmpty) {
                    return _buildEmptyState();
                  }

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final data = products[index].data() as Map<String, dynamic>;
                      final name = data["name"] ?? "Unnamed";
                      final price = (data["price"] ?? 0).toDouble();
                      final image = data["image"] ?? "";
                      final type = data["type"] ?? "";
                      
                      final productData = {
                        "id": products[index].id,
                        "name": name,
                        "price": price,
                        "image": image,
                        "type": type,
                        "description": data["description"] ?? "",
                      };

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailPage(product: productData),
                            ),
                          );
                        },
                        child: Stack(
                          children: [
                            // 🔹 UPDATED: Pass productId to _OverlayCard to fetch rating
                            _OverlayCard(
                              image: image,
                              name: name,
                              price: price,
                              productId: products[index].id, // Pass productId for rating fetch
                              onAddToCart: () async {
                                if (currentUser == null) return;

                                final docRef = FirebaseFirestore.instance
                                    .collection("carts")
                                    .doc(currentUser!.uid);

                                final docSnap = await docRef.get();
                                List<Map<String, dynamic>> cartItems = [];
                                if (docSnap.exists) {
                                  cartItems = List<Map<String, dynamic>>.from(
                                      docSnap.get("items") ?? []);
                                }

                                bool exists = cartItems
                                    .any((item) => item["name"] == name);
                                if (!exists) {
                                  cartItems.add(productData);

                                  await docRef.set({
                                    "email": currentUser!.email,
                                    "items": cartItems,
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text("$name added to cart")),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text("$name already in cart")),
                                  );
                                }
                              },
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => _toggleWishlist(productData),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _isInWishlist(name)
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: Colors.redAccent,
                                    size: 20,
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
            ),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.black87,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          elevation: 0,
          onTap: _onBottomTap,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(
                icon: Icon(Icons.category), label: "Categories"),
            BottomNavigationBarItem(
                icon: Icon(Icons.favorite), label: "Wishlist"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            "No products found",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Try changing your search or filters",
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                searchQuery = "";
                _selectedSort = 'name_asc';
                _selectedPriceRange = 'all';
                _selectedRating = 'all';
              });
            },
            child: const Text("Reset All Filters"),
          ),
        ],
      ),
    );
  }

  String _getSortLabel() {
    switch (_selectedSort) {
      case 'name_desc': return 'Name Z-A';
      case 'price_low': return 'Price: Low to High';
      case 'price_high': return 'Price: High to Low';
      case 'rating': return 'Highest Rating';
      default: return 'Name A-Z';
    }
  }
}

/// 🔹 UPDATED: Overlay Card Widget with Dynamic Rating from Reviews Collection
class _OverlayCard extends StatefulWidget {
  final String image;
  final String name;
  final double price;
  final String productId; // 🔹 NEW: Added productId to fetch rating
  final VoidCallback onAddToCart;

  const _OverlayCard({
    required this.image,
    required this.name,
    required this.price,
    required this.productId,
    required this.onAddToCart,
  });

  @override
  State<_OverlayCard> createState() => __OverlayCardState();
}

class __OverlayCardState extends State<_OverlayCard> {
  double _averageRating = 0.0;
  bool _isLoadingRating = true;

  @override
  void initState() {
    super.initState();
    _fetchAverageRating();
  }

  Future<void> _fetchAverageRating() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('productId', isEqualTo: widget.productId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _averageRating = 0.0;
          _isLoadingRating = false;
        });
        return;
      }

      double totalRating = 0;
      for (var doc in querySnapshot.docs) {
        final rating = doc['rating'] ?? 0;
        totalRating += (rating is int) ? rating.toDouble() : rating;
      }

      setState(() {
        _averageRating = totalRating / querySnapshot.docs.length;
        _isLoadingRating = false;
      });
    } catch (e) {
      debugPrint('Error fetching rating for product ${widget.productId}: $e');
      setState(() {
        _averageRating = 0.0;
        _isLoadingRating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 5,
      shadowColor: Colors.black45,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            widget.image.isNotEmpty
                ? Image.network(
                    widget.image,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 50),
                  ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // 🔹 UPDATED: Rating display with loading state
                    _isLoadingRating
                        ? const Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Loading...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              ...List.generate(5, (index) => Icon(
                                index < _averageRating.round() 
                                    ? Icons.star 
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 14,
                              )),
                              const SizedBox(width: 4),
                              Text(
                                _averageRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                    
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "\$${widget.price.toStringAsFixed(2)}",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                        SizedBox(
                          height: 28,
                          child: ElevatedButton(
                            onPressed: widget.onAddToCart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent,
                              foregroundColor: Colors.black,
                              textStyle: const TextStyle(fontSize: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              elevation: 2,
                            ),
                            child: const Text("Add"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}