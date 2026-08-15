import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AqaidCategoryModel {
  final String id;
  final String title;
  final String arabicTitle;
  final String subtitle;
  final IconData icon;

  const AqaidCategoryModel({
    required this.id,
    required this.title,
    required this.arabicTitle,
    required this.subtitle,
    required this.icon,
  });
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
