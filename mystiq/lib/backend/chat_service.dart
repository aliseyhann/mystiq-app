import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:mystiq_fortune_app/database/constant.dart';
import 'package:dart_amqp/dart_amqp.dart';
import 'dart:io';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  mongo.Db? _db;
  mongo.DbCollection? _messagesCollection;
  Client? _client;
  Channel? _channel;
  Consumer? _consumer;
  
  Future<void> initialize() async {
    try {
      if (_db == null || !_db!.isConnected) {
        _db = await mongo.Db.create(MONGO_URL);
        await _db!.open();
        _messagesCollection = _db!.collection('chat_messages');
      }
      
      if (_client == null) {
        _client = Client(
          settings: ConnectionSettings(
            host: Platform.isAndroid ? '10.0.2.2' : 'localhost',
            port: 5672,
            virtualHost: '/',
            authProvider: const PlainAuthenticator('guest', 'guest'),
          ),
        );
        
        _channel = await _client!.channel();
      }
    } catch (e) {
      print('Chat servisi başlatma hatası: $e');
      await dispose();
      rethrow;
    }
  }

  Future<void> sendMessage({
    required String senderEmail,
    required String recipientEmail,
    required String message,
    required String senderName,
  }) async {
    try {
      final messageData = {
        'senderEmail': senderEmail,
        'recipientEmail': recipientEmail,
        'message': message,
        'senderName': senderName,
        'timestamp': DateTime.now(),
        'isDelivered': false,
        'isRead': false,
        'expiresAt': DateTime.now().add(const Duration(hours: 24)),
      };
      
      await _messagesCollection?.insert(messageData);

      if (_channel != null) {
        try {
          final exchange = await _channel!.exchange(
            'chat',
            ExchangeType.DIRECT,
            durable: false,
          );

          final queueName = 'chat.$recipientEmail';
          final queue = await _channel!.queue(
            queueName,
            durable: false,
          );

          await queue.bind(exchange, queueName);
          
          final timestamp = messageData['timestamp'] as DateTime;
          final expiresAt = messageData['expiresAt'] as DateTime;
          final rabbitMessage = {
            ...messageData,
            'timestamp': timestamp.toIso8601String(),
            'expiresAt': expiresAt.toIso8601String(),
          };
          
          exchange.publish(
            json.encode(rabbitMessage),
            queueName,
          );
        } catch (e) {
          print('RabbitMQ mesaj gönderme hatası: $e');
          await _reconnect();
        }
      }
    } catch (e) {
      print('Mesaj gönderme hatası: $e');
      rethrow;
    }
  }

  Future<void> _reconnect() async {
    try {
      await dispose();
      await initialize();
    } catch (e) {
      print('Yeniden bağlanma hatası: $e');
    }
  }

  Future<void> listenToMessages(
    String userEmail,
    Function(Map<String, dynamic>) onMessageReceived,
  ) async {
    try {
      if (_channel != null) {
        try {
          final exchange = await _channel!.exchange(
            'chat',
            ExchangeType.DIRECT,
            durable: false,
          );

          final queueName = 'chat.$userEmail';
          final queue = await _channel!.queue(
            queueName,
            durable: false,
          );

          await queue.bind(exchange, queueName);
          
          if (_consumer != null) {
            await _consumer!.cancel();
            _consumer = null;
          }
          
          _consumer = await queue.consume();
          _consumer?.listen(
            (message) {
              try {
                final rawData = json.decode(message.payloadAsString) as Map<String, dynamic>;
                final messageData = {
                  ...rawData,
                  'timestamp': DateTime.parse(rawData['timestamp'] as String),
                  'expiresAt': DateTime.parse(rawData['expiresAt'] as String),
                };
                onMessageReceived(messageData);
                message.ack();
              } catch (e) {
                print('Mesaj işleme hatası: $e');
                message.reject(false);
              }
            },
            onError: (error) async {
              print('Mesaj dinleme hatası: $error');
              await _reconnect();
            },
          );
        } catch (e) {
          print('RabbitMQ dinleme hatası: $e');
          await _reconnect();
        }
      }
    } catch (e) {
      print('Mesaj dinleme hatası: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getChatHistory(String userEmail) async {
    try {
      final now = DateTime.now();
      
      // 24 saatten eski mesajları sil
      await _messagesCollection?.remove(
        mongo.where.lt('expiresAt', now),
      );
      
      // Kullanıcının mesajlarını getir
      final messages = await _messagesCollection?.find(
        {
          r'$or': [
            {'senderEmail': userEmail},
            {'recipientEmail': userEmail},
          ],
        },
      ).toList();

      // MongoDB'den gelen tarihleri DateTime'a çevir
      return List<Map<String, dynamic>>.from(messages ?? []).map((msg) {
        if (msg['timestamp'] is String) {
          msg['timestamp'] = DateTime.parse(msg['timestamp'] as String);
        }
        if (msg['expiresAt'] is String) {
          msg['expiresAt'] = DateTime.parse(msg['expiresAt'] as String);
        }
        return msg;
      }).toList();
    } catch (e) {
      print('Sohbet geçmişi getirme hatası: $e');
      return [];
    }
  }

  Future<void> markMessageAsDelivered(String messageId) async {
    try {
      await _messagesCollection?.updateOne(
        mongo.where.eq('_id', mongo.ObjectId.parse(messageId)),
        mongo.modify.set('isDelivered', true),
      );
    } catch (e) {
      print('Mesaj iletildi işaretleme hatası: $e');
    }
  }

  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _messagesCollection?.updateOne(
        mongo.where.eq('_id', mongo.ObjectId.parse(messageId)),
        mongo.modify.set('isRead', true),
      );
    } catch (e) {
      print('Mesaj okundu işaretleme hatası: $e');
    }
  }

  Future<void> dispose() async {
    try {
      if (_consumer != null) {
        await _consumer?.cancel();
        _consumer = null;
      }
      
      if (_channel != null) {
        await _channel?.close();
        _channel = null;
      }
      
      if (_client != null) {
        await _client?.close();
        _client = null;
      }
      
      if (_db != null && _db!.isConnected) {
        await _db?.close();
        _db = null;
      }
    } catch (e) {
      print('Chat servisi kapatma hatası: $e');
    }
  }
} 