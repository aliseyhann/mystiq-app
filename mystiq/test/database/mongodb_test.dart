import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:mystiq_fortune_app/database/mongodb.dart';

@GenerateMocks([Db])
import 'mongodb_test.mocks.dart';

void main() {
  late MockDb mockDb;

  setUp(() {
    mockDb = MockDb();
  });

  group('MongoDatabase', () {
    test('connect should establish connection successfully', () async {
      // Arrange
      when(mockDb.open()).thenAnswer((_) async => null);
      when(mockDb.serverStatus()).thenAnswer((_) async => {'ok': 1});

      // Act
      await MongoDatabase.connect(db: mockDb);

      // Assert
      verify(mockDb.open()).called(1);
      verify(mockDb.serverStatus()).called(1);
    });

    test('connect should handle connection errors', () async {
      // Arrange
      when(mockDb.open()).thenThrow(Exception('Connection failed'));

      // Act & Assert
      expect(() => MongoDatabase.connect(db: mockDb), throwsException);
    });
  });
} 