import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mystiq_fortune_app/pages/homepage.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

@GenerateMocks([mongo.Db, mongo.DbCollection])
import 'home_page_test.mocks.dart';

void main() {
  late MockDb mockDb;
  late MockDbCollection mockUsersCollection;
  late MockDbCollection mockFortuneRequestsCollection;

  setUp(() {
    mockDb = MockDb();
    mockUsersCollection = MockDbCollection();
    mockFortuneRequestsCollection = MockDbCollection();

    when(mockDb.collection('users')).thenReturn(mockUsersCollection);
    when(mockDb.collection('fortune_requests')).thenReturn(mockFortuneRequestsCollection);
  });

  testWidgets('HomePage renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          email: 'test@example.com',
          name: 'Test User',
          db: mockDb,
          usersCollection: mockUsersCollection,
          fortuneRequestsCollection: mockFortuneRequestsCollection,
        ),
      ),
    );

    // Widget'ın yüklenmesini bekle
    await tester.pumpAndSettle();

    // Scaffold widget'ının varlığını kontrol et
    expect(find.byType(Scaffold), findsOneWidget);
  });
} 