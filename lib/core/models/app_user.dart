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

    final int rawStreak = ((map['current_streak'] ?? map['streak'] ?? map['daily_streak']) as num?)?.toInt() ?? 0;
    final int rawLongest = ((map['longest_streak'] ?? map['best_streak']) as num?)?.toInt() ?? rawStreak;

    final int effectiveStreak = StreakHelper.calculateEffectiveStreak(
      storedStreak: rawStreak,
      lastActiveDate: rawDate ?? activeDate,
    );

    return AppUser(
      userId: map['user_id'] as String? ?? map['userId'] as String? ?? '',
      email: map['email'] as String? ?? '',
      username: map['username'] as String? ?? 'User',
      photoUrl: map['photo_url'] as String? ?? map['photoUrl'] as String? ?? '',
      profileImageBase64: map['profileImageBase64'] as String? ?? map['profile_image_base64'] as String?,
      isAdmin: map['is_admin'] as bool? ?? false,
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
      totalDuroodPoints: ((map['total_durood_points'] ?? map['points']) as num?)?.toInt() ?? 0,
      lastActiveDuroodDate: activeDate,
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
        'longest_streak': longestStreak,
        'total_durood_points': totalDuroodPoints,
        'last_active_durood_date':
            lastActiveDuroodDate?.toIso8601String().split('T').first,
      };

  Map<String, dynamic> toInitialMap() => {
        ...toMap(),
        'created_at': FieldValue.serverTimestamp(),
      };
}
