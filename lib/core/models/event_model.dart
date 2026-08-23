import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EventModel {
  static const String imageTypeUrl = 'url';
  static const String imageTypeBase64 = 'base64';

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
  final String imageType;
  final String? imageUrl;
  final String? imageBase64;
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
    this.imageType = imageTypeUrl,
    this.imageUrl,
    this.imageBase64,
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
    String? imageType,
    String? imageUrl,
    String? imageBase64,
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
      imageType: imageType ?? this.imageType,
      imageUrl: imageUrl ?? this.imageUrl,
      imageBase64: imageBase64 ?? this.imageBase64,
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

    // Safely parse date string whether it's a Timestamp, DateTime, String, or num
    String parseDateString(dynamic raw) {
      if (raw == null) return '';
      if (raw is Timestamp) {
        final dt = raw.toDate();
        return '${dt.day}/${dt.month}/${dt.year}';
      }
      if (raw is DateTime) {
        return '${raw.day}/${raw.month}/${raw.year}';
      }
      return raw.toString().trim();
    }

    final rawDate = map['date_time'] ?? map['dateTime'] ?? map['date'];
    final rawImage = map['image_url'] ?? map['imageUrl'] ?? map['image'];
    final rawBase64 = map['image_base64'] ?? map['imageBase64'];
    final rawImageType = map['image_type'] ??
        map['imageType'] ??
        (rawBase64 != null && rawBase64.toString().trim().isNotEmpty
            ? imageTypeBase64
            : imageTypeUrl);

    int parseOrder(dynamic raw) {
      if (raw is num) return raw.toInt();
      if (raw is String) return int.tryParse(raw) ?? 0;
      return 0;
    }

    return EventModel(
      id: id,
      title: map['title']?.toString() ?? '',
      titleUr: map['title_ur']?.toString() ?? '',
      dateTime: parseDateString(rawDate),
      location: map['location']?.toString() ?? '',
      locationUr: map['location_ur']?.toString() ?? '',
      status: map['status']?.toString() ?? map['badgeText']?.toString() ?? 'Coming Soon',
      description: map['description']?.toString() ?? '',
      descriptionUr: map['description_ur']?.toString() ?? '',
      imageType: rawImageType.toString(),
      imageUrl: (rawImage != null && rawImage.toString().trim().isNotEmpty) ? rawImage.toString().trim() : null,
      imageBase64: (rawBase64 != null && rawBase64.toString().trim().isNotEmpty) ? rawBase64.toString().trim() : null,
      order: parseOrder(map['order'] ?? map['arrangement_index']),
      statusHistory: history,
      lastNotifiedStatus: map['last_notified_status']?.toString(),
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
        'image_type': imageType,
        'imageType': imageType,
        'image_url': imageUrl,
        'imageUrl': imageUrl,
        'image_base64': imageBase64,
        'imageBase64': imageBase64,
        'order': order,
        'status_history': statusHistory,
        'last_notified_status': lastNotifiedStatus ?? status,
        'last_notification_sent_at': lastNotificationSentAt ?? FieldValue.serverTimestamp(),
        'created_at': createdAt ?? FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
}
