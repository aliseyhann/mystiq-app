import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_amqp/dart_amqp.dart';
import 'dart:convert';
import 'dart:io';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications;
  SharedPreferences? _prefs;
  static const String _prefsKey = 'notifications_enabled';

  // Test edilebilirlik için platform kontrollerini fonksiyon olarak dışarıdan enjekte edilebilir yaptık
  static bool Function() isAndroid = () => Platform.isAndroid;
  static bool Function() isIOS = () => Platform.isIOS;

  static String get RABBITMQ_HOST {
    if (isAndroid()) {
      return '10.0.2.2'; // Android
    } else if (isIOS()) {
      return 'localhost'; // iOS 
    }
    return 'localhost';
  }
  
  static const int RABBITMQ_PORT = 5672;
  static const String RABBITMQ_USER = 'guest';
  static const String RABBITMQ_PASS = 'guest';

  final Client Function()? clientFactory;

  NotificationService({
    FlutterLocalNotificationsPlugin? notifications,
    SharedPreferences? prefs,
    this.clientFactory,
  }) : _notifications = notifications ?? FlutterLocalNotificationsPlugin(),
       _prefs = prefs;

  Future<SharedPreferences> get _getPrefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> initialize(String userEmail) async {
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      final initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          print('Bildirime tıklandı: ${details.payload}');
        },
      );

      await requestPermission();
      
      await _setupBackgroundListening(userEmail);
      
      listenForNotifications(userEmail);
    } catch (e) {
      print('Bildirim servisi başlatılamadı: $e');
    }
  }

  Future<void> _setupBackgroundListening(String userEmail) async {
    try {
      final client = clientFactory != null ? clientFactory!() : Client(
        settings: ConnectionSettings(
          host: RABBITMQ_HOST,
          port: RABBITMQ_PORT,
          authProvider: PlainAuthenticator(RABBITMQ_USER, RABBITMQ_PASS),
        ),
      );

      final channel = await client.channel();
      final exchange = await channel.exchange(
        'notifications',
        ExchangeType.DIRECT,
        durable: false
      );
      final queue = await channel.queue(
        'notifications.$userEmail',
        durable: true
      );
      
      await queue.bind(exchange, 'notifications.$userEmail');
      
      final consumer = await queue.consume(noAck: false);
      consumer.listen((message) async {
        try {
          final data = json.decode(message.payloadAsString);
          if (data['recipientEmail'] == userEmail) {
            String title, messageText;
            
            if (data['type'] == 'new_fortune') {
              title = 'Yeni Fal İsteği';
              messageText = '${data['senderName']} adlı kullanıcıdan yeni bir fal isteği geldi';
            } else if (data['type'] == 'fortune_ready') {
              title = 'Kahve Falınız Hazır!';
              messageText = 'Falcınız kahve falınızı yorumladı. Hemen görüntülemek için tıklayın!';
            } else {
              message.ack();
              return;
            }

            await sendNotification(
              userId: userEmail,
              title: title,
              message: messageText,
            );
          }
          message.ack();
        } catch (e) {
          print('Bildirim işleme hatası: $e');
          message.ack();
        }
      });
    } catch (e) {
      print('Arka plan dinleme hatası: $e');
    }
  }

  Future<void> requestPermission() async {
    try {
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _notifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidImplementation?.requestNotificationsPermission();
      }
      await setNotificationsEnabled(true);
    } catch (e) {
      print('Bildirim izni alınamadı: $e');
      await setNotificationsEnabled(false);
    }
  }

  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
  }) async {
    try {
      if (await getNotificationsEnabled()) {
        const androidDetails = AndroidNotificationDetails(
          'mystiq_channel',
          'Mystiq Bildirimleri',
          channelDescription: 'Fal yorumları için bildirimler',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          enableLights: true,
          enableVibration: true,
          playSound: true,
          ongoing: false,
          autoCancel: true,
          styleInformation: BigTextStyleInformation(''),
          category: AndroidNotificationCategory.message,
        );

        const iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.active,
          threadIdentifier: 'mystiq_notifications',
        );

        const details = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        await _notifications.show(
          DateTime.now().millisecond,
          title,
          message,
          details,
          payload: userId,
        );
      }
    } catch (e) {
      print('Bildirim gönderilemedi: $e');
    }
  }

  Future<void> publishNotification({
    required String recipientEmail,
    required String type,
    String? senderName,
  }) async {
    try {
      final client = Client(
        settings: ConnectionSettings(
          host: RABBITMQ_HOST,
          port: RABBITMQ_PORT,
          authProvider: PlainAuthenticator(RABBITMQ_USER, RABBITMQ_PASS),
        ),
      );

      final channel = await client.channel();
      final exchange = await channel.exchange(
        'notifications',
        ExchangeType.DIRECT,
        durable: false
      );
      
      final notification = {
        'recipientEmail': recipientEmail,
        'type': type, // 'new_fortune' veya 'fortune_ready'
        'senderName': senderName,
        'timestamp': DateTime.now().toIso8601String(),
      };

      exchange.publish(
        json.encode(notification),
        'notifications.$recipientEmail',
      );

      await client.close();
    } catch (e) {
      print('RabbitMQ bildirim yayınlama hatası: $e');
    }
  }

  void listenForNotifications(String userEmail) async {
    try {
      final client = Client(
        settings: ConnectionSettings(
          host: RABBITMQ_HOST,
          port: RABBITMQ_PORT,
          authProvider: PlainAuthenticator(RABBITMQ_USER, RABBITMQ_PASS),
        ),
      );

      final channel = await client.channel();
      final exchange = await channel.exchange(
        'notifications',
        ExchangeType.DIRECT,
        durable: false
      );
      final queue = await channel.queue(
        'notifications.$userEmail',
        durable: true
      );
      
      await queue.bind(exchange, 'notifications.$userEmail');
      
      final consumer = await queue.consume();
      consumer.listen((message) {
        try {
          final data = json.decode(message.payloadAsString);
          if (data['recipientEmail'] == userEmail) {
            String title, messageText;
            
            if (data['type'] == 'new_fortune') {
              title = 'Yeni Fal İsteği';
              messageText = '${data['senderName']} adlı kullanıcıdan yeni bir fal isteği geldi';
            } else if (data['type'] == 'fortune_ready') {
              title = 'Kahve Falınız Hazır!';
              messageText = 'Falcınız kahve falınızı yorumladı. Hemen görüntülemek için tıklayın!';
            } else {
              return; // Bilinmeyen bildirim tipi
            }

            sendNotification(
              userId: userEmail,
              title: title,
              message: messageText,
            );
          }
        } catch (e) {
          print('Bildirim işleme hatası: $e');
        }
        message.ack();
      });
    } catch (e) {
      print('RabbitMQ dinleme hatası: $e');
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await _getPrefs;
    await prefs.setBool(_prefsKey, enabled);
  }

  Future<bool> getNotificationsEnabled() async {
    final prefs = await _getPrefs;
    return prefs.getBool(_prefsKey) ?? true;
  }
} 