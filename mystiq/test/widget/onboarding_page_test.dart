import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mystiq_fortune_app/onboarding_screen/onboarding_page.dart';

void main() {
  testWidgets('Onboarding sayfası doğru şekilde yükleniyor', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingPage(email: 'test@example.com', skipDbInit: true),
      ),
    );

    // İlk sayfanın başlığını kontrol et
    expect(find.text('Welcome Fortuner'), findsOneWidget);
    expect(find.text('Enter Your Name'), findsOneWidget);
  });

  testWidgets('İsim girişi doğru çalışıyor', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingPage(email: 'test@example.com', skipDbInit: true),
      ),
    );

    // İsim girişi
    await tester.enterText(find.byType(TextField), 'Test Kullanıcı');
    await tester.pump();

    // Next butonuna tıkla
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Doğum tarihi sayfasına geçtiğini kontrol et
    expect(find.text('Horoscope'), findsOneWidget);
  });

  testWidgets('Doğum tarihi seçimi doğru çalışıyor', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingPage(email: 'test@example.com', skipDbInit: true),
      ),
    );

    // İlk sayfayı geç
    await tester.enterText(find.byType(TextField), 'Test Kullanıcı');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Doğum tarihi butonuna tıkla
    await tester.tap(find.text('Birth Date'));
    await tester.pumpAndSettle();

    // Date picker'ın açıldığını kontrol et
    expect(find.byType(DatePickerDialog), findsOneWidget);
  });

  testWidgets('Cinsiyet seçimi doğru çalışıyor', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingPage(email: 'test@example.com', skipDbInit: true),
      ),
    );

    // İlk sayfayı geç
    await tester.enterText(find.byType(TextField), 'Test Kullanıcı');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Doğum tarihi sayfasını geç
    await tester.tap(find.text('Birth Date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Doğum saati sayfasını geç
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Cinsiyet seçimini kontrol et
    expect(find.text('Gender'), findsOneWidget);
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    expect(find.text('Man'), findsOneWidget);
    expect(find.text('Women'), findsOneWidget);
  });

  testWidgets('Medeni durum seçimi doğru çalışıyor', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingPage(email: 'test@example.com', skipDbInit: true),
      ),
    );

    // İlk sayfayı geç
    await tester.enterText(find.byType(TextField), 'Test Kullanıcı');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Diğer sayfaları geç
    for (int i = 0; i < 3; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }

    // Medeni durum seçimini kontrol et
    expect(find.text('Relationship Status'), findsOneWidget);
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    expect(find.text('Single'), findsOneWidget);
    expect(find.text('Married'), findsOneWidget);
  });
} 