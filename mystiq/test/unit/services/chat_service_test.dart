import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:mystiq_fortune_app/backend/chat_service.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:dart_amqp/dart_amqp.dart';

@GenerateMocks([
  Db,
  DbCollection,
  Client,
  Channel,
  Exchange,
  Queue,
  Consumer,
  WriteResult,
])
import 'chat_service_test.mocks.dart';

void main() {
  late ChatService chatService;
  late MockDb mockDb;
  late MockDbCollection mockCollection;
  late MockClient mockClient;
  late MockChannel mockChannel;
  late MockExchange mockExchange;
  late MockQueue mockQueue;
  late MockConsumer mockConsumer;
  late MockWriteResult mockWriteResult;

  setUp(() {
    mockDb = MockDb();
    mockCollection = MockDbCollection();
    mockClient = MockClient();
    mockChannel = MockChannel();
    mockExchange = MockExchange();
    mockQueue = MockQueue();
    mockConsumer = MockConsumer();
    mockWriteResult = MockWriteResult();
    
    when(mockConsumer.cancel()).thenAnswer((_) async => mockConsumer);
    when(mockChannel.exchange(any, any, durable: anyNamed('durable')))
        .thenAnswer((_) async => mockExchange);
    when(mockChannel.queue(any, durable: anyNamed('durable')))
        .thenAnswer((_) async => mockQueue);
    when(mockQueue.bind(any, any)).thenAnswer((_) async => mockQueue);
    when(mockCollection.insert(any)).thenAnswer((_) async => {'_id': '123'});
    when(mockDb.isConnected).thenReturn(true);
    when(mockChannel.close()).thenAnswer((_) async => mockChannel);
    
    chatService = ChatService(
      db: mockDb,
      messagesCollection: mockCollection,
      client: mockClient,
      channel: mockChannel,
      consumer: mockConsumer,
    );
  });

  group('ChatService', () {
    test('initialize should throw when db is not connected', () async {
      when(mockDb.isConnected).thenReturn(false);
      
      expect(
        () async => await chatService.initialize(),
        throwsA(isA<Exception>()),
      );
    });

    test('initialize should throw when client is null', () async {
      when(mockDb.isConnected).thenReturn(true);
      
      chatService = ChatService(
        db: mockDb,
        messagesCollection: mockCollection,
        client: null,
        channel: mockChannel,
        consumer: mockConsumer,
      );

      expect(
        () async => await chatService.initialize(),
        throwsA(isA<Exception>()),
      );
    });

    test('sendMessage should throw when messagesCollection is null', () async {
      chatService = ChatService(
        db: mockDb,
        messagesCollection: null,
        client: mockClient,
        channel: mockChannel,
        consumer: mockConsumer,
      );

      expect(
        () async => await chatService.sendMessage(
          senderEmail: 'a@a.com',
          recipientEmail: 'b@b.com',
          message: 'Merhaba',
          senderName: 'Ali',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('getChatHistory should call find and remove on collection', () async {
      // Arrange
      final mockMessage = {
        'senderEmail': 'a@a.com',
        'recipientEmail': 'b@b.com',
        'timestamp': DateTime.now().toIso8601String(),
        'expiresAt': DateTime.now().toIso8601String(),
      };

      when(mockCollection.remove(any)).thenAnswer((_) async => Future.value({}));
      when(mockCollection.find(any)).thenAnswer((_) => Stream.value(mockMessage));

      // Act
      final result = await chatService.getChatHistory('a@a.com');

      // Assert
      expect(result, isA<List<Map<String, dynamic>>>());
      verify(mockCollection.remove(any)).called(1);
      verify(mockCollection.find(any)).called(1);
    });

    test('markMessageAsDelivered should call updateOne', () async {
      // Arrange
      final fakeWriteResult = MockWriteResult();
      when(mockCollection.updateOne(any, any)).thenAnswer((_) async => fakeWriteResult);

      // Act
      await chatService.markMessageAsDelivered('507f1f77bcf86cd799439011');

      // Assert
      verify(mockCollection.updateOne(any, any)).called(1);
    });

    test('markMessageAsRead should call updateOne', () async {
      // Arrange
      final fakeWriteResult = MockWriteResult();
      when(mockCollection.updateOne(any, any)).thenAnswer((_) async => fakeWriteResult);

      // Act
      await chatService.markMessageAsRead('507f1f77bcf86cd799439011');

      // Assert
      verify(mockCollection.updateOne(any, any)).called(1);
    });
  });

  group('ChatService RabbitMQ Tests', () {
    test('sendMessage should publish message to RabbitMQ when channel exists', () async {
      // Arrange
      final messageData = {
        'senderEmail': 'test@example.com',
        'recipientEmail': 'recipient@example.com',
        'message': 'Test message',
        'timestamp': DateTime.now(),
        'expiresAt': DateTime.now().add(const Duration(days: 1)),
      };

      // Act
      await chatService.sendMessage(
        senderEmail: messageData['senderEmail'] as String,
        recipientEmail: messageData['recipientEmail'] as String,
        message: messageData['message'] as String,
        senderName: 'Test User',
      );

      // Assert
      verify(mockChannel.exchange('chat', ExchangeType.DIRECT, durable: false)).called(1);
      verify(mockChannel.queue('chat.${messageData['recipientEmail']}', durable: false)).called(1);
      verify(mockQueue.bind(any, 'chat.${messageData['recipientEmail']}')).called(1);
      verify(mockExchange.publish(any, 'chat.${messageData['recipientEmail']}')).called(1);
      verify(mockCollection.insert(any)).called(1);
    });

    test('sendMessage should handle RabbitMQ errors and attempt reconnect', () async {
      // Arrange
      when(mockChannel.exchange(any, any, durable: anyNamed('durable')))
          .thenThrow(Exception('RabbitMQ error'));

      final messageData = {
        'senderEmail': 'test@example.com',
        'recipientEmail': 'recipient@example.com',
        'message': 'Test message',
        'timestamp': DateTime.now(),
        'expiresAt': DateTime.now().add(const Duration(days: 1)),
      };

      // Act & Assert
      await expectLater(
        () => chatService.sendMessage(
          senderEmail: messageData['senderEmail'] as String,
          recipientEmail: messageData['recipientEmail'] as String,
          message: messageData['message'] as String,
          senderName: 'Test User',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('sendMessage should handle null channel gracefully', () async {
      // Arrange
      chatService = ChatService(
        db: mockDb,
        messagesCollection: mockCollection,
        client: mockClient,
        channel: null,
        consumer: mockConsumer,
      );

      final messageData = {
        'senderEmail': 'test@example.com',
        'recipientEmail': 'recipient@example.com',
        'message': 'Test message',
        'timestamp': DateTime.now(),
        'expiresAt': DateTime.now().add(const Duration(days: 1)),
      };

      // Act & Assert
      await expectLater(
        () => chatService.sendMessage(
          senderEmail: messageData['senderEmail'] as String,
          recipientEmail: messageData['recipientEmail'] as String,
          message: messageData['message'] as String,
          senderName: 'Test User',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
} 