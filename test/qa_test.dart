import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/models/question_model.dart';
import 'package:islamic_app/core/localization/app_translations.dart';

void main() {
  group('Q&A Simplification and Soft-Delete Tests', () {
    test('QuestionModel handles isDeletedByUser correctly in deserialization and serialization', () {
      final data = {
        'user_id': 'user_123',
        'user_name': 'Brother Ali',
        'user_email': 'ali@test.com',
        'question': 'How to perform Wuzu correctly?',
        'category': 'Wuzu',
        'status': 'Answered',
        'answer': 'Wash hands, rinse mouth and nose, wash face, arms, wipe head, wash feet.',
        'answered_by': 'Mufti Sahab',
        'is_public': false,
        'is_deleted_by_user': true,
      };

      final q = QuestionModel.fromMap('q_1', data);
      expect(q.isDeletedByUser, isTrue);
      expect(q.isAnswered, isTrue);
      expect(q.isPending, isFalse);
      expect(q.category, 'Wuzu');

      final map = q.toMap();
      expect(map['is_deleted_by_user'], isTrue);
      expect(map['user_name'], 'Brother Ali');
    });

    test('QuestionModel defaults isDeletedByUser to false when omitted', () {
      final data = {
        'user_id': 'user_456',
        'user_name': 'Sister Fatima',
        'user_email': 'fatima@test.com',
        'question': 'What are the rules of Fasting?',
        'category': 'Roza',
        'status': 'Pending',
      };

      final q = QuestionModel.fromMap('q_2', data);
      expect(q.isDeletedByUser, isFalse);
      expect(q.isPending, isTrue);
      expect(q.isAnswered, isFalse);
    });

    test('AppTranslations contains all reactive Q&A keys for both English and Urdu', () {
      final en = AppTranslations.translations['en']!;
      final ur = AppTranslations.translations['ur']!;

      expect(en['my_questions_title'], isNotNull);
      expect(ur['my_questions_title'], isNotNull);

      expect(en['search_my_questions_hint'], isNotNull);
      expect(ur['search_my_questions_hint'], isNotNull);

      expect(en['delete_question'], isNotNull);
      expect(ur['delete_question'], isNotNull);

      expect(en['delete_question_confirm'], isNotNull);
      expect(ur['delete_question_confirm'], isNotNull);

      expect(en['status_answered'], contains('Answered'));
      expect(ur['status_answered'], contains('جواب'));

      expect(en['status_pending_24h'], contains('Pending'));
      expect(ur['status_pending_24h'], contains('زیرِ غور'));
    });
  });
}
