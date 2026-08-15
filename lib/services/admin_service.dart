import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/models/event_model.dart';
import '../core/models/masail_model.dart';
import '../core/models/aqaid_model.dart';
import '../core/models/daily_content_model.dart';
import '../core/models/app_user.dart';
import '../core/utils/firestore_seeder.dart';
import 'auth_service.dart';

class AdminService {
  static final _firestore = FirebaseFirestore.instance;

  /// Guard: returns true only if the current user has is_admin == true.
  static Future<bool> isAdmin() async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return false;
    try {
      final user = await AuthService.getAppUser(uid);
      return user?.isAdmin ?? false;
    } catch (e) {
      if (kDebugMode) print('AdminService.isAdmin error: $e');
      return false;
    }
  }

  // ── Database Seeder ──────────────────────────────────────────

  /// Seeds all default entries into Firestore using FirestoreSeeder.
  static Future<bool> seedDefaultContent({bool force = true}) async {
    return await FirestoreSeeder.seedDefaultDataToFirestore(force: force);
  }

  // ── Events CRUD ─────────────────────────────────────────────

  static Stream<List<EventModel>> get eventsStream {
    return _firestore
        .collection('events')
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => EventModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Adds a new event and dispatches an automated deduplicated notification.
  static Future<void> addEvent(EventModel event) async {
    final initialHistory = [
      {
        'status': event.status,
        'changed_at': Timestamp.now(),
        'note': 'Initial event created',
      }
    ];

    final docRef = await _firestore.collection('events').add({
      'title': event.title,
      'title_ur': event.titleUr,
      'date_time': event.dateTime,
      'location': event.location,
      'location_ur': event.locationUr,
      'status': event.status,
      'description': event.description,
      'description_ur': event.descriptionUr,
      'status_history': initialHistory,
      'last_notified_status': event.status,
      'last_notification_sent_at': FieldValue.serverTimestamp(),
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    // Dispatch automated event creation notification
    await sendNotification(
      title: 'New Event Announced! 📢',
      titleUr: 'نئے ایونٹ کا اعلان! 📢',
      body: '${event.title} is ${event.status.toLowerCase() == 'coming soon' ? 'coming soon' : event.status}. Stay tuned!',
      bodyUr: '${event.titleUr.isNotEmpty ? event.titleUr : event.title} جلد آ رہا ہے۔ باخبر رہیں!',
      target: 'all_users',
      type: 'event_announcement',
      eventId: docRef.id,
    );
  }

  /// Modifies event status directly with deduplicated status transition notification.
  static Future<void> updateEventStatus(String eventId, String newStatus, {EventModel? currentEvent}) async {
    EventModel? event = currentEvent;
    if (event == null) {
      final doc = await _firestore.collection('events').doc(eventId).get();
      if (!doc.exists || doc.data() == null) return;
      event = EventModel.fromMap(doc.id, doc.data()!);
    }

    final oldStatus = event.status;
    final lastNotified = event.lastNotifiedStatus;

    // Deduplication check: only notify if status has truly transitioned to an unnotified state
    final shouldNotify = newStatus != oldStatus && newStatus != lastNotified;

    final updateData = <String, dynamic>{
      'status': newStatus,
      'updated_at': FieldValue.serverTimestamp(),
      'status_history': FieldValue.arrayUnion([
        {
          'status': newStatus,
          'previous_status': oldStatus,
          'changed_at': Timestamp.now(),
        }
      ]),
    };

    if (shouldNotify) {
      updateData['last_notified_status'] = newStatus;
      updateData['last_notification_sent_at'] = FieldValue.serverTimestamp();
    }

    await _firestore.collection('events').doc(eventId).update(updateData);

    // If status changed and hasn't been notified yet, dispatch tailored notification
    if (shouldNotify) {
      final title = _getNotificationTitleForStatus(event.title, newStatus);
      final titleUr = _getNotificationTitleUrForStatus(event.getTitle(true), newStatus);
      final body = _getNotificationBodyForStatus(event.title, newStatus);
      final bodyUr = _getNotificationBodyUrForStatus(event.getTitle(true), newStatus);

      await sendNotification(
        title: title,
        titleUr: titleUr,
        body: body,
        bodyUr: bodyUr,
        target: 'all_users',
        type: 'event_update',
        eventId: eventId,
      );
    }
  }

  /// Updates event document with deduplicated status checking.
  static Future<void> updateEvent(String id, Map<String, dynamic> data) async {
    final doc = await _firestore.collection('events').doc(id).get();
    if (!doc.exists || doc.data() == null) {
      await _firestore.collection('events').doc(id).set({
        ...data,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }

    final currentEvent = EventModel.fromMap(doc.id, doc.data()!);
    final newStatus = data['status'] as String?;

    if (newStatus != null && newStatus != currentEvent.status) {
      await updateEventStatus(id, newStatus, currentEvent: currentEvent);
      // Remove status from data since updateEventStatus handled status + history + notifications
      final remainingData = Map<String, dynamic>.from(data)..remove('status');
      if (remainingData.isNotEmpty) {
        await _firestore.collection('events').doc(id).update({
          ...remainingData,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    } else {
      // No status change -> only update other fields (NO notification emitted)
      await _firestore.collection('events').doc(id).update({
        ...data,
        'updated_at': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<void> deleteEvent(String id) async {
    await _firestore.collection('events').doc(id).delete();
  }

  // ── Notification Helpers ─────────────────────────────────────

  static String _getNotificationTitleForStatus(String eventTitle, String status) {
    switch (status.toLowerCase()) {
      case 'featured':
        return 'Event Update: $eventTitle ⭐';
      case 'ongoing':
        return 'Event Started: $eventTitle 🔴';
      case 'completed':
        return 'Event Concluded: $eventTitle ✅';
      case 'cancelled':
        return 'Event Notice: $eventTitle ⚠️';
      case 'coming soon':
      default:
        return 'Event Update: $eventTitle 📢';
    }
  }

  static String _getNotificationTitleUrForStatus(String eventTitleUr, String status) {
    switch (status.toLowerCase()) {
      case 'featured':
        return 'نمایاں ایونٹ: $eventTitleUr ⭐';
      case 'ongoing':
        return 'ایونٹ شروع ہو چکا ہے: $eventTitleUr 🔴';
      case 'completed':
        return 'ایونٹ مکمل ہوا: $eventTitleUr ✅';
      case 'cancelled':
        return 'اہم اطلاع: $eventTitleUr ⚠️';
      case 'coming soon':
      default:
        return 'ایونٹ کی معلومات: $eventTitleUr 📢';
    }
  }

  static String _getNotificationBodyForStatus(String eventTitle, String status) {
    switch (status.toLowerCase()) {
      case 'featured':
        return '$eventTitle is now Featured! Check the schedule and details.';
      case 'ongoing':
        return '$eventTitle is now Live & Ongoing! Join now.';
      case 'completed':
        return '$eventTitle has successfully concluded. JazakAllah Khair for participating!';
      case 'cancelled':
        return '$eventTitle has been cancelled or rescheduled.';
      case 'coming soon':
      default:
        return '$eventTitle is coming soon. Stay tuned for further updates!';
    }
  }

  static String _getNotificationBodyUrForStatus(String eventTitleUr, String status) {
    switch (status.toLowerCase()) {
      case 'featured':
        return '$eventTitleUr اب نمایاں ایونٹ ہے۔ شیڈول اور تفصیلات دیکھیں۔';
      case 'ongoing':
        return '$eventTitleUr اس وقت جاری ہے! ابھی شرکت کریں۔';
      case 'completed':
        return '$eventTitleUr کامیابی سے مکمل ہو گیا۔ شرکت کرنے پر جزاک اللہ خیراً!';
      case 'cancelled':
        return '$eventTitleUr منسوخ یا مؤخر کر دیا گیا ہے۔';
      case 'coming soon':
      default:
        return '$eventTitleUr جلد آ رہا ہے۔ مزید معلومات کے لیے باخبر رہیں!';
    }
  }

  // ── Masail CRUD ─────────────────────────────────────────────

  static Stream<List<MasailItemModel>> get masailStream {
    return _firestore
        .collection('masail_entries')
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MasailItemModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  static Future<void> addMasail(MasailItemModel item) async {
    await _firestore.collection('masail_entries').add(item.toMap());
  }

  static Future<void> updateMasail(String id, Map<String, dynamic> data) async {
    await _firestore.collection('masail_entries').doc(id).update({
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteMasail(String id) async {
    await _firestore.collection('masail_entries').doc(id).delete();
  }

  // ── Aqaid CRUD ──────────────────────────────────────────────

  static Stream<List<AqaidItemModel>> get aqaidStream {
    return _firestore
        .collection('aqaid_entries')
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AqaidItemModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  static Future<void> addAqaid(AqaidItemModel item) async {
    await _firestore.collection('aqaid_entries').add(item.toMap());
  }

  static Future<void> updateAqaid(String id, Map<String, dynamic> data) async {
    await _firestore.collection('aqaid_entries').doc(id).update({
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteAqaid(String id) async {
    await _firestore.collection('aqaid_entries').doc(id).delete();
  }

  // ── Daily Hadith / Ayat CRUD ────────────────────────────────

  static Stream<List<DailyContentModel>> get dailyContentStream {
    return _firestore
        .collection('daily_content')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => DailyContentModel.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) {
        final aTime = a.createdAt ?? a.scheduledDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? b.scheduledDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  static Future<void> addDailyContent(DailyContentModel item) async {
    if (item.isTopicOfTheDay) {
      // Unset previous topic of the day
      final snap = await _firestore.collection('daily_content').where('is_topic_of_the_day', isEqualTo: true).get();
      final batch = _firestore.batch();
      for (var doc in snap.docs) {
        batch.update(doc.reference, {'is_topic_of_the_day': false});
      }
      await batch.commit();
    }
    await _firestore.collection('daily_content').add(item.toMap());
  }

  static Future<void> updateDailyContent(String id, Map<String, dynamic> data) async {
    if (data['is_topic_of_the_day'] == true) {
      final snap = await _firestore.collection('daily_content').where('is_topic_of_the_day', isEqualTo: true).get();
      final batch = _firestore.batch();
      for (var doc in snap.docs) {
        if (doc.id != id) {
          batch.update(doc.reference, {'is_topic_of_the_day': false});
        }
      }
      await batch.commit();
    }
    await _firestore.collection('daily_content').doc(id).update({
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteDailyContent(String id) async {
    await _firestore.collection('daily_content').doc(id).delete();
  }

  static Future<void> setActiveDailyContent(String id) async {
    final batch = _firestore.batch();
    final allSnap = await _firestore.collection('daily_content').get();
    for (var doc in allSnap.docs) {
      batch.update(doc.reference, {'is_active': doc.id == id});
    }
    await batch.commit();
  }

  static Future<void> setTopicOfTheDay(String id, bool isTopic) async {
    final batch = _firestore.batch();
    if (isTopic) {
      final allSnap = await _firestore.collection('daily_content').get();
      for (var doc in allSnap.docs) {
        batch.update(doc.reference, {
          'is_topic_of_the_day': doc.id == id,
          if (doc.id == id) 'is_active': true,
        });
      }
    } else {
      batch.update(_firestore.collection('daily_content').doc(id), {
        'is_topic_of_the_day': false,
      });
    }
    await batch.commit();
  }

  // ── Push Notifications ─────────────────────────────────────

  static Stream<List<Map<String, dynamic>>> get notificationsStream {
    return _firestore
        .collection('notifications')
        .orderBy('sent_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList())
        .handleError((e) {
      // Fallback if index building
      return _firestore
          .collection('notifications')
          .snapshots()
          .map((snap) => snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
    });
  }

  static Future<void> sendNotification({
    required String title,
    required String body,
    String? titleUr,
    String? bodyUr,
    String target = 'all_users',
    String type = 'broadcast',
    String? eventId,
  }) async {
    await _firestore.collection('notifications').add({
      'title': title,
      'title_ur': titleUr ?? title,
      'body': body,
      'body_ur': bodyUr ?? body,
      'target': target,
      'type': type,
      'event_id': ?eventId,
      'sent_at': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteNotification(String id) async {
    await _firestore.collection('notifications').doc(id).delete();
  }



  // ── User Management ─────────────────────────────────────────

  static Stream<List<AppUser>> get usersStream {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AppUser.fromMap({'user_id': doc.id, ...doc.data()}))
            .toList());
  }

  static Future<void> toggleAdminStatus(String userId, bool currentStatus) async {
    await _firestore.collection('users').doc(userId).update({
      'is_admin': !currentStatus,
    });
  }

  // ── Global Counter Stats ─────────────────────────────────────

  static Stream<Map<String, dynamic>> get globalCounterStream {
    return _firestore
        .collection('global_counter')
        .doc('main')
        .snapshots()
        .map((snap) => snap.data() ?? {});
  }

  // ── User Count & Leaderboard ─────────────────────────────────

  static Stream<int> get usersCountStream {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  static Stream<List<AppUser>> get leaderboardUsersStream {
    return _firestore
        .collection('users')
        .orderBy('current_streak', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AppUser.fromMap({'user_id': doc.id, ...doc.data()}))
            .toList());
  }

  static Future<int> getTotalUserCount() async {
    try {
      final snap = await _firestore.collection('users').count().get();
      return snap.count ?? 0;
    } catch (e) {
      if (kDebugMode) print('AdminService.getTotalUserCount error: $e');
      return 0;
    }
  }
}

