import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/models/event_model.dart';
import '../core/models/masail_model.dart';
import '../core/models/aqaid_model.dart';
import '../core/models/daily_content_model.dart';
import '../core/models/question_model.dart';
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
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => EventModel.fromMap(doc.id, doc.data()))
              .toList();

          list.sort((a, b) {
            final bool aHasOrder = a.order > 0;
            final bool bHasOrder = b.order > 0;

            if (aHasOrder && bHasOrder) {
              if (a.order != b.order) return a.order.compareTo(b.order);
            } else if (aHasOrder) {
              return -1;
            } else if (bHasOrder) {
              return 1;
            }

            final aCreated = a.createdAt;
            final bCreated = b.createdAt;
            final DateTime aTime = aCreated is Timestamp
                ? aCreated.toDate()
                : (aCreated is String ? DateTime.tryParse(aCreated) ?? DateTime.fromMillisecondsSinceEpoch(0) : DateTime.fromMillisecondsSinceEpoch(0));
            final DateTime bTime = bCreated is Timestamp
                ? bCreated.toDate()
                : (bCreated is String ? DateTime.tryParse(bCreated) ?? DateTime.fromMillisecondsSinceEpoch(0) : DateTime.fromMillisecondsSinceEpoch(0));
            return aTime.compareTo(bTime);
          });

          return list;
        });
  }

  /// Batch updates the arrangement order numbers of events in Firestore.
  static Future<void> updateEventsOrder(List<EventModel> reorderedEvents) async {
    final batch = _firestore.batch();
    for (int i = 0; i < reorderedEvents.length; i++) {
      final event = reorderedEvents[i];
      final newOrder = i + 1; // 1-indexed arrangement numbering (#1, #2, #3...)
      final docRef = _firestore.collection('events').doc(event.id);
      batch.update(docRef, {
        'order': newOrder,
        'updated_at': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    if (kDebugMode) {
      print('AdminService: Batch updated arrangement order for ${reorderedEvents.length} events.');
    }
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

    int assignedOrder = event.order;
    if (assignedOrder <= 0) {
      try {
        final existingSnap = await _firestore.collection('events').get();
        assignedOrder = existingSnap.docs.length + 1;
      } catch (_) {
        assignedOrder = 1;
      }
    }

    final docRef = await _firestore.collection('events').add({
      'title': event.title,
      'title_ur': event.titleUr,
      'date_time': event.dateTime,
      'location': event.location,
      'location_ur': event.locationUr,
      'status': event.status,
      'description': event.description,
      'description_ur': event.descriptionUr,
      'order': assignedOrder,
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
    final type = item.type.toLowerCase();
    if (item.isTopicOfTheDay) {
      // Unset previous topic of the day for the SAME TYPE only (Hadith or Ayat)
      final snap = await _firestore
          .collection('daily_content')
          .where('type', isEqualTo: type)
          .where('is_topic_of_the_day', isEqualTo: true)
          .get();
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
      String? type = data['type'] as String?;
      if (type == null) {
        final existingDoc = await _firestore.collection('daily_content').doc(id).get();
        type = existingDoc.data()?['type'] as String? ?? 'hadith';
      }
      final snap = await _firestore
          .collection('daily_content')
          .where('type', isEqualTo: type.toLowerCase())
          .where('is_topic_of_the_day', isEqualTo: true)
          .get();
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

  /// Toggle active state of a single daily content entry without altering others
  static Future<void> toggleDailyContentActive(String id, bool isActive) async {
    await _firestore.collection('daily_content').doc(id).update({
      'is_active': isActive,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> setActiveDailyContent(String id) async {
    final doc = await _firestore.collection('daily_content').doc(id).get();
    final currentActive = doc.data()?['is_active'] as bool? ?? true;
    await toggleDailyContentActive(id, !currentActive);
  }

  /// Sets or unsets Topic of the Day for a specific entry.
  /// If set to true, only unsets previous Topic of the Day for the same type (Hadith vs Ayat).
  static Future<void> setTopicOfTheDay(String id, bool isTopic, {String? type}) async {
    if (isTopic) {
      String itemType = type ?? '';
      if (itemType.isEmpty) {
        final doc = await _firestore.collection('daily_content').doc(id).get();
        itemType = (doc.data()?['type'] as String? ?? 'hadith').toLowerCase();
      }
      final snap = await _firestore
          .collection('daily_content')
          .where('type', isEqualTo: itemType)
          .where('is_topic_of_the_day', isEqualTo: true)
          .get();
      final batch = _firestore.batch();
      for (var doc in snap.docs) {
        if (doc.id != id) {
          batch.update(doc.reference, {'is_topic_of_the_day': false});
        }
      }
      batch.update(_firestore.collection('daily_content').doc(id), {
        'is_topic_of_the_day': true,
        'is_active': true,
        'updated_at': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    } else {
      await _firestore.collection('daily_content').doc(id).update({
        'is_topic_of_the_day': false,
        'updated_at': FieldValue.serverTimestamp(),
      });
    }
  }


  // ── Push Notifications ─────────────────────────────────────

  static Stream<List<Map<String, dynamic>>> get notificationsStream {
    return _firestore
        .collection('notifications')
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      list.sort((a, b) {
        final aTime = a['sent_at'];
        final bTime = b['sent_at'];
        DateTime aDate = aTime is Timestamp
            ? aTime.toDate()
            : (aTime is String ? DateTime.tryParse(aTime) ?? DateTime.fromMillisecondsSinceEpoch(0) : DateTime.fromMillisecondsSinceEpoch(0));
        DateTime bDate = bTime is Timestamp
            ? bTime.toDate()
            : (bTime is String ? DateTime.tryParse(bTime) ?? DateTime.fromMillisecondsSinceEpoch(0) : DateTime.fromMillisecondsSinceEpoch(0));
        return bDate.compareTo(aDate); // newest first
      });
      return list;
    }).handleError((e) {
      if (kDebugMode) print('AdminService.notificationsStream error: $e');
      return <Map<String, dynamic>>[];
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
    final data = <String, dynamic>{
      'title': title.trim(),
      'title_ur': (titleUr != null && titleUr.trim().isNotEmpty) ? titleUr.trim() : title.trim(),
      'body': body.trim(),
      'body_ur': (bodyUr != null && bodyUr.trim().isNotEmpty) ? bodyUr.trim() : body.trim(),
      'target': target,
      'type': type,
      'sent_at': FieldValue.serverTimestamp(),
    };
    if (eventId != null && eventId.isNotEmpty) {
      data['event_id'] = eventId;
    }
    await _firestore.collection('notifications').add(data);
  }

  static Future<void> deleteNotification(String id) async {
    await _firestore.collection('notifications').doc(id).delete();
  }

  static Future<void> clearAllNotifications() async {
    final snap = await _firestore.collection('notifications').get();
    final batch = _firestore.batch();
    for (var doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }


  // ── Questions & Answers (Q&A) Management ────────────────────

  static Stream<List<QuestionModel>> get questionsStream {
    return _firestore
        .collection('user_questions')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => QuestionModel.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime); // Newest first
      });
      return list;
    });
  }

  static Stream<int> get pendingQuestionsCountStream {
    return _firestore
        .collection('user_questions')
        .where('status', isEqualTo: 'Pending')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Answers a question and automatically dispatches a notification to the user.
  static Future<void> answerQuestion({
    required String questionId,
    required String answer,
    required bool isPublic,
    required String answeredBy,
  }) async {
    final doc = await _firestore.collection('user_questions').doc(questionId).get();
    if (!doc.exists || doc.data() == null) return;

    final question = QuestionModel.fromMap(doc.id, doc.data()!);

    await _firestore.collection('user_questions').doc(questionId).update({
      'status': 'Answered',
      'answer': answer.trim(),
      'answered_by': answeredBy,
      'answered_at': FieldValue.serverTimestamp(),
      'is_public': isPublic,
      'updated_at': FieldValue.serverTimestamp(),
    });

    // Automated notification to the user
    try {
      if (question.userId.isNotEmpty && question.userId != 'guest') {
        await _firestore.collection('notifications').add({
          'title': 'Your Question Has Been Answered! ✍️',
          'title_ur': 'آپ کے سوال کا جواب دے دیا گیا ہے! ✍️',
          'body': 'Admin has responded to your question regarding ${question.category}.',
          'body_ur': 'ایڈمن نے ${QuestionModel.getCategoryUrdu(question.category)} کے متعلق آپ کے سوال کا جواب فراہم کر دیا ہے۔',
          'target': question.userId,
          'type': 'question_answered',
          'question_id': questionId,
          'sent_at': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (kDebugMode) print('AdminService.answerQuestion notification error: $e');
    }
  }

  static Future<void> deleteQuestion(String id) async {
    await _firestore.collection('user_questions').doc(id).delete();
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
