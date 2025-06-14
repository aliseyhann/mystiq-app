import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dart_amqp/dart_amqp.dart';
import 'package:mystiq_fortune_app/backend/rabbitmq_service.dart';

@GenerateMocks([Client, Channel, Consumer, Queue])
import 'rabbitmq_service_test.mocks.dart';

void main() {
  late MockClient mockClient;
  late MockChannel mockChannel;
  late MockConsumer mockConsumer;
  late MockQueue mockQueue;

  setUp(() {
    mockClient = MockClient();
    mockChannel = MockChannel();
    mockConsumer = MockConsumer();
    mockQueue = MockQueue();
  });

  group('RabbitMQService', () {
    test('listenForResetRequests should handle messages correctly', () async {
      // Arrange
      when(mockClient.channel()).thenAnswer((_) async => mockChannel);
      when(mockChannel.queue('reset_queue', durable: true)).thenAnswer((_) async => mockQueue);
      when(mockQueue.consume()).thenAnswer((_) async => mockConsumer);

      // Act
      await listenForResetRequests(client: mockClient);

      // Assert
      verify(mockClient.channel()).called(1);
      verify(mockChannel.queue('reset_queue', durable: true)).called(1);
      verify(mockQueue.consume()).called(1);
    });
  });
} 