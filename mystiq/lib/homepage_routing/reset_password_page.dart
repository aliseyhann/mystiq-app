import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:mystiq_fortune_app/database/constant.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String resetCode;
  const ResetPasswordPage({
    super.key,
    required this.email,
    required this.resetCode,
  });

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _resetCodeController = TextEditingController(); 
  late mongo.Db db;
  late mongo.DbCollection usersCollection;
  
  @override
  void initState() {
    super.initState();
    _connectToDatabase();
  }

  void _connectToDatabase() async {
    db = mongo.Db(MONGO_URL);
    await db.open();
    usersCollection = db.collection('users');
  }

  Future<void> _updatePassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final enteredCode = _resetCodeController.text;

    if (enteredCode.isNotEmpty && newPassword.isNotEmpty && confirmPassword.isNotEmpty) {
      if (enteredCode != widget.resetCode) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geçersiz sıfırlama kodu!')),
        );
        return;
      }

      if (newPassword == confirmPassword) {
        try {
          final result = await usersCollection.updateOne(
            mongo.where.eq('email', widget.email),
            mongo.modify.set('password', newPassword),
          );

          if (result.nModified > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Şifreniz başarıyla güncellendi!')),
            );
            Navigator.pop(context); 
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Şifre güncellenirken bir hata oluştu!')),
            );
          }
        } catch (e) {
          print("MongoDB hatası: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bir hata oluştu!')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Şifreler eşleşmiyor!')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun!')),
      );
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _resetCodeController.dispose();
    db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Şifreyi Yenile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _resetCodeController,
              decoration: const InputDecoration(
                labelText: '4 Basamaklı Kod',
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Yeni Şifre'),
            ),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Yeni Şifreyi Onayla'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updatePassword,
              child: const Text('Şifreyi Güncelle'),
            ),
          ],
        ),
      ),
    );
  }
}

