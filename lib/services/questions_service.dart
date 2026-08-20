import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../core/models/question_model.dart';

class QuestionsService {
  static final _firestore = FirebaseFirestore.instance;

  /// Submits a user question to Firestore, captures FCM token for 1-to-1 reply notifications,
  /// and dispatches an automated in-app confirmation notification.
  static Future<String> submitQuestion({
    required String category,
    required String question,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'guest';
    final userEmail = user?.email ?? 'guest@islamicapp.org';
    final userName = user?.displayName ?? (userEmail.contains('@') ? userEmail.split('@').first : 'Beloved User');

    String? fcmToken;
    try {
      if (!kIsWeb) {
        fcmToken = await FirebaseMessaging.instance.getToken();
      }
    } catch (e) {
      if (kDebugMode) print('QuestionsService: Error fetching FCM token: $e');
    }

    final docRef = await _firestore.collection('user_questions').add({
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'fcm_token': fcmToken,
      'category': category,
      'question': question.trim(),
      'status': 'Pending',
      'answer': null,
      'answered_by': null,
      'answered_at': null,
      'is_public': false,
      'created_at': FieldValue.serverTimestamp(),
    });

    // Automated In-App Confirmation Notification to the user
    try {
      await _firestore.collection('notifications').add({
        'title': 'Question Received / سوال موصول ہوا',
        'title_ur': 'سوال موصول ہوا',
        'body': 'We have received your question. You will receive an answer within 24 hours.',
        'body_ur': 'آپ کا سوال موصول ہو چکا ہے۔ ایڈمن ٹیم 24 گھنٹوں کے اندر جواب فراہم کر دے گی۔',
        'target': userId,
        'type': 'question_received',
        'question_id': docRef.id,
        'sent_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) print('QuestionsService: Error sending submission notification: $e');
    }

    return docRef.id;
  }

  /// Live stream of questions submitted by a specific user (excluding deleted ones).
  static Stream<List<QuestionModel>> getUserQuestionsStream(String userId) {
    try {
      return _firestore
          .collection('user_questions')
          .where('user_id', isEqualTo: userId)
          .snapshots()
          .map((snap) {
        final list = snap.docs
            .map((doc) => QuestionModel.fromMap(doc.id, doc.data()))
            .where((q) => !q.isDeletedByUser)
            .toList();
        list.sort((a, b) {
          final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime); // Newest first
        });
        return list;
      }).handleError((e) {
        if (kDebugMode) print('QuestionsService error: $e');
        return <QuestionModel>[];
      });
    } catch (_) {
      return Stream.value(<QuestionModel>[]);
    }
  }

  /// Live stream of all questions (legacy fallback).
  static Stream<List<QuestionModel>> get publicAnsweredQuestionsStream {
    try {
      return _firestore
          .collection('user_questions')
          .where('status', isEqualTo: 'Answered')
          .snapshots()
          .map((snap) {
        final list = snap.docs
            .map((doc) => QuestionModel.fromMap(doc.id, doc.data()))
            .where((q) => !q.isDeletedByUser)
            .toList();
        list.sort((a, b) {
          final aTime = a.answeredAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.answeredAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });
        return list;
      }).handleError((e) {
        if (kDebugMode) print('QuestionsService error: $e');
        return <QuestionModel>[];
      });
    } catch (_) {
      return Stream.value(<QuestionModel>[]);
    }
  }

  /// Soft deletes a user question from app view while retaining it in Admin view.
  static Future<void> deleteQuestion(String questionId) async {
    try {
      await _firestore.collection('user_questions').doc(questionId).update({
        'is_deleted_by_user': true,
        'deleted_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) print('QuestionsService.deleteQuestion error: $e');
      rethrow;
    }
  }

  /// Explicit alias for deleting user question.
  static Future<void> deleteUserQuestion(String questionId) => deleteQuestion(questionId);
}
