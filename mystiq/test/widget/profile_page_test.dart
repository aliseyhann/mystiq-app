import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:mystiq_fortune_app/pages/profile_page.dart';
import 'package:mystiq_fortune_app/backend/notification_service.dart';

@GenerateMocks([NotificationService])
import 'profile_page_test.mocks.dart';

void main() {
  late MockNotificationService mockNotificationService;

  setUp(() {
    mockNotificationService = MockNotificationService();
    when(mockNotificationService.getNotificationsEnabled())
        .thenAnswer((_) async => true);
  });

  testWidgets('ProfilePage renders correctly', (WidgetTester tester) async {
    final mockData = {
      'name': 'Test User',
      'email': 'test@example.com',
      'birth-date': DateTime.now().toIso8601String(),
      'birth-time': '12:00',
      'gender': 'Man',
      'marital-status': 'Single',
    };

    await tester.pumpWidget(MaterialApp(
      home: ProfilePage(
        email: 'test@example.com',
        enableDatabase: false,
        mockData: mockData,
        notificationService: mockNotificationService,
      ),
    ));

    // Widget'ın yüklenmesini bekle
    await tester.pumpAndSettle();

    // Scaffold widget'ının varlığını kontrol et
    expect(find.byType(Scaffold), findsOneWidget);
  });
} 