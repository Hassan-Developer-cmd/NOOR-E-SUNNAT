import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'fcm_v1_service.dart';
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
      'date': event.dateTime,
      'location': event.location,
      'location_ur': event.locationUr,
      'status': event.status,
      'description': event.description,
      'description_ur': event.descriptionUr,
      'image_type': event.imageType,
      'imageType': event.imageType,
      'image_url': event.imageUrl,
      'imageUrl': event.imageUrl,
      'image_base64': event.imageBase64,
      'imageBase64': event.imageBase64,
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
    final shouldNotify = newStatus.trim().toLowerCase() != oldStatus.trim().toLowerCase() &&
        newStatus.trim().toLowerCase() != (lastNotified?.trim().toLowerCase() ?? '');

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

    await _firestore.collection('events').doc(eventId).set(updateData, SetOptions(merge: true));

    // If status changed and hasn't been notified yet, dispatch tailored notification in background
    if (shouldNotify) {
      unawaited(() async {
        try {
          final title = _getNotificationTitleForStatus(event!.title, newStatus);
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
        } catch (e) {
          if (kDebugMode) print('Event notification error: $e');
        }
      }());
    }
  }

  /// Updates event document with deduplicated status checking and resilient merge.
  static Future<void> updateEvent(String id, Map<String, dynamic> data) async {
    try {
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

      if (newStatus != null && newStatus.trim().toLowerCase() != currentEvent.status.trim().toLowerCase()) {
        await updateEventStatus(id, newStatus, currentEvent: currentEvent);
      }

      await _firestore.collection('events').doc(id).set({
        ...data,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Fallback write directly ensuring the update persists regardless of read failure
      await _firestore.collection('events').doc(id).set({
        ...data,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
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
    await _firestore.collection('daily_content').add(item.toMap());
  }

  static Future<void> updateDailyContent(String id, Map<String, dynamic> data) async {
    await _firestore.collection('daily_content').doc(id).update({
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteDailyContent(String id) async {
    await _firestore.collection('daily_content').doc(id).delete();
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

  /// Retrieves configured FCM Server Key from Firestore app_config.
  static Future<String?> getFcmServerKey() async {
    try {
      final doc = await _firestore.collection('app_config').doc('fcm_settings').get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['server_key'] as String?;
      }
    } catch (_) {}
    return null;
  }

  /// Saves FCM Server Key in Firestore app_config.
  static Future<void> saveFcmServerKey(String key) async {
    await _firestore.collection('app_config').doc('fcm_settings').set({
      'server_key': key.trim(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<String> sendNotification({
    required String title,
    required String body,
    String? titleUr,
    String? bodyUr,
    String target = 'all_users',
    String type = 'broadcast',
    String? eventId,
  }) async {
    final cleanTitle = title.trim();
    final cleanBody = body.trim();
    final cleanTitleUr = (titleUr != null && titleUr.trim().isNotEmpty) ? titleUr.trim() : cleanTitle;
    final cleanBodyUr = (bodyUr != null && bodyUr.trim().isNotEmpty) ? bodyUr.trim() : cleanBody;

    final data = <String, dynamic>{
      'title': cleanTitle,
      'title_ur': cleanTitleUr,
      'body': cleanBody,
      'body_ur': cleanBodyUr,
      'target': target,
      'type': type,
      'sent_at': FieldValue.serverTimestamp(),
    };
    if (eventId != null && eventId.isNotEmpty) {
      data['event_id'] = eventId;
    }

    // 1. Write to Firestore notifications collection (for in-app notification center)
    final docRef = await _firestore.collection('notifications').add(data);

    String fcmResult = 'saved_to_database';

    // 2. Direct FCM v1 HTTP API Dispatch (Service Account + OAuth2 Bearer Token)
    try {
      final v1Sent = await FcmV1Service.sendBroadcast(
        title: cleanTitle,
        body: cleanBody,
        topic: target,
        type: type,
        id: docRef.id,
        route: '/home',
        eventId: eventId,
      );
      if (v1Sent) {
        fcmResult = 'fcm_v1_success';
      }
    } catch (e) {
      if (kDebugMode) print('AdminService FCM v1 dispatch error: $e');
    }

    // 3. Direct FCM Legacy REST API Trigger (Fallback if server key is configured)
    final serverKey = await getFcmServerKey();
    if (serverKey != null && serverKey.isNotEmpty && fcmResult != 'fcm_v1_success') {
      try {
        final fcmUrl = Uri.parse('https://fcm.googleapis.com/fcm/send');
        final fcmRes = await http.post(
          fcmUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'key=$serverKey',
          },
          body: jsonEncode({
            'to': '/topics/$target',
            'priority': 'high',
            'notification': {
              'title': cleanTitle,
              'body': cleanBody,
              'sound': 'default',
              'android_channel_id': 'high_importance_channel',
            },
            'data': {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'id': docRef.id,
              'type': type,
              'title': cleanTitle,
              'body': cleanBody,
              'route': '/home',
              'eventId': eventId ?? '',
            },
          }),
        );
        if (kDebugMode) {
          print('Direct FCM REST response: ${fcmRes.statusCode} ${fcmRes.body}');
        }
        if (fcmRes.statusCode == 200) {
          fcmResult = 'fcm_sent_success';
        }
      } catch (e) {
        if (kDebugMode) print('Direct FCM REST error: $e');
      }
    }

    // 4. Parallel Cloud Function HTTP Endpoint Trigger (Fallback)
    try {
      final url = Uri.parse(
        'https://us-central1-islamic-app-ed1ed.cloudfunctions.net/sendFCMBroadcastHttp',
      );
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': cleanTitle,
          'body': cleanBody,
          'target': target,
          'type': type,
          'id': docRef.id,
          'eventId': eventId ?? '',
        }),
      );
    } catch (_) {}

    return fcmResult;
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
        return bTime.compareTo(aTime); // newest first
      });
      return list;
    }).handleError((e) {
      if (kDebugMode) print('AdminService.questionsStream error: $e');
      return <QuestionModel>[];
    });
  }

  static Stream<int> get pendingQuestionsCountStream {
    return _firestore
        .collection('user_questions')
        .where('status', isEqualTo: 'Pending')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Answers a question and automatically dispatches a targeted 1-to-1 notification to the author.
  static Future<void> answerQuestion({
    required String questionId,
    required String answer,
    bool isPublic = false,
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
      'updated_at': FieldValue.serverTimestamp(),
      'is_public': isPublic,
    });

    // Automated targeted 1-to-1 notification strictly to the author
    try {
      if (question.userId.isNotEmpty && question.userId != 'guest') {
        final notifData = <String, dynamic>{
          'title': 'آپ کے سوال کا جواب دے دیا گیا ہے / Question Answered',
          'title_ur': 'آپ کے سوال کا جواب دے دیا گیا ہے! ✍️',
          'title_en': 'Your Question Has Been Answered! ✍️',
          'body': 'علمائے کرام نے آپ کے سوال کا جواب فراہم کر دیا ہے۔ دیکھنے کے لیے ٹیپ کریں۔',
          'body_ur': 'علمائے کرام نے آپ کے سوال کا جواب فراہم کر دیا ہے۔ دیکھنے کے لیے ٹیپ کریں۔',
          'body_en': 'Admin has responded to your question regarding ${question.category}. Tap to view.',
          'target': question.userId,
          'user_id': question.userId,
          'type': 'question_answered',
          'question_id': questionId,
          'sent_at': FieldValue.serverTimestamp(),
        };

        if (question.fcmToken != null && question.fcmToken!.isNotEmpty) {
          notifData['fcm_token'] = question.fcmToken;
          notifData['token'] = question.fcmToken;
        }

        await _firestore.collection('notifications').add(notifData);

        // Direct targeted 1-to-1 FCM v1 push notification
        if (question.fcmToken != null && question.fcmToken!.isNotEmpty) {
          try {
            await FcmV1Service.sendToToken(
              fcmToken: question.fcmToken!,
              title: 'آپ کے سوال کا جواب دے دیا گیا ہے / Question Answered',
              body: 'علمائے کرام نے آپ کے سوال کا جواب فراہم کر دیا ہے۔ دیکھنے کے لیے ٹیپ کریں۔',
              type: 'question_answered',
              questionId: questionId,
            );
          } catch (_) {}
        } else {
          try {
            await FcmV1Service.sendBroadcast(
              topic: 'user_${question.userId}',
              title: 'آپ کے سوال کا جواب دے دیا گیا ہے / Question Answered',
              body: 'علمائے کرام نے آپ کے سوال کا جواب فراہم کر دیا ہے۔ دیکھنے کے لیے ٹیپ کریں۔',
              type: 'question_answered',
              questionId: questionId,
            );
          } catch (_) {}
        }

        // Direct 1-to-1 FCM Legacy REST Dispatch (if server key configured)
        final serverKey = await getFcmServerKey();
        if (serverKey != null && serverKey.isNotEmpty) {
          try {
            final targetRecipient = (question.fcmToken != null && question.fcmToken!.isNotEmpty)
                ? question.fcmToken!
                : '/topics/user_${question.userId}';

            await http.post(
              Uri.parse('https://fcm.googleapis.com/fcm/send'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'key=$serverKey',
              },
              body: jsonEncode({
                'to': targetRecipient,
                'priority': 'high',
                'notification': {
                  'title': 'آپ کے سوال کا جواب دے دیا گیا ہے / Question Answered',
                  'body': 'علمائے کرام نے آپ کے سوال کا جواب فراہم کر دیا ہے۔ دیکھنے کے لیے ٹیپ کریں۔',
                  'sound': 'default',
                  'android_channel_id': 'high_importance_channel',
                },
                'data': {
                  'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                  'type': 'question_answered',
                  'route': '/qna',
                  'questionId': questionId,
                },
              }),
            );
          } catch (_) {}
        }

        // Direct 1-to-1 FCM HTTP Bridge Trigger (Fallback)
        try {
          final url = Uri.parse(
            'https://us-central1-islamic-app-ed1ed.cloudfunctions.net/sendFCMBroadcastHttp',
          );
          await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'title': 'آپ کے سوال کا جواب دے دیا گیا ہے / Question Answered',
              'body': 'علمائے کرام نے آپ کے سوال کا جواب فراہم کر دیا ہے۔ دیکھنے کے لیے ٹیپ کریں۔',
              'target': question.userId,
              'fcmToken': question.fcmToken,
              'type': 'question_answered',
              'questionId': questionId,
            }),
          );
        } catch (_) {}
      }
    } catch (e) {
      if (kDebugMode) print('AdminService.answerQuestion notification error: $e');
    }
  }

  /// Permanently deletes a user question from Firestore.
  static Future<void> deleteQuestion(String questionId) async {
    await _firestore.collection('user_questions').doc(questionId).delete();
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
        .collection('counters')
        .doc('durood_stats')
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
