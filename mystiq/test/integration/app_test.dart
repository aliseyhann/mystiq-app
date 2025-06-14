import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mystiq_fortune_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Tüm Kullanıcı Akışları', () {
    testWidgets('1- Giriş Akışı', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Ana ekranda "Login" butonuna tıkla
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // LoginPage'de TextField'ları ve "Log In" butonunu kontrol et
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Log In'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), '123456');
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      // Başarılı giriş sonrası ana ekran veya hata mesajı
      expect(
        find.byWidgetPredicate((widget) =>
          widget is SnackBar &&
          ((widget.content as Text).data!.contains('Giriş başarılı') ||
           (widget.content as Text).data!.contains('E-posta veya şifre yanlış!'))
        ),
        findsOneWidget,
      );
    });

    testWidgets('2- Kayıt Olma Akışı', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Ana ekranda "Register" butonuna tıkla
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      // RegisterPage'de rol seç
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Regular User').last);
      await tester.pumpAndSettle();

      // Email ve şifre gir
      await tester.enterText(find.byType(TextField).at(0), 'newuser@example.com');
      await tester.enterText(find.byType(TextField).at(1), '123456');

      // Kayıt ol
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Başarılı kayıt mesajı
      expect(find.textContaining('Kayıt başarılı'), findsOneWidget);
    });

    testWidgets('3- Şifre Sıfırlama Akışı', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Ana ekranda "Login" butonuna tıkla
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // LoginPage'de "Forgot Password?" linkine tıkla
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Açılan dialogda e-posta gir
      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      // Kod ve yeni şifre ekranı açılırsa, kod ve şifre gir
      // (Bu adım backend/mock gerektirir)
      // await tester.enterText(find.byType(TextField).at(0), '1234'); // Kod
      // await tester.enterText(find.byType(TextField).at(1), 'yeniSifre');
      // await tester.enterText(find.byType(TextField).at(2), 'yeniSifre');
      // await tester.tap(find.text('Şifreyi Güncelle'));
      // await tester.pumpAndSettle();
      // expect(find.textContaining('Şifreniz başarıyla güncellendi'), findsOneWidget);
    });

    // Diğer akışlar için şablonlar:
    testWidgets('4- Profil Güncelleme', (WidgetTester tester) async {
      // TODO: Profil sayfasına git, bilgileri güncelle, başarı mesajı kontrol et
    });

    testWidgets('5- Bildirim Ayarları', (WidgetTester tester) async {
      // TODO: Bildirim switch'ini aç/kapat, kaydedildiğini kontrol et
    });

    testWidgets('6- Hesap Silme', (WidgetTester tester) async {
      // TODO: Profilde hesap silme işlemini başlat, onayla, login ekranına yönlendirildiğini kontrol et
    });

    testWidgets('7- Çıkış Yapma', (WidgetTester tester) async {
      // TODO: Çıkış butonuna tıkla, login ekranına yönlendirildiğini kontrol et
    });

    testWidgets('8- Fal İsteği Gönderme ve Alma', (WidgetTester tester) async {
      // TODO: Chat/fal ekranına git, mesaj gönder/al, bildirim kontrolü
    });

    testWidgets('9- Onboarding Akışı', (WidgetTester tester) async {
      // TODO: Yeni kullanıcı ile onboarding ekranlarını tamamla, ana sayfaya geçişi kontrol et
    });
  });
}