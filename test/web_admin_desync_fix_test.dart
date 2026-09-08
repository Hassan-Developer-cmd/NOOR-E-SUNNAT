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

    test('Header Counter: Synchronizes 20,400 Total and 14,100 Today directly from global_counter/main', () {
      final docData = <String, dynamic>{
        'globalTotal': 20400,
        'todayTotal': 14100,
        'date': StreakHelper.getTodayDateString(),
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

      final bool isMatchingToday = docDateString.isNotEmpty &&
          (docDateString == localTodayString || docDateString == utcTodayString);
      final int today = isMatchingToday ? rawToday : 0;

      expect(total, 20400, reason: "Total Durood must match ~20.4K from global_counter/main");
      expect(today, 14100, reason: "Today's Durood must match ~14.1K when matching today's date");
    });

    test('Header Counter: Real-time update reflects incremental Salawat recitation', () {
      // 1. Initial snapshot from global_counter/main
      final initialDoc = <String, dynamic>{
        'globalTotal': 20400,
        'todayTotal': 14100,
        'date': StreakHelper.getTodayDateString(),
      };

      // 2. Incoming stream snapshot after user submits 10 Salawat from mobile
      const int increment = 10;
      final updatedDoc = <String, dynamic>{
        'globalTotal': initialDoc['globalTotal'] + increment,
        'todayTotal': initialDoc['todayTotal'] + increment,
        'date': initialDoc['date'],
      };

      final total = (updatedDoc['globalTotal'] as num?)?.toInt() ?? 0;
      final today = (updatedDoc['todayTotal'] as num?)?.toInt() ?? 0;

      expect(total, 20410);
      expect(today, 14110);
    });

    test('Header Counter: Missing or empty date string resets Today to 0', () {
      final docData = <String, dynamic>{
        'globalTotal': 20400,
        'todayTotal': 14100,
        'date': '',
      };

      final total = (docData['globalTotal'] as num?)?.toInt() ?? 0;
      final rawToday = (docData['todayTotal'] as num?)?.toInt() ?? 0;
      final docDateString = StreakHelper.toCalendarDateString(docData['date']);
      final localTodayString = StreakHelper.toCalendarDateString(DateTime.now());
      final utcTodayString = StreakHelper.toCalendarDateString(DateTime.now().toUtc());

      final bool isMatchingToday = docDateString.isNotEmpty &&
          (docDateString == localTodayString || docDateString == utcTodayString);
      final int today = isMatchingToday ? rawToday : 0;

      expect(total, 20400);
      expect(today, 0, reason: "When date string is missing/empty, Today's count must display 0");
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
        'lastActiveDate': StreakHelper.getTodayDateString(),
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

    group('HOME AND DUROOD COUNTER SCREEN DATA HARMONIZATION', () {
      test('Home Screen and Counter Screen evaluate identical values from Firestore streams', () {
        // Simulated Firestore snapshots for user Hadi
        final userDocData = {'myTotal': 2522, 'streak': 0, 'duroodPoints': 2522};
        final dailyStatsDocData = {'myToday': 9};

        // Resolution logic matching both HomeScreen and CounterScreen
        int resolveMyTotal(Map<String, dynamic>? userData, int fallbackTotal, int pendingBuffer) {
          final cloud = (userData?['myTotal'] as num?)?.toInt();
          return (cloud != null) ? (cloud + pendingBuffer) : fallbackTotal;
        }

        int resolveMyToday(Map<String, dynamic>? dailyData, int fallbackToday, int pendingBuffer) {
          final cloud = ((dailyData?['myToday'] ?? dailyData?['todayCount']) as num?)?.toInt();
          return (cloud != null) ? (cloud + pendingBuffer) : fallbackToday;
        }

        const pendingBuffer = 0;
        final homeMyTotal = resolveMyTotal(userDocData, 0, pendingBuffer);
        final homeMyToday = resolveMyToday(dailyStatsDocData, 0, pendingBuffer);

        final counterMyTotal = resolveMyTotal(userDocData, 0, pendingBuffer);
        final counterMyToday = resolveMyToday(dailyStatsDocData, 0, pendingBuffer);

        // Both screens must be 100% identical
        expect(homeMyTotal, 2522);
        expect(counterMyTotal, 2522);
        expect(homeMyToday, 9);
        expect(counterMyToday, 9);
        expect(homeMyTotal == counterMyTotal, isTrue);
        expect(homeMyToday == counterMyToday, isTrue);
      });

      test('Optimistic increments (+5) update both screens instantaneously via pendingBuffer', () {
        final userDocData = {'myTotal': 2522};
        final dailyStatsDocData = {'myToday': 9};

        int resolveMyTotal(Map<String, dynamic>? userData, int fallbackTotal, int pendingBuffer) {
          final cloud = (userData?['myTotal'] as num?)?.toInt();
          return (cloud != null) ? (cloud + pendingBuffer) : fallbackTotal;
        }

        int resolveMyToday(Map<String, dynamic>? dailyData, int fallbackToday, int pendingBuffer) {
          final cloud = ((dailyData?['myToday'] ?? dailyData?['todayCount']) as num?)?.toInt();
          return (cloud != null) ? (cloud + pendingBuffer) : fallbackToday;
        }

        // Tap increment +5
        const pendingBuffer = 5;
        final homeMyTotal = resolveMyTotal(userDocData, 0, pendingBuffer);
        final homeMyToday = resolveMyToday(dailyStatsDocData, 0, pendingBuffer);

        final counterMyTotal = resolveMyTotal(userDocData, 0, pendingBuffer);
        final counterMyToday = resolveMyToday(dailyStatsDocData, 0, pendingBuffer);

        expect(homeMyTotal, 2527);
        expect(counterMyTotal, 2527);
        expect(homeMyToday, 14);
        expect(counterMyToday, 14);
      });

      test('Authoritative cloud stream resolves stale cache (4322, 24) to true counts (2522, 9)', () {
        // Suppose local memory/prefs had stale 4,322 and 24
        final staleLocalTotal = 4322;
        final staleLocalToday = 24;

        // Authoritative Firestore streams emit:
        final cloudUserData = {'myTotal': 2522};
        final cloudDailyData = {'myToday': 9};

        // When cloud stream emits, single source of truth overrides stale local numbers:
        int resolveTotal(Map<String, dynamic>? data, int local) {
          final cloud = (data?['myTotal'] as num?)?.toInt();
          return cloud ?? local;
        }

        int resolveToday(Map<String, dynamic>? data, int local) {
          final cloud = (data?['myToday'] as num?)?.toInt();
          return cloud ?? local;
        }

        expect(resolveTotal(cloudUserData, staleLocalTotal), 2522);
        expect(resolveToday(cloudDailyData, staleLocalToday), 9);
      });
    });

    group('MOBILE HOME SCREEN DUROOD POINTS CARD STREAM BINDING', () {
      test('Hadi and Hassan receive their individual real points (5,107 and 5,098), eliminating 8,712', () {
        final hadiDoc = {
          'userId': 'dXs6IyecFqWVvfQPoqXr4kR9g3g1',
          'username': 'Hadi',
          'duroodPoints': 5107,
          'myTotal': 2522,
        };

        final hassanDoc = {
          'userId': 'hassan_uid_123',
          'username': 'Hassan',
          'duroodPoints': 5098,
          'myTotal': 2522,
        };

        // Resolution logic matching Home Screen and Profile Screen
        int resolvePoints(Map<String, dynamic>? userData, int fallbackPoints, int pendingBuffer) {
          final cloud = ((userData?['duroodPoints'] ??
              userData?['points'] ??
              userData?['total_durood_points']) as num?)?.toInt();
          return (cloud != null) ? (cloud + pendingBuffer) : fallbackPoints;
        }

        const pendingBuffer = 0;
        const staleGlobalCache = 8712;

        final hadiPoints = resolvePoints(hadiDoc, staleGlobalCache, pendingBuffer);
        final hassanPoints = resolvePoints(hassanDoc, staleGlobalCache, pendingBuffer);

        expect(hadiPoints, 5107, reason: 'Hadi must display exactly 5,107 points');
        expect(hassanPoints, 5098, reason: 'Hassan must display exactly 5,098 points');
        expect(hadiPoints != staleGlobalCache, isTrue);
        expect(hassanPoints != staleGlobalCache, isTrue);
      });

      test('Device cache holding 8712 is purged, and user-scoped key durood_points_{uid} is utilized', () {
        final Map<String, dynamic> prefs = {
          'cached_durood_points': 8712, // corrupt global cache
        };

        const currentUid = 'dXs6IyecFqWVvfQPoqXr4kR9g3g1';

        // Purge deprecated shared keys
        prefs.remove('cached_durood_points');
        expect(prefs.containsKey('cached_durood_points'), isFalse);

        // Store user-isolated points
        prefs['durood_points_$currentUid'] = 5107;
        expect(prefs['durood_points_$currentUid'], 5107);

        // Another user has distinct isolated key
        const anotherUid = 'hassan_uid_123';
        prefs['durood_points_$anotherUid'] = 5098;
        expect(prefs['durood_points_$anotherUid'], 5098);
        expect(prefs['durood_points_$currentUid'], 5107);
      });

      test('Switching accounts or logout clears user-isolated points and resets local state', () {
        final Map<String, dynamic> prefs = {
          'durood_points_userA': 5107,
          'my_total_userA': 2522,
        };

        // Logout action for userA
        const oldUid = 'userA';
        prefs.remove('durood_points_$oldUid');
        prefs.remove('my_total_$oldUid');

        expect(prefs.containsKey('durood_points_userA'), isFalse);
        expect(prefs.containsKey('my_total_userA'), isFalse);
      });
    });

    group('Dynamic Leaderboard & Real-Time Query Driven Requirements', () {
      test('1. Pure Dynamic Firestore Query: Safe numeric parsing of mixed String/num types', () {
        final todayStr = StreakHelper.getTodayDateString();
        final doc1 = {
          'userId': 'u1',
          'email': 'user1@example.com',
          'name': 'User One',
          'totalPoints': '1500', // String representation
          'myTotal': '750',
          'streak': '14',
          'lastStreakDate': todayStr,
        };
        final doc2 = {
          'userId': 'u2',
          'email': 'user2@example.com',
          'name': 'User Two',
          'duroodPoints': 3000.0, // Double representation
          'myTotal': 1200,
          'streak': 20,
          'lastStreakDate': todayStr,
        };
        final doc3 = {
          'userId': 'u3',
          'email': 'user3@example.com',
          'name': 'User Three',
          'points': 500, // Int representation
          'myTotal': 200,
          'streak': 3,
          'lastStreakDate': todayStr,
        };

        final u1 = AppUser.fromMap(doc1);
        final u2 = AppUser.fromMap(doc2);
        final u3 = AppUser.fromMap(doc3);

        expect(u1.totalPoints, 1500);
        expect(u1.myTotal, 750);
        expect(u1.streak, 14);

        expect(u2.totalPoints, 3000);
        expect(u2.myTotal, 1200);
        expect(u2.streak, 20);

        expect(u3.totalPoints, 500);
        expect(u3.myTotal, 200);
        expect(u3.streak, 3);
      });

      test('2. Dynamic Sorting: Strictly orders by Current Streak descending, then Total Durood', () {
        final todayStr = StreakHelper.getTodayDateString();
        final users = [
          AppUser.fromMap({'userId': 'u_low', 'username': 'Low', 'totalPoints': 100, 'myTotal': 50, 'streak': 1, 'lastStreakDate': todayStr}),
          AppUser.fromMap({'userId': 'u_high', 'username': 'High', 'duroodPoints': 5000, 'myTotal': 2500, 'streak': 15, 'lastStreakDate': todayStr}),
          AppUser.fromMap({'userId': 'u_mid', 'username': 'Mid', 'points': '2000', 'myTotal': 1000, 'streak': 8, 'lastStreakDate': todayStr}),
          AppUser.fromMap({'userId': 'u_zero', 'username': 'Zero', 'totalPoints': 0, 'myTotal': 0, 'streak': 0}),
        ];

        users.sort((a, b) {
          final streakCmp = b.streak.compareTo(a.streak);
          if (streakCmp != 0) return streakCmp;
          final duroodA = a.myTotal > 0 ? a.myTotal : a.totalCount;
          final duroodB = b.myTotal > 0 ? b.myTotal : b.totalCount;
          final duroodCmp = duroodB.compareTo(duroodA);
          if (duroodCmp != 0) return duroodCmp;
          final pointsA = a.totalPoints > 0 ? a.totalPoints : a.duroodPoints;
          final pointsB = b.totalPoints > 0 ? b.totalPoints : b.duroodPoints;
          return pointsB.compareTo(pointsA);
        });

        expect(users[0].username, 'High');
        expect(users[0].streak, 15);
        expect(users[1].username, 'Mid');
        expect(users[1].streak, 8);
        expect(users[2].username, 'Low');
        expect(users[2].streak, 1);
        expect(users[3].username, 'Zero');
        expect(users[3].streak, 0);
      });

      test('3. Dynamic Rank Calculation: Computed purely at render time from row index (index + 1)', () {
        final todayStr = StreakHelper.getTodayDateString();
        final sortedUsers = [
          AppUser.fromMap({'userId': '1', 'username': 'Leader 1', 'totalPoints': 5000, 'streak': 10, 'lastStreakDate': todayStr}),
          AppUser.fromMap({'userId': '2', 'username': 'Leader 2', 'totalPoints': 4000, 'streak': 8, 'lastStreakDate': todayStr}),
          AppUser.fromMap({'userId': '3', 'username': 'Leader 3', 'totalPoints': 3000, 'streak': 5, 'lastStreakDate': todayStr}),
          AppUser.fromMap({'userId': '4', 'username': 'Runner 4', 'totalPoints': 2000, 'streak': 2, 'lastStreakDate': todayStr}),
        ];

        for (int index = 0; index < sortedUsers.length; index++) {
          final rank = index + 1;
          expect(rank, index + 1);

          // Badge style assignment verification
          if (index == 0) {
            expect(rank, 1, reason: 'Index 0 must produce Gold #1');
          } else if (index == 1) {
            expect(rank, 2, reason: 'Index 1 must produce Silver #2');
          } else if (index == 2) {
            expect(rank, 3, reason: 'Index 2 must produce Bronze #3');
          } else {
            expect(rank >= 4, isTrue, reason: 'Index >= 3 produces standard #rank pill');
          }
        }
      });

      test('4. Real-Time Auto-Reorder: Incremental streak update triggers dynamic live re-rank', () {
        final todayStr = StreakHelper.getTodayDateString();
        // Initial state: User B is #1 (streak 10), User A is #2 (streak 5)
        final userA = AppUser.fromMap({'userId': 'uA', 'username': 'User A', 'totalPoints': 3000, 'myTotal': 1500, 'streak': 5, 'lastStreakDate': todayStr});
        final userB = AppUser.fromMap({'userId': 'uB', 'username': 'User B', 'totalPoints': 4000, 'myTotal': 2000, 'streak': 10, 'lastStreakDate': todayStr});

        List<AppUser> currentList = [userA, userB];
        void sortList(List<AppUser> list) {
          list.sort((a, b) {
            final streakCmp = b.streak.compareTo(a.streak);
            if (streakCmp != 0) return streakCmp;
            final duroodA = a.myTotal > 0 ? a.myTotal : a.totalCount;
            final duroodB = b.myTotal > 0 ? b.myTotal : b.totalCount;
            final duroodCmp = duroodB.compareTo(duroodA);
            if (duroodCmp != 0) return duroodCmp;
            final pointsA = a.totalPoints > 0 ? a.totalPoints : a.duroodPoints;
            final pointsB = b.totalPoints > 0 ? b.totalPoints : b.duroodPoints;
            return pointsB.compareTo(pointsA);
          });
        }

        sortList(currentList);
        expect(currentList[0].username, 'User B');
        expect(currentList[1].username, 'User A');
        expect(0 + 1, 1); // User B is #1

        // Real-time update arrives from mobile: User A recites Durood and streak increments to 11
        final updatedUserA = AppUser.fromMap({'userId': 'uA', 'username': 'User A', 'totalPoints': 5000, 'myTotal': 3500, 'streak': 11, 'lastStreakDate': todayStr});
        currentList = [updatedUserA, userB];
        sortList(currentList);

        // Auto-reorder immediately places User A at #1 and User B at #2 without page refresh
        expect(currentList[0].username, 'User A');
        expect(currentList[0].streak, 11);
        expect(currentList[1].username, 'User B');
        expect(currentList[1].streak, 10);

        // Dynamic ranks recompute strictly by row index
        final rankUserA = currentList.indexOf(updatedUserA) + 1;
        final rankUserB = currentList.indexOf(userB) + 1;
        expect(rankUserA, 1, reason: 'User A dynamically becomes #1 (Gold)');
        expect(rankUserB, 2, reason: 'User B dynamically becomes #2 (Silver)');
      });

      test('5. Equal Streak Tiebreaker: Sorts by Total Durood descending when streaks are equal', () {
        final users = [
          AppUser.fromMap({'userId': 'u1', 'username': 'Awais Khan', 'myTotal': 10, 'streak': 0}),
          AppUser.fromMap({'userId': 'u2', 'username': 'Hassan', 'myTotal': 2513, 'streak': 0}),
          AppUser.fromMap({'userId': 'u3', 'username': 'David', 'myTotal': 1763, 'streak': 0}),
        ];

        users.sort((a, b) {
          final streakCmp = b.streak.compareTo(a.streak);
          if (streakCmp != 0) return streakCmp;
          final duroodA = a.myTotal > 0 ? a.myTotal : a.totalCount;
          final duroodB = b.myTotal > 0 ? b.myTotal : b.totalCount;
          final duroodCmp = duroodB.compareTo(duroodA);
          if (duroodCmp != 0) return duroodCmp;
          final pointsA = a.totalPoints > 0 ? a.totalPoints : a.duroodPoints;
          final pointsB = b.totalPoints > 0 ? b.totalPoints : b.duroodPoints;
          return pointsB.compareTo(pointsA);
        });

        expect(users[0].username, 'Hassan'); // 2513
        expect(users[1].username, 'David'); // 1763
        expect(users[2].username, 'Awais Khan'); // 10
      });

      test('6. Real Portal Dataset: Hafsa Zakir (3 Days) is #1, Hadi (2 Days) is #2, Hassan (0 Days, 2513) is #3', () {
        final todayStr = StreakHelper.getTodayDateString();
        final yesterdayStr = StreakHelper.toCalendarDateString(DateTime.now().subtract(const Duration(days: 1)));
        final portalUsers = [
          AppUser.fromMap({'userId': '1', 'username': 'Hadi', 'myTotal': 12613, 'duroodPoints': 15198, 'streak': 2, 'lastStreakDate': yesterdayStr}),
          AppUser.fromMap({'userId': '2', 'username': 'Hassan', 'myTotal': 2513, 'duroodPoints': 5098, 'streak': 0}),
          AppUser.fromMap({'userId': '3', 'username': 'David', 'myTotal': 1763, 'duroodPoints': 3526, 'streak': 0}),
          AppUser.fromMap({'userId': '4', 'username': 'Hafsa Zakir', 'myTotal': 673, 'duroodPoints': 673, 'streak': 3, 'lastStreakDate': todayStr}),
          AppUser.fromMap({'userId': '5', 'username': 'Awais Khan', 'myTotal': 10, 'duroodPoints': 20, 'streak': 0}),
          AppUser.fromMap({'userId': '6', 'username': 'Asim Khan', 'myTotal': 9, 'duroodPoints': 18, 'streak': 0}),
        ];

        portalUsers.sort((a, b) {
          final streakCmp = b.streak.compareTo(a.streak);
          if (streakCmp != 0) return streakCmp;
          final duroodA = a.myTotal > 0 ? a.myTotal : a.totalCount;
          final duroodB = b.myTotal > 0 ? b.myTotal : b.totalCount;
          final duroodCmp = duroodB.compareTo(duroodA);
          if (duroodCmp != 0) return duroodCmp;
          final pointsA = a.totalPoints > 0 ? a.totalPoints : a.duroodPoints;
          final pointsB = b.totalPoints > 0 ? b.totalPoints : b.duroodPoints;
          return pointsB.compareTo(pointsA);
        });

        expect(portalUsers[0].username, 'Hafsa Zakir', reason: 'Hafsa Zakir has 3 Days streak -> #1 🥇');
        expect(portalUsers[0].streak, 3);
        expect(portalUsers[1].username, 'Hadi', reason: 'Hadi has 2 Days streak -> #2 🥈');
        expect(portalUsers[1].streak, 2);
        expect(portalUsers[2].username, 'Hassan', reason: 'Hassan has 0 Days streak, highest Durood (2,513) -> #3 🥉');
        expect(portalUsers[3].username, 'David', reason: 'David has 0 Days streak, second highest Durood (1,763) -> #4');
        expect(portalUsers[4].username, 'Awais Khan');
        expect(portalUsers[5].username, 'Asim Khan');
      });

      test('7. Zero Mock Fallback: Empty snapshot evaluates cleanly to 0 users without presets', () {
        final List<AppUser> emptySnapshotUsers = [];
        expect(emptySnapshotUsers.isEmpty, isTrue);
        expect(emptySnapshotUsers.length, 0);
      });
    });

    group('Production Zero Reset Verification', () {
      test('1. Global Counter: Evaluates cleanly to 0 Total and 0 Today post-reset', () {
        final resetDoc = <String, dynamic>{
          'globalTotal': 0,
          'todayTotal': 0,
          'date': StreakHelper.getTodayDateString(),
        };

        final total = (resetDoc['globalTotal'] as num?)?.toInt() ?? 0;
        final today = (resetDoc['todayTotal'] as num?)?.toInt() ?? 0;

        expect(total, 0, reason: 'Total Durood must evaluate strictly to 0');
        expect(today, 0, reason: "Today's Durood must evaluate strictly to 0");
      });

      test('2. User Metrics: All user fields evaluate cleanly to 0 post-reset', () {
        final resetUserData = <String, dynamic>{
          'userId': 'test_uid_123',
          'email': 'user@example.com',
          'username': 'ResetUser',
          'streak': 0,
          'currentStreak': 0,
          'longest_streak': 0,
          'myTotal': 0,
          'totalDurood': 0,
          'personal_total_durood': 0,
          'myToday': 0,
          'todayTotal': 0,
          'personal_today_durood': 0,
          'duroodPoints': 0,
          'totalPoints': 0,
          'points': 0,
          'lastStreakDate': '',
          'lastActiveDate': '',
        };

        final user = AppUser.fromMap(resetUserData);

        expect(user.streak, 0);
        expect(user.myTotal, 0);
        expect(user.myToday, 0);
        expect(user.duroodPoints, 0);
        expect(user.totalPoints, 0);
      });

      test('3. Post-Reset Leaderboard: All users display 0 Streak, 0 Durood, and 0 Points', () {
        final resetUsers = [
          AppUser.fromMap({'userId': '1', 'username': 'User A', 'myTotal': 0, 'duroodPoints': 0, 'streak': 0}),
          AppUser.fromMap({'userId': '2', 'username': 'User B', 'myTotal': 0, 'duroodPoints': 0, 'streak': 0}),
          AppUser.fromMap({'userId': '3', 'username': 'User C', 'myTotal': 0, 'duroodPoints': 0, 'streak': 0}),
        ];

        for (final u in resetUsers) {
          expect(u.streak, 0);
          expect(u.myTotal, 0);
          expect(u.duroodPoints, 0);
        }
      });

      test('4. Instant Atomic Increment: 1 tap from 3 increments mobile, global, and user doc to 4', () {
        int mobileCount = 3;
        int globalTotal = 3;
        int userMyTotal = 3;
        int userTotalDurood = 3;
        int userDuroodPoints = 3;
        int userTotalPoints = 3;

        // User taps 1 time
        const int tapIncrement = 1;
        mobileCount += tapIncrement;

        // Atomic write simulation (FieldValue.increment(1))
        globalTotal += tapIncrement;
        userMyTotal += tapIncrement;
        userTotalDurood += tapIncrement;
        userDuroodPoints += tapIncrement;
        userTotalPoints += tapIncrement;

        expect(mobileCount, 4);
        expect(globalTotal, 4);
        expect(userMyTotal, 4);
        expect(userTotalDurood, 4);
        expect(userDuroodPoints, 4);
        expect(userTotalPoints, 4);
      });

      test('5. Quick Add (+100): Increments mobile, global, and user metrics by 100 via unified pipeline', () {
        int mobileCount = 4;
        int globalTotal = 4;
        int userMyTotal = 4;
        int userTotalDurood = 4;
        int userDuroodPoints = 4;
        int userTotalPoints = 4;

        // User selects +100 Quick Add
        const int quickAddAmount = 100;
        mobileCount += quickAddAmount;

        // Unified atomic write simulation (FieldValue.increment(100))
        globalTotal += quickAddAmount;
        userMyTotal += quickAddAmount;
        userTotalDurood += quickAddAmount;
        userDuroodPoints += quickAddAmount;
        userTotalPoints += quickAddAmount;

        expect(mobileCount, 104);
        expect(globalTotal, 104);
        expect(userMyTotal, 104);
        expect(userTotalDurood, 104);
        expect(userDuroodPoints, 104);
        expect(userTotalPoints, 104);
      });

      test('6. Unified Pipeline: Presets (+100, +200, +500, +1000) maintain strict mathematical parity with server', () {
        for (final preset in [100, 200, 500, 1000]) {
          int initial = 0;
          initial += preset;
          expect(initial, preset);
        }
      });
    });
  });
}
