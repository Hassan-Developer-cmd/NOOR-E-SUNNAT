import 'package:cloud_firestore/cloud_firestore.dart';

/// Centralized helper for streak calculation, date parsing, and account streak persistence.
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

  /// Calculates calendar days difference: (toDate - fromDate).
  static int calendarDaysDifference(dynamic fromDate, dynamic toDate) {
    try {
      final s1 = toCalendarDateString(fromDate);
      final s2 = toCalendarDateString(toDate);
      if (s1.isEmpty || s2.isEmpty) return 0;
      final p1 = s1.split('-').map(int.parse).toList();
      final p2 = s2.split('-').map(int.parse).toList();
      final d1 = DateTime(p1[0], p1[1], p1[2]);
      final d2 = DateTime(p2[0], p2[1], p2[2]);
      return d2.difference(d1).inDays;
    } catch (_) {
      return 0;
    }
  }

  /// Checks if two dates fall on the exact same calendar day.
  static bool isSameDay(dynamic date1, dynamic date2) {
    final s1 = toCalendarDateString(date1);
    final s2 = toCalendarDateString(date2);
    return s1.isNotEmpty && s1 == s2;
  }

  /// Resolves the current effective streak for an account.
  /// If the user was active today (diff == 0) or yesterday (diff == 1), their streak is intact.
  /// Only if more than 1 full day has passed without Durood activity (diff > 1) does the active streak expire.
  static int calculateEffectiveStreak({
    required int storedStreak,
    required dynamic lastActiveDate,
    dynamic referenceDate,
  }) {
    if (storedStreak <= 0) return 0;
    final ref = referenceDate ?? DateTime.now();
    final lastStr = toCalendarDateString(lastActiveDate);

    // If no last active date is available on account, preserve the stored streak from backend
    if (lastStr.isEmpty) {
      return storedStreak;
    }

    final diff = calendarDaysDifference(lastStr, ref);
    if (diff <= 1) {
      // Active today or yesterday: user has today to continue streak!
      return storedStreak;
    } else {
      // More than 1 day missed without Durood: streak ended
      return 0;
    }
  }

  /// Computes the updated streak map when the user adds Durood today.
  static Map<String, dynamic> computeStreakOnDuroodRecitation({
    required int currentStoredStreak,
    required int longestStoredStreak,
    required dynamic lastActiveDate,
    required String todayDateStr,
  }) {
    final lastStr = toCalendarDateString(lastActiveDate);

    // If already active today, do not increment streak again for today
    if (lastStr.isNotEmpty && isSameDay(lastStr, todayDateStr)) {
      return {};
    }

    int nextStreak;
    if (lastStr.isNotEmpty) {
      final diff = calendarDaysDifference(lastStr, todayDateStr);
      if (diff == 1) {
        // Consecutive calendar day: increment streak!
        nextStreak = currentStoredStreak + 1;
      } else if (diff > 1) {
        // Missed one or more days: start fresh streak at 1
        nextStreak = 1;
      } else {
        // diff <= 0 (same day or edge case): ensure at least 1
        nextStreak = currentStoredStreak > 0 ? currentStoredStreak : 1;
      }
    } else {
      // No prior active date recorded on account:
      // If an existing streak was stored on account (e.g. from backend/admin), increment it, else start at 1
      nextStreak = currentStoredStreak > 0 ? currentStoredStreak + 1 : 1;
    }

    final newLongest = nextStreak > longestStoredStreak ? nextStreak : longestStoredStreak;
    return {
      'current_streak': nextStreak,
      'longest_streak': newLongest,
    };
  }
}
