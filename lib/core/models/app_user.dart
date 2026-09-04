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

  factory AppUser.fromMap(Map<String, dynamic> map) {
    DateTime? activeDate;
    final rawDate = map['last_active_durood_date'] ??
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

    final int rawStreak = ((map['streak'] ??
            map['current_streak'] ??
            map['currentStreak'] ??
            map['daily_streak']) as num?)
            ?.toInt() ??
        0;
    final int rawLongest = ((map['longest_streak'] ?? map['best_streak']) as num?)?.toInt() ?? rawStreak;

    final int calculatedStreak = StreakHelper.calculateEffectiveStreak(
      storedStreak: rawStreak,
      lastActiveDate: rawDate ?? activeDate,
    );
    // If calculated streak is > 0 use it; otherwise fallback to rawStreak if account has stored streak
    final int effectiveStreak = calculatedStreak > 0 ? calculatedStreak : rawStreak;

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
      personalTotalDurood: ((map['personal_total_durood'] ??
              map['total_durood_count'] ??
              map['personal_durood'] ??
              map['total_recitations'] ??
              map['total_count'] ??
              map['totalDurood']) as num?)
              ?.toInt() ??
          0,
      personalTodayDurood: ((map['personal_today_durood'] ??
              map['today_durood_count'] ??
              map['today_count']) as num?)
              ?.toInt() ??
          0,
      currentStreak: effectiveStreak,
      longestStreak: rawLongest >= effectiveStreak ? rawLongest : effectiveStreak,
      totalDuroodPoints: ((map['duroodPoints'] ??
              map['durood_points'] ??
              map['total_durood_points'] ??
              map['points'] ??
              map['totalPoints']) as num?)
              ?.toInt() ??
          0,
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
        'personal_total_durood': personalTotalDurood,
        'personal_today_durood': personalTodayDurood,
        'current_streak': currentStreak,
        'streak': currentStreak,
        'longest_streak': longestStreak,
        'total_durood_points': totalDuroodPoints,
        'durood_points': totalDuroodPoints,
        'duroodPoints': totalDuroodPoints,
        'points': totalDuroodPoints,
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
