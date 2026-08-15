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
  final String citation;
  final String citationUr;
  final String referenceBook;
  final String referenceBookUr;

  const MasailItemModel({
    required this.id,
    required this.categoryId,
    required this.question,
    this.questionUr = '',
    required this.answer,
    this.answerUr = '',
    required this.citation,
    this.citationUr = '',
    required this.referenceBook,
    this.referenceBookUr = '',
  });

  String getQuestion(bool isUrdu) => isUrdu && questionUr.isNotEmpty ? questionUr : question;
  String getAnswer(bool isUrdu) => isUrdu && answerUr.isNotEmpty ? answerUr : answer;
  String getCitation(bool isUrdu) => isUrdu && citationUr.isNotEmpty ? citationUr : citation;
  String getReferenceBook(bool isUrdu) => isUrdu && referenceBookUr.isNotEmpty ? referenceBookUr : referenceBook;

  factory MasailItemModel.fromMap(String id, Map<String, dynamic> map) {
    return MasailItemModel(
      id: id,
      categoryId: map['category_id'] as String? ?? '',
      question: map['question'] as String? ?? '',
      questionUr: map['question_ur'] as String? ?? '',
      answer: map['answer'] as String? ?? '',
      answerUr: map['answer_ur'] as String? ?? '',
      citation: map['citation'] as String? ?? '',
      citationUr: map['citation_ur'] as String? ?? '',
      referenceBook: map['reference_book'] as String? ?? '',
      referenceBookUr: map['reference_book_ur'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'category_id': categoryId,
        'question': question,
        'question_ur': questionUr,
        'answer': answer,
        'answer_ur': answerUr,
        'citation': citation,
        'citation_ur': citationUr,
        'reference_book': referenceBook,
        'reference_book_ur': referenceBookUr,
        'created_at': FieldValue.serverTimestamp(),
      };
}
