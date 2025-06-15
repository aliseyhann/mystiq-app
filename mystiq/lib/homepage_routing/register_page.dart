import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:mystiq_fortune_app/database/constant.dart';
import 'package:mystiq_fortune_app/homepage_routing/login_page.dart';

class RegisterPage extends StatefulWidget {
  final String role;
  final String assetPath;
  const RegisterPage({Key? key, required this.role, this.assetPath = '/Users/aliseyhan/mobile-application-development-course/mystiq_fortune_app/assets/google_logo.svg'}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedRole;

  late mongo.Db db;
  late mongo.DbCollection usersCollection;

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
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

  void _registerUser() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isNotEmpty && password.isNotEmpty && _selectedRole != null) {
      
      final existingUser = await usersCollection.findOne({"email": email});
      if (existingUser == null) {
        await usersCollection.insertOne({
          "email": email, 
          "password": password, 
          "role": _selectedRole,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kayıt başarılı!")),
        );

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginPage(role: _selectedRole!)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bu e-posta adresi zaten kullanılıyor!")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun!")),
      );
    }    
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    db.close();
    super.dispose();
  }

  Future<void> googleLogin() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        final String? email = googleUser.email;

        _connectToDatabase();

        final existingUser = await usersCollection.findOne({"email": email});
        if (existingUser == null) {
          await usersCollection.insertOne({
            "role": _selectedRole,
            "email": email,
            "createdAt": DateTime.now(),
          });
          print("Yeni kullanıcı eklendi: $email");
        } else {
          print("Kullanıcı zaten mevcut: $email");
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage(role: _selectedRole!)),
        );
      }
    } catch (error) {
      print("Google Sign-In Hatası: $error");
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 80),
              child: Image.asset("assets/logo.png", width: 300, height: 300,
              ),
            ),
            DropdownButton<String>(
              value: _selectedRole != '' ? _selectedRole : null,
              hint: const Text("Choose your role"),
              items: <String>["Fortune Teller", "Regular User"].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newRole) {
                setState(() {
                  _selectedRole = newRole!;
                });
              },
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 250,
              child: TextField(
                controller: _emailController,
                enabled: _selectedRole != null,
                decoration: InputDecoration(
                  hintText: "Enter a mail address",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              )
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 250,
              child: TextField(
                controller: _passwordController,
                enabled: _selectedRole != null,
                decoration: InputDecoration(
                  hintText: "Enter a password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: true,
              )
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                minimumSize: const Size(100, 50),
                side: const BorderSide(color: Color.fromARGB(255, 255, 255, 255)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                )
              ),
              onPressed: _selectedRole != null ? _registerUser : null,
              label: const Text("Sign Up"),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Expanded(
                  child: Divider(
                    thickness: 1,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  child: Text(
                    "OR",
                    style: TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    thickness: 1,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 0, 0), // Button arka plan rengi
                foregroundColor: const Color.fromARGB(255, 255, 255, 255), // Button yazı ve ikon rengi
                minimumSize: const Size(250, 50), // Buton boyutu
                side: const BorderSide(color: Color.fromARGB(255, 255, 255, 255)), // Kenarlık rengi
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _selectedRole != null ? googleLogin : null,
               icon: SvgPicture.asset(
                widget.assetPath,
                width: 24,
                height: 24,
              ),
              label: const Text("Sign Up with Google"),
            ),
          ],
        )
      ),
    );
  }
}