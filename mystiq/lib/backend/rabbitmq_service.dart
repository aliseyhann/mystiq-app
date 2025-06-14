import 'dart:convert';
import 'package:dart_amqp/dart_amqp.dart';
import 'package:mystiq_fortune_app/backend/email_service.dart';
import 'dart:io';

class RabbitMQService {
  static String get host {
    if (Platform.isAndroid) {
      return '10.0.2.2'; // Android emulator için localhost
    } else if (Platform.isIOS) {
      return 'localhost'; // iOS simulator için
    }
    return 'localhost'; // Diğer platformlar için
  }
}

// Test edilebilirlik için opsiyonel client parametresi eklendi
dynamic listenForResetRequests({Client? client}) async {
  try {
    final connectionSettings = ConnectionSettings(
      host: RabbitMQService.host,
      port: 5672,
      authProvider: PlainAuthenticator('guest', 'guest'),
    );

    client ??= Client(settings: connectionSettings);
    final channel = await client.channel();
    final queue = await channel.queue('reset_queue', durable: true);

    final consumer = await queue.consume();

    consumer.listen((AmqpMessage message) async {
      final data = jsonDecode(message.payloadAsString);
      final email = data['email'];
      final resetCode = data['resetCode'];

      print('Sıfırlama kodu: $resetCode, Kullanıcı E-posta: $email');

      await sendPasswordResetEmail(email, resetCode);

      message.ack();
    });
  } catch (e) {
    print("Hata oluştu: $e");
  }
}








