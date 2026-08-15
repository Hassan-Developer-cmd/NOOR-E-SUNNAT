import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InAppNotificationItem {
  final String id;
  final String title;
  final String titleUr;
  final String body;
  final String bodyUr;
  final String type;
  final String? eventId;
  final DateTime? sentAt;

  const InAppNotificationItem({
    required this.id,
    required this.title,
    this.titleUr = '',
    required this.body,
    this.bodyUr = '',
    this.type = 'broadcast',
    this.eventId,
    this.sentAt,
  });

  String getTitle(bool isUrdu) => isUrdu && titleUr.isNotEmpty ? titleUr : title;
  String getBody(bool isUrdu) => isUrdu && bodyUr.isNotEmpty ? bodyUr : body;

  factory InAppNotificationItem.fromMap(String id, Map<String, dynamic> map) {
    DateTime? timestamp;
    if (map['sent_at'] is Timestamp) {
      timestamp = (map['sent_at'] as Timestamp).toDate();
    } else if (map['sent_at'] is String) {
      timestamp = DateTime.tryParse(map['sent_at'] as String);
    }

    return InAppNotificationItem(
      id: id,
      title: map['title'] as String? ?? '',
      titleUr: map['title_ur'] as String? ?? '',
      body: map['body'] as String? ?? '',
      bodyUr: map['body_ur'] as String? ?? '',
      type: map['type'] as String? ?? 'broadcast',
      eventId: map['event_id'] as String?,
      sentAt: timestamp,
    );
  }
}

class NotificationService {
  static final _firestore = FirebaseFirestore.instance;
  static const _lastReadPrefKey = 'last_read_notification_timestamp_ms';

  /// Live stream of notifications ordered by newest first.
  static Stream<List<InAppNotificationItem>> get notificationsStream {
    return _firestore
        .collection('notifications')
        .orderBy('sent_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => InAppNotificationItem.fromMap(doc.id, doc.data()))
            .toList())
        .handleError((e) {
      if (kDebugMode) print('NotificationService stream error: $e');
      return <InAppNotificationItem>[];
    });
  }

  /// Real-time count of unread notifications.
  static Stream<int> get unreadCountStream async* {
    final prefs = await SharedPreferences.getInstance();
    final lastReadMs = prefs.getInt(_lastReadPrefKey) ?? 0;

    yield* _firestore
        .collection('notifications')
        .orderBy('sent_at', descending: true)
        .snapshots()
        .map((snap) {
      int count = 0;
      for (var doc in snap.docs) {
        final data = doc.data();
        if (data['sent_at'] is Timestamp) {
          final timeMs = (data['sent_at'] as Timestamp).millisecondsSinceEpoch;
          if (timeMs > lastReadMs) count++;
        }
      }
      return count;
    });
  }

  /// Marks all current notifications as read.
  static Future<void> markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastReadPrefKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      if (kDebugMode) print('NotificationService.markAllAsRead error: $e');
    }
  }
}
