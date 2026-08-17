import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/models/daily_content_model.dart';
import 'package:islamic_app/services/content_service.dart';

void main() {
  group('Daily Content & Topic of the Day Tests', () {
    test('DailyContentModel resolves hadith, ayat, and topicOfTheDay correctly', () {
      final hadith = DailyContentModel(
        id: '1',
        type: 'hadith',
        title: 'Hadith Title',
        titleUr: 'حدیث عنوان',
        content: 'Hadith English',
        contentUr: 'حدیث اردو',
        citation: 'Sahih Bukhari 1',
        citationUr: 'صحیح البخاری ۱',
      );

      expect(hadith.isHadith, isTrue);
      expect(hadith.isAyat, isFalse);
      expect(hadith.isTopicOfTheDay, isFalse);
      expect(hadith.getTitle(false), 'Hadith Title');
      expect(hadith.getTitle(true), 'حدیث عنوان');

      final ayat = DailyContentModel(
        id: '2',
        type: 'ayat',
        title: 'Ayah Title',
        titleUr: 'آیت عنوان',
        content: 'Ayah English',
        contentUr: 'آیت اردو',
        citation: 'Surah Al-Ahzab 33:56',
        citationUr: 'سورۃ الاحزاب ۳۳:۵۶',
      );

      expect(ayat.isAyat, isTrue);
      expect(ayat.isHadith, isFalse);
      expect(ayat.isTopicOfTheDay, isFalse);

      final topic = DailyContentModel(
        id: '3',
        type: 'topicOfTheDay',
        title: 'Friday Salawat Topic',
        titleUr: 'جمعہ کے فضائل',
        content: 'Topic English',
        contentUr: 'موضوع اردو',
        citation: 'Dalail al-Khayrat',
        citationUr: 'دلائل الخیرات',
      );

      expect(topic.isTopicOfTheDay, isTrue);
      expect(topic.getTitle(false), 'Friday Salawat Topic');
      expect(topic.getTitle(true), 'جمعہ کے فضائل');
    });

    test('ContentService default entries are valid and populated', () {
      expect(ContentService.defaultHadith.id, isNotEmpty);
      expect(ContentService.defaultAyat.id, isNotEmpty);
      expect(ContentService.defaultTopicOfTheDay.id, isNotEmpty);
      expect(ContentService.defaultTopicOfTheDay.isTopicOfTheDay, isTrue);
    });

    test('DailyContentModel fromMap and toMap preserve Topic of the Day', () {
      final map = {
        'type': 'topicOfTheDay',
        'title': 'Blessings of Salawat',
        'title_ur': 'درود پاک کی برکات',
        'arabic_text': 'الصلاة على النبي',
        'content': 'Reciting salawat brings barakah.',
        'content_ur': 'درود پڑھنا برکت کا باعث ہے۔',
        'citation': 'Ihya Ulum al-Din',
        'citation_ur': 'احیاء علوم الدین',
        'is_active': true,
        'is_topic_of_the_day': true,
      };

      final model = DailyContentModel.fromMap('topic_doc_1', map);
      expect(model.id, 'topic_doc_1');
      expect(model.isTopicOfTheDay, isTrue);
      expect(model.title, 'Blessings of Salawat');
      expect(model.titleUr, 'درود پاک کی برکات');

      final serialized = model.toMap();
      expect(serialized['type'], 'topicOfTheDay');
      expect(serialized['is_topic_of_the_day'], isTrue);
    });
  });
}
