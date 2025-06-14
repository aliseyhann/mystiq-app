import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mystiq_fortune_app/pages/compatibility_page.dart';

void main() {
  testWidgets('CompatibilityPage renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: CompatibilityPage(),
    ));
    expect(find.text('Zodiac Compatibility'), findsOneWidget);
  });
} 