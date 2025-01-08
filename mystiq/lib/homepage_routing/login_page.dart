import 'dart:convert';
import 'dart:math';
import 'package:dart_amqp/dart_amqp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:mystiq_fortune_app/backend/rabbitmq_service.dart';
import 'package:mystiq_fortune_app/backend/session_service.dart';
import 'package:mystiq_fortune_app/database/constant.dart';
import 'package:mystiq_fortune_app/homepage_routing/register_page.dart';
import 'package:mystiq_fortune_app/homepage_routing/reset_password_page.dart';
import 'package:mystiq_fortune_app/onboarding_screen/onboarding_page.dart';
import 'package:mystiq_fortune_app/pages/MainPage/main_page_fortune_teller.dart';
import 'package:mystiq_fortune_app/pages/MainPage/main_page_normal_user.dart';

class LoginPage extends StatefulWidget {
  final String role;
  const LoginPage({super.key, required this.role});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String selectedRole = '';

  late mongo.Db db;
  late mongo.DbCollection usersCollection;

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  String? _resetCode; 

  @override
  void initState() {
    super.initState();
    _connectToDatabase();
  }

  void _connectToDatabase() async {
    db = mongo.Db(MONGO_URL);
    await db.open();
    usersCollection = db.collection("users");
  }

  void _loginUser() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isNotEmpty && password.isNotEmpty) {
      final user = await usersCollection.findOne({
        "email": email,
        "password": password,
      });

      if (user != null) {
        String role = user["role"];

        // Oturumu kaydet
        await SessionService.saveSession(email, role);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Giriş başarılı!")),
        );

        if (role == "Fortune Teller") {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => MainPageFortuneTeller(
                email: email,
                name: user['name'] ?? 'Falcı',
              ),
            ),
            (Route<dynamic> route) => false,
          );
        } else if (role == "Regular User") {
          final checking = await usersCollection.findOne({
            'email': email,
            'name': {'\$exists': true},
            'birth-date': {'\$exists': true},
            'birth-time': {'\$exists': true},
            'gender': {'\$exists': true},
            'marital-status': {'\$exists': true},
          });
          if (checking != null) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => MainPageNormalUser(
                  email: email,
                  name: user['name'] ?? 'Kullanıcı',
                ),
              ),
              (Route<dynamic> route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => OnboardingPage(email: email)),
              (Route<dynamic> route) => false,
            );
          }
        }

        _emailController.clear();
        _passwordController.clear();

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("E-posta veya şifre yanlış!")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter all fields!")),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Lütfen önce Google ile kaydolun!")),
          );  
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RegisterPage(role: selectedRole),
            ),
          );
        } else {
          String role = existingUser["role"];

          // Oturumu kaydet
          await SessionService.saveSession(email!, role);

          if (role == "Fortune Teller") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainPageFortuneTeller(
                  email: googleUser.email,
                  name: googleUser.displayName ?? 'Falcı',
                ),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainPageNormalUser(
                  email: email,
                  name: googleUser.displayName ?? 'Kullanıcı',
                ),
              ),
            );
          }
        }
      }
    } catch (error) {
      print("Google Sign-In Hatası: $error");
    }
  }

  Future<void> sendPasswordResetRequest(String email) async {
    Client? client;
    try {
      final connectionSettings = ConnectionSettings(
        host: RabbitMQService.host,
        port: 5672,
        authProvider: const PlainAuthenticator('guest', 'guest'),
      );

      client = Client(settings: connectionSettings);
      final channel = await client.channel();
      final exchange = await channel.exchange('email_exchange', ExchangeType.DIRECT);
      final queue = await channel.queue('reset_queue', durable: true);
      await queue.bind(exchange, 'reset_queue');

      _resetCode = _generateRandomCode(); 
      
      final message = jsonEncode({
        'email': email,
        'resetCode': _resetCode,
      });

      exchange.publish(
        message,
        'reset_queue',
      );

      listenForResetRequests();
    } catch (e) {
      print("Şifre sıfırlama isteği gönderilemedi: $e");
      rethrow; // Hatayı yukarı fırlat
    } finally {
      if (client != null) {
        await client.close();
      }
    }
  }

  String _generateRandomCode() {
    final random = Random();
    final code = 1000 + random.nextInt(9000);
    return code.toString();
  }

  void _showForgotPasswordDialog() {
    if (!mounted) return;
    
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        TextEditingController emailController = TextEditingController();

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Reset Password",
            style: TextStyle(
              color: Colors.purple,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  hintText: "Enter your email address",
                  prefixIcon: Icon(Icons.email, color: Colors.purple),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              const Text(
                "A reset code will be sent to your email",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text;
                if (email.isNotEmpty && isValidEmail(email)) {
                  navigator.pop(); // Dialog'u kapat
                  
                  try {
                    await sendPasswordResetRequest(email);
                    
                    if (mounted) {
                      // Kullanıcıya bilgi ver
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text("Reset code has been sent to your email."),
                          backgroundColor: Colors.green,
                        ),
                      );

                      // Biraz bekleyip reset sayfasına yönlendir
                      await Future.delayed(const Duration(seconds: 1));
                      
                      if (mounted && _resetCode != null) {
                        navigator.push(
                          MaterialPageRoute(
                            builder: (context) => ResetPasswordPage(
                              email: email,
                              resetCode: _resetCode!,
                            ),
                          ),
                        );
                      }
                    }
                  } catch (error) {
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text("Failed to send reset code. Please try again."),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } else {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text("Please enter a valid email address."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
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
              child: Image.asset('assets/logo.png', width: 300, height: 300,
              ),
            ),
            SizedBox(
              width: 250,
              child: TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: "Enter a mail address",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 250,
              child: TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  hintText: "Enter a password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: true,
              ),
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
                ),
              ),
              onPressed: () {
                _loginUser();
              },
              label: const Text("Log In"),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                _showForgotPasswordDialog();
              },
              child: const Text(
                "Forgot Password?",
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
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
                      fontWeight: FontWeight.bold,
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
                backgroundColor: const Color.fromARGB(255, 255, 0, 0),
                foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                minimumSize: const Size(250, 50),
                side: const BorderSide(color: Color.fromARGB(255, 255, 255, 255)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                googleLogin();
              },
              icon: SvgPicture.asset(
                '/Users/aliseyhan/mobile-application-development-course/mystiq_fortune_app/assets/google_logo.svg',
                width: 24,
                height: 24,
              ),
              label: const Text("Log In with Google"),
            ),     
          ],
        )
      ),
    );
  }
}