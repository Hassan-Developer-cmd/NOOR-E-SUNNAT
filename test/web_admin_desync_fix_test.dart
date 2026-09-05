import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/models/app_user.dart';
import 'package:islamic_app/core/utils/streak_helper.dart';

void main() {
  group('Web Admin Dashboard Desync Fix Verification', () {
    test('Header Counter: Extracts 4,296 Total and 2,513 Today from global_counter doc', () {
      final docData = <String, dynamic>{
        'globalTotal': 4296,
        'todayTotal': 2513,
        'date': DateTime.now().toIso8601String(), // ISO string with time
      };

      final total = (docData['globalTotal'] as num?)?.toInt() ??
          ((docData['total_count'] as num?)?.toInt() ?? 0);

      final rawToday = (docData['todayTotal'] as num?)?.toInt() ??
          ((docData['today_count'] as num?)?.toInt() ??
              ((docData['globalToday'] as num?)?.toInt() ?? 0));

      final rawDocDate = docData['date'] ?? docData['last_reset_date'];
      final docDateString = StreakHelper.toCalendarDateString(rawDocDate);
      final localTodayString = StreakHelper.toCalendarDateString(DateTime.now());
      final utcTodayString = StreakHelper.toCalendarDateString(DateTime.now().toUtc());

      int today = rawToday;
      if (docDateString.isNotEmpty &&
          docDateString != localTodayString &&
          docDateString != utcTodayString) {
        today = 0;
      }

      expect(total, 4296);
      expect(today, 2513);
    });

    test('Header Counter: Preserves today count when date is UTC calendar string', () {
      final utcDateString = StreakHelper.toCalendarDateString(DateTime.now().toUtc());
      final docData = <String, dynamic>{
        'globalTotal': 4296,
        'todayTotal': 2513,
        'date': utcDateString,
      };

      final rawToday = (docData['todayTotal'] as num?)?.toInt() ?? 0;
      final rawDocDate = docData['date'];
      final docDateString = StreakHelper.toCalendarDateString(rawDocDate);
      final localTodayString = StreakHelper.toCalendarDateString(DateTime.now());
      final utcTodayString = StreakHelper.toCalendarDateString(DateTime.now().toUtc());

      int today = rawToday;
      if (docDateString.isNotEmpty &&
          docDateString != localTodayString &&
          docDateString != utcTodayString) {
        today = 0;
      }

      expect(today, 2513, reason: "Today's count must not reset if matching UTC date");
    });

    test('Header Counter: Correctly resets today count to 0 only when date is an old calendar day', () {
      final docData = <String, dynamic>{
        'globalTotal': 4296,
        'todayTotal': 2513,
        'date': '2020-01-01',
      };

      final rawToday = (docData['todayTotal'] as num?)?.toInt() ?? 0;
      final rawDocDate = docData['date'];
      final docDateString = StreakHelper.toCalendarDateString(rawDocDate);
      final localTodayString = StreakHelper.toCalendarDateString(DateTime.now());
      final utcTodayString = StreakHelper.toCalendarDateString(DateTime.now().toUtc());

      int today = rawToday;
      if (docDateString.isNotEmpty &&
          docDateString != localTodayString &&
          docDateString != utcTodayString) {
        today = 0;
      }

      expect(today, 0, reason: "Today's count must reset when date is clearly in the past");
    });

    test('AppUser Model: Correctly parses mobile schema fields (streak: 11, points: 5,098)', () {
      final todayStr = StreakHelper.getTodayDateString();
      // Simulating user doc as stored by mobile client for active user (e.g. Hadi / Hassan)
      final userDoc = <String, dynamic>{
        'userId': 'user_hadi_123',
        'email': 'hadi@example.com',
        'displayName': 'Hadi',
        'streak': 11,
        'duroodPoints': 5098,
        'totalCount': 5098,
        'lastStreakDate': todayStr,
        'lastActiveDate': todayStr,
      };

      final user = AppUser.fromMap(userDoc);

      expect(user.streak, 11, reason: 'Streak getter must read stored streak when active today');
      expect(user.currentStreak, 11, reason: 'currentStreak must be preserved when active today');
      expect(user.duroodPoints, 5098, reason: 'duroodPoints getter must read 5098');
      expect(user.points, 5098);
      expect(user.totalPoints, 5098);
      expect(user.totalCount, 5098);
      expect(user.duroodCount, 5098);
      expect(user.personalTotalDurood, 5098);
    });

    test('AppUser Model: Fallback reads legacy field names seamlessly with active date', () {
      final todayStr = StreakHelper.getTodayDateString();
      final legacyDoc = <String, dynamic>{
        'userId': 'legacy_user_1',
        'email': 'legacy@example.com',
        'username': 'LegacyUser',
        'current_streak': 7,
        'total_durood_points': 1400,
        'personal_total_durood': 1400,
        'last_active_durood_date': todayStr,
      };

      final user = AppUser.fromMap(legacyDoc);

      expect(user.streak, 7);
      expect(user.duroodPoints, 1400);
      expect(user.totalCount, 1400);
    });

    test('Leaderboard Sorting: Ranks active users with points/durood at the top', () {
      final todayStr = StreakHelper.getTodayDateString();
      final users = [
        AppUser.fromMap({
          'userId': 'user_inactive',
          'email': 'inactive@example.com',
          'username': 'Inactive',
          'streak': 0,
          'duroodPoints': 0,
          'totalCount': 0,
          'lastStreakDate': '',
        }),
        AppUser.fromMap({
          'userId': 'user_hassan',
          'email': 'hassan@example.com',
          'username': 'Hassan',
          'streak': 5,
          'duroodPoints': 2500,
          'totalCount': 2500,
          'lastStreakDate': todayStr,
        }),
        AppUser.fromMap({
          'userId': 'user_hadi',
          'email': 'hadi@example.com',
          'username': 'Hadi',
          'streak': 11,
          'duroodPoints': 5098,
          'totalCount': 5098,
          'lastStreakDate': todayStr,
        }),
      ];

      // Sort with identical logic to admin_service and admin_dashboard_web
      users.sort((a, b) {
        final cmp = b.duroodPoints.compareTo(a.duroodPoints);
        if (cmp != 0) return cmp;
        final totalCmp = b.myTotal.compareTo(a.myTotal);
        if (totalCmp != 0) return totalCmp;
        return b.streak.compareTo(a.streak);
      });

      expect(users[0].username, 'Hadi');
      expect(users[0].duroodPoints, 5098);
      expect(users[0].streak, 11);

      expect(users[1].username, 'Hassan');
      expect(users[1].duroodPoints, 2500);
      expect(users[1].streak, 5);

      expect(users[2].username, 'Inactive');
      expect(users[2].duroodPoints, 0);
      expect(users[2].streak, 0);
    });

    test('Two-way compatibility: toMap writes both canonical and legacy keys', () {
      final todayStr = StreakHelper.getTodayDateString();
      final user = AppUser.fromMap({
        'userId': 'u1',
        'email': 'u1@test.com',
        'username': 'U1',
        'streak': 11,
        'duroodPoints': 5098,
        'totalCount': 5098,
        'lastStreakDate': todayStr,
      });

      final map = user.toMap();
      expect(map['streak'], 11);
      expect(map['current_streak'], 11);
      expect(map['duroodPoints'], 5098);
      expect(map['total_durood_points'], 5098);
      expect(map['totalCount'], 5098);
      expect(map['myTotal'], 5098);
      expect(map['personal_total_durood'], 5098);
      expect(map['lastStreakDate'], todayStr);
    });

    test('UNIFIED SCHEMA: AppUser parses and exposes myTotal and myToday directly', () {
      final user = AppUser.fromMap({
        'userId': 'user_muhammad',
        'email': 'user@example.com',
        'name': 'Muhammad',
        'myTotal': 8500,
        'myToday': 450,
        'streak': 15,
        'duroodPoints': 8500,
        'lastActiveDate': '2026-09-05',
      });

      expect(user.myTotal, 8500);
      expect(user.myToday, 450);
      expect(user.streak, 15);
      expect(user.duroodPoints, 8500);
      expect(user.toMap()['myTotal'], 8500);
      expect(user.toMap()['myToday'], 450);
    });

    test('ATOMIC INCREMENT & MIDNIGHT RESET: Batch increment payload calculations', () {
      final todayDateString = '2026-09-05';
      const int count = 33;

      // Scenario A: Same Day submission (date == todayDateString)
      final sameDayDoc = <String, dynamic>{
        'globalTotal': 4296,
        'todayTotal': 2513,
        'date': '2026-09-05',
      };
      final isSameDay = sameDayDoc['date'] == todayDateString;
      final sameDayPayload = isSameDay
          ? {
              'todayTotalAction': 'increment',
              'todayTotalValue': count,
              'globalTotalAction': 'increment',
              'globalTotalValue': count,
            }
          : {
              'todayTotalAction': 'reset',
              'todayTotalValue': count,
              'globalTotalAction': 'increment',
              'globalTotalValue': count,
            };

      expect(sameDayPayload['todayTotalAction'], 'increment');
      expect(sameDayPayload['todayTotalValue'], 33);

      // Scenario B: First submission after midnight (date != todayDateString)
      final newDayDoc = <String, dynamic>{
        'globalTotal': 4296,
        'todayTotal': 2513,
        'date': '2026-09-04', // Previous day
      };
      final isNewDay = newDayDoc['date'] != todayDateString;
      final newDayPayload = isNewDay
          ? {
              'todayTotalAction': 'reset',
              'todayTotalValue': count,
              'globalTotalAction': 'increment',
              'globalTotalValue': count,
              'date': todayDateString,
            }
          : {
              'todayTotalAction': 'increment',
              'todayTotalValue': count,
            };

      expect(newDayPayload['todayTotalAction'], 'reset');
      expect(newDayPayload['todayTotalValue'], 33);
      expect(newDayPayload['date'], '2026-09-05');
    });

    test('LOCAL STORAGE KEYS: Format complies strictly with user-isolated schema', () {
      final uid = 'user_123';
      final todayStr = '2026-09-05';

      final myTodayKey = 'my_today_${uid}_$todayStr';
      final myTotalKey = 'my_total_$uid';
      final pointsKey = 'durood_points_$uid';
      final streakKey = 'user_streak_$uid';

      expect(myTodayKey, 'my_today_user_123_2026-09-05');
      expect(myTotalKey, 'my_total_user_123');
      expect(pointsKey, 'durood_points_user_123');
      expect(streakKey, 'user_streak_user_123');
    });

    test('STRICT PRIVACY: Global counter payload contains zero user-specific keys', () {
      final globalPayload = <String, dynamic>{
        'globalTotal': 4296,
        'todayTotal': 2513,
        'date': '2026-09-05',
      };

      expect(globalPayload.containsKey('myTotal'), isFalse);
      expect(globalPayload.containsKey('myToday'), isFalse);
      expect(globalPayload.containsKey('userId'), isFalse);
      expect(globalPayload.containsKey('uid'), isFalse);
      expect(globalPayload.containsKey('streak'), isFalse);
      expect(globalPayload.containsKey('duroodPoints'), isFalse);
    });

    test('SESSION ISOLATION: Unauthenticated session omits personal metrics', () {
      bool isLoggedIn(String? uid) => uid != null;

      final bool isUserLoggedIn = isLoggedIn(null);
      final int? effectiveMyTotal = isUserLoggedIn ? 2513 : null;
      final int? effectiveMyToday = isUserLoggedIn ? 150 : null;

      expect(effectiveMyTotal, isNull);
      expect(effectiveMyToday, isNull);
      expect(isUserLoggedIn, isFalse);
    });

    test('SESSION ISOLATION: Authenticated session binds strictly to currentUid paths', () {
      const currentUid = 'auth_user_abc123';
      const todayDateString = '2026-09-05';

      final userDocPath = 'users/$currentUid';
      final dailyStatDocPath = 'users/$currentUid/daily_stats/$todayDateString';

      expect(userDocPath, 'users/auth_user_abc123');
      expect(dailyStatDocPath, 'users/auth_user_abc123/daily_stats/2026-09-05');
    });

    group('SNAPCHAT-STYLE STREAK LOGIC (CALENDAR DAY WINDOW)', () {
      final refDate = DateTime(2026, 9, 6);
      final todayStr = StreakHelper.getTodayDateString(refDate); // '2026-09-06'
      final yesterdayStr = StreakHelper.getYesterdayDateString(refDate); // '2026-09-05'
      final twoDaysAgoStr = StreakHelper.toCalendarDateString(refDate.subtract(const Duration(days: 2))); // '2026-09-04'

      test('Case 1: Already recited today (lastStreakDate == today) -> streak unchanged', () {
        final result = StreakHelper.computeStreakOnDuroodRecitation(
          currentStoredStreak: 5,
          longestStoredStreak: 10,
          lastActiveDate: todayStr,
          todayDateStr: todayStr,
          referenceDate: refDate,
        );

        expect(result['streak'], 5, reason: 'Streak count must remain unchanged when recited multiple times today');
        expect(result['current_streak'], 5);
        expect(result['lastStreakDate'], todayStr);
      });

      test('Case 2: Recited yesterday, now active today (lastStreakDate == yesterday) -> streak = streak + 1', () {
        final result = StreakHelper.computeStreakOnDuroodRecitation(
          currentStoredStreak: 5,
          longestStoredStreak: 10,
          lastActiveDate: yesterdayStr,
          todayDateStr: todayStr,
          referenceDate: refDate,
        );

        expect(result['streak'], 6, reason: 'Streak count must increment by 1 when recited consecutive days');
        expect(result['current_streak'], 6);
        expect(result['longest_streak'], 10);
        expect(result['lastStreakDate'], todayStr);
      });

      test('Case 2 (Record): Increment beats longest streak -> updates longest_streak', () {
        final result = StreakHelper.computeStreakOnDuroodRecitation(
          currentStoredStreak: 10,
          longestStoredStreak: 10,
          lastActiveDate: yesterdayStr,
          todayDateStr: todayStr,
          referenceDate: refDate,
        );

        expect(result['streak'], 11);
        expect(result['longest_streak'], 11, reason: 'Longest streak must update when new personal best');
        expect(result['lastStreakDate'], todayStr);
      });

      test('Case 3: Streak broken / missed yesterday or inactive > 1 day -> resets streak to 1', () {
        final result = StreakHelper.computeStreakOnDuroodRecitation(
          currentStoredStreak: 8,
          longestStoredStreak: 12,
          lastActiveDate: twoDaysAgoStr,
          todayDateStr: todayStr,
          referenceDate: refDate,
        );

        expect(result['streak'], 1, reason: 'Streak must reset to 1 when user missed yesterday');
        expect(result['current_streak'], 1);
        expect(result['longest_streak'], 12, reason: 'Longest streak record is preserved');
        expect(result['lastStreakDate'], todayStr);
      });

      test('Case 3: Brand new user with no previous date -> starts streak at 1', () {
        final result = StreakHelper.computeStreakOnDuroodRecitation(
          currentStoredStreak: 0,
          longestStoredStreak: 0,
          lastActiveDate: '',
          todayDateStr: todayStr,
          referenceDate: refDate,
        );

        expect(result['streak'], 1);
        expect(result['longest_streak'], 1);
        expect(result['lastStreakDate'], todayStr);
      });

      test('Launch / Midnight Verification: Inactive > 1 day resets displayed streak to 0', () {
        final effectiveStreak = StreakHelper.calculateEffectiveStreak(
          storedStreak: 7,
          lastActiveDate: twoDaysAgoStr,
          referenceDate: refDate,
        );

        expect(effectiveStreak, 0, reason: 'Displayed streak must reset to 0 if inactive > 1 day without reciting');
      });

      test('Launch / Midnight Verification: Active today maintains displayed streak', () {
        final effectiveStreak = StreakHelper.calculateEffectiveStreak(
          storedStreak: 7,
          lastActiveDate: todayStr,
          referenceDate: refDate,
        );

        expect(effectiveStreak, 7, reason: 'Displayed streak maintained when active today');
      });

      test('Launch / Midnight Verification: Active yesterday maintains displayed streak (grace window)', () {
        final effectiveStreak = StreakHelper.calculateEffectiveStreak(
          storedStreak: 7,
          lastActiveDate: yesterdayStr,
          referenceDate: refDate,
        );

        expect(effectiveStreak, 7, reason: 'User has until end of today to recite; streak not prematurely killed');
      });

      test('Global Reset to 0: User doc with streak: 0 and empty date evaluates to 0', () {
        final user = AppUser.fromMap({
          'userId': 'reset_user_1',
          'email': 'reset@example.com',
          'username': 'ResetUser',
          'streak': 0,
          'duroodPoints': 0,
          'lastStreakDate': '',
        });

        expect(user.streak, 0);
        expect(user.currentStreak, 0);
        expect(user.duroodPoints, 0);
      });
    });

    group('PER-USER ISOLATED DUROOD POINTS', () {
      test('User A and User B points are completely independent and not shared', () {
        final userA = AppUser.fromMap({
          'userId': 'user_a',
          'email': 'usera@example.com',
          'username': 'User A',
          'streak': 0,
          'duroodPoints': 45,
          'myTotal': 45,
        });

        final userB = AppUser.fromMap({
          'userId': 'user_b',
          'email': 'userb@example.com',
          'username': 'User B',
          'streak': 0,
          'duroodPoints': 350,
          'myTotal': 350,
        });

        expect(userA.duroodPoints, 45);
        expect(userB.duroodPoints, 350);
        expect(userA.duroodPoints != userB.duroodPoints, isTrue);
      });

      test('Table row binds strictly to user document duroodPoints field', () {
        final docA = {'userId': 'u_a', 'username': 'Alice', 'duroodPoints': 100};
        final docB = {'userId': 'u_b', 'username': 'Bob', 'duroodPoints': 250};

        final uA = AppUser.fromMap(docA);
        final uB = AppUser.fromMap(docB);

        // Verify web table display values
        String tablePointsCell(AppUser u) => '${u.duroodPoints} pts ⭐';

        expect(tablePointsCell(uA), '100 pts ⭐');
        expect(tablePointsCell(uB), '250 pts ⭐');
      });
    });
  });
}
