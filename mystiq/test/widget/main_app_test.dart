import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mystiq_fortune_app/main.dart';
import 'package:mystiq_fortune_app/home_page.dart';
import 'package:mystiq_fortune_app/pages/MainPage/main_page_fortune_teller.dart';
import 'package:mystiq_fortune_app/pages/MainPage/main_page_normal_user.dart';
import 'package:mystiq_fortune_app/backend/session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeSessionService extends SessionService {
  final Map<String, String?>? fakeSession;
  FakeSessionService(this.fakeSession)
      : super(FakeSharedPreferences());

  @override
  Future<Map<String, String?>> getSession() async {
    await Future.delayed(const Duration(milliseconds: 10));
    return fakeSession ?? {};
  }
}

// Sahte SharedPreferences
class FakeSharedPreferences implements SharedPreferences {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('MyApp Widget Tests', () {
    testWidgets('Oturum yoksa HomePage render edilir', (WidgetTester tester) async {
      await tester.pumpWidget(
        MyApp(sessionService: FakeSessionService({}))
      );
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('Oturum varsa ve rol Regular User ise MainPageNormalUser render edilir', (WidgetTester tester) async {
      await tester.pumpWidget(
        MyApp(sessionService: FakeSessionService({
          'email': 'test@example.com',
          'role': 'Regular User',
          'name': 'Test User',
        }))
      );
      await tester.pumpAndSettle();
      expect(find.byType(MainPageNormalUser), findsOneWidget);
    });

    testWidgets('Oturum varsa ve rol Fortune Teller ise MainPageFortuneTeller render edilir', (WidgetTester tester) async {
      await tester.pumpWidget(
        MyApp(sessionService: FakeSessionService({
          'email': 'test@example.com',
          'role': 'Fortune Teller',
          'name': 'Test Falcı',
        }))
      );
      await tester.pumpAndSettle();
      expect(find.byType(MainPageFortuneTeller), findsOneWidget);
    });

    testWidgets('Yüklenme sırasında progress indicator gösterilir', (WidgetTester tester) async {
      // getSession gecikmeli dönecek
      final sessionService = FakeSessionService(null);
      await tester.pumpWidget(MyApp(sessionService: sessionService));
      // İlk pump'ta FutureBuilder beklemede olacak
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}