import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AqaidCategory {
  final String id;
  final String title;
  final String titleUr;
  final String arabicTitle;
  final String subtitle;
  final IconData icon;
  final String bgAsset;
  final bool isFullWidth;

  const AqaidCategory({
    required this.id,
    required this.title,
    required this.titleUr,
    required this.arabicTitle,
    required this.subtitle,
    required this.icon,
    this.bgAsset = '',
    this.isFullWidth = false,
  });

  static const List<AqaidCategory> defaultCategories = [
    AqaidCategory(
      id: 'tawheed',
      title: 'Tawheed',
      titleUr: 'توحید',
      arabicTitle: 'توحيد',
      subtitle: 'Oneness of Allah (SWT)',
      icon: Icons.auto_awesome,
      bgAsset: 'assets/images/tauheed.png',
    ),
    AqaidCategory(
      id: 'risalat',
      title: 'Risalat',
      titleUr: 'رسالت',
      arabicTitle: 'رسالت',
      subtitle: 'Prophethood of Muhammad (ﷺ)',
      icon: Icons.star,
      bgAsset: 'assets/images/risalat.png',
    ),
    AqaidCategory(
      id: 'ahle_sunnat',
      title: 'Ahle Sunnat',
      titleUr: 'اہلِ سنت',
      arabicTitle: 'اہلِ سنت',
      subtitle: 'Creed of Ahle Sunnat Wal Jama\'at',
      icon: Icons.shield_rounded,
      bgAsset: 'assets/images/sahaba.png',
    ),
    AqaidCategory(
      id: 'quran',
      title: 'Quran',
      titleUr: 'قرآن پاک',
      arabicTitle: 'القرآن',
      subtitle: 'The Holy Quran & Divine Revelations',
      icon: Icons.menu_book_rounded,
      bgAsset: 'assets/images/ishq_rasool.png',
    ),
    AqaidCategory(
      id: 'sahaba_ahlebait',
      title: 'Sahaba o Ahlebait',
      titleUr: 'صحابہ و اہل بیت',
      arabicTitle: 'صحابہ و اہل بیت',
      subtitle: 'Companions & Blessed Household',
      icon: Icons.people_alt_rounded,
      bgAsset: 'assets/images/sahaba.png',
      isFullWidth: true,
    ),
    AqaidCategory(
      id: 'ishq_rasool',
      title: 'Ishq-e-Rasool',
      titleUr: 'عشقِ رسول',
      arabicTitle: 'عشقِ رسول',
      subtitle: 'Love & Devotion to Prophet (ﷺ)',
      icon: Icons.favorite,
      bgAsset: 'assets/images/ishq_rasool.png',
    ),
    AqaidCategory(
      id: 'wilayat',
      title: 'Wilayat',
      titleUr: 'ولایت',
      arabicTitle: 'ولایت',
      subtitle: 'Sainthood & Spiritual Path',
      icon: Icons.brightness_7,
      bgAsset: 'assets/images/wilayat.png',
    ),
  ];
}

class AqaidItemModel {
  final String id;
  final String categoryId;
  final String title;
  final String titleUr;
  final String arabicText;
  final String explanation;
  final String explanationUr;
  final String book;
  final String bookUr;

  const AqaidItemModel({
    required this.id,
    required this.categoryId,
    required this.title,
    this.titleUr = '',
    required this.arabicText,
    required this.explanation,
    this.explanationUr = '',
    required this.book,
    this.bookUr = '',
    String? reference,
    String? referenceUr,
    String? citation,
    String? citationUr,
  });

  // Backward compatibility getters
  String get reference => book;
  String get referenceUr => bookUr;
  String get citation => book;
  String get citationUr => bookUr;

  String getTitle(bool isUrdu) => isUrdu && titleUr.isNotEmpty ? titleUr : title;
  String getExplanation(bool isUrdu) => isUrdu && explanationUr.isNotEmpty ? explanationUr : explanation;
  String getBook(bool isUrdu) => isUrdu && bookUr.isNotEmpty ? bookUr : book;
  String getReference(bool isUrdu) => getBook(isUrdu);
  String getCitation(bool isUrdu) => getBook(isUrdu);

  factory AqaidItemModel.fromMap(String id, Map<String, dynamic> map) {
    final rawBook = (map['book'] as String?)?.trim();
    final rawBookUr = (map['book_ur'] as String?)?.trim();
    final rawRef = (map['reference'] as String?)?.trim();
    final rawRefUr = (map['reference_ur'] as String?)?.trim();
    final rawCit = (map['citation'] as String?)?.trim();
    final rawCitUr = (map['citation_ur'] as String?)?.trim();

    final effectiveBook = (rawBook != null && rawBook.isNotEmpty)
        ? rawBook
        : ((rawRef != null && rawRef.isNotEmpty)
            ? rawRef
            : (rawCit ?? ''));

    final effectiveBookUr = (rawBookUr != null && rawBookUr.isNotEmpty)
        ? rawBookUr
        : ((rawRefUr != null && rawRefUr.isNotEmpty)
            ? rawRefUr
            : (rawCitUr ?? ''));

    return AqaidItemModel(
      id: id,
      categoryId: map['category_id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      titleUr: map['title_ur'] as String? ?? '',
      arabicText: map['arabic_text'] as String? ?? '',
      explanation: map['explanation'] as String? ?? '',
      explanationUr: map['explanation_ur'] as String? ?? '',
      book: effectiveBook,
      bookUr: effectiveBookUr,
    );
  }

  Map<String, dynamic> toMap() => {
        'category_id': categoryId,
        'title': title,
        'title_ur': titleUr,
        'arabic_text': arabicText,
        'explanation': explanation,
        'explanation_ur': explanationUr,
        'book': book,
        'book_ur': bookUr,
        // Keep legacy fields for backward compatibility
        'reference': book,
        'reference_ur': bookUr,
        'citation': book,
        'citation_ur': bookUr,
        'created_at': FieldValue.serverTimestamp(),
      };
}
