import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:mystiq_fortune_app/pages/chat/chat_page.dart';
import 'package:mystiq_fortune_app/backend/chat_service.dart';

@GenerateMocks([ChatService])
import 'chat_page_test.mocks.dart';

void main() {
  late MockChatService mockChatService;

  setUp(() {
    mockChatService = MockChatService();
    when(mockChatService.initialize()).thenAnswer((_) async => null);
    when(mockChatService.getChatHistory(any)).thenAnswer((_) async => []);
  });

  testWidgets('ChatPage renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChatPage(
          currentUserEmail: 'test@example.com',
          currentUserName: 'Test User',
          recipientEmail: 'other@example.com',
          recipientName: 'Other User',
          chatService: mockChatService,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
  });
} 