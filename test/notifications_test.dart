import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/features/home/presentation/widgets/notifications_sheet.dart';
import 'package:islamic_app/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('NotificationService User Separation & Delivery Tests', () {
    test('isRelevantToUser delivers broadcast notifications to all users', () {
      final broadcastDoc1 = {
        'title': 'General Announcement',
        'body': 'Milad gathering tomorrow',
        'target': 'all_users',
        'type': 'broadcast',
      };
      final broadcastDoc2 = {
        'title': 'Event Update',
        'body': 'New event added',
        'target': 'broadcast',
      };

      expect(NotificationService.isRelevantToUser(broadcastDoc1, targetUid: 'user_1'), isTrue);
      expect(NotificationService.isRelevantToUser(broadcastDoc1, targetUid: 'user_2'), isTrue);
      expect(NotificationService.isRelevantToUser(broadcastDoc2, targetUid: 'guest'), isTrue);
    });

    test('isRelevantToUser strictly routes user-targeted notifications only to intended user', () {
      final userSpecificDoc = {
        'title': 'Your Question Received',
        'body': 'We received your inquiry regarding Namaz',
        'target': 'user_123',
        'user_id': 'user_123',
        'type': 'question_received',
      };

      // Delivered to user_123
      expect(NotificationService.isRelevantToUser(userSpecificDoc, targetUid: 'user_123'), isTrue);

      // Blocked from other users
      expect(NotificationService.isRelevantToUser(userSpecificDoc, targetUid: 'user_999'), isFalse);
      expect(NotificationService.isRelevantToUser(userSpecificDoc, targetUid: 'guest'), isFalse);
    });

    test('isRelevantToUser hides notifications deleted by specific user', () {
      final broadcastDoc = {
        'title': 'Daily Reminder',
        'body': 'Recite Durood Shareef',
        'target': 'all_users',
        'deleted_by_users': ['user_123'],
      };

      // Blocked for user_123 who deleted it
      expect(NotificationService.isRelevantToUser(broadcastDoc, targetUid: 'user_123'), isFalse);

      // Still delivered to other users who have not deleted it
      expect(NotificationService.isRelevantToUser(broadcastDoc, targetUid: 'user_456'), isTrue);
    });

    test('markAllAsRead marks items as read and resets unread count', () async {
      final now = DateTime.now();
      final item1 = InAppNotificationItem(
        id: 'notif-1',
        title: 'New Event Alert',
        body: 'Join us for Durood gathering',
        sentAt: now,
      );
      final item2 = InAppNotificationItem(
        id: 'notif-2',
        title: 'Daily Reminder',
        body: 'Recite Salawat 100 times',
        sentAt: now,
      );

      // Initially, unread check for fresh item
      expect(NotificationService.isItemUnread(item1), isTrue);
      expect(NotificationService.isItemUnread(item2), isTrue);

      // Mark single item as read
      await NotificationService.markAsRead('notif-1');
      expect(NotificationService.isItemUnread(item1), isFalse);
      expect(NotificationService.isItemUnread(item2), isTrue);

      // Mark all as read
      await NotificationService.markAllAsRead();
      expect(NotificationService.isItemUnread(item1), isFalse);
      expect(NotificationService.isItemUnread(item2), isFalse);
      expect(NotificationService.unreadCountNotifier.value, 0);
    });

    testWidgets('NotificationsSheet renders header and Mark all read button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationsSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find Mark all read TextButton
      final markAllBtn = find.byType(TextButton);
      expect(markAllBtn, findsOneWidget);

      // Tap Mark all read
      await tester.tap(markAllBtn);
      await tester.pumpAndSettle();

      expect(NotificationService.unreadCountNotifier.value, 0);
    });
  });
}
