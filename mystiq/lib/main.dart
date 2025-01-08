import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mystiq_fortune_app/database/mongodb.dart';
import 'package:mystiq_fortune_app/pages/MainPage/main_page_fortune_teller.dart';
import 'package:mystiq_fortune_app/pages/MainPage/main_page_normal_user.dart';
import 'package:mystiq_fortune_app/backend/session_service.dart';
import 'package:mystiq_fortune_app/backend/notification_service.dart';
import 'home_page.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  await MongoDatabase.connect();
  
  // Önce oturum bilgisini kontrol et
  final sessionData = await SessionService.getSession();
  final notificationService = NotificationService();
  
  // Eğer aktif oturum varsa bildirimleri başlat
  if (sessionData['email'] != null) {
    await notificationService.initialize(sessionData['email']!);
  }
  
  print("database connected.");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MystiQ',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FutureBuilder<Map<String, String?>>(
        future: SessionService.getSession(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final sessionData = snapshot.data;
          if (sessionData != null && 
              sessionData['email'] != null && 
              sessionData['role'] != null) {
            // Aktif oturum var
            if (sessionData['role'] == 'Fortune Teller') {
              return MainPageFortuneTeller(
                email: sessionData['email']!,
                name: sessionData['name'] ?? 'Falcı',
              );
            } else {
              return MainPageNormalUser(
                email: sessionData['email']!,
                name: sessionData['name'] ?? 'Kullanıcı',
              );
            }
          }

          // Aktif oturum yok
          return const HomePage();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}