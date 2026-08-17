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

  group('NotificationService Mark All Read & Clear Tests', () {
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
