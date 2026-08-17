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
    final rawSent = map['sent_at'] ??
        map['created_at'] ??
        map['timestamp'] ??
        map['time'] ??
        map['sentAt'] ??
        map['createdAt'];

    if (rawSent is Timestamp) {
      timestamp = rawSent.toDate();
    } else if (rawSent is String && rawSent.isNotEmpty) {
      timestamp = DateTime.tryParse(rawSent);
    } else if (rawSent is int && rawSent > 0) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(rawSent);
    }

    final resolvedTitle = (map['title'] ?? map['title_en'] ?? map['titleEn'] ?? '') as String;
    final resolvedTitleUr = (map['title_ur'] ?? map['titleUr'] ?? map['title_urdu'] ?? '') as String;
    final resolvedBody = (map['body'] ?? map['body_en'] ?? map['bodyEn'] ?? map['message'] ?? '') as String;
    final resolvedBodyUr = (map['body_ur'] ?? map['bodyUr'] ?? map['body_urdu'] ?? map['message_ur'] ?? '') as String;

    return InAppNotificationItem(
      id: id,
      title: resolvedTitle,
      titleUr: resolvedTitleUr,
      body: resolvedBody,
      bodyUr: resolvedBodyUr,
      type: (map['type'] ?? 'broadcast') as String,
      eventId: map['event_id'] as String?,
      sentAt: timestamp,
    );
  }
}

class NotificationService {
  static final _firestore = FirebaseFirestore.instance;
  static const _lastReadPrefKey = 'last_read_notification_timestamp_ms';
  static const _readIdsPrefKey = 'read_notification_ids_set';
  static const _clearedIdsPrefKey = 'cleared_notification_ids_set';

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _liveNotificationsSub;
  static final Set<String> _seenNotificationIds = {};
  static final Set<String> _readNotificationIds = {};
  static final Set<String> _clearedNotificationIds = {};

  /// Reactive notifiers for live UI updates
  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);
  static final ValueNotifier<int> lastReadTimestampNotifier = ValueNotifier<int>(0);
  static final ValueNotifier<Set<String>> readNotificationIdsNotifier = ValueNotifier<Set<String>>({});
  static final ValueNotifier<Set<String>> clearedNotificationIdsNotifier = ValueNotifier<Set<String>>({});

  static int _lastReadMs = 0;
  static List<Map<String, dynamic>> _latestNotificationData = [];

  /// Initializes local notifications and reads cached state.
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _lastReadMs = prefs.getInt(_lastReadPrefKey) ?? 0;
      lastReadTimestampNotifier.value = _lastReadMs;

      final savedReadIds = prefs.getStringList(_readIdsPrefKey) ?? [];
      _readNotificationIds.clear();
      _readNotificationIds.addAll(savedReadIds);
      readNotificationIdsNotifier.value = Set.from(_readNotificationIds);

      final savedClearedIds = prefs.getStringList(_clearedIdsPrefKey) ?? [];
      _clearedNotificationIds.clear();
      _clearedNotificationIds.addAll(savedClearedIds);
      clearedNotificationIdsNotifier.value = Set.from(_clearedNotificationIds);

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
      final docId = data['id'] as String?;
      if (docId != null) {
        if (_readNotificationIds.contains(docId) || _clearedNotificationIds.contains(docId)) {
          continue;
        }
      }

      int? timeMs;
      final raw = data['sent_at'] ??
          data['created_at'] ??
          data['timestamp'] ??
          data['time'] ??
          data['sentAt'] ??
          data['createdAt'];

      if (raw is Timestamp) {
        timeMs = raw.millisecondsSinceEpoch;
      } else if (raw is String && raw.isNotEmpty) {
        timeMs = DateTime.tryParse(raw)?.millisecondsSinceEpoch;
      } else if (raw is int && raw > 0) {
        timeMs = raw;
      }

      if (timeMs != null) {
        if (timeMs > _lastReadMs) count++;
      } else {
        if (_lastReadMs == 0) count++;
      }
    }
    unreadCountNotifier.value = count;
  }

  /// Checks if a specific notification item is unread.
  static bool isItemUnread(InAppNotificationItem item) {
    if (_readNotificationIds.contains(item.id)) return false;
    if (_clearedNotificationIds.contains(item.id)) return false;
    if (item.sentAt == null) return false;
    return item.sentAt!.millisecondsSinceEpoch > _lastReadMs;
  }

  /// Legacy helper for timestamp checks.
  static bool isUnread(DateTime? sentAt) {
    if (sentAt == null) return false;
    return sentAt.millisecondsSinceEpoch > _lastReadMs;
  }

  /// Starts listening to Firestore for real-time notifications and displays WhatsApp-style heads-up popups.
  static void startListeningToLiveNotifications() {
    _liveNotificationsSub?.cancel();

    bool isFirstSnapshot = true;

    try {
      _liveNotificationsSub = _firestore
          .collection('notifications')
          .snapshots()
          .listen((snapshot) {
        _latestNotificationData = snapshot.docs.map((d) {
          final data = Map<String, dynamic>.from(d.data());
          data['id'] = d.id;
          return data;
        }).toList();
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
    } catch (e) {
      if (kDebugMode) print('NotificationService startListeningToLiveNotifications error: $e');
    }
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
    try {
      return _firestore.collection('notifications').snapshots().map((snap) {
        final list = snap.docs
            .where((doc) => !_clearedNotificationIds.contains(doc.id))
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
    } catch (_) {
      return Stream.value(<InAppNotificationItem>[]);
    }
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

  /// Marks an individual notification as read instantly.
  static Future<void> markAsRead(String id) async {
    try {
      _readNotificationIds.add(id);
      readNotificationIdsNotifier.value = Set.from(_readNotificationIds);
      _recalculateUnread();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_readIdsPrefKey, _readNotificationIds.toList());

      try {
        await _firestore.collection('notifications').doc(id).update({
          'is_read': true,
          'read_at': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    } catch (e) {
      if (kDebugMode) print('NotificationService.markAsRead error: $e');
    }
  }

  /// Marks all current notifications as read instantly.
  static Future<void> markAllAsRead() async {
    try {
      int maxTimestamp = DateTime.now().millisecondsSinceEpoch;
      for (var data in _latestNotificationData) {
        final id = data['id'] as String?;
        if (id != null) {
          _readNotificationIds.add(id);
        }

        final raw = data['sent_at'] ??
            data['created_at'] ??
            data['timestamp'] ??
            data['time'] ??
            data['sentAt'] ??
            data['createdAt'];
        if (raw is Timestamp && raw.millisecondsSinceEpoch > maxTimestamp) {
          maxTimestamp = raw.millisecondsSinceEpoch;
        } else if (raw is int && raw > maxTimestamp) {
          maxTimestamp = raw;
        }
      }

      for (var id in _seenNotificationIds) {
        _readNotificationIds.add(id);
      }

      _lastReadMs = maxTimestamp + 60000;
      lastReadTimestampNotifier.value = _lastReadMs;
      readNotificationIdsNotifier.value = Set.from(_readNotificationIds);
      unreadCountNotifier.value = 0; // Force immediate 0 count in badge

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastReadPrefKey, _lastReadMs);
      await prefs.setStringList(_readIdsPrefKey, _readNotificationIds.toList());

      // Attempt remote Firestore batch update if connected
      try {
        final snap = await _firestore.collection('notifications').get();
        if (snap.docs.isNotEmpty) {
          final batch = _firestore.batch();
          for (var doc in snap.docs) {
            batch.update(doc.reference, {
              'is_read': true,
              'read_at': FieldValue.serverTimestamp(),
            });
          }
          await batch.commit();
        }
      } catch (_) {}
    } catch (e) {
      if (kDebugMode) print('NotificationService.markAllAsRead error: $e');
    }
  }

  /// Clears all notifications locally from user view.
  static Future<void> clearAllNotificationsLocally() async {
    try {
      for (var data in _latestNotificationData) {
        final id = data['id'] as String?;
        if (id != null) {
          _clearedNotificationIds.add(id);
          _readNotificationIds.add(id);
        }
      }
      for (var id in _seenNotificationIds) {
        _clearedNotificationIds.add(id);
        _readNotificationIds.add(id);
      }

      clearedNotificationIdsNotifier.value = Set.from(_clearedNotificationIds);
      readNotificationIdsNotifier.value = Set.from(_readNotificationIds);
      unreadCountNotifier.value = 0;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_clearedIdsPrefKey, _clearedNotificationIds.toList());
      await prefs.setStringList(_readIdsPrefKey, _readNotificationIds.toList());
    } catch (e) {
      if (kDebugMode) print('NotificationService.clearAllNotificationsLocally error: $e');
    }
  }

  /// Deletes a notification from Firestore by document ID.
  static Future<void> deleteNotification(String id) async {
    try {
      _clearedNotificationIds.add(id);
      _readNotificationIds.add(id);
      clearedNotificationIdsNotifier.value = Set.from(_clearedNotificationIds);
      readNotificationIdsNotifier.value = Set.from(_readNotificationIds);
      _recalculateUnread();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_clearedIdsPrefKey, _clearedNotificationIds.toList());

      await _firestore.collection('notifications').doc(id).delete();
      _seenNotificationIds.remove(id);
    } catch (e) {
      if (kDebugMode) print('NotificationService.deleteNotification error: $e');
    }
  }

  /// Disposes stream subscriptions.
  static void dispose() {
    _liveNotificationsSub?.cancel();
  }
}
