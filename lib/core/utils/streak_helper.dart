import 'package:cloud_firestore/cloud_firestore.dart';

/// Centralized helper for Snapchat-style consecutive calendar-day streak logic,
/// date parsing, and account streak persistence.
class StreakHelper {
  /// Converts any dynamic date value (DateTime, Timestamp, String, int) into a standard YYYY-MM-DD string.
  static String toCalendarDateString(dynamic rawDate) {
    if (rawDate == null) return '';
    if (rawDate is DateTime) {
      return '${rawDate.year}-${rawDate.month.toString().padLeft(2, '0')}-${rawDate.day.toString().padLeft(2, '0')}';
    }
    if (rawDate is Timestamp) {
      final dt = rawDate.toDate();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }
    if (rawDate is int && rawDate > 0) {
      final dt = DateTime.fromMillisecondsSinceEpoch(rawDate);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }
    if (rawDate is String && rawDate.isNotEmpty) {
      final trimmed = rawDate.trim();
      if (trimmed.contains('T')) {
        return trimmed.split('T').first;
      }
      if (trimmed.contains(' ')) {
        return trimmed.split(' ').first;
      }
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(trimmed)) {
        return trimmed;
      }
      final parsed = DateTime.tryParse(trimmed);
      if (parsed != null) {
        return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
      }
    }
    return '';
  }

  /// Returns today's ISO calendar date string: "YYYY-MM-DD".
  static String getTodayDateString([DateTime? referenceDate]) {
    final ref = referenceDate ?? DateTime.now();
    return toCalendarDateString(ref);
  }

  /// Returns yesterday's ISO calendar date string: "YYYY-MM-DD".
  static String getYesterdayDateString([DateTime? referenceDate]) {
    final ref = referenceDate ?? DateTime.now();
    final yesterday = ref.subtract(const Duration(days: 1));
    return toCalendarDateString(yesterday);
  }

  /// Calculates calendar days difference: (toDate - fromDate).
  /// Returns 999999 if either date string is invalid.
  static int calendarDaysDifference(dynamic fromDate, dynamic toDate) {
    try {
      final s1 = toCalendarDateString(fromDate);
      final s2 = toCalendarDateString(toDate);
      if (s1.isEmpty || s2.isEmpty) return 999999;
      final p1 = s1.split('-').map(int.parse).toList();
      final p2 = s2.split('-').map(int.parse).toList();
      final d1 = DateTime(p1[0], p1[1], p1[2]);
      final d2 = DateTime(p2[0], p2[1], p2[2]);
      return d2.difference(d1).inDays;
    } catch (_) {
      return 999999;
    }
  }

  /// Checks if two dates fall on the exact same calendar day.
  static bool isSameDay(dynamic date1, dynamic date2) {
    final s1 = toCalendarDateString(date1);
    final s2 = toCalendarDateString(date2);
    return s1.isNotEmpty && s1 == s2;
  }

  /// Resolves the current displayed streak on App Launch / Midnight Verification.
  ///
  /// - If lastStreakDate is today (diff == 0), user recited today: streak is storedStreak.
  /// - If lastStreakDate is yesterday (diff == 1), user recited yesterday: streak is maintained (user has today to continue).
  /// - If lastStreakDate is older than yesterday (diff > 1) or empty, the streak is broken: resets to 0.
  static int calculateEffectiveStreak({
    required int storedStreak,
    required dynamic lastActiveDate,
    dynamic referenceDate,
  }) {
    if (storedStreak <= 0) return 0;
    final lastStr = toCalendarDateString(lastActiveDate);
    if (lastStr.isEmpty) return 0;

    final ref = referenceDate ?? DateTime.now();
    final todayStr = toCalendarDateString(ref);

    final diff = calendarDaysDifference(lastStr, todayStr);
    if (diff == 0 || diff == 1) {
      // Recited today or yesterday: active streak maintained
      return storedStreak;
    } else {
      // Missed yesterday (> 1 day inactive): streak broken
      return 0;
    }
  }

  /// Computes updated streak on Daily Recitation (Snapchat-style):
  ///
  /// Let `today` be current date ("YYYY-MM-DD") and `yesterday` be previous date ("YYYY-MM-DD"):
  /// - Case 1 (Already recited today):
  ///   if (lastStreakDate == today) -> Do not change the streak count.
  /// - Case 2 (Recited yesterday, now active today):
  ///   if (lastStreakDate == yesterday) -> streak = streak + 1, update lastStreakDate = today.
  /// - Case 3 (Streak broken / missed yesterday or inactive > 1 day or brand new):
  ///   if (lastStreakDate != yesterday && lastStreakDate != today) -> Reset streak = 1, update lastStreakDate = today.
  static Map<String, dynamic> computeStreakOnDuroodRecitation({
    required int currentStoredStreak,
    required int longestStoredStreak,
    required dynamic lastActiveDate,
    required String todayDateStr,
    dynamic referenceDate,
  }) {
    final lastStr = toCalendarDateString(lastActiveDate);
    final ref = referenceDate ?? (DateTime.tryParse(todayDateStr) ?? DateTime.now());
    final yesterdayStr = getYesterdayDateString(ref);

    // Case 1: Already recited today -> Do not change streak count
    if (lastStr == todayDateStr) {
      final safeStreak = currentStoredStreak > 0 ? currentStoredStreak : 1;
      return {
        'streak': safeStreak,
        'current_streak': safeStreak,
        'lastStreakDate': todayDateStr,
        'lastActiveDate': todayDateStr,
      };
    }

    int nextStreak;
    // Case 2: Recited yesterday, now active today -> increment streak by 1
    if (lastStr == yesterdayStr) {
      nextStreak = currentStoredStreak + 1;
    } else {
      // Case 3: Streak broken / missed yesterday or inactive > 1 day -> start fresh at 1
      nextStreak = 1;
    }

    final newLongest = nextStreak > longestStoredStreak ? nextStreak : longestStoredStreak;
    return {
      'streak': nextStreak,
      'current_streak': nextStreak,
      'longest_streak': newLongest,
      'lastStreakDate': todayDateStr,
      'lastActiveDate': todayDateStr,
    };
  }
}
