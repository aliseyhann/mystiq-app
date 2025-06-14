import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mystiq_fortune_app/home_page.dart';
import 'package:mystiq_fortune_app/homepage_routing/login_page.dart';
import 'package:mystiq_fortune_app/homepage_routing/register_page.dart';

void main() {
  group('HomePage Widget Tests', () {
    testWidgets('HomePage should create state correctly', (WidgetTester tester) async {
      // HomePage widget'ını oluştur
      await tester.pumpWidget(const MaterialApp(home: HomePage()));

      // HomePage'in state'ini kontrol et
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('HomePage should display login and register buttons', (WidgetTester tester) async {
      // HomePage widget'ını oluştur
      await tester.pumpWidget(const MaterialApp(home: HomePage()));

      // Login ve Register butonlarının varlığını kontrol et
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
    });

    testWidgets('HomePage should navigate to login page when login button is pressed', (WidgetTester tester) async {
      // HomePage widget'ını oluştur
      await tester.pumpWidget(const MaterialApp(home: HomePage()));

      // Login butonuna tıkla
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Login sayfasına yönlendirildiğini kontrol et
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('HomePage should navigate to register page when register button is pressed', (WidgetTester tester) async {
      // HomePage widget'ını oluştur
      await tester.pumpWidget(const MaterialApp(home: HomePage()));

      // Register butonuna tıkla
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      // Register sayfasına yönlendirildiğini kontrol et
      expect(find.byType(RegisterPage), findsOneWidget);
    });
  });
} 