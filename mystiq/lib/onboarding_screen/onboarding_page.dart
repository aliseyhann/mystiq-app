import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:mystiq_fortune_app/database/constant.dart';
import 'package:mystiq_fortune_app/pages/MainPage/main_page_normal_user.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.email,});
  final String email;

  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();

  late mongo.Db db;
  late mongo.DbCollection usersCollection;

  int _currentPage = 0;

  String name = '';
  DateTime? birthDate;
  String birthTime = '';
  String gender = '';
  String maritalStatus = '';

  @override
  void initState() {
    super.initState();
    _connectToDatabase();
  }

  void _connectToDatabase() async {
    db = await mongo.Db.create(MONGO_URL);
    await db.open();
    usersCollection = db.collection("users");
  } 

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _saveToDatabase();
    }
  }

  void _backPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300), 
        curve: Curves.easeInOut,
      );
    }
  }

  void _saveToDatabase() async {
    // Veritabanına kaydetme işlemi
    await usersCollection.updateOne(
      mongo.where.eq('email', widget.email),
      mongo.modify.set('name', name),
    );
    await usersCollection.updateOne(
      mongo.where.eq('email', widget.email),
      mongo.modify.set('birth-date', birthDate),
    );
    await usersCollection.updateOne(
      mongo.where.eq('email', widget.email),
      mongo.modify.set('birth-time', birthTime),
    );
    await usersCollection.updateOne(
      mongo.where.eq('email', widget.email),
      mongo.modify.set('gender', gender),
    );
    await usersCollection.updateOne(
      mongo.where.eq('email', widget.email),
      mongo.modify.set('marital-status', maritalStatus),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Bilgiler başarıyla kaydedildi!")),
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => MainPageNormalUser(
          email: widget.email,
          name: name,
        ),
      ),
      (Route<dynamic> route) => false,
    );
  }

  @override
  void dispose() {
    db.close();
    super.dispose();
  }

  String timeOfDayToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [
          _buildNamePage(),

          _buildBirthDatePage(),

          _buildBirthTimePage(),

          _buildGenderPage(),

          _buildMaritalStatusPage(),
        ],
      ),
    );
  }

  Widget _buildNamePage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome Fortuner"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _buildOnboardingStep(
        title: "Enter Your Name",
        content: TextField(
          decoration: const InputDecoration(hintText: "Name"),
          onChanged: (value) {
            name = value;
          },
        ),
      ),
    );
  }

  Widget _buildBirthDatePage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Horoscope"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _backPage();
          },
        ),
      ),
        body: _buildOnboardingStep(
        title: "Choose Your Birth Date",
        content: ElevatedButton(
          onPressed: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (pickedDate != null) {
              setState(() {
                birthDate = pickedDate;
              });
            }
          },
          child: Text(
            birthDate != null
                ? "${birthDate!.day}/${birthDate!.month}/${birthDate!.year}"
                : "Birth Date",
          ),
        ),
      ),
    );
  }

  Widget _buildBirthTimePage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rising Sign"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _backPage();
          },
        ),
      ),
      body: _buildOnboardingStep(
        title: "Choose Your Birth Time",
        content: Column(
          children: [
            Text(
              birthTime.isNotEmpty ? birthTime : "No time selected",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (pickedTime != null) {
                  setState(() {
                    birthTime = timeOfDayToString(pickedTime);
                  });
                }
              },
              child: Text("Select Time"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gender"),
        centerTitle: true,
          leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _backPage();
          },
        ),
      ),
      body: _buildOnboardingStep(
        title: "Choose Your Gender",
        content: DropdownButton<String>(
          value: gender.isNotEmpty ? gender : null,
          items: ["Man", "Women"]
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (value) {
            setState(() {
              gender = value!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildMaritalStatusPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Relationship Status"),
        centerTitle: true,
          leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _backPage();
          },
        ),
      ),
      body: _buildOnboardingStep(
        title: "Choose Your Marial Status",
        content: DropdownButton<String>(
          value: maritalStatus.isNotEmpty ? maritalStatus : null,
          items: ["In Relationship", "Single", "Married", "Engaged", "Divorced", "Widow"]
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (value) {
            setState(() {
              maritalStatus = value!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildOnboardingStep({required String title, required Widget content}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          content,
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _nextPage,
            child: const Text("Next"),
          ),
        ],
      ),
    );
  }
}
