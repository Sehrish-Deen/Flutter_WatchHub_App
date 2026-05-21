import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePageAdmin extends StatefulWidget {
  const HomePageAdmin({super.key});

  @override
  State<HomePageAdmin> createState() => _HomePageAdminState();
}

class _HomePageAdminState extends State<HomePageAdmin> {
  String selectedType = "Banner"; // default
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController subtitleCtrl = TextEditingController();
  final TextEditingController imageUrlCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();

  /// Save Data to Firestore
  void _saveData() async {
    if (imageUrlCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please enter image URL")),
      );
      return;
    }

    // Validation for Banner & Trending
    if ((selectedType == "Banner" || selectedType == "Trending") &&
        titleCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please enter title")),
      );
      return;
    }

    // Validation for Popular
    if (selectedType == "Popular" &&
        (titleCtrl.text.isEmpty || priceCtrl.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please enter product name & price")),
      );
      return;
    }

    Map<String, dynamic> data = {
      "type": selectedType,
      "image": imageUrlCtrl.text.trim(),
      "createdAt": FieldValue.serverTimestamp(),
    };

    if (selectedType == "Banner" || selectedType == "Trending") {
      data.addAll({
        "title": titleCtrl.text.trim(),
        "subtitle": subtitleCtrl.text.trim(),
      });
    } else if (selectedType == "Popular") {
      data.addAll({
        "name": titleCtrl.text.trim(),
        "price": double.tryParse(priceCtrl.text.trim()) ?? 0,
        "description": subtitleCtrl.text.trim(),
      });
    }

    try {
      await FirebaseFirestore.instance.collection("home_page").add(data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ $selectedType added successfully")),
      );

      // clear fields
      titleCtrl.clear();
      subtitleCtrl.clear();
      imageUrlCtrl.clear();
      priceCtrl.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to save: $e")),
      );
    }
  }

  /// Delete item from Firestore
  void _deleteItem(String docId) async {
    try {
      await FirebaseFirestore.instance.collection("home_page").doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Item deleted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to delete: $e")),
      );
    }
  }

  /// Edit item - Open dialog with pre-filled data
  void _editItem(DocumentSnapshot item) {
    // Temporary variables for edit dialog
    String editSelectedType = item['type'] ?? 'Banner';
    final TextEditingController editTitleCtrl = TextEditingController();
    final TextEditingController editSubtitleCtrl = TextEditingController();
    final TextEditingController editImageUrlCtrl = TextEditingController();
    final TextEditingController editPriceCtrl = TextEditingController();

    // Set controllers with existing data - safely handle missing fields
    final data = item.data() as Map<String, dynamic>;
    
    editTitleCtrl.text = data['title'] ?? data['name'] ?? '';
    editSubtitleCtrl.text = data['subtitle'] ?? data['description'] ?? '';
    editImageUrlCtrl.text = data['image'] ?? '';
    
    // Only set price if it exists and the type is Popular
    if (data['type'] == 'Popular' && data.containsKey('price')) {
      editPriceCtrl.text = data['price']?.toString() ?? '';
    }

    // Show edit dialog
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Edit Item"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: editSelectedType,
                    decoration: const InputDecoration(
                      labelText: "Select Section",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: "Banner", child: Text("Banner")),
                      DropdownMenuItem(value: "Trending", child: Text("Trending")),
                      DropdownMenuItem(value: "Popular", child: Text("Popular")),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        editSelectedType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Image URL
                  TextField(
                    controller: editImageUrlCtrl,
                    decoration: const InputDecoration(
                      labelText: "Image URL",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Fields based on type
                  if (editSelectedType == "Banner" || editSelectedType == "Trending") ...[
                    TextField(
                      controller: editTitleCtrl,
                      decoration: const InputDecoration(
                        labelText: "Title",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: editSubtitleCtrl,
                      decoration: const InputDecoration(
                        labelText: "Subtitle",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],

                  if (editSelectedType == "Popular") ...[
                    TextField(
                      controller: editTitleCtrl,
                      decoration: const InputDecoration(
                        labelText: "Product Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: editSubtitleCtrl,
                      decoration: const InputDecoration(
                        labelText: "Description",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: editPriceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Price",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Validation
                  if (editImageUrlCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("⚠️ Please enter image URL")),
                    );
                    return;
                  }

                  if ((editSelectedType == "Banner" || editSelectedType == "Trending") &&
                      editTitleCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("⚠️ Please enter title")),
                    );
                    return;
                  }

                  if (editSelectedType == "Popular" &&
                      (editTitleCtrl.text.isEmpty || editPriceCtrl.text.isEmpty)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("⚠️ Please enter product name & price")),
                    );
                    return;
                  }

                  // Update data in Firestore
                  Map<String, dynamic> updatedData = {
                    "type": editSelectedType,
                    "image": editImageUrlCtrl.text.trim(),
                    "updatedAt": FieldValue.serverTimestamp(),
                  };

                  if (editSelectedType == "Banner" || editSelectedType == "Trending") {
                    updatedData.addAll({
                      "title": editTitleCtrl.text.trim(),
                      "subtitle": editSubtitleCtrl.text.trim(),
                    });
                    // Remove Popular-specific fields if changing from Popular to Banner/Trending
                    updatedData.addAll({
                      "name": FieldValue.delete(),
                      "price": FieldValue.delete(),
                      "description": FieldValue.delete(),
                    });
                  } else if (editSelectedType == "Popular") {
                    updatedData.addAll({
                      "name": editTitleCtrl.text.trim(),
                      "price": double.tryParse(editPriceCtrl.text.trim()) ?? 0,
                      "description": editSubtitleCtrl.text.trim(),
                    });
                    // Remove Banner/Trending-specific fields if changing to Popular
                    updatedData.addAll({
                      "title": FieldValue.delete(),
                      "subtitle": FieldValue.delete(),
                    });
                  }

                  try {
                    await FirebaseFirestore.instance
                        .collection("home_page")
                        .doc(item.id)
                        .update(updatedData);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("✅ $editSelectedType updated successfully")),
                    );

                    Navigator.pop(context);
                    
                    // Update main state if needed
                    setState(() {
                      selectedType = editSelectedType;
                    });
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("❌ Failed to update: $e")),
                    );
                  }
                },
                child: const Text("Update"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Page Admin"),
        backgroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add New Item Section
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Add New Item",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      // Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: selectedType,
                        decoration: const InputDecoration(
                          labelText: "Select Section",
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: "Banner", child: Text("Banner")),
                          DropdownMenuItem(value: "Trending", child: Text("Trending")),
                          DropdownMenuItem(value: "Popular", child: Text("Popular")),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Common: Image
                      TextField(
                        controller: imageUrlCtrl,
                        decoration: const InputDecoration(
                          labelText: "Image URL",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Banner & Trending: Title + Subtitle
                      if (selectedType == "Banner" || selectedType == "Trending") ...[
                        TextField(
                          controller: titleCtrl,
                          decoration: const InputDecoration(
                            labelText: "Title",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: subtitleCtrl,
                          decoration: const InputDecoration(
                            labelText: "Subtitle",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Popular: Name, Price, Description
                      if (selectedType == "Popular") ...[
                        TextField(
                          controller: titleCtrl,
                          decoration: const InputDecoration(
                            labelText: "Product Name",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: subtitleCtrl,
                          decoration: const InputDecoration(
                            labelText: "Description",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Price",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Save button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        onPressed: _saveData,
                        child: const Text("Save"),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Existing Items List
              const Text(
                "Existing Items",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // StreamBuilder to display items
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("home_page")
                    .orderBy("createdAt", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: Text("No items added yet")),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var item = snapshot.data!.docs[index];
                      var data = item.data() as Map<String, dynamic>;

                      // Safely get price with null check
                      String priceText = '';
                      if (data['type'] == 'Popular' && data.containsKey('price')) {
                        priceText = 'Price: \$${data['price']?.toStringAsFixed(2) ?? '0.00'}';
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Image.network(
                            data['image'] ?? '',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.error),
                          ),
                          title: Text(
                            data['title'] ?? data['name'] ?? 'No Title',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['subtitle'] ?? data['description'] ?? 'No Description',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Type: ${data['type']}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              if (priceText.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  priceText,
                                  style: const TextStyle(fontSize: 12, color: Colors.green),
                                ),
                              ],
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editItem(item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteItem(item.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}