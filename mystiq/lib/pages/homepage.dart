import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:mystiq_fortune_app/database/constant.dart';
import 'package:mystiq_fortune_app/pages/chat/chat_page.dart';
import 'package:mystiq_fortune_app/pages/compatibility_page.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:async';

class HomePage extends StatefulWidget {
  final String email;
  final String name;
  final mongo.Db? db;
  final mongo.DbCollection? usersCollection;
  final mongo.DbCollection? fortuneRequestsCollection;
  final bool enableTimer;
  final bool enableDatabase;

  const HomePage({
    Key? key,
    required this.email,
    required this.name,
    this.db,
    this.usersCollection,
    this.fortuneRequestsCollection,
    this.enableTimer = true,
    this.enableDatabase = true,
  }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late mongo.Db db;
  late mongo.DbCollection fortuneRequestsCollection;
  late mongo.DbCollection usersCollection;
  Map<String, dynamic> userAstroData = {
    'sunSign': '',
    'risingSign': '',
    'element': '',
    'maritalStatus': '',
  };
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    if (widget.db != null && widget.usersCollection != null && widget.fortuneRequestsCollection != null) {
      db = widget.db!;
      usersCollection = widget.usersCollection!;
      fortuneRequestsCollection = widget.fortuneRequestsCollection!;
      _loadUserData();
    } else if (widget.enableDatabase) {
      _connectToDatabase();
    }
    if (widget.enableTimer) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  Future<void> _connectToDatabase() async {
    db = await mongo.Db.create(MONGO_URL);
    await db.open();
    fortuneRequestsCollection = db.collection('fortune_requests');
    usersCollection = db.collection('users');
    await _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await usersCollection.findOne(
        mongo.where.eq('email', widget.email)
      );

      if (userData != null && mounted) {
        setState(() {
          String sunSign = _calculateSunSign(userData['birth-date']);
          userAstroData = {
            'sunSign': sunSign,
            'risingSign': _calculateRisingSign(userData['birth-date'], userData['birth-time']),
            'element': _getElement(sunSign),
            'maritalStatus': userData['marital-status'] ?? 'Belirtilmemiş',
          };
        });
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  String _calculateSunSign(dynamic birthDate) {
    if (birthDate == null) return '';
    
    try {
      final DateTime date = birthDate is DateTime 
          ? birthDate 
          : DateTime.parse(birthDate.toString());
      
      final int month = date.month;
      final int day = date.day;

      if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return 'Aries';
      if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return 'Taurus';
      if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return 'Gemini';
      if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return 'Cancer';
      if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return 'Leo';
      if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return 'Virgo';
      if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return 'Libra';
      if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return 'Scorpio';
      if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return 'Sagittarius';
      if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return 'Capricorn';
      if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return 'Aquarius';
      return 'Pisces';
    } catch (e) {
      return '';
    }
  }

  String _calculateRisingSign(dynamic birthDate, dynamic birthTime) {
    if (birthDate == null || birthTime == null) return '';
    
    try {
      final DateTime date = birthDate is DateTime 
          ? birthDate 
          : DateTime.parse(birthDate.toString());
      
      final TimeOfDay time = birthTime is String 
          ? TimeOfDay(
              hour: int.parse(birthTime.split(':')[0]),
              minute: int.parse(birthTime.split(':')[1])
            )
          : TimeOfDay.now();
      
      final int totalMinutes = time.hour * 60 + time.minute;
      final int signIndex = ((totalMinutes + (date.month * 30)) % 360) ~/ 30;
      
      const List<String> signs = ['Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 
                                'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'];
      
      return signs[signIndex];
    } catch (e) {
      return '';
    }
  }

  String _getElement(String sign) {
    const Map<String, String> elements = {
      'Aries': 'Fire',
      'Leo': 'Fire',
      'Sagittarius': 'Fire',
      'Taurus': 'Earth',
      'Virgo': 'Earth',
      'Capricorn': 'Earth',
      'Gemini': 'Air',
      'Libra': 'Air',
      'Aquarius': 'Air',
      'Cancer': 'Water',
      'Scorpio': 'Water',
      'Pisces': 'Water',
    };
    return elements[sign] ?? '';
  }

  Widget _buildAstroInfo(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.isNotEmpty ? value : '-',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.purple,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _getCompletedFortuneRequests() async {
    try {
      final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));
      
      // 1 günden eski yanıtları sil
      await fortuneRequestsCollection.deleteMany(
        mongo.where
          .eq('userEmail', widget.email)
          .eq('status', 'completed')
          .lt('respondedAt', oneDayAgo)
      );
      
      // Kalan yanıtları getir
      final requests = await fortuneRequestsCollection
          .find(mongo.where
            .eq('userEmail', widget.email)
            .eq('status', 'completed')
            .gte('respondedAt', oneDayAgo))
          .toList();
      
      return List<Map<String, dynamic>>.from(requests);
    } catch (e) {
      print('Yanıtları getirme hatası: $e');
      return [];
    }
  }

  void _showInbox() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Inbox',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(height: 20),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _getCompletedFortuneRequests(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'No answered fortune readings found.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  final now = DateTime.now();
                  final requests = snapshot.data!.where((request) {
                    final respondedAt = request['respondedAt'] as DateTime;
                    return now.difference(respondedAt).inHours < 24;
                  }).toList();

                  if (requests.isEmpty) {
                    return const Center(
                      child: Text(
                        'No answered fortune readings found.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final request = requests[index];
                      final respondedAt = request['respondedAt'] as DateTime;
                      final remainingTime = DateTime.now().difference(respondedAt);
                      final hoursLeft = 24 - remainingTime.inHours;

                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.purple,
                            child: Icon(Icons.coffee, color: Colors.white),
                          ),
                          title: Text(
                            'Fortune Teller: ${request['fortuneTellerName']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('$hoursLeft hours left'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.pop(context);
                            _showFortuneResponseDialog(request);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFortuneResponseDialog(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Coffee Fortune Response',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image: MemoryImage(base64Decode(request['image'])),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  request['response'],
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Fortune Teller: ${request['fortuneTellerName']}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm')
                          .format(request['respondedAt']),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            currentUserEmail: widget.email,
                            currentUserName: widget.name,
                            recipientEmail: request['fortuneTellerEmail'],
                            recipientName: request['fortuneTellerName'],
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Contact Fortune Teller',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Close',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E1D39),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // Kullanıcı Bilgileri Kartı
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  children: [
                    // Burç İkonu
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.purple, width: 3),
                      ),
                      child: ClipOval(
                        child: userAstroData['sunSign'].isNotEmpty
                            ? Image.asset(
                                'assets/zodiac/${userAstroData['sunSign'].toLowerCase()}.png',
                                fit: BoxFit.scaleDown,
                              )
                            : Image.asset(
                                'assets/zodiac/loading-buffering.gif',
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Burç Bilgileri
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildInfoColumn('SUN SIGN', userAstroData['sunSign'], const Color.fromARGB(179, 0, 0, 0), Colors.purple),
                        _buildInfoColumn('ELEMENT', userAstroData['element'], const Color.fromARGB(179, 0, 0, 0), Colors.purple),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildInfoColumn('RISING SIGN', userAstroData['risingSign'], const Color.fromARGB(179, 0, 0, 0), Colors.purple),
                        _buildInfoColumn('STATUS', userAstroData['maritalStatus'], const Color.fromARGB(179, 0, 0, 0), Colors.purple),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Özellik Kartları
              _buildFeatureCard(
                icon: Icons.favorite,
                title: 'Zodiac Compatibility',
                subtitle: 'Calculate compatibility between two zodiac signs',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CompatibilityPage()),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                icon: Icons.mail,
                title: 'Inbox',
                subtitle: 'View your answered fortune readings',
                onTap: _showInbox,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, Color labelColor, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, color: Colors.purple, size: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.purple),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    if (widget.db == null && widget.enableDatabase) {
      db.close();
    }
    super.dispose();
  }
}