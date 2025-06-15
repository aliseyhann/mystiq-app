import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mystiq_fortune_app/pages/profile/fortune_teller_profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'fortune_teller_profile_page_test.mocks.dart';

@GenerateMocks([SharedPreferences])
void main() {
  late MockSharedPreferences mockPrefs;

  setUp(() {
    mockPrefs = MockSharedPreferences();
  });

  testWidgets('Fortune teller profile sayfası doğru şekilde yükleniyor', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FortuneTellerProfilePage(email: 'test@example.com'),
      ),
    );

    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('Kullanıcı adı düzenleme dialogu açılıyor', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FortuneTellerProfilePage(email: 'test@example.com'),
      ),
    );

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.text('Edit name'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('Çıkış yapma dialogu açılıyor', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FortuneTellerProfilePage(email: 'test@example.com'),
      ),
    );

    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    expect(find.text('Are you sure you want to logout?'), findsOneWidget);
  });
} 