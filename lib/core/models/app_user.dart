import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/streak_helper.dart';

class AppUser {
  final String userId;
  final String email;
  final String username;
  final String photoUrl;
  final String? profileImageBase64;
  final bool isAdmin;
  final int personalTotalDurood;
  final int personalTodayDurood;
  final int currentStreak;
  final int longestStreak;
  final int totalDuroodPoints;
  final DateTime? lastActiveDuroodDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? rawData;

  const AppUser({
    required this.userId,
    required this.email,
    required this.username,
    required this.photoUrl,
    this.profileImageBase64,
    this.isAdmin = false,
    this.personalTotalDurood = 0,
    this.personalTodayDurood = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalDuroodPoints = 0,
    this.lastActiveDuroodDate,
    this.createdAt,
    this.updatedAt,
    this.rawData,
  });

  /// Safely extracts an integer from any numeric or string representation.
  /// Handles Firestore schema variations where numbers may be int, double, or String.
  static int parseNumeric(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final clean = value.replaceAll(',', '').trim();
      final parsed = int.tryParse(clean) ?? double.tryParse(clean)?.toInt();
      if (parsed != null) return parsed;
    }
    return defaultValue;
  }

  int get myTotal => (rawData != null && rawData!['myTotal'] != null)
      ? parseNumeric(rawData!['myTotal'])
      : totalCount;

  int get myToday => (rawData != null && rawData!['myToday'] != null)
      ? parseNumeric(rawData!['myToday'])
      : personalTodayDurood;

  int get streak => currentStreak;
  int get effectiveStreak => currentStreak;

  int get duroodPoints {
    if (rawData != null) {
      for (final key in const [
        'totalPoints',
        'duroodPoints',
        'points',
        'total_durood_points',
        'durood_points',
      ]) {
        if (rawData!.containsKey(key) && rawData![key] != null) {
          final val = parseNumeric(rawData![key]);
          if (val > 0) return val;
        }
      }
    }
    if (totalDuroodPoints > 0) return totalDuroodPoints;
    return 0;
  }

  int get points => duroodPoints;
  int get totalPoints => duroodPoints;

  int get totalCount {
    if (rawData != null) {
      for (final key in const [
        'myTotal',
        'totalCount',
        'duroodCount',
        'total_count',
        'personal_total_durood',
        'totalDurood',
      ]) {
        if (rawData!.containsKey(key) && rawData![key] != null) {
          final val = parseNumeric(rawData![key]);
          if (val > 0) return val;
        }
      }
    }
    return personalTotalDurood;
  }

  int get duroodCount => totalCount;
  int get totalDurood => totalCount;

  factory AppUser.fromMap(Map<String, dynamic> map) {
    DateTime? activeDate;
    final dynamic rawStreakDateVal = map['lastStreakDate'];
    final dynamic rawStreakDate = (rawStreakDateVal is String && rawStreakDateVal.trim().isEmpty)
        ? null
        : rawStreakDateVal;

    final rawDate = rawStreakDate ??
        map['lastActiveDate'] ??
        map['last_active_durood_date'] ??
        map['last_active_timestamp'] ??
        map['last_active_date'] ??
        map['last_durood_at'];

    if (rawDate is Timestamp) {
      activeDate = rawDate.toDate();
    } else if (rawDate is String && rawDate.isNotEmpty) {
      activeDate = DateTime.tryParse(rawDate);
    } else if (rawDate is int && rawDate > 0) {
      activeDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    }

    DateTime? createdDate;
    final rawCreated = map['created_at'] ??
        map['createdAt'] ??
        map['joined_at'] ??
        map['joinedAt'] ??
        map['timestamp'];
    if (rawCreated is Timestamp) {
      createdDate = rawCreated.toDate();
    } else if (rawCreated is String && rawCreated.isNotEmpty) {
      createdDate = DateTime.tryParse(rawCreated);
    } else if (rawCreated is int && rawCreated > 0) {
      createdDate = DateTime.fromMillisecondsSinceEpoch(rawCreated);
    }

    DateTime? updatedDate;
    final rawUpdated = map['updated_at'] ??
        map['updatedAt'] ??
        map['last_updated'] ??
        map['lastUpdated'];
    if (rawUpdated is Timestamp) {
      updatedDate = rawUpdated.toDate();
    } else if (rawUpdated is String && rawUpdated.isNotEmpty) {
      updatedDate = DateTime.tryParse(rawUpdated);
    } else if (rawUpdated is int && rawUpdated > 0) {
      updatedDate = DateTime.fromMillisecondsSinceEpoch(rawUpdated);
    }

    final int rawStreak = parseNumeric(
      map['streak'] ??
          map['current_streak'] ??
          map['currentStreak'] ??
          map['daily_streak'],
    );
    final int rawLongest = parseNumeric(
      map['longest_streak'] ?? map['best_streak'],
      rawStreak,
    );

    // Snapchat-style effective streak calculation: resets to 0 if inactive for > 1 calendar day
    final int effectiveStreak = StreakHelper.calculateEffectiveStreak(
      storedStreak: rawStreak,
      lastActiveDate: rawDate ?? activeDate,
    );

    final resolvedName = (map['name'] as String?)?.trim().isNotEmpty == true
        ? (map['name'] as String).trim()
        : ((map['displayName'] as String?)?.trim().isNotEmpty == true
            ? (map['displayName'] as String).trim()
            : ((map['username'] as String?)?.trim().isNotEmpty == true
                ? (map['username'] as String).trim()
                : 'User'));

    return AppUser(
      userId: map['user_id'] as String? ?? map['userId'] as String? ?? map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      username: resolvedName,
      photoUrl: map['photo_url'] as String? ?? map['photoUrl'] as String? ?? map['photoURL'] as String? ?? '',
      profileImageBase64: map['profileImageBase64'] as String? ?? map['profile_image_base64'] as String?,
      isAdmin: map['is_admin'] as bool? ?? map['isAdmin'] as bool? ?? false,
      personalTotalDurood: parseNumeric(
        map['myTotal'] ??
            map['totalCount'] ??
            map['duroodCount'] ??
            map['personal_total_durood'] ??
            map['total_durood_count'] ??
            map['personal_durood'] ??
            map['total_recitations'] ??
            map['total_count'] ??
            map['totalDurood'],
      ),
      personalTodayDurood: parseNumeric(
        map['myToday'] ??
            map['personal_today_durood'] ??
            map['today_durood_count'] ??
            map['today_count'] ??
            map['todayTotal'],
      ),
      currentStreak: effectiveStreak,
      longestStreak: rawLongest >= effectiveStreak ? rawLongest : effectiveStreak,
      totalDuroodPoints: parseNumeric(
        map['totalPoints'] ??
            map['duroodPoints'] ??
            map['points'] ??
            map['durood_points'] ??
            map['total_durood_points'],
      ),
      lastActiveDuroodDate: activeDate,
      createdAt: createdDate,
      updatedAt: updatedDate,
      rawData: map,
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'email': email,
        'username': username,
        'photo_url': photoUrl,
        if (profileImageBase64 != null) 'profileImageBase64': profileImageBase64,
        'is_admin': isAdmin,
        'myTotal': personalTotalDurood,
        'personal_total_durood': personalTotalDurood,
        'totalCount': personalTotalDurood,
        'duroodCount': personalTotalDurood,
        'myToday': personalTodayDurood,
        'personal_today_durood': personalTodayDurood,
        'current_streak': currentStreak,
        'streak': currentStreak,
        'longest_streak': longestStreak,
        'total_durood_points': totalDuroodPoints,
        'durood_points': totalDuroodPoints,
        'duroodPoints': totalDuroodPoints,
        'points': totalDuroodPoints,
        'totalPoints': totalDuroodPoints,
        'lastStreakDate':
            lastActiveDuroodDate?.toIso8601String().split('T').first,
        'lastActiveDate':
            lastActiveDuroodDate?.toIso8601String().split('T').first,
        'last_active_durood_date':
            lastActiveDuroodDate?.toIso8601String().split('T').first,
        if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt?.toIso8601String(),
      };

  Map<String, dynamic> toInitialMap() => {
        ...toMap(),
        'created_at': FieldValue.serverTimestamp(),
      };
}
