import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mystiq_fortune_app/backend/notification_service.dart';

@GenerateMocks([
  FlutterLocalNotificationsPlugin,
  SharedPreferences,
])
import 'notification_service_test.mocks.dart';

void main() {
  late MockFlutterLocalNotificationsPlugin mockNotifications;
  late MockSharedPreferences mockPrefs;
  late NotificationService notificationService;

  setUp(() {
    mockNotifications = MockFlutterLocalNotificationsPlugin();
    mockPrefs = MockSharedPreferences();
    notificationService = NotificationService(
      notifications: mockNotifications,
      prefs: mockPrefs,
    );
  });

  group('NotificationService Tests', () {
    test('initialize should set up notifications correctly', () async {
      // Arrange
      const userEmail = 'test@example.com';
      when(mockNotifications.initialize(
        any,
        onDidReceiveNotificationResponse: anyNamed('onDidReceiveNotificationResponse'),
      )).thenAnswer((_) async => true);

      // Act
      await notificationService.initialize(userEmail);

      // Assert
      verify(mockNotifications.initialize(
        any,
        onDidReceiveNotificationResponse: anyNamed('onDidReceiveNotificationResponse'),
      )).called(1);
    });

    test('sendNotification should send notification when enabled', () async {
      // Arrange
      const userId = 'test@example.com';
      const title = 'Test Title';
      const message = 'Test Message';

      when(mockPrefs.getBool('notifications_enabled')).thenReturn(true);
      when(mockNotifications.show(
        any,
        title,
        message,
        any,
        payload: userId,
      )).thenAnswer((_) async => true);

      // Act
      await notificationService.sendNotification(
        userId: userId,
        title: title,
        message: message,
      );

      // Assert
      verify(mockNotifications.show(
        any,
        title,
        message,
        any,
        payload: userId,
      )).called(1);
    });

    test('sendNotification should not send notification when disabled', () async {
      // Arrange
      const userId = 'test@example.com';
      const title = 'Test Title';
      const message = 'Test Message';

      when(mockPrefs.getBool('notifications_enabled')).thenReturn(false);

      // Act
      await notificationService.sendNotification(
        userId: userId,
        title: title,
        message: message,
      );

      // Assert
      verifyNever(mockNotifications.show(
        any,
        any,
        any,
        any,
        payload: any,
      ));
    });

    test('setNotificationsEnabled should update preferences', () async {
      // Arrange
      const enabled = true;
      when(mockPrefs.setBool('notifications_enabled', enabled))
          .thenAnswer((_) async => true);

      // Act
      await notificationService.setNotificationsEnabled(enabled);

      // Assert
      verify(mockPrefs.setBool('notifications_enabled', enabled)).called(1);
    });

    test('getNotificationsEnabled should return correct value', () async {
      // Arrange
      const enabled = true;
      when(mockPrefs.getBool('notifications_enabled')).thenReturn(enabled);

      // Act
      final result = await notificationService.getNotificationsEnabled();

      // Assert
      expect(result, equals(enabled));
    });
  });
} 