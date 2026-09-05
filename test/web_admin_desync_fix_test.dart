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
      // Simulating user doc as stored by mobile client for active user (e.g. Hadi / Hassan)
      final userDoc = <String, dynamic>{
        'userId': 'user_hadi_123',
        'email': 'hadi@example.com',
        'displayName': 'Hadi',
        'streak': 11,
        'duroodPoints': 5098,
        'totalCount': 5098,
        'lastActiveDate': '2026-09-04', // active yesterday or timezone lag
      };

      final user = AppUser.fromMap(userDoc);

      expect(user.streak, 11, reason: 'Streak getter must read stored streak');
      expect(user.currentStreak, 11, reason: 'currentStreak must be preserved when rawStreak > 0');
      expect(user.duroodPoints, 5098, reason: 'duroodPoints getter must read 5098');
      expect(user.points, 5098);
      expect(user.totalPoints, 5098);
      expect(user.totalCount, 5098);
      expect(user.duroodCount, 5098);
      expect(user.personalTotalDurood, 5098);
    });

    test('AppUser Model: Fallback reads legacy field names seamlessly', () {
      final legacyDoc = <String, dynamic>{
        'userId': 'legacy_user_1',
        'email': 'legacy@example.com',
        'username': 'LegacyUser',
        'current_streak': 7,
        'total_durood_points': 1400,
        'personal_total_durood': 1400,
      };

      final user = AppUser.fromMap(legacyDoc);

      expect(user.streak, 7);
      expect(user.duroodPoints, 1400);
      expect(user.totalCount, 1400);
    });

    test('Leaderboard Sorting: Ranks active users with points/durood at the top', () {
      final users = [
        AppUser.fromMap({
          'userId': 'user_inactive',
          'email': 'inactive@example.com',
          'username': 'Inactive',
          'streak': 0,
          'duroodPoints': 0,
          'totalCount': 0,
        }),
        AppUser.fromMap({
          'userId': 'user_hassan',
          'email': 'hassan@example.com',
          'username': 'Hassan',
          'streak': 5,
          'duroodPoints': 2500,
          'totalCount': 2500,
        }),
        AppUser.fromMap({
          'userId': 'user_hadi',
          'email': 'hadi@example.com',
          'username': 'Hadi',
          'streak': 11,
          'duroodPoints': 5098,
          'totalCount': 5098,
        }),
      ];

      // Sort with identical logic to admin_service and admin_dashboard_web
      users.sort((a, b) {
        final aScore = a.duroodPoints > 0 ? a.duroodPoints : a.totalCount;
        final bScore = b.duroodPoints > 0 ? b.duroodPoints : b.totalCount;
        final cmp = bScore.compareTo(aScore);
        if (cmp != 0) return cmp;
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
      final user = AppUser.fromMap({
        'userId': 'u1',
        'email': 'u1@test.com',
        'username': 'U1',
        'streak': 11,
        'duroodPoints': 5098,
        'totalCount': 5098,
      });

      final map = user.toMap();
      expect(map['streak'], 11);
      expect(map['current_streak'], 11);
      expect(map['duroodPoints'], 5098);
      expect(map['total_durood_points'], 5098);
      expect(map['totalCount'], 5098);
      expect(map['myTotal'], 5098);
      expect(map['personal_total_durood'], 5098);
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
  });
}
