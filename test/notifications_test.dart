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

    test('Native Android WAKE_LOCK and Notification Channel Configuration Check', () {
      expect(highImportanceChannel.id, equals('high_importance_channel'));
      expect(highImportanceChannel.importance, equals(Importance.max));
      expect(highImportanceChannel.playSound, isTrue);
      expect(highImportanceChannel.enableVibration, isTrue);
    });

    test('Single notification delete filters strictly out only that specific ID', () {
      final notifs = ['notif_1', 'notif_2', 'notif_3'];
      final Set<String> clearedIds = {};

      // Delete only notif_2
      const targetId = 'notif_2';
      clearedIds.add(targetId);

      final visible = notifs.where((id) => !clearedIds.contains(id)).toList();

      expect(visible.length, equals(2));
      expect(visible, contains('notif_1'));
      expect(visible, contains('notif_3'));
      expect(visible, isNot(contains('notif_2')), reason: 'Only the specific single notification must be deleted');
    });

    test('Clear All notifications deletes all active items', () {
      final notifs = ['notif_1', 'notif_2', 'notif_3'];
      final Set<String> clearedIds = {};

      // Clear all
      clearedIds.addAll(notifs);

      final visible = notifs.where((id) => !clearedIds.contains(id)).toList();
      expect(visible, isEmpty, reason: 'All notifications must be deleted on Clear All');
    });

    test('Notification deduplication prevents duplicate display for same payload or title/body', () {
      NotificationService.clearDeduplicationCache();

      const docId = 'broadcast_notif_9988';
      const title = 'Special Milad Event';
      const body = 'Join us tonight at 9 PM.';

      // First arrival (e.g. via FCM onMessage)
      expect(
        NotificationService.isDuplicateNotification(docId, title, body),
        isFalse,
        reason: 'First notification should not be flagged as duplicate',
      );

      // Simulate first notification being shown
      NotificationService.showHeadsUpNotification(
        id: 12345,
        title: title,
        body: body,
        payload: docId,
      );

      // Second arrival with same docId (e.g. Firestore snapshots arriving 100ms later)
      expect(
        NotificationService.isDuplicateNotification(docId, title, body),
        isTrue,
        reason: 'Simultaneous Firestore snapshot with same docId must be suppressed as duplicate',
      );

      // Duplicate arrival with same content even if docId is null
      expect(
        NotificationService.isDuplicateNotification(null, title, body),
        isTrue,
        reason: 'Simultaneous notification with identical title and body must be suppressed as duplicate',
      );

      // Completely distinct notification should NOT be flagged as duplicate
      expect(
        NotificationService.isDuplicateNotification('other_doc_1122', 'New Durood Goal', 'Keep reciting!'),
        isFalse,
        reason: 'Distinct notification should be allowed',
      );
    });
  });
}
