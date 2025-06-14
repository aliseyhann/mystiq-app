import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server.dart'; 

class EmailService {
  final Function(mailer.Message, SmtpServer) sendEmail;

  EmailService({Function(mailer.Message, SmtpServer)? sendEmail})
      : sendEmail = sendEmail ?? mailer.send;

Future<void> sendPasswordResetEmail(String userEmail, String resetCode) async {
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  final smtpServer = gmail(
    dotenv.env['GMAIL_MAIL'] ?? '', 
    dotenv.env['GMAIL_PASSWORD'] ?? ''
  );

  final message = mailer.Message()
    ..from = mailer.Address(dotenv.env['GMAIL_MAIL'] ?? '', 'Mystiq Fortune App')
    ..recipients.add(userEmail)
    ..subject = 'MystiQ - Password Reset Request'
    ..html = """
    <html>
      <head>
        <style>
          body {
            font-family: 'Arial', sans-serif;
            background-color: #f4f7fa;
            margin: 0;
            padding: 0;
          }
          .container {
            width: 100%;
            max-width: 600px;
            margin: 0 auto;
            background-color: #ffffff;
            border-radius: 8px;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
            padding: 30px;
            text-align: center;
          }
          .header {
            font-size: 24px;
            font-weight: bold;
            color: #333;
            margin-bottom: 20px;
          }
          .content {
            font-size: 16px;
            color: #555;
            line-height: 1.6;
          }
          .code {
            font-size: 24px;
            font-weight: bold;
            color: #ff5722;
            background-color: #fce4ec;
            padding: 10px;
            border-radius: 4px;
            margin-top: 20px;
          }
          .footer {
            font-size: 14px;
            color: #777;
            margin-top: 30px;
            text-align: center;
          }
          .button {
            display: inline-block;
            padding: 12px 25px;
            background-color: #ff5722;
            color: white;
            text-decoration: none;
            border-radius: 4px;
            font-size: 16px;
            margin-top: 20px;
          }
          .button:hover {
            background-color: #e64a19;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">MystiQ Fortune App</div>
          <div class="content">
            <p>Hello,</p>
            <p>You can use the 4-digit code below to reset your password:</p>
            <div class="code">$resetCode</div>
            <p>If you did not make this request, ignore this email.</p>
          </div>
          <div class="footer">
            <p>Thanks,</p>
            <p>Mystiq Fortune App Team</p>
          </div>
        </div>
      </body>
    </html>
  """;

  try {
      final sendReport = await sendEmail(message, smtpServer);
    print('E-posta başarıyla gönderildi: $sendReport');
  } on mailer.MailerException catch (e) {
    print('E-posta gönderimi sırasında hata oluştu: $e');
  }
  }
}

// Eski fonksiyon, geriye dönük uyumluluk için
Future<void> sendPasswordResetEmail(String userEmail, String resetCode) async {
  final emailService = EmailService();
  await emailService.sendPasswordResetEmail(userEmail, resetCode);
}



