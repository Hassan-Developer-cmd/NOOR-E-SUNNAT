import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EventModel {
  static const List<String> supportedStatuses = [
    'Coming Soon',
    'Featured',
    'Ongoing',
    'Completed',
    'Cancelled',
  ];

  final String id;
  final String title;
  final String titleUr;
  final String dateTime;
  final String location;
  final String locationUr;
  final String status;
  final String description;
  final String descriptionUr;
  final String? imageUrl;
  final int order;
  final List<Map<String, dynamic>> statusHistory;
  final String? lastNotifiedStatus;
  final dynamic lastNotificationSentAt;
  final dynamic createdAt;
  final dynamic updatedAt;

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
    this.imageUrl,
    this.order = 0,
    this.statusHistory = const [],
    this.lastNotifiedStatus,
    this.lastNotificationSentAt,
    this.createdAt,
    this.updatedAt,
  });

  String getTitle(bool isUrdu) => isUrdu && titleUr.isNotEmpty ? titleUr : title;
  String getLocation(bool isUrdu) => isUrdu && locationUr.isNotEmpty ? locationUr : location;
  String getDescription(bool isUrdu) => isUrdu && descriptionUr.isNotEmpty ? descriptionUr : description;

  String getStatusLabel(bool isUrdu) {
    switch (status.toLowerCase()) {
      case 'ongoing':
        return isUrdu ? '🔥 جاری ہے' : '🔥 LIVE NOW';
      case 'featured':
        return isUrdu ? '⭐ خصوصی' : '⭐ FEATURED';
      case 'coming soon':
        return isUrdu ? '⏳ عنقریب' : '⏳ COMING SOON';
      case 'completed':
        return isUrdu ? '✅ مکمل ہو گیا' : '✅ COMPLETED';
      case 'cancelled':
        return isUrdu ? '🚫 منسوخ' : '🚫 CANCELLED';
      default:
        return status.toUpperCase();
    }
  }


  EventModel copyWith({
    String? id,
    String? title,
    String? titleUr,
    String? dateTime,
    String? location,
    String? locationUr,
    String? status,
    String? description,
    String? descriptionUr,
    String? imageUrl,
    int? order,
    List<Map<String, dynamic>>? statusHistory,
    String? lastNotifiedStatus,
    dynamic lastNotificationSentAt,
    dynamic createdAt,
    dynamic updatedAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      titleUr: titleUr ?? this.titleUr,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      locationUr: locationUr ?? this.locationUr,
      status: status ?? this.status,
      description: description ?? this.description,
      descriptionUr: descriptionUr ?? this.descriptionUr,
      imageUrl: imageUrl ?? this.imageUrl,
      order: order ?? this.order,
      statusHistory: statusHistory ?? this.statusHistory,
      lastNotifiedStatus: lastNotifiedStatus ?? this.lastNotifiedStatus,
      lastNotificationSentAt: lastNotificationSentAt ?? this.lastNotificationSentAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Gradient computed from status for display
  List<Color> get gradientColors {
    switch (status.toLowerCase()) {
      case 'featured':
        return [const Color(0xFF0F766E), const Color(0xFF065F46)]; // Deep Teal / Emerald
      case 'ongoing':
        return [const Color(0xFFDC2626), const Color(0xFF991B1B)]; // Live Crimson
      case 'completed':
        return [const Color(0xFF059669), const Color(0xFF047857)]; // Emerald Green
      case 'cancelled':
        return [const Color(0xFF64748B), const Color(0xFF475569)]; // Slate Grey
      case 'coming soon':
      default:
        return [const Color(0xFF0284C7), const Color(0xFF0369A1)]; // Ocean Indigo / Gold
    }
  }

  // Chip background color for tables & badges
  Color get statusBgColor {
    switch (status.toLowerCase()) {
      case 'featured':
        return const Color(0xFFFEF3C7);
      case 'ongoing':
        return const Color(0xFFFEE2E2);
      case 'completed':
        return const Color(0xFFD1FAE5);
      case 'cancelled':
        return const Color(0xFFF1F5F9);
      case 'coming soon':
      default:
        return const Color(0xFFE0F2FE);
    }
  }

  // Chip text color for tables & badges
  Color get statusFgColor {
    switch (status.toLowerCase()) {
      case 'featured':
        return const Color(0xFFB45309);
      case 'ongoing':
        return const Color(0xFFDC2626);
      case 'completed':
        return const Color(0xFF059669);
      case 'cancelled':
        return const Color(0xFF64748B);
      case 'coming soon':
      default:
        return const Color(0xFF0284C7);
    }
  }

  String get date => dateTime;
  String get badgeText => status;

  factory EventModel.fromFirestore(Map<String, dynamic> data, String id) =>
      EventModel.fromMap(id, data);

  factory EventModel.fromMap(String id, Map<String, dynamic> map) {
    // Parse status history
    List<Map<String, dynamic>> history = [];
    if (map['status_history'] is List) {
      history = (map['status_history'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    final rawDate = map['date_time'] ?? map['dateTime'] ?? map['date'] ?? '';
    final rawImage = map['image_url'] ?? map['imageUrl'] ?? map['image'];

    return EventModel(
      id: id,
      title: map['title'] as String? ?? '',
      titleUr: map['title_ur'] as String? ?? '',
      dateTime: rawDate as String? ?? '',
      location: map['location'] as String? ?? '',
      locationUr: map['location_ur'] as String? ?? '',
      status: map['status'] as String? ?? map['badgeText'] as String? ?? 'Coming Soon',
      description: map['description'] as String? ?? '',
      descriptionUr: map['description_ur'] as String? ?? '',
      imageUrl: rawImage as String?,
      order: (map['order'] as num?)?.toInt() ?? (map['arrangement_index'] as num?)?.toInt() ?? 0,
      statusHistory: history,
      lastNotifiedStatus: map['last_notified_status'] as String?,
      lastNotificationSentAt: map['last_notification_sent_at'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'title_ur': titleUr,
        'date_time': dateTime,
        'date': dateTime,
        'location': location,
        'location_ur': locationUr,
        'status': status,
        'badgeText': status,
        'description': description,
        'description_ur': descriptionUr,
        'image_url': imageUrl,
        'imageUrl': imageUrl,
        'order': order,
        'status_history': statusHistory,
        'last_notified_status': lastNotifiedStatus ?? status,
        'last_notification_sent_at': lastNotificationSentAt ?? FieldValue.serverTimestamp(),
        'created_at': createdAt ?? FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
}
