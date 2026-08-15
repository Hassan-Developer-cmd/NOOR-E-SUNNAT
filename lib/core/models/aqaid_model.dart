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
  final String reference;
  final String referenceUr;

  const AqaidItemModel({
    required this.id,
    required this.categoryId,
    required this.title,
    this.titleUr = '',
    required this.arabicText,
    required this.explanation,
    this.explanationUr = '',
    required this.reference,
    this.referenceUr = '',
  });

  String getTitle(bool isUrdu) => isUrdu && titleUr.isNotEmpty ? titleUr : title;
  String getExplanation(bool isUrdu) => isUrdu && explanationUr.isNotEmpty ? explanationUr : explanation;
  String getReference(bool isUrdu) => isUrdu && referenceUr.isNotEmpty ? referenceUr : reference;

  factory AqaidItemModel.fromMap(String id, Map<String, dynamic> map) {
    return AqaidItemModel(
      id: id,
      categoryId: map['category_id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      titleUr: map['title_ur'] as String? ?? '',
      arabicText: map['arabic_text'] as String? ?? '',
      explanation: map['explanation'] as String? ?? '',
      explanationUr: map['explanation_ur'] as String? ?? '',
      reference: map['reference'] as String? ?? '',
      referenceUr: map['reference_ur'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'category_id': categoryId,
        'title': title,
        'title_ur': titleUr,
        'arabic_text': arabicText,
        'explanation': explanation,
        'explanation_ur': explanationUr,
        'reference': reference,
        'reference_ur': referenceUr,
        'created_at': FieldValue.serverTimestamp(),
      };
}
