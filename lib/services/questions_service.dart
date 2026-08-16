import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../core/models/question_model.dart';

class QuestionsService {
  static final _firestore = FirebaseFirestore.instance;

  /// Submits a user question to Firestore and dispatches an automated in-app confirmation notification.
  static Future<String> submitQuestion({
    required String category,
    required String question,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'guest';
    final userEmail = user?.email ?? 'guest@islamicapp.org';
    final userName = user?.displayName ?? (userEmail.contains('@') ? userEmail.split('@').first : 'Beloved User');

    final docRef = await _firestore.collection('user_questions').add({
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
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

  /// Live stream of questions submitted by a specific user.
  static Stream<List<QuestionModel>> getUserQuestionsStream(String userId) {
    return _firestore
        .collection('user_questions')
        .where('user_id', isEqualTo: userId)
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

  /// Live stream of public answered questions for all users.
  static Stream<List<QuestionModel>> get publicAnsweredQuestionsStream {
    return _firestore
        .collection('user_questions')
        .where('status', isEqualTo: 'Answered')
        .where('is_public', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => QuestionModel.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) {
        final aTime = a.answeredAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.answeredAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  /// Deletes a question from Firestore by ID.
  static Future<void> deleteQuestion(String questionId) async {
    try {
      await _firestore.collection('user_questions').doc(questionId).delete();
    } catch (e) {
      if (kDebugMode) print('QuestionsService.deleteQuestion error: $e');
      rethrow;
    }
  }
}
