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
    final rawDate = map['scheduled_date'];
    if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else if (rawDate is String && rawDate.isNotEmpty) {
      date = DateTime.tryParse(rawDate);
    }

    DateTime? created;
    final rawCreated = map['created_at'];
    if (rawCreated is Timestamp) {
      created = rawCreated.toDate();
    } else if (rawCreated is String && rawCreated.isNotEmpty) {
      created = DateTime.tryParse(rawCreated);
    }

    return DailyContentModel(
      id: id,
      type: map['type'] as String? ?? 'hadith',
      title: map['title'] as String? ?? '',
      titleUr: map['title_ur'] as String? ?? '',
      arabicText: map['arabic_text'] as String? ?? '',
      content: map['content'] as String? ?? '',
      contentUr: map['content_ur'] as String? ?? '',
      citation: (map['citation'] ?? map['book'] ?? map['reference']) as String? ?? '',
      citationUr: (map['citation_ur'] ?? map['book_ur'] ?? map['reference_ur']) as String? ?? '',
      imageUrl: map['image_url'] as String? ?? '',
      isActive: map['is_active'] as bool? ?? true,
      isTopicOfTheDay: map['is_topic_of_the_day'] as bool? ?? false,
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

  String getTitle(bool isUrdu) {
    if (isUrdu && titleUr.isNotEmpty) return titleUr;
    if (title.isNotEmpty) return title;
    if (isUrdu) {
      return isAyat ? 'آج کی آیتِ مبارکہ' : 'آج کی حدیثِ پاک';
    }
    return isAyat ? 'Ayat of the Day' : 'Hadith of the Day';
  }

  String getContent(bool isUrdu) {
    if (isUrdu && contentUr.isNotEmpty) return contentUr;
    return content;
  }

  String getCitation(bool isUrdu) {
    if (isUrdu && citationUr.isNotEmpty) return citationUr;
    return citation;
  }
}

