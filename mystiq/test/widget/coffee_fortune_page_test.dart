import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:mystiq_fortune_app/pages/coffee_fortune_page.dart';
import 'package:mystiq_fortune_app/backend/chat_service.dart';

@GenerateMocks([ChatService])
import 'coffee_fortune_page_test.mocks.dart';

void main() {
  late MockChatService mockChatService;

  setUp(() {
    mockChatService = MockChatService();
    when(mockChatService.initialize()).thenAnswer((_) async => null);
    when(mockChatService.getChatHistory(any)).thenAnswer((_) async => []);
  });

  testWidgets('CoffeeFortunePage renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CoffeeFortunePage(
          email: 'test@example.com',
          chatService: mockChatService,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Scaffold), findsOneWidget);
  });
} 