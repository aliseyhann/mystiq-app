import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mystiq_fortune_app/pages/horoscopes_page.dart';

void main() {
  testWidgets('HoroscopePage renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: HoroscopePage(),
    ));
    expect(find.text('Daily Horoscope'), findsOneWidget);
  });
} 