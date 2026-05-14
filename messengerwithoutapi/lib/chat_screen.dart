import 'package:flutter/material.dart';
import 'package:flutter_application_1/Fon.dart';
import 'package:flutter_application_1/local_data.dart';


class ChatScreen extends StatefulWidget {
  final String chatId;
  final String title;
  final bool darkMode;
  const ChatScreen({super.key, required this.chatId, required this.title, required this.darkMode});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    LocalData().addMessage(widget.chatId, text);
    _messageController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final messages = LocalData().getMessages(widget.chatId);
    return MobileAnimatedBackground(
      backgroundColor: widget.darkMode ? Colors.black : Colors.white,
      lineColor: widget.darkMode ? Colors.white : Colors.black,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: widget.darkMode ? Colors.white : Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(widget.title, style: TextStyle(color: widget.darkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages.reversed.toList()[index];
                  return Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.darkMode ? const Color(0xFF2563EB) : const Color(0xFF2196F3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      child: Text(msg, style: const TextStyle(color: Colors.white, height: 1.3)),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.darkMode ? Colors.white10 : Colors.grey[50],
                border: Border(top: BorderSide(color: widget.darkMode ? Colors.white24 : Colors.black12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(color: widget.darkMode ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: widget.darkMode ? Colors.white10 : Colors.white,
                        hintText: 'Сообщение...',
                        hintStyle: TextStyle(color: widget.darkMode ? Colors.white60 : Colors.black38),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: _messageController.text.trim().isNotEmpty
                        ? (widget.darkMode ? Colors.blueAccent : Colors.blue)
                        : (widget.darkMode ? Colors.white10 : Colors.grey[300]),
                    child: IconButton(
                      icon: const Icon(Icons.send),
                      color: _messageController.text.trim().isNotEmpty ? Colors.white : Colors.grey,
                      onPressed: _sendMessage,
                    ),
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