import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:mystiq_fortune_app/database/constant.dart';
import 'package:mystiq_fortune_app/backend/notification_service.dart';
import 'package:mystiq_fortune_app/backend/chat_service.dart';
import 'dart:async';

class CoffeeFortunePage extends StatefulWidget {
  final String email;
  final ChatService? chatService;

  const CoffeeFortunePage({
    Key? key,
    required this.email,
    this.chatService,
  }) : super(key: key);

  @override
  State<CoffeeFortunePage> createState() => _CoffeeFortunePageState();
}

class _CoffeeFortunePageState extends State<CoffeeFortunePage> {
  late final ChatService _chatService;
  Timer? _refreshTimer;
  late mongo.Db db;
  late mongo.DbCollection usersCollection;
  late mongo.DbCollection fortuneRequestsCollection;
  File? _selectedImage;
  bool _isLoading = false;

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
    _connectToDatabase();
  }

  void _connectToDatabase() async {
    try {
      db = await mongo.Db.create(MONGO_URL);
      await db.open();
      usersCollection = db.collection("users");
      fortuneRequestsCollection = db.collection("fortune_requests");
    } catch (e) {
      debugPrint("Database connection error: $e");
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _chatService.dispose();
    db.close();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final fortuneTellers = await usersCollection
            .find(mongo.where.eq('role', 'Fortune Teller'))
            .toList();

        if (!mounted) {
          setState(() {
            _isLoading = false;
          });
          return;
        }

        final selectedFortuneTeller = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Select a Fortune Teller',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (fortuneTellers.isEmpty)
                    const Text(
                      'No available fortune teller at the moment.',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: fortuneTellers.length,
                        itemBuilder: (context, index) {
                          final fortuneTeller = fortuneTellers[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.purple,
                              child: Text(
                                (fortuneTeller['name'] ?? 'F')[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(fortuneTeller['name'] ?? 'Anonymous Fortune Teller'),
                            onTap: () {
                              Navigator.pop(context, fortuneTeller);
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        if (selectedFortuneTeller == null) {
          setState(() {
            _isLoading = false;
          });
          return;
        }

        if (!mounted) {
          setState(() {
            _isLoading = false;
          });
          return;
        }

        final bytes = await _selectedImage!.readAsBytes();
        final base64Image = base64Encode(bytes);

        final userData = await usersCollection.findOne(
          mongo.where.eq('email', widget.email)
        );

        if (!mounted) {
          setState(() {
            _isLoading = false;
          });
          return;
        }

        if (userData != null) {
          final fortuneRequest = {
            'userId': userData['_id'],
            'userEmail': widget.email,
            'userName': userData['name'],
            'image': base64Image,
            'status': 'pending',
            'createdAt': DateTime.now(),
            'response': null,
            'respondedAt': null,
            'fortuneTellerId': selectedFortuneTeller['_id'],
            'fortuneTellerName': selectedFortuneTeller['name'],
            'fortuneTellerEmail': selectedFortuneTeller['email'],
          };

          await fortuneRequestsCollection.insert(fortuneRequest);

          await NotificationService().publishNotification(
            recipientEmail: selectedFortuneTeller['email'].toString(),
            type: 'new_fortune',
            senderName: userData['name'],
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Your coffee fortune has been sent to ${selectedFortuneTeller['name']}! They will contact you soon."),
                backgroundColor: Colors.green,
              ),
            );
            setState(() {
              _selectedImage = null;
              _isLoading = false;
            });
          }
        }
      } catch (e) {
        debugPrint("Error uploading fortune request: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("An error occurred while sending the fortune. Please try again."),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a photo!"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // Bildirim gönderme
  Future<void> _sendNotification(String fortuneTellerId, String message) async {
    await NotificationService().sendNotification(
      userId: fortuneTellerId,
      title: 'New Coffee Fortune Request',
      message: message,
    );
  }

  Future<void> _initializeChat() async {
    try {
      await _chatService.initialize();
    } catch (e) {
      print('Chat servisi başlatma hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bağlantı hatası oluştu. Lütfen tekrar deneyin.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E1D39),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Coffee Fortune',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 120,
                backgroundImage: _selectedImage != null
                    ? FileImage(_selectedImage!)
                    : const AssetImage('assets/coffee_fortune.png') as ImageProvider,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Upload Your Fortune',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Upload your fortune by clicking the button below',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 30),
            if (_isLoading)
              const CircularProgressIndicator(color: Colors.white)
            else
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2E1D39),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Select Photo',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _uploadImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2E1D39),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Send Fortune',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
