// Flutter & Firebase
import 'package:rxdart/rxdart.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// Pages
import 'pages/home_page.dart';
import 'pages/categories_page.dart';
import 'pages/cart_page.dart';
import 'pages/wishlist_page.dart';
import 'pages/profile_page.dart';
import 'pages/orders_page.dart';
import 'pages/notifications_page.dart';
import 'pages/support_page.dart';
import 'pages/coupons_page.dart';
import 'pages/about_page.dart';
import 'pages/settings_page.dart';
import 'pages/splash_page.dart';

// AuthGate
import 'auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint("✅ Firebase initialized successfully!");

  runApp(const WatchHubApp());
}

class WatchHubApp extends StatelessWidget {
  const WatchHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashPage(), // 👈 App start pe Splash Screen aayegi
    );
  }
}

/// ===================
/// MAIN PAGE
/// ===================
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  final PageController _controller = PageController();

  final List<Widget> _pages = const [
    HomePage(),
    CategoriesPage(),
    WishlistPage(),
    ProfilePage(),
  ];

  void _onBottomTap(int index) {
    setState(() {
      _selectedIndex = index;
      _controller.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      drawer: buildDrawer(context),
      body: PageView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),
      bottomNavigationBar: buildBottomNavBar(),
    );
  }

  /// ===================
  /// APP BAR
  /// ===================
  AppBar buildAppBar(BuildContext context) {
    // Support stream
    final supportStream = FirebaseFirestore.instance
        .collection("support_requests")
        .where("userStatus", isEqualTo: "Unread")
        .snapshots();

    // Admin stream
    final adminStream = FirebaseFirestore.instance
        .collection("notifications")
        .where("status", isEqualTo: "Unread")
        .snapshots();

    // Combine both streams 👇
    final combinedStream = Rx.combineLatest2<QuerySnapshot, QuerySnapshot,
        Map<String, int>>(
      supportStream,
      adminStream,
      (supportSnap, adminSnap) => {
        "support": supportSnap.docs.length,
        "admin": adminSnap.docs.length,
      },
    );

    // Cart stream (user-wise)
    final cartStream = FirebaseFirestore.instance
        .collection("carts")
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .snapshots();

    return AppBar(
      elevation: 5,
      centerTitle: true,
      title: const Text(
        "WATCH HUB",
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
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
        /// 🔔 Notification Bell with Total Badge
        StreamBuilder<Map<String, int>>(
          stream: combinedStream,
          builder: (context, snapshot) {
            int supportCount = snapshot.data?["support"] ?? 0;
            int adminCount = snapshot.data?["admin"] ?? 0;
            int totalCount = supportCount + adminCount;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.orange),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsPage(),
                      ),
                    );
                  },
                ),
                if (totalCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        "$totalCount",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),

        const SizedBox(width: 6),

        // 🛒 Cart Icon with Badge
        StreamBuilder<DocumentSnapshot>(
          stream: cartStream,
          builder: (context, snapshot) {
            int cartCount = 0;
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              final items = data?["items"] ?? [];
              cartCount = (items as List).length;
            }

            return Stack(
              clipBehavior: Clip.none,
              children: [
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
                if (cartCount > 0)
                  Positioned(
                    right: 8,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        "$cartCount",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),

        
      ],


    );
  }

  /// ===================
  /// DRAWER
  /// ===================
  Drawer buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection("users")
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const DrawerHeader(
                  decoration: BoxDecoration(color: Colors.black87),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  ),
                );
              }

              var userData = snapshot.data!.data() as Map<String, dynamic>?;

              String name = userData?["name"] ?? "Guest User";
              String email = userData?["email"] ??
                  FirebaseAuth.instance.currentUser?.email ??
                  "";
              String imageUrl = userData?["profileImage"] ?? "";

              return SizedBox(
                height: 220,
                child: DrawerHeader(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black87, Colors.grey],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        backgroundImage:
                            imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                        child: imageUrl.isEmpty
                            ? const Icon(Icons.person,
                                size: 50, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          _buildDrawerItem(Icons.person, "Profile & Account", const ProfilePage()),
          _buildDrawerItem(Icons.inventory, "My Orders", const OrdersPage()),
          _buildDrawerItem(Icons.favorite, "Wishlist", const WishlistPage()),
          _buildDrawerItem(Icons.notifications, "Notifications", const NotificationsPage()),
          _buildDrawerItem(Icons.support, "Support / Help Center", const SupportPage()),
          _buildDrawerItem(Icons.local_offer, "Coupons / Offers", const CouponsPage()),
          _buildDrawerItem(Icons.info, "About Us / Contact", const AboutPage()),
          _buildDrawerItem(Icons.settings, "App Settings", const SettingsPage()),
          const Divider(height: 1, color: Colors.grey),
          _buildDrawerItem(Icons.logout, "Logout", const AuthGate(), isLogout: true),
        ],
      ),
    );
  }

  /// ===================
  /// BOTTOM NAV BAR
  /// ===================
  Widget buildBottomNavBar() {
    return Container(
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
          BottomNavigationBarItem(icon: Icon(Icons.category), label: "Categories"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Wishlist"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  /// ===================
  /// Drawer item widget
  /// ===================
  Widget _buildDrawerItem(IconData icon, String title, Widget? page,
      {bool isLogout = false}) {
    return InkWell(
      onTap: () async {
        if (isLogout) {
          await FirebaseAuth.instance.signOut();
          debugPrint("🚪 User logged out!");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AuthGate()),
          );
        } else if (page != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        }
      },
      borderRadius: BorderRadius.circular(12),
      splashColor: Colors.orangeAccent.withOpacity(0.3),
      highlightColor: Colors.orangeAccent.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.black87),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
