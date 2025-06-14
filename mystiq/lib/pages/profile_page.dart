import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:mystiq_fortune_app/database/constant.dart';
import 'package:mystiq_fortune_app/homepage_routing/login_page.dart';
import 'package:mystiq_fortune_app/backend/session_service.dart';
import 'package:mystiq_fortune_app/backend/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  final String email;
  final bool enableDatabase;
  final Map<String, dynamic>? mockData;
  final NotificationService? notificationService;

  const ProfilePage({
    Key? key, 
    required this.email,
    this.enableDatabase = true,
    this.mockData,
    this.notificationService,
  }) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late mongo.Db db;
  late mongo.DbCollection usersCollection;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  late NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _notificationService = widget.notificationService ?? NotificationService();
    if (widget.mockData != null) {
      setState(() {
        userData = widget.mockData;
        isLoading = false;
      });
    } else if (widget.enableDatabase) {
    _connectToDatabase();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _connectToDatabase() async {
    try {
      db = await mongo.Db.create(MONGO_URL);
      await db.open();
      usersCollection = db.collection("users");
      await _loadUserData();
    } catch (e) {
      print("Database connection error: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      final data = await usersCollection.findOne({"email": widget.email});
      setState(() {
        userData = data;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading user data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateUserData(String field, dynamic value) async {
    try {
      await usersCollection.updateOne(
        mongo.where.eq('email', widget.email),
        mongo.modify.set(field, value),
      );
      await _loadUserData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated successfully!')),
      );
    } catch (e) {
      print("Error updating user data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update. Please try again.')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    try {
      await usersCollection.deleteOne({"email": widget.email});
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage(role: '')),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      print("Error deleting account: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete account. Please try again.')),
      );
    }
  }

  void _showEditDialog({
    required String title,
    required String currentValue,
    required Function(String) onSave,
    List<String>? options,
  }) {
    final controller = TextEditingController(text: currentValue);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(height: 24),
              if (options != null)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: options.map((option) => ListTile(
                      title: Text(
                        option,
                        style: const TextStyle(fontSize: 16),
                      ),
                      onTap: () {
                        onSave(option);
                        Navigator.pop(context);
                      },
                      trailing: currentValue == option
                          ? const Icon(Icons.check, color: Colors.purple)
                          : null,
                    )).toList(),
                  ),
                )
              else
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Enter here',
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
              const SizedBox(height: 24),
              if (options == null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (controller.text.isNotEmpty) {
                          onSave(controller.text);
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _editField(String field, String currentValue) {
    _showEditDialog(
      title: '${field.replaceAll('-', ' ').toUpperCase()} Edit',
      currentValue: currentValue,
      onSave: (value) => _updateUserData(field, value),
    );
  }

  void _editDateTime(String field, DateTime? currentValue) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentValue ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.purple,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _updateUserData(field, picked);
    }
  }

  void _editBirthTime(String currentValue) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentValue.isNotEmpty 
          ? TimeOfDay(
              hour: int.parse(currentValue.split(':')[0]),
              minute: int.parse(currentValue.split(':')[1])
            )
          : TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.purple,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      _updateUserData('birth-time', formattedTime);
    }
  }

  void _editGender(String currentValue) {
    _showEditDialog(
      title: 'Choose Gender',
      currentValue: currentValue,
      onSave: (value) => _updateUserData('gender', value),
      options: ['Man', 'Woman'],
    );
  }

  void _editMaritalStatus(String currentValue) {
    _showEditDialog(
      title: 'Marital Status',
      currentValue: currentValue,
      onSave: (value) => _updateUserData('marital-status', value),
      options: ['Single', 'In a relationship', 'Married', 'Engaged', 'Divorced', 'Widowed'],
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_rounded,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Delete Account',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Are you sure you want to delete your account? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteAccount();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: Colors.purple));
    }

    if (userData == null) {
      return Center(child: Text('Failed to load user data'));
    }

    return Scaffold(
      backgroundColor: Color(0xFF2E1D39),
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.purple,
                  child: Text(
                    (userData!['name'] ?? 'U')[0].toUpperCase(),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(userData!['name'] ?? 'Not set'),
                subtitle: Text(widget.email),
                trailing: IconButton(
                  icon: Icon(Icons.edit, color: Colors.purple),
                  onPressed: () => _editField('name', userData!['name'] ?? ''),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.calendar_today, color: Colors.purple),
                    title: Text('Birth Date'),
                    subtitle: Text(
                      userData!['birth-date'] != null
                          ? DateTime.parse(userData!['birth-date'].toString())
                              .toString()
                              .split(' ')[0]
                          : 'Not set'
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.edit, color: Colors.purple),
                      onPressed: () => _editDateTime(
                        'birth-date',
                        userData!['birth-date'] != null
                            ? DateTime.parse(userData!['birth-date'].toString())
                            : null,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.access_time, color: Colors.purple),
                    title: Text('Birth Time'),
                    subtitle: Text(userData!['birth-time']?.toString() ?? 'Not set'),
                    trailing: IconButton(
                      icon: Icon(Icons.edit, color: Colors.purple),
                      onPressed: () => _editBirthTime(
                        userData!['birth-time']?.toString() ?? ''
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.person, color: Colors.purple),
                    title: Text('Gender'),
                    subtitle: Text(userData!['gender'] ?? 'Not set'),
                    trailing: IconButton(
                      icon: Icon(Icons.edit, color: Colors.purple),
                      onPressed: () => _editGender(userData!['gender'] ?? ''),
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.favorite, color: Colors.purple),
                    title: Text('Marital Status'),
                    subtitle: Text(userData!['marital-status'] ?? 'Not set'),
                    trailing: IconButton(
                      icon: Icon(Icons.edit, color: Colors.purple),
                      onPressed: () => _editMaritalStatus(
                        userData!['marital-status'] ?? ''
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: const Icon(Icons.notifications, color: Colors.purple),
                title: const Text(
                  'Notifications',
                  style: TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: FutureBuilder<bool>(
                  future: _notificationService.getNotificationsEnabled(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.purple,
                        ),
                      );
                    }
                    final enabled = snapshot.data ?? true;
                    return Switch(
                      value: enabled,
                      onChanged: (value) async {
                        await _notificationService.setNotificationsEnabled(value);
                        setState(() {});
                      },
                      activeColor: Colors.purple,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.purple),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: const Text(
                        'Are you sure you want to logout?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            final sessionService = SessionService(prefs);
                            await sessionService.clearSession();
                            if (mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(role: ''),
                                ),
                                (route) => false,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete Account'),
                onTap: () {
                  _showDeleteConfirmation();
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (widget.enableDatabase) {
    db.close();
    }
    super.dispose();
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
