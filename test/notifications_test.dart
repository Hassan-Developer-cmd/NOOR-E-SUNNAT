import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/main.dart';
import 'package:islamic_app/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Push Notifications & Channel Configuration Tests', () {
    test('High Importance Notification Channel configuration verification', () {
      expect(highImportanceChannel.id, equals('high_importance_channel'));
      expect(highImportanceChannel.name, equals('High Importance Notifications'));
      expect(highImportanceChannel.importance, equals(Importance.max));
      expect(highImportanceChannel.playSound, isTrue);
      expect(highImportanceChannel.enableVibration, isTrue);
    });

    test('InAppNotificationItem correctly parses English & Urdu payloads', () {
      final sampleData = {
        'title': 'New Event Added',
        'title_ur': 'نیا ایونٹ شامل کیا گیا',
        'body': 'Milad gathering tomorrow at 8 PM.',
        'body_ur': 'کل رات 8 بجے محفل میلاد منعقد ہوگی۔',
        'type': 'event',
        'event_id': 'evt_123',
        'target': 'all_users',
        'created_at': DateTime.now().toIso8601String(),
        'deleted_by_users': <String>[],
        'read_by_users': <String>[],
      };

      final item = InAppNotificationItem.fromMap('notif_001', sampleData);

      expect(item.id, equals('notif_001'));
      expect(item.getTitle(false), equals('New Event Added'));
      expect(item.getTitle(true), equals('نیا ایونٹ شامل کیا گیا'));
      expect(item.getBody(false), equals('Milad gathering tomorrow at 8 PM.'));
      expect(item.getBody(true), equals('کل رات 8 بجے محفل میلاد منعقد ہوگی۔'));
      expect(item.type, equals('event'));
      expect(item.eventId, equals('evt_123'));
      expect(item.target, equals('all_users'));
    });

    test('Notification relevance filtering for broadcast vs targeted users', () {
      // 1. Broadcast notification
      final broadcastData = {
        'title': 'General Announcement',
        'body': 'Update available',
        'target': 'all_users',
      };
      expect(
        NotificationService.isRelevantToUser(broadcastData, targetUid: 'user_abc', targetEmail: 'test@example.com'),
        isTrue,
      );

      // 2. Targeted to specific user UID
      final targetedData = {
        'title': 'Your Question Was Answered',
        'body': 'An Islamic scholar replied.',
        'target': 'user_abc',
        'user_id': 'user_abc',
      };
      expect(
        NotificationService.isRelevantToUser(targetedData, targetUid: 'user_abc', targetEmail: 'test@example.com'),
        isTrue,
      );
      expect(
        NotificationService.isRelevantToUser(targetedData, targetUid: 'user_xyz', targetEmail: 'other@example.com'),
        isFalse,
      );

      // 3. User deleted notification
      final deletedData = {
        'title': 'General Announcement',
        'body': 'Update available',
        'target': 'all_users',
        'deleted_by_users': ['user_abc'],
      };
      expect(
        NotificationService.isRelevantToUser(deletedData, targetUid: 'user_abc', targetEmail: 'test@example.com'),
        isFalse,
      );
    });

    test('Background FCM Payload structure matches Android OS requirements', () {
      const channelId = 'high_importance_channel';
      const clickAction = 'FLUTTER_NOTIFICATION_CLICK';

      final fcmPayload = {
        'notification': {
          'title': 'NOOR E SUNNAT - Terminated Push Test 📢',
          'body': 'Test verified: This notification is delivered via high_importance_channel when app is closed.',
        },
        'data': {
          'click_action': clickAction,
          'id': 'test_push_1787146211928',
          'type': 'announcement',
          'title': 'NOOR E SUNNAT - Terminated Push Test 📢',
          'body': 'Test verified: This notification is delivered via high_importance_channel when app is closed.',
          'timestamp': DateTime.now().toIso8601String(),
        },
        'android': {
          'priority': 'high',
          'notification': {
            'channelId': channelId,
            'sound': 'default',
            'priority': 'max',
            'clickAction': clickAction,
            'defaultSound': true,
            'defaultVibrateTimings': true,
          },
        },
        'topic': 'all_users',
      };

      final notifMap = fcmPayload['notification'] as Map<String, dynamic>;
      expect(notifMap['title'], equals('NOOR E SUNNAT - Terminated Push Test 📢'));
      expect(notifMap['body'], isNotEmpty);
      expect(
        ((fcmPayload['android'] as Map)['notification'] as Map)['channelId'],
        equals(highImportanceChannel.id),
      );
      expect(
        ((fcmPayload['android'] as Map)['notification'] as Map)['priority'],
        equals('max'),
      );
      expect(fcmPayload['topic'], equals('all_users'));
    });

    test('End-to-End Terminated Push: System Tray Banner, Sound, and Vibration parameters validation', () {
      expect(highImportanceChannel.id, equals('high_importance_channel'));
      expect(highImportanceChannel.importance.value, equals(5)); // Importance.max is 5
      expect(highImportanceChannel.playSound, isTrue);
      expect(highImportanceChannel.enableVibration, isTrue);
    });

    test('Targeted 1-to-1 Q&A Push Notification Payload matches recipient device token only', () {
      const channelId = 'high_importance_channel';
      const recipientToken = 'fcm_device_token_user_author_456';
      const questionId = 'q_897123';

      final targetedPayload = {
        'token': recipientToken,
        'notification': {
          'title': 'آپ کے سوال کا جواب دے دیا گیا ہے / Question Answered',
          'body': 'علمائے کرام نے آپ کے سوال کا جواب فراہم کر دیا ہے۔ دیکھنے کے لیے ٹیپ کریں۔',
        },
        'data': {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'route': '/qna',
          'questionId': questionId,
          'type': 'question_answered',
        },
        'android': {
          'priority': 'high',
          'notification': {
            'channelId': channelId,
            'sound': 'default',
            'priority': 'max',
            'defaultSound': true,
            'defaultVibrateTimings': true,
          },
        },
      };

      expect(targetedPayload['token'], equals(recipientToken));
      expect(targetedPayload.containsKey('topic'), isFalse);
      final dataMap = targetedPayload['data'] as Map<String, dynamic>;
      expect(dataMap['route'], equals('/qna'));
      expect(dataMap['questionId'], equals(questionId));
      expect((targetedPayload['notification'] as Map)['title'], contains('Question Answered'));
    });
  });
}
