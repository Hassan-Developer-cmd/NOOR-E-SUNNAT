import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MasailCategory {
  final String id;
  final String title;
  final String titleUr;
  final String arabicTitle;
  final IconData icon;
  final String? badge;

  const MasailCategory({
    required this.id,
    required this.title,
    required this.titleUr,
    required this.arabicTitle,
    required this.icon,
    this.badge,
  });

  static const List<MasailCategory> defaultCategories = [
    MasailCategory(
      id: 'namaz',
      title: 'Namaz & Salah',
      titleUr: 'نماز کے احکام و مسائل',
      arabicTitle: 'كتاب الصلاة',
      icon: Icons.access_time_filled_rounded,
      badge: 'Essential',
    ),
    MasailCategory(
      id: 'wuzu',
      title: 'Wuzu & Taharat',
      titleUr: 'وضو اور طہارت',
      arabicTitle: 'كتاب الطهارة',
      icon: Icons.water_drop_rounded,
    ),
    MasailCategory(
      id: 'roza',
      title: 'Roza & Ramadan',
      titleUr: 'روزہ اور رمضان کے احکام',
      arabicTitle: 'كتاب الصوم',
      icon: Icons.nightlight_round,
    ),
    MasailCategory(
      id: 'zakat',
      title: 'Zakat & Charity',
      titleUr: 'زکوٰۃ و خیرات کے مسائل',
      arabicTitle: 'كتاب الزكاة',
      icon: Icons.volunteer_activism_rounded,
    ),
    MasailCategory(
      id: 'hajj',
      title: 'Hajj & Umrah',
      titleUr: 'حج اور عمرہ کا طریقہ',
      arabicTitle: 'كتاب الحج',
      icon: Icons.mosque_rounded,
    ),
    MasailCategory(
      id: 'tayamum',
      title: 'Tayamum',
      titleUr: 'تیمم کے احکام',
      arabicTitle: 'كتاب التيمم',
      icon: Icons.landscape_rounded,
    ),
    MasailCategory(
      id: 'nikah',
      title: 'Nikah & Talaq',
      titleUr: 'نکاح اور طلاق کے مسائل',
      arabicTitle: 'كتاب النكاح',
      icon: Icons.favorite_rounded,
    ),
    MasailCategory(
      id: 'taharat',
      title: 'Ghusl & Cleanliness',
      titleUr: 'غسل اور پاکی کے احکام',
      arabicTitle: 'كتاب الغسل',
      icon: Icons.cleaning_services_rounded,
    ),
    MasailCategory(
      id: 'miras',
      title: 'Miras / Inheritance',
      titleUr: 'وراثت اور ترکہ کی تقسیم',
      arabicTitle: 'كتاب المواريث',
      icon: Icons.balance_rounded,
    ),
  ];
}

class MasailItemModel {
  final String id;
  final String categoryId;
  final String question;
  final String questionUr;
  final String answer;
  final String answerUr;
  final String book;
  final String bookUr;

  const MasailItemModel({
    required this.id,
    required this.categoryId,
    required this.question,
    this.questionUr = '',
    required this.answer,
    this.answerUr = '',
    required this.book,
    this.bookUr = '',
    String? citation,
    String? citationUr,
    String? referenceBook,
    String? referenceBookUr,
  });

  // Backward compatibility getters
  String get citation => book;
  String get citationUr => bookUr;
  String get referenceBook => book;
  String get referenceBookUr => bookUr;

  String getQuestion(bool isUrdu) => isUrdu && questionUr.isNotEmpty ? questionUr : question;
  String getAnswer(bool isUrdu) => isUrdu && answerUr.isNotEmpty ? answerUr : answer;
  String getBook(bool isUrdu) => isUrdu && bookUr.isNotEmpty ? bookUr : book;
  String getCitation(bool isUrdu) => getBook(isUrdu);
  String getReferenceBook(bool isUrdu) => getBook(isUrdu);

  factory MasailItemModel.fromMap(String id, Map<String, dynamic> map) {
    final rawBook = (map['book'] as String?)?.trim();
    final rawBookUr = (map['book_ur'] as String?)?.trim();
    final rawCit = (map['citation'] as String?)?.trim();
    final rawCitUr = (map['citation_ur'] as String?)?.trim();
    final rawRef = (map['reference_book'] as String?)?.trim();
    final rawRefUr = (map['reference_book_ur'] as String?)?.trim();

    final effectiveBook = (rawBook != null && rawBook.isNotEmpty)
        ? rawBook
        : ((rawCit != null && rawCit.isNotEmpty)
            ? rawCit
            : (rawRef ?? ''));

    final effectiveBookUr = (rawBookUr != null && rawBookUr.isNotEmpty)
        ? rawBookUr
        : ((rawCitUr != null && rawCitUr.isNotEmpty)
            ? rawCitUr
            : (rawRefUr ?? ''));

    return MasailItemModel(
      id: id,
      categoryId: map['category_id'] as String? ?? '',
      question: map['question'] as String? ?? '',
      questionUr: map['question_ur'] as String? ?? '',
      answer: map['answer'] as String? ?? '',
      answerUr: map['answer_ur'] as String? ?? '',
      book: effectiveBook,
      bookUr: effectiveBookUr,
    );
  }

  Map<String, dynamic> toMap() => {
        'category_id': categoryId,
        'question': question,
        'question_ur': questionUr,
        'answer': answer,
        'answer_ur': answerUr,
        'book': book,
        'book_ur': bookUr,
        // Keep legacy fields for backward compatibility
        'citation': book,
        'citation_ur': bookUr,
        'reference_book': book,
        'reference_book_ur': bookUr,
        'created_at': FieldValue.serverTimestamp(),
      };
}
