import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mystiq_fortune_app/backend/session_service.dart';

@GenerateMocks([SharedPreferences])
import 'session_service_test.mocks.dart';

void main() {
  late MockSharedPreferences mockPrefs;
  late SessionService sessionService;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    sessionService = SessionService(mockPrefs);
  });

  group('SessionService Tests', () {
    test('saveSession should save user session data correctly', () async {
      // Arrange
      const email = 'test@example.com';
      const role = 'user';

      when(mockPrefs.setString('user_email', email))
          .thenAnswer((_) async => true);
      when(mockPrefs.setString('user_role', role))
          .thenAnswer((_) async => true);
      when(mockPrefs.setInt('last_login', any))
          .thenAnswer((_) async => true);

      // Act
      await sessionService.saveSession(email, role);

      // Assert
      verify(mockPrefs.setString('user_email', email)).called(1);
      verify(mockPrefs.setString('user_role', role)).called(1);
      verify(mockPrefs.setInt('last_login', any)).called(1);
    });

    test('getSession should return session data when session is valid', () async {
      // Arrange
      const email = 'test@example.com';
      const role = 'user';
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      when(mockPrefs.getString('user_email')).thenReturn(email);
      when(mockPrefs.getString('user_role')).thenReturn(role);
      when(mockPrefs.getInt('last_login')).thenReturn(currentTime);
      when(mockPrefs.setInt('last_login', any)).thenAnswer((_) async => true);

      // Act
      final result = await sessionService.getSession();

      // Assert
      expect(result['email'], equals(email));
      expect(result['role'], equals(role));
    });

    test('getSession should clear session when session is expired', () async {
      // Arrange
      const email = 'test@example.com';
      const role = 'user';
      final expiredTime = DateTime.now()
          .subtract(Duration(minutes: SessionService.sessionDurationMinutes + 1))
          .millisecondsSinceEpoch;

      when(mockPrefs.getString('user_email')).thenReturn(email);
      when(mockPrefs.getString('user_role')).thenReturn(role);
      when(mockPrefs.getInt('last_login')).thenReturn(expiredTime);
      when(mockPrefs.remove('user_email')).thenAnswer((_) async => true);
      when(mockPrefs.remove('user_role')).thenAnswer((_) async => true);
      when(mockPrefs.remove('last_login')).thenAnswer((_) async => true);

      // Act
      final result = await sessionService.getSession();

      // Assert
      expect(result['email'], isNull);
      expect(result['role'], isNull);
      verify(mockPrefs.remove('user_email')).called(1);
      verify(mockPrefs.remove('user_role')).called(1);
      verify(mockPrefs.remove('last_login')).called(1);
    });

    test('clearSession should remove all session data', () async {
      // Arrange
      when(mockPrefs.remove('user_email')).thenAnswer((_) async => true);
      when(mockPrefs.remove('user_role')).thenAnswer((_) async => true);
      when(mockPrefs.remove('last_login')).thenAnswer((_) async => true);

      // Act
      await sessionService.clearSession();

      // Assert
      verify(mockPrefs.remove('user_email')).called(1);
      verify(mockPrefs.remove('user_role')).called(1);
      verify(mockPrefs.remove('last_login')).called(1);
    });
  });
} 