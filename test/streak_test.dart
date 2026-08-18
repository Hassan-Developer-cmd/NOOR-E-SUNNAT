import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/models/app_user.dart';
import 'package:islamic_app/core/utils/streak_helper.dart';

void main() {
  group('StreakHelper and Account-Linked Streak Tests', () {
    test('StreakHelper parses various date formats cleanly to YYYY-MM-DD', () {
      expect(StreakHelper.toCalendarDateString(DateTime(2026, 8, 18)), '2026-08-18');
      expect(StreakHelper.toCalendarDateString('2026-08-18T14:30:00.000Z'), '2026-08-18');
      expect(StreakHelper.toCalendarDateString('2026-08-18 10:15:00'), '2026-08-18');
      expect(StreakHelper.toCalendarDateString('2026-08-18'), '2026-08-18');
      expect(StreakHelper.toCalendarDateString(null), '');
    });

    test('calendarDaysDifference calculates exact day diffs', () {
      expect(StreakHelper.calendarDaysDifference('2026-08-17', '2026-08-18'), 1);
      expect(StreakHelper.calendarDaysDifference('2026-08-18', '2026-08-18'), 0);
      expect(StreakHelper.calendarDaysDifference('2026-08-15', '2026-08-18'), 3);
    });

    test('calculateEffectiveStreak preserves account streak on new login/reinstall', () {
      // 1. User was active yesterday (diff == 1): streak must NOT reset to 0 upon opening app
      final streakYesterday = StreakHelper.calculateEffectiveStreak(
        storedStreak: 7,
        lastActiveDate: '2026-08-17',
        referenceDate: '2026-08-18',
      );
      expect(streakYesterday, 7);

      // 2. User was active today (diff == 0): streak remains intact
      final streakToday = StreakHelper.calculateEffectiveStreak(
        storedStreak: 7,
        lastActiveDate: '2026-08-18',
        referenceDate: '2026-08-18',
      );
      expect(streakToday, 7);

      // 3. User was active 3 days ago (diff == 3): streak has expired (0)
      final streakExpired = StreakHelper.calculateEffectiveStreak(
        storedStreak: 7,
        lastActiveDate: '2026-08-15',
        referenceDate: '2026-08-18',
      );
      expect(streakExpired, 0);

      // 4. Admin created or imported user with streak: preserved
      final streakImported = StreakHelper.calculateEffectiveStreak(
        storedStreak: 12,
        lastActiveDate: null,
        referenceDate: '2026-08-18',
      );
      expect(streakImported, 12);
    });

    test('computeStreakOnDuroodRecitation increments on consecutive days and resets after gap', () {
      // Consecutive day recitation: 5 -> 6
      final consecutiveUpdate = StreakHelper.computeStreakOnDuroodRecitation(
        currentStoredStreak: 5,
        longestStoredStreak: 10,
        lastActiveDate: '2026-08-17',
        todayDateStr: '2026-08-18',
      );
      expect(consecutiveUpdate['current_streak'], 6);
      expect(consecutiveUpdate['longest_streak'], 10);

      // Same day recitation: returns empty (already recorded)
      final sameDayUpdate = StreakHelper.computeStreakOnDuroodRecitation(
        currentStoredStreak: 6,
        longestStoredStreak: 10,
        lastActiveDate: '2026-08-18',
        todayDateStr: '2026-08-18',
      );
      expect(sameDayUpdate.isEmpty, isTrue);

      // Missed 2 days: resets streak to 1, preserves all-time longest streak
      final brokenStreakUpdate = StreakHelper.computeStreakOnDuroodRecitation(
        currentStoredStreak: 6,
        longestStoredStreak: 10,
        lastActiveDate: '2026-08-15',
        todayDateStr: '2026-08-18',
      );
      expect(brokenStreakUpdate['current_streak'], 1);
      expect(brokenStreakUpdate['longest_streak'], 10);

      // New record streak
      final newRecordUpdate = StreakHelper.computeStreakOnDuroodRecitation(
        currentStoredStreak: 10,
        longestStoredStreak: 10,
        lastActiveDate: '2026-08-17',
        todayDateStr: '2026-08-18',
      );
      expect(newRecordUpdate['current_streak'], 11);
      expect(newRecordUpdate['longest_streak'], 11);
    });

    test('AppUser parses cloud account data and resolves effective streak consistently', () {
      final userMap = {
        'user_id': 'uid_123',
        'username': 'Tariq',
        'email': 'tariq@gmail.com',
        'current_streak': 15,
        'longest_streak': 20,
        'last_active_durood_date': '2026-08-17',
      };

      final user = AppUser.fromMap(userMap);
      expect(user.currentStreak, 15);
      expect(user.longestStreak, 20);
    });
  });
}
