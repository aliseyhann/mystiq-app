import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server.dart';
import 'package:mystiq_fortune_app/backend/email_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

@GenerateMocks([mailer.Message, SmtpServer])
import 'email_service_test.mocks.dart';

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
  });
} 