import 'package:flutter/material.dart';
import 'package:mystiq_fortune_app/backend/chat_service.dart';
import 'package:mystiq_fortune_app/pages/chat/chat_page.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class ChatHistoryPage extends StatefulWidget {
  final String currentUserEmail;
  final String currentUserName;

  const ChatHistoryPage({
    Key? key,
    required this.currentUserEmail,
    required this.currentUserName,
  }) : super(key: key);

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  final ChatService _chatService = ChatService();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initializeChatHistory();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _initializeChatHistory() async {
    await _chatService.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  String _getMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inHours < 24) {
      return DateFormat('HH:mm').format(timestamp);
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E1D39),
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF3D2952),
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _chatService.getChatHistory(widget.currentUserEmail),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6A3B99),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No messages yet.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            );
          }

          // Group messages by sender
          final messagesByUser = <String, List<Map<String, dynamic>>>{};
          for (var message in snapshot.data!) {
            final otherEmail = message['senderEmail'] == widget.currentUserEmail
                ? message['recipientEmail'] as String
                : message['senderEmail'] as String;
            final otherName = message['senderEmail'] == widget.currentUserEmail
                ? message['recipientName'] as String? ?? 'User'
                : message['senderName'] as String? ?? 'User';

            if (!messagesByUser.containsKey(otherEmail)) {
              messagesByUser[otherEmail] = [];
            }
            messagesByUser[otherEmail]!.add({
              ...message,
              'otherName': otherName,
            });
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: messagesByUser.length,
            itemBuilder: (context, index) {
              final otherEmail = messagesByUser.keys.elementAt(index);
              final messages = messagesByUser[otherEmail]!;
              final lastMessage = messages.last;
              final otherName = lastMessage['otherName'] as String;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                color: const Color(0xFF3D2952),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF6A3B99),
                    child: Text(
                      otherName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    otherName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        lastMessage['message'] as String? ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getMessageTime(lastMessage['timestamp'] as DateTime),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          currentUserEmail: widget.currentUserEmail,
                          currentUserName: widget.currentUserName,
                          recipientEmail: otherEmail,
                          recipientName: otherName,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _chatService.dispose();
    super.dispose();
  }
} 