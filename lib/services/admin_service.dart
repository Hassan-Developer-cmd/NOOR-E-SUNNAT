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

  static Future<void> addEvent(EventModel event) async {
    await _firestore.collection('events').add(event.toMap());
  }

  static Future<void> updateEvent(String id, Map<String, dynamic> data) async {
    await _firestore.collection('events').doc(id).update({
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteEvent(String id) async {
    await _firestore.collection('events').doc(id).delete();
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
        .map((snap) => snap.docs
            .map((doc) => DailyContentModel.fromMap(doc.id, doc.data()))
            .toList());
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

  static Future<void> setActiveDailyContent(String id) async {
    final batch = _firestore.batch();
    final allSnap = await _firestore.collection('daily_content').get();
    for (var doc in allSnap.docs) {
      batch.update(doc.reference, {'is_active': doc.id == id});
    }
    await batch.commit();
  }

  // ── Push Notifications ─────────────────────────────────────

  static Stream<List<Map<String, dynamic>>> get notificationsStream {
    return _firestore
        .collection('notifications')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  static Future<void> sendNotification({
    required String title,
    required String body,
    String target = 'all_users',
  }) async {
    await _firestore.collection('notifications').add({
      'title': title,
      'body': body,
      'target': target,
      'sent_at': FieldValue.serverTimestamp(),
    });
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

