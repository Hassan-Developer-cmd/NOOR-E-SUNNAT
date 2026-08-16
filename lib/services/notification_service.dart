import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
    final rawSent = map['sent_at'];
    if (rawSent is Timestamp) {
      timestamp = rawSent.toDate();
    } else if (rawSent is String && rawSent.isNotEmpty) {
      timestamp = DateTime.tryParse(rawSent);
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
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _liveNotificationsSub;
  static final Set<String> _seenNotificationIds = {};

  /// Reactive notifiers for live UI updates
  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);
  static final ValueNotifier<int> lastReadTimestampNotifier = ValueNotifier<int>(0);

  static int _lastReadMs = 0;
  static List<Map<String, dynamic>> _latestNotificationData = [];

  /// Initializes local notifications and reads cached lastRead timestamp.
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _lastReadMs = prefs.getInt(_lastReadPrefKey) ?? 0;
      lastReadTimestampNotifier.value = _lastReadMs;

      if (!kIsWeb) {
        const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
        const darwinInit = DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

        const initSettings = InitializationSettings(
          android: androidInit,
          iOS: darwinInit,
          macOS: darwinInit,
        );

        await _localNotifications.initialize(
          settings: initSettings,
          onDidReceiveNotificationResponse: (NotificationResponse response) {
            if (kDebugMode) {
              print('Notification clicked with payload: ${response.payload}');
            }
          },
        );

        // Request permissions for Android 13+ (API 33)
        final androidImplementation = _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidImplementation != null) {
          await androidImplementation.requestNotificationsPermission();
        }
      }

      _isInitialized = true;
      startListeningToLiveNotifications();
    } catch (e) {
      if (kDebugMode) print('NotificationService.initialize error: $e');
    }
  }

  /// Recalculates unread count from cached docs and triggers reactive notifiers.
  static void _recalculateUnread() {
    int count = 0;
    for (var data in _latestNotificationData) {
      int? timeMs;
      final raw = data['sent_at'];
      if (raw is Timestamp) {
        timeMs = raw.millisecondsSinceEpoch;
      } else if (raw is String && raw.isNotEmpty) {
        timeMs = DateTime.tryParse(raw)?.millisecondsSinceEpoch;
      }

      if (timeMs != null) {
        if (timeMs > _lastReadMs) count++;
      } else {
        if (_lastReadMs == 0) count++;
      }
    }
    unreadCountNotifier.value = count;
  }

  /// Checks if a specific notification timestamp is unread.
  static bool isUnread(DateTime? sentAt) {
    if (sentAt == null) return false;
    return sentAt.millisecondsSinceEpoch > _lastReadMs;
  }

  /// Starts listening to Firestore for real-time notifications and displays WhatsApp-style heads-up popups.
  static void startListeningToLiveNotifications() {
    _liveNotificationsSub?.cancel();

    bool isFirstSnapshot = true;

    _liveNotificationsSub = _firestore
        .collection('notifications')
        .snapshots()
        .listen((snapshot) {
      _latestNotificationData = snapshot.docs.map((d) => d.data()).toList();
      _recalculateUnread();

      if (isFirstSnapshot) {
        // Record all existing notification IDs so we do not spam notifications for old history on app boot
        for (var doc in snapshot.docs) {
          _seenNotificationIds.add(doc.id);
        }
        isFirstSnapshot = false;
        return;
      }

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final doc = change.doc;
          if (!_seenNotificationIds.contains(doc.id)) {
            _seenNotificationIds.add(doc.id);
            final data = doc.data();
            if (data != null) {
              final title = (data['title'] as String? ?? 'Notification').trim();
              final body = (data['body'] as String? ?? '').trim();
              if (title.isNotEmpty || body.isNotEmpty) {
                showHeadsUpNotification(
                  id: doc.id.hashCode,
                  title: title,
                  body: body,
                  payload: doc.id,
                );
              }
            }
          }
        }
      }
    }, onError: (e) {
      if (kDebugMode) print('NotificationService live listener error: $e');
    });
  }

  /// Displays an immediate high-priority heads-up notification (like WhatsApp).
  static Future<void> showHeadsUpNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'faizan_e_durood_channel',
        'Faizan-e-Durood Notifications',
        channelDescription:
            'High priority broadcast notifications, event alerts & answers',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'Faizan e Durood',
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(
          '',
          contentTitle: '',
          summaryText: 'Faizan e Durood',
        ),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        presentBanner: true,
        presentList: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) print('NotificationService.showHeadsUpNotification error: $e');
    }
  }

  /// Live stream of notifications ordered by newest first with robust client-side sorting.
  static Stream<List<InAppNotificationItem>> get notificationsStream {
    return _firestore.collection('notifications').snapshots().map((snap) {
      final list = snap.docs
          .map((doc) => InAppNotificationItem.fromMap(doc.id, doc.data()))
          .toList();

      list.sort((a, b) {
        final aTime = a.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime); // newest first
      });

      return list;
    }).handleError((e) {
      if (kDebugMode) print('NotificationService stream error: $e');
      return <InAppNotificationItem>[];
    });
  }

  /// Real-time count of unread notifications stream.
  static Stream<int> get unreadCountStream async* {
    if (!_isInitialized) {
      final prefs = await SharedPreferences.getInstance();
      _lastReadMs = prefs.getInt(_lastReadPrefKey) ?? 0;
      lastReadTimestampNotifier.value = _lastReadMs;
    }
    _recalculateUnread();
    yield unreadCountNotifier.value;

    final controller = StreamController<int>.broadcast();
    void listener() {
      if (!controller.isClosed) {
        controller.add(unreadCountNotifier.value);
      }
    }
    unreadCountNotifier.addListener(listener);
    yield* controller.stream;
  }

  /// Marks all current notifications as read instantly.
  static Future<void> markAllAsRead() async {
    try {
      _lastReadMs = DateTime.now().millisecondsSinceEpoch;
      lastReadTimestampNotifier.value = _lastReadMs;
      _recalculateUnread(); // Instantly clears unread count to 0 in UI

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastReadPrefKey, _lastReadMs);
    } catch (e) {
      if (kDebugMode) print('NotificationService.markAllAsRead error: $e');
    }
  }

  /// Deletes a notification from Firestore by document ID.
  static Future<void> deleteNotification(String id) async {
    try {
      await _firestore.collection('notifications').doc(id).delete();
      _seenNotificationIds.remove(id);
    } catch (e) {
      if (kDebugMode) print('NotificationService.deleteNotification error: $e');
      rethrow;
    }
  }

  /// Disposes stream subscriptions.
  static void dispose() {
    _liveNotificationsSub?.cancel();
  }
}
