import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/animated_info_card.dart';
import '../widgets/animated_line_chart.dart';
import '../widgets/recent_activity.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // 🔹 Users Count (Dynamic)
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const AnimatedInfoCard(title: "Users", value: 0);
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const AnimatedInfoCard(title: "Users", value: 0);
                      }
                      int userCount = snapshot.data!.docs.length;
                      return AnimatedInfoCard(title: "Users", value: userCount);
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // 🔹 Orders Count (Dynamic)
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('orders')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const AnimatedInfoCard(title: "Orders", value: 0);
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const AnimatedInfoCard(title: "Orders", value: 0);
                      }
                      int ordersCount = snapshot.data!.docs.length;
                      return AnimatedInfoCard(title: "Orders", value: ordersCount);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 🔹 Chart
            const SizedBox(height: 350, child: AnimatedLineChart()),
            const SizedBox(height: 20),

            // 🔹 Recent Activity
            const DashboardStats(),
          ],
        ),
      ),
    );
  }
}
