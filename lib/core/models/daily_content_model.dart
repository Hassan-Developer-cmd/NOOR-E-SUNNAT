import 'package:cloud_firestore/cloud_firestore.dart';

class DailyContentModel {
  final String id;
  final String type; // 'hadith' or 'ayat'
  final String title;
  final String titleUr;
  final String arabicText;
  final String content;
  final String contentUr;
  final String citation;
  final String citationUr;
  final String imageUrl;
  final bool isActive;
  final bool isTopicOfTheDay;
  final DateTime? scheduledDate;
  final DateTime? createdAt;

  const DailyContentModel({
    required this.id,
    this.type = 'hadith',
    required this.title,
    this.titleUr = '',
    this.arabicText = '',
    required this.content,
    this.contentUr = '',
    required this.citation,
    this.citationUr = '',
    this.imageUrl = '',
    this.isActive = true,
    this.isTopicOfTheDay = false,
    this.scheduledDate,
    this.createdAt,
  });

  factory DailyContentModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime? date;
    final rawDate = map['scheduled_date'] ?? map['scheduledDate'] ?? map['date'];
    if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else if (rawDate is String && rawDate.isNotEmpty) {
      date = DateTime.tryParse(rawDate);
    }

    DateTime? created;
    final rawCreated = map['created_at'] ?? map['createdAt'] ?? map['timestamp'];
    if (rawCreated is Timestamp) {
      created = rawCreated.toDate();
    } else if (rawCreated is String && rawCreated.isNotEmpty) {
      created = DateTime.tryParse(rawCreated);
    }

    // Dynamic field resolving for 100% Firestore schema compatibility
    final resolvedTitle = (map['title'] ??
            map['title_en'] ??
            map['titleEn'] ??
            map['topic'] ??
            map['topic_en'] ??
            map['topicEn'] ??
            '') as String;

    final resolvedTitleUr = (map['title_ur'] ??
            map['titleUr'] ??
            map['title_urdu'] ??
            map['topic_ur'] ??
            map['topicUr'] ??
            map['topic_urdu'] ??
            map['topicUrdu'] ??
            map['urdu_title'] ??
            map['urduTitle'] ??
            '') as String;

    final resolvedArabic = (map['arabic_text'] ??
            map['arabicText'] ??
            map['arabic'] ??
            map['matn'] ??
            map['text_ar'] ??
            '') as String;

    final resolvedContent = (map['content'] ??
            map['content_en'] ??
            map['contentEn'] ??
            map['text'] ??
            map['text_en'] ??
            map['textEn'] ??
            map['translation'] ??
            map['translation_en'] ??
            map['translationEn'] ??
            map['english_text'] ??
            map['englishText'] ??
            map['body'] ??
            map['body_en'] ??
            '') as String;

    final resolvedContentUr = (map['content_ur'] ??
            map['contentUr'] ??
            map['content_urdu'] ??
            map['text_ur'] ??
            map['textUr'] ??
            map['text_urdu'] ??
            map['urduText'] ??
            map['urdu_text'] ??
            map['translation_ur'] ??
            map['translationUr'] ??
            map['translation_urdu'] ??
            map['translationUrdu'] ??
            map['urdu_translation'] ??
            map['urdu'] ??
            map['body_ur'] ??
            map['body_urdu'] ??
            '') as String;

    final resolvedCitation = (map['citation'] ??
            map['citation_en'] ??
            map['citationEn'] ??
            map['book'] ??
            map['book_en'] ??
            map['reference'] ??
            map['reference_en'] ??
            map['referenceEn'] ??
            map['source'] ??
            '') as String;

    final resolvedCitationUr = (map['citation_ur'] ??
            map['citationUr'] ??
            map['citation_urdu'] ??
            map['book_ur'] ??
            map['bookUr'] ??
            map['book_urdu'] ??
            map['reference_ur'] ??
            map['referenceUr'] ??
            map['reference_urdu'] ??
            map['source_ur'] ??
            map['source_urdu'] ??
            '') as String;

    return DailyContentModel(
      id: id,
      type: map['type'] as String? ?? 'hadith',
      title: resolvedTitle,
      titleUr: resolvedTitleUr,
      arabicText: resolvedArabic,
      content: resolvedContent,
      contentUr: resolvedContentUr,
      citation: resolvedCitation,
      citationUr: resolvedCitationUr,
      imageUrl: map['image_url'] as String? ?? map['imageUrl'] as String? ?? '',
      isActive: map['is_active'] as bool? ?? map['isActive'] as bool? ?? true,
      isTopicOfTheDay: map['is_topic_of_the_day'] as bool? ??
          map['isTopicOfTheDay'] as bool? ??
          false,
      scheduledDate: date,
      createdAt: created,
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type,
        'title': title,
        'title_ur': titleUr,
        'arabic_text': arabicText,
        'content': content,
        'content_ur': contentUr,
        'citation': citation,
        'citation_ur': citationUr,
        'image_url': imageUrl,
        'is_active': isActive,
        'is_topic_of_the_day': isTopicOfTheDay,
        'scheduled_date': scheduledDate != null
            ? Timestamp.fromDate(scheduledDate!)
            : FieldValue.serverTimestamp(),
        'created_at': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  DailyContentModel copyWith({
    String? id,
    String? type,
    String? title,
    String? titleUr,
    String? arabicText,
    String? content,
    String? contentUr,
    String? citation,
    String? citationUr,
    String? imageUrl,
    bool? isActive,
    bool? isTopicOfTheDay,
    DateTime? scheduledDate,
    DateTime? createdAt,
  }) {
    return DailyContentModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      titleUr: titleUr ?? this.titleUr,
      arabicText: arabicText ?? this.arabicText,
      content: content ?? this.content,
      contentUr: contentUr ?? this.contentUr,
      citation: citation ?? this.citation,
      citationUr: citationUr ?? this.citationUr,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      isTopicOfTheDay: isTopicOfTheDay ?? this.isTopicOfTheDay,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isHadith => type.toLowerCase() == 'hadith';
  bool get isAyat => type.toLowerCase() == 'ayat';

  static bool _containsUrduOrArabic(String text) {
    return RegExp(r'[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]').hasMatch(text);
  }

  String getTitle(bool isUrdu) {
    if (isUrdu) {
      if (titleUr.isNotEmpty) return titleUr;
      if (title.isNotEmpty && _containsUrduOrArabic(title)) return title;
      if (isTopicOfTheDay) return 'آج کا خاص موضوع';
      return isAyat ? 'آج کی آیتِ مبارکہ' : 'آج کی حدیث مبارکہ';
    } else {
      if (title.isNotEmpty && !_containsUrduOrArabic(title)) return title;
      if (isTopicOfTheDay) return 'Topic of the day';
      return isAyat ? 'DAILY AYAT' : 'DAILY HADITH';
    }
  }

  String getContent(bool isUrdu) {
    if (isUrdu) {
      if (contentUr.isNotEmpty) return contentUr;
      if (content.isNotEmpty && _containsUrduOrArabic(content)) return content;
      if (content.isNotEmpty) return content;
      return 'جو شخص مجھ پر ایک بار درود بھیجتا ہے، اللہ تعالیٰ اس پر دس رحمتیں نازل فرماتا ہے۔';
    } else {
      if (content.isNotEmpty && !_containsUrduOrArabic(content)) return content;
      if (content.isNotEmpty) return content;
      if (contentUr.isNotEmpty) return contentUr;
      return 'Whoever sends blessings upon me once, Allah will send blessings upon him ten times.';
    }
  }

  String getCitation(bool isUrdu) {
    if (isUrdu) {
      if (citationUr.isNotEmpty) {
        return citationUr.startsWith('حوالہ:') ? citationUr : 'حوالہ: $citationUr';
      }
      if (citation.isNotEmpty) {
        return citation.startsWith('حوالہ:') ? citation : 'حوالہ: $citation';
      }
      return isAyat ? 'حوالہ: سورۃ الاحزاب (۳۳:۵۶)' : 'حوالہ: صحیح مسلم ۴۰۸';
    } else {
      if (citation.isNotEmpty && !_containsUrduOrArabic(citation)) {
        return citation.startsWith('Reference:') ? citation : 'Reference: $citation';
      }
      if (citation.isNotEmpty) return citation;
      if (citationUr.isNotEmpty) return citationUr;
      return isAyat ? 'Reference: Surah Al-Ahzab (33:56)' : 'Reference: Sahih Muslim 408';
    }
  }
}
