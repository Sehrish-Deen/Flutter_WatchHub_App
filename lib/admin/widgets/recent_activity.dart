import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardStats extends StatelessWidget {
  const DashboardStats({super.key});

  // Function to calculate stats from orders
  Map<String, int> _calculateStats(List<QueryDocumentSnapshot> orders) {
    int totalOrders = orders.length;
    int pendingOrders = 0;
    int completedOrders = 0;
    int cancelledOrders = 0;

    for (var order in orders) {
      final data = order.data() as Map<String, dynamic>;
      final status = data['status']?.toString().toLowerCase() ?? 'pending';
      
      switch (status) {
        case 'pending':
          pendingOrders++;
          break;
        case 'completed':
        case 'delivered':
          completedOrders++;
          break;
        case 'cancelled':
        case 'canceled':
          cancelledOrders++;
          break;
      }
    }

    return {
      'total': totalOrders,
      'pending': pendingOrders,
      'completed': completedOrders,
      'cancelled': cancelledOrders,
    };
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingStats();
        }

        if (snapshot.hasError) {
          return _buildErrorStats(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyStats();
        }

        final orders = snapshot.data!.docs;
        final stats = _calculateStats(orders);

        return _buildStatsGrid(stats);
      },
    );
  }

  Widget _buildStatsGrid(Map<String, int> stats) {
    List<Map<String, dynamic>> statsData = [
      {
        "title": "Total Orders",
        "count": stats['total'].toString(),
        "color": Colors.blue,
        "icon": Icons.shopping_bag
      },
      {
        "title": "Pending Orders",
        "count": stats['pending'].toString(),
        "color": Colors.orange,
        "icon": Icons.hourglass_bottom
      },
      {
        "title": "Completed",
        "count": stats['completed'].toString(),
        "color": Colors.green,
        "icon": Icons.check_circle
      },
      {
        "title": "Cancelled",
        "count": stats['cancelled'].toString(),
        "color": Colors.red,
        "icon": Icons.cancel
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Dashboard Overview",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          itemCount: statsData.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            var stat = statsData[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(stat["icon"], size: 32, color: stat["color"]),
                  const SizedBox(height: 10),
                  Text(
                    stat["count"],
                    style: TextStyle(
                      color: stat["color"],
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    stat["title"],
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoadingStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Dashboard Overview",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          itemCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    "Loading...",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildErrorStats(String error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Dashboard Overview",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              const Icon(Icons.error, color: Colors.red, size: 32),
              const SizedBox(height: 10),
              const Text(
                "Error Loading Stats",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 5),
              Text(
                error,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Dashboard Overview",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Column(
            children: [
              Icon(Icons.shopping_bag, color: Colors.grey, size: 32),
              SizedBox(height: 10),
              Text(
                "No Orders Yet",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              SizedBox(height: 5),
              Text(
                "Start receiving orders to see statistics",
                style: TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}