import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MasailCategoryModel {
  final String id;
  final String title;
  final String arabicTitle;
  final IconData icon;
  final int count;

  const MasailCategoryModel({
    required this.id,
    required this.title,
    required this.arabicTitle,
    required this.icon,
    required this.count,
  });
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
