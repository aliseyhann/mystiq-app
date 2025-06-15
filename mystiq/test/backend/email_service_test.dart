import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server.dart';
import 'package:mystiq_fortune_app/backend/email_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';

@GenerateMocks([mailer.Message, SmtpServer])
import 'email_service_test.mocks.dart';

class FakeMailerException extends mailer.MailerException {
  FakeMailerException(String message) : super(message);
}

class MockEmailService extends EmailService {
  @override
  Future<void> sendPasswordResetEmail(String userEmail, String resetCode) async {
    throw FakeMailerException('SMTP error');
  }
}

void main() {
  late MockMessage mockMessage;
  late MockSmtpServer mockSmtpServer;
  late EmailService emailService;

  setUp(() async {
    mockMessage = MockMessage();
    mockSmtpServer = MockSmtpServer();
    emailService = EmailService(sendEmail: (message, server) async => 'Mocked send report');
    await dotenv.load(fileName: ".env");
  });

  group('EmailService', () {
    test('sendPasswordResetEmail should send email successfully', () async {
      const testEmail = 'test@example.com';
      const testCode = '1234';
      await emailService.sendPasswordResetEmail(testEmail, testCode);
      // Assert: No exception thrown
    });

    test('sendPasswordResetEmail should handle invalid email', () async {
      const invalidEmail = 'invalid-email';
      const testCode = '1234';
      await emailService.sendPasswordResetEmail(invalidEmail, testCode);
      // Assert: No exception thrown
    });

    test('sendPasswordResetEmail should handle invalid reset code', () async {
      const testEmail = 'test@example.com';
      const invalidCode = '';
      await emailService.sendPasswordResetEmail(testEmail, invalidCode);
      // Assert: No exception thrown
    });

    test('mock objects should be used', () {
      verify(mockMessage.toString()).called(1);
      verify(mockSmtpServer.toString()).called(1);
    });

    test('sendPasswordResetEmail should catch MailerException and print error', () async {
      final emailService = MockEmailService();

      final prints = <String>[];
      await runZoned(
        () async => await emailService.sendPasswordResetEmail('test@example.com', '1234'),
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) {
            prints.add(line);
          },
        ),
      );

      expect(
        prints.any((line) => line.contains('E-posta gönderimi sırasında hata oluştu:')),
        isTrue,
      );
    });

    test('sendPasswordResetEmail (legacy) should call the new implementation', () async {
      final emailService = EmailService(sendEmail: (message, server) async => 'Mocked send report');
      await emailService.sendPasswordResetEmail('test@example.com', '1234');
      // Assert: No exception thrown
    });

    test('legacy sendPasswordResetEmail should call the new implementation', () async {
      // sendEmail fonksiyonu çağrılıyor mu kontrolü
      bool called = false;
      final emailService = EmailService(
        sendEmail: (message, server) async {
          called = true;
          return 'ok';
        },
      );

      // Eski fonksiyonu çağırıyoruz
      Future<void> legacySendPasswordResetEmail(String userEmail, String resetCode) async {
        final service = emailService;
        await service.sendPasswordResetEmail(userEmail, resetCode);
      }

      await legacySendPasswordResetEmail('test@example.com', '1234');
      expect(called, isTrue);
    });
  });
} 