import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mystiq_fortune_app/pages/MainPage/main_page_normal_user.dart';

void main() {
  testWidgets('MainPageNormalUser renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: MainPageNormalUser(email: 'test@example.com', name: 'Test User', enableTimer: false),
    ));
    expect(find.byKey(const Key('mainPageNormalUserScaffold')), findsOneWidget);
  });
} 