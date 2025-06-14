import 'package:flutter/material.dart';
import 'package:mystiq_fortune_app/backend/chat_service.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class ChatPage extends StatefulWidget {
  final String currentUserEmail;
  final String currentUserName;
  final String recipientEmail;
  final String recipientName;
  final ChatService? chatService;

  const ChatPage({
    Key? key,
    required this.currentUserEmail,
    required this.currentUserName,
    required this.recipientEmail,
    required this.recipientName,
    this.chatService,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatService _chatService;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _chatService = widget.chatService ?? ChatService();
    _initializeChat();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _initializeChat() async {
    try {
      await _chatService.initialize();
      await _loadMessages();
      _listenForNewMessages();
    } catch (e) {
      print('Chat başlatma hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bağlantı hatası oluştu. Lütfen tekrar deneyin.')),
        );
      }
    }
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _chatService.getChatHistory(widget.currentUserEmail);
      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(messages);
          _messages.sort((a, b) {
            final aTime = a['timestamp'] as DateTime;
            final bTime = b['timestamp'] as DateTime;
            return aTime.compareTo(bTime);
          });
        });
        // Mesajlar yüklendiğinde en alta kaydır
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } catch (e) {
      print('Mesaj yükleme hatası: $e');
    }
  }

  void _listenForNewMessages() {
    try {
      _chatService.listenToMessages(widget.currentUserEmail, (message) {
        if (mounted && 
            message['senderEmail'] == widget.recipientEmail &&
            message['recipientEmail'] == widget.currentUserEmail) {
          setState(() {
            _messages.add(message);
            _messages.sort((a, b) {
              final aTime = a['timestamp'] as DateTime;
              final bTime = b['timestamp'] as DateTime;
              return aTime.compareTo(bTime);
            });
          });
          _scrollToBottom();
          _chatService.markMessageAsDelivered(message['_id'].toString());
          _chatService.markMessageAsRead(message['_id'].toString());
        }
      });
    } catch (e) {
      print('Mesaj dinleme başlatma hatası: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    try {
      await _chatService.sendMessage(
        senderEmail: widget.currentUserEmail,
        recipientEmail: widget.recipientEmail,
        message: text,
        senderName: widget.currentUserName,
      );
      
      _messageController.clear();
      await _loadMessages();
      // Mesaj gönderildikten sonra en alta kaydır
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      print('Mesaj gönderme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mesaj gönderilemedi')),
        );
      }
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

  String _getRemainingTime(DateTime expiresAt) {
    final now = DateTime.now();
    final difference = expiresAt.difference(now);
    
    if (difference.isNegative) {
      return 'Süresi doldu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat kaldı';
    } else {
      return '${difference.inMinutes} dakika kaldı';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E1D39),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.recipientName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              widget.recipientEmail,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF3D2952),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isCurrentUser = message['senderEmail'] == widget.currentUserEmail;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: isCurrentUser
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrentUser 
                              ? const Color(0xFF6A3B99)
                              : Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: isCurrentUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['message'] as String,
                              style: TextStyle(
                                color: isCurrentUser ? Colors.white : Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getMessageTime(message['timestamp'] as DateTime),
                              style: TextStyle(
                                color: isCurrentUser
                                    ? Colors.white70
                                    : Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF3D2952),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Mesajınızı yazın...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF2E1D39),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF6A3B99),
                  ),
                  child: IconButton(
                    onPressed: () => _sendMessage(_messageController.text.trim()),
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    _chatService.dispose();
    super.dispose();
  }
} 