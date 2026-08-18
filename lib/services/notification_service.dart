import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final String? target;
  final String? userId;
  final String? eventId;
  final String? questionId;
  final DateTime? sentAt;
  final List<String> deletedByUsers;
  final List<String> readByUsers;
  final bool isRead;

  const InAppNotificationItem({
    required this.id,
    required this.title,
    this.titleUr = '',
    required this.body,
    this.bodyUr = '',
    this.type = 'broadcast',
    this.target,
    this.userId,
    this.eventId,
    this.questionId,
    this.sentAt,
    this.deletedByUsers = const [],
    this.readByUsers = const [],
    this.isRead = false,
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

    List<String> parseStringList(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString()).toList();
      }
      return [];
    }

    return InAppNotificationItem(
      id: id,
      title: resolvedTitle,
      titleUr: resolvedTitleUr,
      body: resolvedBody,
      bodyUr: resolvedBodyUr,
      type: (map['type'] ?? 'broadcast') as String,
      target: map['target'] as String?,
      userId: (map['user_id'] ?? map['userId'] ?? map['target_user']) as String?,
      eventId: map['event_id'] as String?,
      questionId: map['question_id'] as String?,
      sentAt: timestamp,
      deletedByUsers: parseStringList(map['deleted_by_users']),
      readByUsers: parseStringList(map['read_by_users']),
      isRead: map['is_read'] as bool? ?? false,
    );
  }
}

class NotificationService {
  static final _firestore = FirebaseFirestore.instance;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _liveNotificationsSub;
  static StreamSubscription<User?>? _authSubscription;

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

  static String get _currentUserId {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    } catch (_) {
      return 'guest';
    }
  }

  static String get _currentUserEmail {
    try {
      return FirebaseAuth.instance.currentUser?.email ?? '';
    } catch (_) {
      return '';
    }
  }

  static String _lastReadPrefKey(String uid) => 'last_read_notification_timestamp_ms_$uid';
  static String _readIdsPrefKey(String uid) => 'read_notification_ids_set_$uid';
  static String _clearedIdsPrefKey(String uid) => 'cleared_notification_ids_set_$uid';

  /// Determines whether a notification data map is addressed to the specified or active user.
  static bool isRelevantToUser(
    Map<String, dynamic> data, {
    String? targetUid,
    String? targetEmail,
  }) {
    final uid = (targetUid ?? _currentUserId).trim().toLowerCase();
    final email = (targetEmail ?? _currentUserEmail).trim().toLowerCase();

    // Check if user has deleted this notification on Firestore level
    final deletedByList = data['deleted_by_users'];
    if (deletedByList is List && deletedByList.map((e) => e.toString().toLowerCase()).contains(uid)) {
      return false;
    }

    if (data['is_deleted_by_user'] == true) {
      final docUid = (data['user_id'] ?? data['userId'] ?? data['target'] ?? '').toString().trim().toLowerCase();
      if (docUid == uid || (email.isNotEmpty && docUid == email)) {
        return false;
      }
    }

    final target = (data['target'] as String? ?? '').trim().toLowerCase();
    final docUserId = (data['user_id'] as String? ?? data['userId'] as String? ?? '').trim().toLowerCase();

    // 1. Broadcast targets -> relevant to all users
    if (target.isEmpty ||
        target == 'all' ||
        target == 'all_users' ||
        target == 'broadcast' ||
        target == 'active_today') {
      return true;
    }

    // 2. Explicit user ID matches
    if (uid.isNotEmpty && uid != 'guest') {
      if (target == uid || docUserId == uid) return true;
    }

    // 3. Explicit email matches
    if (email.isNotEmpty) {
      if (target == email || docUserId == email) return true;
    }

    // 4. If target is 'guest' and user is guest
    if (uid == 'guest' && (target == 'guest' || docUserId == 'guest')) {
      return true;
    }

    return false;
  }

  /// Initializes local notifications and reads cached state for the active user.
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadUserState();

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

      // Listen to Auth State changes to separate notifications per user account
      _authSubscription?.cancel();
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) async {
        await _loadUserState();
        _seenNotificationIds.clear();
        startListeningToLiveNotifications();
      });

      _isInitialized = true;
      startListeningToLiveNotifications();
    } catch (e) {
      if (kDebugMode) print('NotificationService.initialize error: $e');
    }
  }

  /// Loads cached read & cleared state for current user ID from SharedPreferences.
  static Future<void> _loadUserState() async {
    try {
      final uid = _currentUserId;
      final prefs = await SharedPreferences.getInstance();

      _lastReadMs = prefs.getInt(_lastReadPrefKey(uid)) ?? 0;
      lastReadTimestampNotifier.value = _lastReadMs;

      final savedReadIds = prefs.getStringList(_readIdsPrefKey(uid)) ?? [];
      _readNotificationIds.clear();
      _readNotificationIds.addAll(savedReadIds);
      readNotificationIdsNotifier.value = Set.from(_readNotificationIds);

      final savedClearedIds = prefs.getStringList(_clearedIdsPrefKey(uid)) ?? [];
      _clearedNotificationIds.clear();
      _clearedNotificationIds.addAll(savedClearedIds);
      clearedNotificationIdsNotifier.value = Set.from(_clearedNotificationIds);

      _recalculateUnread();
    } catch (e) {
      if (kDebugMode) print('NotificationService._loadUserState error: $e');
    }
  }

  /// Recalculates unread count strictly for the active user.
  static void _recalculateUnread() {
    int count = 0;
    final uid = _currentUserId;
    final email = _currentUserEmail;

    for (var data in _latestNotificationData) {
      // Must be relevant to this user
      if (!isRelevantToUser(data, targetUid: uid, targetEmail: email)) {
        continue;
      }

      final docId = data['id'] as String?;
      if (docId != null) {
        if (_readNotificationIds.contains(docId) || _clearedNotificationIds.contains(docId)) {
          continue;
        }
      }

      // Check remote read_by_users
      final readByList = data['read_by_users'];
      if (readByList is List && readByList.contains(uid)) {
        continue;
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

  /// Checks if a specific notification item is unread for the current user.
  static bool isItemUnread(InAppNotificationItem item) {
    final uid = _currentUserId;
    if (_readNotificationIds.contains(item.id)) return false;
    if (_clearedNotificationIds.contains(item.id)) return false;
    if (item.readByUsers.contains(uid)) return false;
    if (item.deletedByUsers.contains(uid)) return false;
    if (item.sentAt == null) return false;
    return item.sentAt!.millisecondsSinceEpoch > _lastReadMs;
  }

  /// Starts listening to Firestore notifications and displays heads-up alerts only for relevant users.
  static void startListeningToLiveNotifications() {
    _liveNotificationsSub?.cancel();

    bool isFirstSnapshot = true;

    try {
      _liveNotificationsSub = _firestore
          .collection('notifications')
          .snapshots()
          .listen((snapshot) {
        final uid = _currentUserId;
        final email = _currentUserEmail;

        _latestNotificationData = snapshot.docs.map((d) {
          final data = Map<String, dynamic>.from(d.data());
          data['id'] = d.id;
          return data;
        }).toList();

        _recalculateUnread();

        if (isFirstSnapshot) {
          // Record existing notification IDs on first load so we do not spam past notifications
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
                // Strictly verify recipient relevance before showing heads-up notification!
                if (!isRelevantToUser(data, targetUid: uid, targetEmail: email)) {
                  continue;
                }

                // If user already cleared this, do not show
                if (_clearedNotificationIds.contains(doc.id)) {
                  continue;
                }

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
        'noor_e_sunnat_channel',
        'NOOR E SUNNAT Notifications',
        channelDescription:
            'High priority broadcast notifications, event alerts & answers',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'NOOR E SUNNAT',
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(
          '',
          contentTitle: '',
          summaryText: 'NOOR E SUNNAT',
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

  /// Live stream of notifications strictly filtered for the active user.
  static Stream<List<InAppNotificationItem>> get notificationsStream {
    try {
      return _firestore.collection('notifications').snapshots().map((snap) {
        final uid = _currentUserId;
        final email = _currentUserEmail;

        final list = snap.docs
            .where((doc) {
              final data = doc.data();
              if (_clearedNotificationIds.contains(doc.id)) return false;
              return isRelevantToUser(data, targetUid: uid, targetEmail: email);
            })
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

  /// Real-time count of unread notifications stream for the current user.
  static Stream<int> get unreadCountStream async* {
    if (!_isInitialized) {
      await _loadUserState();
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

  /// Marks an individual notification as read for the active user.
  static Future<void> markAsRead(String id) async {
    try {
      final uid = _currentUserId;
      _readNotificationIds.add(id);
      readNotificationIdsNotifier.value = Set.from(_readNotificationIds);
      _recalculateUnread();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_readIdsPrefKey(uid), _readNotificationIds.toList());

      try {
        final docRef = _firestore.collection('notifications').doc(id);
        final doc = await docRef.get();
        if (doc.exists) {
          final data = doc.data() ?? {};
          final target = (data['target'] as String? ?? '').trim().toLowerCase();
          final docUid = (data['user_id'] as String? ?? '').trim().toLowerCase();

          // If personal notification for this user, mark is_read: true
          if (target == uid.toLowerCase() || docUid == uid.toLowerCase()) {
            await docRef.update({
              'is_read': true,
              'read_at': FieldValue.serverTimestamp(),
            });
          } else {
            // For broadcast notifications, add user ID to read_by_users array
            await docRef.update({
              'read_by_users': FieldValue.arrayUnion([uid]),
            });
          }
        }
      } catch (_) {}
    } catch (e) {
      if (kDebugMode) print('NotificationService.markAsRead error: $e');
    }
  }

  /// Marks all current notifications as read for the active user.
  static Future<void> markAllAsRead() async {
    try {
      final uid = _currentUserId;
      final email = _currentUserEmail;
      int maxTimestamp = DateTime.now().millisecondsSinceEpoch;

      for (var data in _latestNotificationData) {
        if (!isRelevantToUser(data, targetUid: uid, targetEmail: email)) continue;

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
      await prefs.setInt(_lastReadPrefKey(uid), _lastReadMs);
      await prefs.setStringList(_readIdsPrefKey(uid), _readNotificationIds.toList());
    } catch (e) {
      if (kDebugMode) print('NotificationService.markAllAsRead error: $e');
    }
  }

  /// Clears all notifications locally from the active user's view.
  static Future<void> clearAllNotificationsLocally() async {
    try {
      final uid = _currentUserId;
      final email = _currentUserEmail;

      for (var data in _latestNotificationData) {
        if (!isRelevantToUser(data, targetUid: uid, targetEmail: email)) continue;
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
      await prefs.setStringList(_clearedIdsPrefKey(uid), _clearedNotificationIds.toList());
      await prefs.setStringList(_readIdsPrefKey(uid), _readNotificationIds.toList());
    } catch (e) {
      if (kDebugMode) print('NotificationService.clearAllNotificationsLocally error: $e');
    }
  }

  /// Deletes/clears a notification for the active user without destroying broadcast records for others.
  static Future<void> deleteNotification(String id) async {
    try {
      final uid = _currentUserId;

      // 1. Immediately update local state
      _clearedNotificationIds.add(id);
      _readNotificationIds.add(id);
      clearedNotificationIdsNotifier.value = Set.from(_clearedNotificationIds);
      readNotificationIdsNotifier.value = Set.from(_readNotificationIds);
      _recalculateUnread();

      // 2. Persist local state in SharedPreferences per-user
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_clearedIdsPrefKey(uid), _clearedNotificationIds.toList());
      await prefs.setStringList(_readIdsPrefKey(uid), _readNotificationIds.toList());

      // 3. Update remote Firestore document cleanly
      try {
        final docRef = _firestore.collection('notifications').doc(id);
        final doc = await docRef.get();
        if (doc.exists) {
          final data = doc.data() ?? {};
          final target = (data['target'] as String? ?? '').trim().toLowerCase();
          final docUid = (data['user_id'] as String? ?? '').trim().toLowerCase();

          // If this is a personal notification exclusively for this user, delete or mark deleted
          if ((target.isNotEmpty && target == uid.toLowerCase()) ||
              (docUid.isNotEmpty && docUid == uid.toLowerCase())) {
            await docRef.update({
              'is_deleted_by_user': true,
              'deleted_at': FieldValue.serverTimestamp(),
            });
          } else {
            // If it is a broadcast notification, append user to deleted_by_users list so other users still see it!
            await docRef.update({
              'deleted_by_users': FieldValue.arrayUnion([uid]),
            });
          }
        }
      } catch (e) {
        if (kDebugMode) print('NotificationService remote sync on delete: $e');
      }

      _seenNotificationIds.remove(id);
    } catch (e) {
      if (kDebugMode) print('NotificationService.deleteNotification error: $e');
    }
  }

  /// Disposes stream subscriptions.
  static void dispose() {
    _liveNotificationsSub?.cancel();
    _authSubscription?.cancel();
  }
}
