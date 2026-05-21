import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrackOrderPage extends StatefulWidget {
  final String orderId;
  const TrackOrderPage({super.key, required this.orderId});

  @override
  State<TrackOrderPage> createState() => _TrackOrderPageState();
}

class _TrackOrderPageState extends State<TrackOrderPage>
    with SingleTickerProviderStateMixin {
  bool isLoading = true;
  String status = "Processing";

  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  // Default steps
  List<Map<String, String>> orderSteps = [
    {"step": "Processing", "status": "pending"},
    {"step": "Approved", "status": "pending"},
    {"step": "Delivered", "status": "pending"},
  ];

  @override
  void initState() {
    super.initState();
    fetchOrderStatus();
  }

  void fetchOrderStatus() async {
    final doc = await FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .get();

    if (doc.exists && doc.data() != null) {
      status = (doc['status'] ?? "Processing").toString();
    }

    // Update steps status based on current status
    for (var step in orderSteps) {
      if (step["step"]!.toLowerCase() == status.toLowerCase()) {
        step["status"] = "inProgress";
        break;
      } else {
        step["status"] = "completed";
      }
    }

    // Setup animation
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _progressAnimation =
        Tween<double>(begin: 0, end: getProgress()).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();

    setState(() {
      isLoading = false;
    });
  }

  double getProgress() {
    switch (status.toLowerCase()) {
      case "processing":
        return 0.2;
      case "approved":
        return 0.5;
      case "delivered":
        return 1.0;
      case "decline":
        return 0.0;
      default:
        return 0.0;
    }
  }

  Color getStepColor(String stepStatus) {
    switch (stepStatus) {
      case "completed":
        return Colors.green;
      case "inProgress":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData getStepIcon(String stepStatus) {
    switch (stepStatus) {
      case "completed":
        return Icons.check_circle;
      case "inProgress":
        return Icons.radio_button_checked;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Track Order",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.grey.shade200,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Delivery Progress",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _progressAnimation.value,
                        minHeight: 12,
                        color: Colors.orange,
                        backgroundColor: Colors.grey.shade300,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 6),
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return Text(
                      "${(_progressAnimation.value * 100).round()}% completed",
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Timeline steps
            Expanded(
              child: ListView.builder(
                itemCount: orderSteps.length,
                itemBuilder: (context, index) {
                  final step = orderSteps[index];
                  final isLast = index == orderSteps.length - 1;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Icon(
                            getStepIcon(step["status"]!),
                            color: getStepColor(step["status"]!),
                            size: 28,
                          ),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 50,
                              color: getStepColor(
                                      orderSteps[index + 1]["status"]!)
                                  .withOpacity(0.5),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            step["step"]!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: getStepColor(step["status"]!),
                            ),
                          ),
                        ),
                      )
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
