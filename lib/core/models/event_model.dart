import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class EventModel {
  final String id;
  final String title;
  final String titleUr;
  final String dateTime;
  final String location;
  final String locationUr;
  final String status;
  final String description;
  final String descriptionUr;

  const EventModel({
    required this.id,
    required this.title,
    this.titleUr = '',
    required this.dateTime,
    required this.location,
    this.locationUr = '',
    required this.status,
    required this.description,
    this.descriptionUr = '',
  });

  String getTitle(bool isUrdu) => isUrdu && titleUr.isNotEmpty ? titleUr : title;
  String getLocation(bool isUrdu) => isUrdu && locationUr.isNotEmpty ? locationUr : location;
  String getDescription(bool isUrdu) => isUrdu && descriptionUr.isNotEmpty ? descriptionUr : description;

  // Gradient computed from status for display
  List<Color> get gradientColors {
    switch (status.toLowerCase()) {
      case 'featured':
        return [AppColors.primaryEmerald, AppColors.emeraldDark];
      case 'recurring':
        return [const Color(0xFF1E5631), const Color(0xFF4C9A2A)];
      default:
        return [const Color(0xFF8B6B23), const Color(0xFFD4AF37)];
    }
  }

  factory EventModel.fromMap(String id, Map<String, dynamic> map) {
    return EventModel(
      id: id,
      title: map['title'] as String? ?? '',
      titleUr: map['title_ur'] as String? ?? '',
      dateTime: map['date_time'] as String? ?? '',
      location: map['location'] as String? ?? '',
      locationUr: map['location_ur'] as String? ?? '',
      status: map['status'] as String? ?? 'Upcoming',
      description: map['description'] as String? ?? '',
      descriptionUr: map['description_ur'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'title_ur': titleUr,
        'date_time': dateTime,
        'location': location,
        'location_ur': locationUr,
        'status': status,
        'description': description,
        'description_ur': descriptionUr,
        'created_at': FieldValue.serverTimestamp(),
      };
}
