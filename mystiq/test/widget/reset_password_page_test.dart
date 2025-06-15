import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mystiq_fortune_app/homepage_routing/reset_password_page.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester, {String email = 'test@example.com', String resetCode = '1234'}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ResetPasswordPage(email: email, resetCode: resetCode),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Tüm alanlar boşsa uyarı gösterir', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('Şifreyi Güncelle'));
    await tester.pump();
    expect(find.text('Lütfen tüm alanları doldurun!'), findsOneWidget);
  });

  testWidgets('Yanlış kod girilirse uyarı gösterir', (tester) async {
    await pumpPage(tester);
    await tester.enterText(find.byType(TextField).at(0), '0000');
    await tester.enterText(find.byType(TextField).at(1), 'pass1');
    await tester.enterText(find.byType(TextField).at(2), 'pass1');
    await tester.tap(find.text('Şifreyi Güncelle'));
    await tester.pump();
    expect(find.text('Geçersiz sıfırlama kodu!'), findsOneWidget);
  });

  testWidgets('Şifreler eşleşmiyorsa uyarı gösterir', (tester) async {
    await pumpPage(tester);
    await tester.enterText(find.byType(TextField).at(0), '1234');
    await tester.enterText(find.byType(TextField).at(1), 'pass1');
    await tester.enterText(find.byType(TextField).at(2), 'pass2');
    await tester.tap(find.text('Şifreyi Güncelle'));
    await tester.pump();
    expect(find.text('Şifreler eşleşmiyor!'), findsOneWidget);
  });

  // Aşağıdaki testler için widget'ın dependency injection ile mock'lanabilir hale getirilmesi gerekir.
  // testWidgets('Şifre başarıyla güncellenirse başarı mesajı ve pop', (tester) async { ... });
  // testWidgets('Şifre güncellenemezse hata mesajı gösterir', (tester) async { ... });
  // testWidgets('MongoDB exception fırlatırsa genel hata mesajı gösterir', (tester) async { ... });
} 