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
  final DateTime? scheduledDate;

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
    this.scheduledDate,
  });

  factory DailyContentModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime? date;
    final rawDate = map['scheduled_date'];
    if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else if (rawDate is String && rawDate.isNotEmpty) {
      date = DateTime.tryParse(rawDate);
    }

    return DailyContentModel(
      id: id,
      type: map['type'] as String? ?? 'hadith',
      title: map['title'] as String? ?? '',
      titleUr: map['title_ur'] as String? ?? '',
      arabicText: map['arabic_text'] as String? ?? '',
      content: map['content'] as String? ?? '',
      contentUr: map['content_ur'] as String? ?? '',
      citation: map['citation'] as String? ?? '',
      citationUr: map['citation_ur'] as String? ?? '',
      imageUrl: map['image_url'] as String? ?? '',
      isActive: map['is_active'] as bool? ?? true,
      scheduledDate: date,
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
        'scheduled_date': scheduledDate != null
            ? Timestamp.fromDate(scheduledDate!)
            : FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      };

  String getTitle(bool isUrdu) {
    if (isUrdu && titleUr.isNotEmpty) return titleUr;
    return title.isNotEmpty ? title : 'Hadith of the Day';
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
