import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SupportContent(),
    );
  }
}

class SupportContent extends StatefulWidget {
  const SupportContent({super.key});

  @override
  State<SupportContent> createState() => _SupportContentState();
}

class _SupportContentState extends State<SupportContent> {
  final List<ChatMessageData> messages = [
    ChatMessageData(message: "Hi! How can I help you?", isUser: false),
  ];

  final TextEditingController _chatController = TextEditingController();

  /// 🔹 Gemini API call
  Future<String> getAIReply(String userMessage) async {
    const String apiKey = "AIzaSyAviiVrEn9w7FxScsRpp5CY9-Lt4ziUbZo"; 

    try {
      final response = await http.post(
        Uri.parse(
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": userMessage}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["candidates"][0]["content"]["parts"][0]["text"];
      } else {
        return "API Error: ${response.statusCode} - ${response.body}";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  void openChat(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey.shade100,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    "Chat with AI Support",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return ChatMessage(
                        message: msg.message,
                        isUser: msg.isUser,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatController,
                          decoration: InputDecoration(
                            hintText: "Type a message...",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.orange,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: () async {
                            String text = _chatController.text.trim();
                            if (text.isNotEmpty) {
                              setModalState(() {
                                messages.add(ChatMessageData(
                                    message: text, isUser: true));
                                messages.add(ChatMessageData(
                                    message: "Typing...", isUser: false));
                                _chatController.clear();
                              });

                              String reply = await getAIReply(text);

                              setModalState(() {
                                messages.removeLast(); // remove "Typing..."
                                messages.add(ChatMessageData(
                                    message: reply, isUser: false));
                              });
                            }
                          },
                          customBorder: const CircleBorder(),
                          child: const Padding(
                            padding: EdgeInsets.all(14.0),
                            child: Icon(Icons.send, color: Colors.white),
                          ),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        });
      },
    );
  }

  Future<void> launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@example.com',
    );
    await launchUrl(emailLaunchUri);
  }

  Future<void> launchCall() async {
    final Uri phoneLaunchUri = Uri(
      scheme: 'tel',
      path: '+923001234567',
    );
    await launchUrl(phoneLaunchUri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        elevation: 0,
        title: const Text(
          "Support & Help",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.grey.shade200,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "How can we help you?",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 12),
            const Text(
              "Choose one of the options below to get support quickly.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Material(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => openChat(context),
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        child: const Text(
                          "Chat with AI",
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Material(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => launchEmail(),
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        child: const Text(
                          "Email Support",
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Material(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => launchCall(),
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        child: const Text(
                          "Call Support",
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "Frequently Asked Questions",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: const [
                  SupportFAQItem(
                    question: "How can I track my order?",
                    answer:
                        "You can track your order from the 'My Orders' section and view the delivery progress.",
                  ),
                  SupportFAQItem(
                    question: "How can I cancel my order?",
                    answer:
                        "Orders can be canceled from the 'My Orders' page if the status is not 'Shipped' or 'Delivered'.",
                  ),
                  SupportFAQItem(
                    question: "How do I return a product?",
                    answer:
                        "You can request a return from the 'My Orders' page for eligible products within 7 days.",
                  ),
                  SupportFAQItem(
                    question: "Payment issues",
                    answer:
                        "For any payment-related issues, contact our support team via chat or email.",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessageData {
  final String message;
  final bool isUser;
  ChatMessageData({required this.message, this.isUser = false});
}

class ChatMessage extends StatelessWidget {
  final String message;
  final bool isUser;

  const ChatMessage({super.key, required this.message, this.isUser = false});

  void _copyText(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Copied to clipboard")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: isUser ? Colors.black87 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              message,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
          if (!isUser) // ✅ Copy button only for AI responses
            TextButton.icon(
              onPressed: () => _copyText(context, message),
              icon: const Icon(Icons.copy, size: 16),
              label: const Text("Copy"),
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }
}

class SupportFAQItem extends StatefulWidget {
  final String question;
  final String answer;

  const SupportFAQItem(
      {super.key, required this.question, required this.answer});

  @override
  State<SupportFAQItem> createState() => _SupportFAQItemState();
}

class _SupportFAQItemState extends State<SupportFAQItem> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          setState(() {
            isExpanded = !isExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  )
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 10),
                Text(
                  widget.answer,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
