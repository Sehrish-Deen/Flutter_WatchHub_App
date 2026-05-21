import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:watchhub/auth/login_page.dart';

// Pages
import 'dashboard/dashboard_page.dart';
import 'pages/CouponsPage.dart';
import 'pages/NotificationsPage.dart';
import 'pages/Product_cetegory.dart';
import 'pages/products_page.dart';
import 'pages/orders_page.dart';
import 'pages/users_page.dart';
import 'package:watchhub/admin/pages/feedbacklist.dart';
import 'pages/admin_sale_page.dart';
import 'pages/admin_cart_page.dart';
import 'pages/HomePageAdmin.dart';
import 'pages/AdminReview.dart';

class ResponsiveAdminPanel extends StatefulWidget {
  const ResponsiveAdminPanel({super.key});

  @override
  State<ResponsiveAdminPanel> createState() => _ResponsiveAdminPanelState();
}

class _ResponsiveAdminPanelState extends State<ResponsiveAdminPanel> {
  int _selectedIndex = 0;
  bool _isSidebarOpen = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> _pages = [
    "Dashboard",
    "Product Categories",
    "Products",
    "Orders",
    "Users",
    "Coupons",
    "Notifications",
    "Sale Products",
    "Carts",
    "Feedback",
    "Home Page",
    "Reviews" // 👈 New entry
        "Logout",
  ];

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: Colors.black,
      key: _scaffoldKey,
      drawer: isMobile ? _buildDrawer() : null,
   appBar: AppBar(
  backgroundColor: Colors.orange,
  title: Text(
    " ${_pages[_selectedIndex]}",
    style: const TextStyle(fontWeight: FontWeight.bold),
  ),
  leading: isMobile
      ? IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        )
      : null,
  actions: [
    /// ===== FEEDBACK ICON WITH BADGE =====
    StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("support_requests")
          .where("status", isEqualTo: "Pending") // sirf pending count
          .snapshots(),
      builder: (context, snapshot) {
        int feedbackCount = 0;
        if (snapshot.hasData) {
          feedbackCount = snapshot.data!.docs.length;
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.feedback, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminFeedbackPage(),
                  ),
                );
              },
            ),
            if (feedbackCount > 0)
              Positioned(
                right: 6,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    feedbackCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),

    const Padding(
      padding: EdgeInsets.only(right: 16.0),
      child: CircleAvatar(
        backgroundColor: Colors.white,
        child: Icon(Icons.person, color: Colors.orange),
      ),
    ),
  ],
),

      body: Row(
        children: [
          if (!isMobile) _buildSidebar(),
          Expanded(child: _buildPageContent(_selectedIndex)),
        ],
      ),
    );
  }

  /// Sidebar (desktop)
  Widget _buildSidebar() {
    return Container(
      width: _isSidebarOpen ? 220 : 70,
      color: Colors.black,
      child: Column(
        children: [
          // Sidebar Header with Logo + Title
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange,
            child: Row(
              mainAxisAlignment: _isSidebarOpen
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundImage: AssetImage("assets/images/logo.jpg"),
                ),
                if (_isSidebarOpen) ...[
                  const SizedBox(width: 10),
                  const Text(
                    "Admin Panel",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _isSidebarOpen ? Icons.arrow_back_ios : Icons.menu,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isSidebarOpen = !_isSidebarOpen;
              });
            },
          ),
          const SizedBox(height: 20),
          _buildSidebarItem(
            Icons.dashboard_outlined,
            Icons.dashboard,
            "Dashboard",
            0,
          ),
          _buildSidebarItem(
            Icons.category_outlined,
            Icons.category,
            "Product Categories",
            1,
          ),
          _buildSidebarItem(Icons.watch_outlined, Icons.watch, "Products", 2),
          _buildSidebarItem(
            Icons.shopping_cart_outlined,
            Icons.shopping_cart,
            "Orders",
            3,
          ),
          _buildSidebarItem(
            Icons.people_alt_outlined,
            Icons.people,
            "Users",
            4,
          ),
          _buildSidebarItem(
            Icons.card_giftcard_outlined,
            Icons.card_giftcard,
            "Coupons",
            5,
          ),
          _buildSidebarItem(
            Icons.notifications_outlined,
            Icons.notifications,
            "Notifications",
            6,
          ),
          _buildSidebarItem(
            Icons.local_offer_outlined,
            Icons.local_offer,
            "Sale Products",
            7,
          ),
          _buildSidebarItem(
            Icons.shopping_bag_outlined,
            Icons.shopping_bag,
            "Carts",
            8,
          ),
          _buildSidebarItem(
            Icons.feedback_outlined,
            Icons.feedback,
            "Feedback",
            9,
          ),
          _buildSidebarItem(Icons.home_outlined, Icons.home, "Home Page", 10),


         _buildSidebarItem(Icons.rate_review_outlined, Icons.rate_review, "Reviews", 11),
_buildSidebarItem(Icons.logout, Icons.logout, "Logout", 12, isLogout: true),

        ],
      ),
    );
  }

  /// Drawer (mobile)
  Drawer _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF383636), Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Drawer Header with Logo + Admin Title
            Container(
              padding: const EdgeInsets.symmetric(vertical: 35),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    backgroundImage: AssetImage("assets/images/logo.jpg"),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Admin Panel",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const Divider(color: Colors.grey, thickness: 1.5),
                ],
              ),
            ),
            _buildDrawerItem(Icons.dashboard_outlined, "Dashboard", 0),
            _buildDrawerItem(Icons.category_outlined, "Product Categories", 1),
            _buildDrawerItem(Icons.watch_outlined, "Products", 2),
            _buildDrawerItem(Icons.shopping_cart_outlined, "Orders", 3),
            _buildDrawerItem(Icons.people_alt_outlined, "Users", 4),
            _buildDrawerItem(Icons.card_giftcard_outlined, "Coupons", 5),
            _buildDrawerItem(Icons.notifications_outlined, "Notifications", 6),
            _buildDrawerItem(Icons.local_offer_outlined, "Sale Products", 7),
            _buildDrawerItem(Icons.shopping_bag_outlined, "Carts", 8),
            _buildDrawerItem(Icons.feedback_outlined, "Feedback", 9),
            _buildDrawerItem(Icons.home_outlined, "Home Page", 10),

            _buildDrawerItem(Icons.rate_review_outlined, "Reviews", 11),
_buildDrawerItem(Icons.logout, "Logout", 12, isLogout: true),

          ],
        ),
      ),
    );
  }

  /// Sidebar Item
  Widget _buildSidebarItem(
    IconData icon,
    IconData selectedIcon,
    String title,
    int index, {
    bool isLogout = false,
  }) {
    bool selected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        selected ? selectedIcon : icon,
        color: selected ? Colors.orange : Colors.grey,
      ),
      title: _isSidebarOpen
          ? Text(
              title,
              style: TextStyle(
                color: selected ? Colors.orange : Colors.grey,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            )
          : null,
      onTap: () async {
        if (isLogout) {
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        } else {
          setState(() {
            _selectedIndex = index;
          });
        }
      },
    );
  }

  /// Drawer Item
  Widget _buildDrawerItem(
    IconData icon,
    String title,
    int index, {
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: _selectedIndex == index ? Colors.orange : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: _selectedIndex == index ? Colors.orange : Colors.grey,
          fontWeight: _selectedIndex == index
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      onTap: () async {
        if (isLogout) {
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        } else {
          setState(() {
            _selectedIndex = index;
          });
          if (Navigator.canPop(context)) Navigator.pop(context);
        }
      },
    );
  }

  /// Page Content
  Widget _buildPageContent(int index) {
    switch (index) {
      case 0:
        return const DashboardPage();
      case 1:
        return const ProductCategoryPage();
      case 2:
        return const ProductsPage();
      case 3:
        return const OrdersPage();
      case 4:
        return const UsersPage();
      case 5:
        return const CouponsPage();
      case 6:
        return const NotificationsPage();
      case 7:
        return const AdminSalePage();
      case 8:
        return const AdminCartPage();
      case 9:
        return const AdminFeedbackPage();
      case 10:
        return const HomePageAdmin();
   case 11:
  return const AdminReviewsPage(); // 👈 AdminReview page
case 12:
  return const Center(child: Text("Logging out..."));

      default:
        return const Center(
          child: Text("Page not found", style: TextStyle(color: Colors.white)),
        );
    }
  }
}
