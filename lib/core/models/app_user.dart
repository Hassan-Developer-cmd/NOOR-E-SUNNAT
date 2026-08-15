import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String userId;
  final String email;
  final String username;
  final String photoUrl;
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
    final rawDate = map['last_active_durood_date'];
    if (rawDate is Timestamp) {
      activeDate = rawDate.toDate();
    } else if (rawDate is String && rawDate.isNotEmpty) {
      activeDate = DateTime.tryParse(rawDate);
    }

    return AppUser(
      userId: map['user_id'] as String? ?? map['userId'] as String? ?? '',
      email: map['email'] as String? ?? '',
      username: map['username'] as String? ?? 'User',
      photoUrl: map['photo_url'] as String? ?? map['photoUrl'] as String? ?? '',
      isAdmin: map['is_admin'] as bool? ?? false,
      personalTotalDurood: (map['personal_total_durood'] as num?)?.toInt() ?? 0,
      personalTodayDurood: (map['personal_today_durood'] as num?)?.toInt() ?? 0,
      currentStreak: (map['current_streak'] as num?)?.toInt() ?? 0,
      longestStreak: (map['longest_streak'] as num?)?.toInt() ?? 0,
      totalDuroodPoints: (map['total_durood_points'] as num?)?.toInt() ?? 0,
      lastActiveDuroodDate: activeDate,
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'email': email,
        'username': username,
        'photo_url': photoUrl,
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
