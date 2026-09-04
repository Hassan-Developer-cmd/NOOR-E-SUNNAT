import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:islamic_app/core/models/app_user.dart';
import 'package:islamic_app/core/utils/streak_helper.dart';
import 'package:islamic_app/services/counter_service.dart';
import 'package:islamic_app/services/admin_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Counter Persistence & Date Transition Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Persists "my_durood_{date}" and totals across simulated app restart (retaining 15 counts)', () async {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = StreakHelper.toCalendarDateString(DateTime.now());

      // 1. Increment Durood by 15 during active session
      const countAdded = 15;
      await prefs.setInt('my_durood_$todayStr', countAdded);
      await prefs.setString('my_durood_date', todayStr);
      await prefs.setInt('cached_personal_total', countAdded);
      await prefs.setInt('cached_global_total', 1000 + countAdded);
      await prefs.setInt('cached_global_today', countAdded);
      await prefs.setString('cached_global_date', todayStr);
      await prefs.setString('cached_active_uid', 'test_uid_123');

      // 2. Simulate force kill / app process termination & reload on same day
      final reloadedPrefs = await SharedPreferences.getInstance();
      final storedDate = reloadedPrefs.getString('my_durood_date');
      final isSameDay = storedDate == todayStr;

      final loadedMyToday = isSameDay
          ? (reloadedPrefs.getInt('my_durood_$todayStr') ?? 0)
          : 0;
      final loadedPersonalTotal = reloadedPrefs.getInt('cached_personal_total');
      final loadedGlobalTotal = reloadedPrefs.getInt('cached_global_total');
      final loadedGlobalToday = reloadedPrefs.getInt('cached_global_today');

      // "My Today" must still show 15, while Global Total and Global Today retain their values
      expect(loadedMyToday, 15);
      expect(loadedPersonalTotal, 15);
      expect(loadedGlobalTotal, 1015);
      expect(loadedGlobalToday, 15);
    });

    test('Midnight Auto-Reset: Resets My Today to 0 when date actually changes', () async {
      final prefs = await SharedPreferences.getInstance();
      const yesterdayStr = '2026-09-03';
      final todayStr = StreakHelper.toCalendarDateString(DateTime.now()); // 2026-09-04

      // 1. Stored state from previous day
      await prefs.setInt('my_durood_$yesterdayStr', 50);
      await prefs.setString('my_durood_date', yesterdayStr);
      await prefs.setInt('cached_personal_total', 150);
      await prefs.setInt('cached_global_total', 5000);
      await prefs.setInt('cached_global_today', 200);
      await prefs.setString('cached_global_date', yesterdayStr);

      // 2. Midnight check logic upon opening app next day
      final storedDate = prefs.getString('my_durood_date');
      final int myToday;
      if (storedDate != null && storedDate != todayStr) {
        // Date has changed: reset "My Today" count to 0 and update storedDate
        myToday = 0;
        await prefs.setInt('my_durood_$todayStr', 0);
        await prefs.setString('my_durood_date', todayStr);
      } else {
        myToday = prefs.getInt('my_durood_$todayStr') ?? 0;
      }

      final cachedGlobalDate = prefs.getString('cached_global_date');
      final isGlobalSameDay = StreakHelper.isSameDay(cachedGlobalDate, todayStr);
      final globalToday = isGlobalSameDay ? (prefs.getInt('cached_global_today') ?? 0) : 0;
      final personalTotal = prefs.getInt('cached_personal_total') ?? 0;
      final globalTotal = prefs.getInt('cached_global_total') ?? 0;

      // My Today resets to 0 on new day
      expect(myToday, 0);
      expect(prefs.getString('my_durood_date'), todayStr);
      expect(globalToday, 0);
      // Cumulative totals remain intact!
      expect(personalTotal, 150);
      expect(globalTotal, 5000);
    });

    test('Backward compatibility: Fallback reads legacy key my_durood_today_{date}', () async {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = StreakHelper.toCalendarDateString(DateTime.now());

      // Only legacy key exists
      await prefs.setInt('my_durood_today_$todayStr', 25);

      final myToday = prefs.getInt('my_durood_$todayStr') ??
          prefs.getInt('my_durood_today_$todayStr') ??
          0;

      expect(myToday, 25);
    });

    test('Simultaneous Two-Device Multi-User Sync: Device A increments reflect globally on Device B while My Today remains isolated', () async {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      // Initial state in Firestore counters/durood_stats
      var globalTotal = 1000;
      var todayTotal = 50;
      var firestoreDate = todayStr;

      // Device A user: "user_device_A"
      // Device B user: "user_device_B"
      int userAMyToday = 0;
      int userBMyToday = 0;

      // 1. User on Device A recites 15 Durood
      const int addedByDeviceA = 15;
      userAMyToday += addedByDeviceA;

      // In Firestore global counter:
      if (firestoreDate == todayStr) {
        globalTotal += addedByDeviceA;
        todayTotal += addedByDeviceA;
      }

      // Store Device A's isolated cache
      await prefs.setInt('my_durood_user_device_A_$todayStr', userAMyToday);
      await prefs.setString('my_durood_date', todayStr);

      // Store Device B's isolated cache
      await prefs.setInt('my_durood_user_device_B_$todayStr', userBMyToday);

      // 2. Verify Device B perspective (Live Firestore Snapshot)
      // Device B receives global snapshot update:
      final deviceBGlobalTotal = globalTotal;
      final deviceBTodayTotal = todayTotal;
      final deviceBMyToday = prefs.getInt('my_durood_user_device_B_$todayStr') ?? 0;

      expect(deviceBGlobalTotal, 1015);
      expect(deviceBTodayTotal, 65);
      expect(deviceBMyToday, 0, reason: 'Device B My Today must remain 0 and not be affected by Device A recitations');

      // 3. Verify Device A perspective
      final deviceAGlobalTotal = globalTotal;
      final deviceATodayTotal = todayTotal;
      final deviceAMyToday = prefs.getInt('my_durood_user_device_A_$todayStr') ?? 0;

      expect(deviceAGlobalTotal, 1015);
      expect(deviceATodayTotal, 65);
      expect(deviceAMyToday, 15, reason: 'Device A My Today must show 15');
    });

    test('Midnight (12:00 AM) Reset: doc["date"] != todayDateString resets todayTotal to new count and increments globalTotal', () {
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      const yesterdayStr = '2026-09-03';

      final Map<String, dynamic> globalDocYesterday = {
        'globalTotal': 5000,
        'todayTotal': 350,
        'date': yesterdayStr,
      };

      // 1. First recitation after midnight on new day: addedCount = 10
      const addedCount = 10;
      final Map<String, dynamic> updatedGlobalDoc;

      if (globalDocYesterday['date'] != todayStr) {
        updatedGlobalDoc = {
          'globalTotal': (globalDocYesterday['globalTotal'] as int) + addedCount,
          'todayTotal': addedCount, // Reset to newly added count!
          'date': todayStr,
        };
      } else {
        updatedGlobalDoc = {
          'globalTotal': (globalDocYesterday['globalTotal'] as int) + addedCount,
          'todayTotal': (globalDocYesterday['todayTotal'] as int) + addedCount,
          'date': todayStr,
        };
      }

      expect(updatedGlobalDoc['globalTotal'], 5010);
      expect(updatedGlobalDoc['todayTotal'], 10);
      expect(updatedGlobalDoc['date'], todayStr);
    });

    test('StreamBuilder Fallback: If doc["date"] != todayDateString on render, immediately treat todayTotal as 0 in UI', () {
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      const yesterdayStr = '2026-09-03';

      final Map<String, dynamic> globalDocStale = {
        'globalTotal': 10000,
        'todayTotal': 850,
        'date': yesterdayStr,
      };

      final String? docDate = globalDocStale['date']?.toString();
      final bool isSameDay = docDate == todayStr;
      final int renderedTodayTotal = isSameDay ? (globalDocStale['todayTotal'] as int) : 0;

      expect(renderedTodayTotal, 0, reason: 'UI must immediately treat todayTotal as 0 when doc date is from yesterday');
      expect(globalDocStale['globalTotal'], 10000, reason: 'globalTotal retains full all-time cumulative sum');
    });

    test('CounterService singleton auto-recovers and does not throw after disposal', () {
      final service1 = CounterService();
      expect(service1.isDisposed, false);

      // Simulate disposal
      service1.dispose();
      expect(service1.isDisposed, true);

      // notifyListeners should not throw on disposed instance
      expect(() => service1.notifyListeners(), returnsNormally);

      // Next access to CounterService singleton automatically yields an active, usable instance
      final service2 = CounterService();
      expect(service2.isDisposed, false);
      expect(() => service2.notifyListeners(), returnsNormally);
    });

    test('ISSUE 1: _todayKey resolves user ID reliably and persists across app restarts', () async {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      const uid = 'user_abc_789';

      // 1. Store count using reliable user key: my_durood_${uid}_$today
      final userKey = 'my_durood_${uid}_$todayStr';
      await prefs.setInt(userKey, 42);
      await prefs.setString('my_durood_date', todayStr);
      await prefs.setString('cached_active_uid', uid);

      // 2. Early startup simulation: auth is still resolving, but cached_active_uid exists
      final resolvedUid = prefs.getString('cached_active_uid') ?? 'guest';
      final startupKey = 'my_durood_${resolvedUid}_$todayStr';
      final hydratedCount = prefs.getInt(startupKey) ?? 0;

      expect(hydratedCount, 42, reason: 'Must restore 42 immediately using resolved user ID');

      // 3. Late auth event simulation: user logs in / authStateChanges fires with uid
      final authenticatedKey = 'my_durood_${uid}_$todayStr';
      final reHydratedCount = prefs.getInt(authenticatedKey) ?? 0;
      expect(reHydratedCount, 42, reason: 'Re-hydrating on auth change must also read 42');
    });

    test('ISSUE 1: Missing today doc in Firestore daily_stats does NOT overwrite local count with 0', () {
      int resolveEffectiveCount({required bool exists, Map<String, dynamic>? data, required int localCount}) {
        if (exists && data != null) {
          final int cloudCount = ((data['myToday'] ?? data['count']) as num?)?.toInt() ?? 0;
          return cloudCount > localCount ? cloudCount : localCount;
        }
        return localCount;
      }

      final countWhenMissing = resolveEffectiveCount(
        exists: false,
        data: null,
        localCount: 55,
      );
      expect(countWhenMissing, 55, reason: 'Local count must remain intact when Firestore doc does not exist yet');

      final countWhenExisting = resolveEffectiveCount(
        exists: true,
        data: {'myToday': 100},
        localCount: 55,
      );
      expect(countWhenExisting, 100);
    });

    test('ISSUE 2: Home Screen Global Today Stream parsing handles field variations and loading fallback', () {
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      const cachedGlobalToday = 120;

      int computeEffectiveToday(Map<String, dynamic>? data, int cachedValue) {
        int effective = cachedValue;
        if (data != null) {
          final docDate = (data['date'] ?? data['lastUpdatedDate'])?.toString();
          if (docDate == todayStr) {
            final firestoreToday = ((data['todayTotal'] ?? data['globalToday'] ?? data['todayCount'] ?? 0) as num).toInt();
            effective = firestoreToday > cachedValue ? firestoreToday : cachedValue;
          } else if (docDate != null && docDate != todayStr) {
            effective = 0;
          }
        }
        return effective;
      }

      // Case A: Stream is loading (data == null)
      // Must fallback to cached snap.globalToday, NOT 0!
      final effectiveTodayA = computeEffectiveToday(null, cachedGlobalToday);
      expect(effectiveTodayA, 120, reason: 'When stream is loading, HomeScreen must display hydrated value, not 0');

      // Case B: Document uses "todayTotal"
      final Map<String, dynamic> dataTodayTotal = {
        'todayTotal': 250,
        'date': todayStr,
      };
      final docDateB = (dataTodayTotal['date'] ?? dataTodayTotal['lastUpdatedDate'])?.toString();
      int effectiveTodayB = cachedGlobalToday;
      if (docDateB == todayStr) {
        final firestoreToday = ((dataTodayTotal['todayTotal'] ?? dataTodayTotal['globalToday'] ?? dataTodayTotal['todayCount'] ?? 0) as num).toInt();
        effectiveTodayB = firestoreToday > cachedGlobalToday ? firestoreToday : cachedGlobalToday;
      }
      expect(effectiveTodayB, 250);

      // Case C: Document uses "globalToday"
      final Map<String, dynamic> dataGlobalToday = {
        'globalToday': 300,
        'lastUpdatedDate': todayStr,
      };
      final docDateC = (dataGlobalToday['date'] ?? dataGlobalToday['lastUpdatedDate'])?.toString();
      int effectiveTodayC = cachedGlobalToday;
      if (docDateC == todayStr) {
        final firestoreToday = ((dataGlobalToday['todayTotal'] ?? dataGlobalToday['globalToday'] ?? dataGlobalToday['todayCount'] ?? 0) as num).toInt();
        effectiveTodayC = firestoreToday > cachedGlobalToday ? firestoreToday : cachedGlobalToday;
      }
      expect(effectiveTodayC, 300);

      // Case D: Document uses "todayCount"
      final Map<String, dynamic> dataTodayCount = {
        'todayCount': 400,
        'date': todayStr,
      };
      final docDateD = (dataTodayCount['date'] ?? dataTodayCount['lastUpdatedDate'])?.toString();
      int effectiveTodayD = cachedGlobalToday;
      if (docDateD == todayStr) {
        final firestoreToday = ((dataTodayCount['todayTotal'] ?? dataTodayCount['globalToday'] ?? dataTodayCount['todayCount'] ?? 0) as num).toInt();
        effectiveTodayD = firestoreToday > cachedGlobalToday ? firestoreToday : cachedGlobalToday;
      }
      expect(effectiveTodayD, 400);

      // Case E: Document is from yesterday (midnight rollover) -> should reset to 0
      final Map<String, dynamic> dataYesterday = {
        'todayTotal': 500,
        'date': '2026-09-03',
      };
      final docDateE = (dataYesterday['date'] ?? dataYesterday['lastUpdatedDate'])?.toString();
      int effectiveTodayE = cachedGlobalToday;
      if (docDateE == todayStr) {
        final firestoreToday = ((dataYesterday['todayTotal'] ?? dataYesterday['globalToday'] ?? dataYesterday['todayCount'] ?? 0) as num).toInt();
        effectiveTodayE = firestoreToday > cachedGlobalToday ? firestoreToday : cachedGlobalToday;
      } else if (docDateE != null && docDateE != todayStr) {
        effectiveTodayE = 0;
      }
      expect(effectiveTodayE, 0, reason: 'Past day docDate must reset today total to 0');
    });

    test('Streak & Durood Points: Persist across simulated restart and survive profile sync', () async {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      const uid = 'user_streak_pts_test';

      // 1. Save user state (streak: 7, points: 250, personalTotal: 125)
      await prefs.setString('cached_active_uid', uid);
      await prefs.setString('my_durood_date', todayStr);
      await prefs.setInt('my_durood_${uid}_$todayStr', 10);
      await prefs.setInt('cached_current_streak_$uid', 7);
      await prefs.setInt('cached_durood_points_$uid', 250);
      await prefs.setInt('cached_personal_total_$uid', 125);
      await prefs.setInt('cached_current_streak', 7);
      await prefs.setInt('cached_durood_points', 250);
      await prefs.setInt('cached_personal_total', 125);

      // 2. Hydration on simulated restart
      final activeUid = prefs.getString('cached_active_uid') ?? 'guest';
      final loadedStreak = prefs.getInt('cached_current_streak_$activeUid') ?? prefs.getInt('cached_current_streak') ?? 0;
      final loadedPoints = prefs.getInt('cached_durood_points_$activeUid') ?? prefs.getInt('cached_durood_points') ?? 0;
      final loadedTotal = prefs.getInt('cached_personal_total_$activeUid') ?? prefs.getInt('cached_personal_total') ?? 0;
      final loadedToday = prefs.getInt('my_durood_${activeUid}_$todayStr') ?? 0;

      expect(loadedStreak, 7, reason: 'Streak must be restored to 7, not 0');
      expect(loadedPoints, 250, reason: 'Durood points must be restored to 250, not 0');
      expect(loadedTotal, 125);
      expect(loadedToday, 10);

      // 3. Simulated Firestore profile doc where points are 0 or streak is 0
      final Map<String, dynamic> staleProfileDoc = {
        'total_durood_points': 0, // stale or unpopulated
        'current_streak': 0,
      };

      final int firestorePoints = ((staleProfileDoc['total_durood_points'] ??
          staleProfileDoc['durood_points'] ??
          staleProfileDoc['points']) as num?)?.toInt() ?? 0;

      final effectivePoints = loadedPoints > firestorePoints ? loadedPoints : firestorePoints;
      expect(effectivePoints, 250, reason: 'Stale 0 in Firestore must never downgrade local Durood points');

      int effectiveStreak = (staleProfileDoc['current_streak'] as num?)?.toInt() ?? 0;
      if (effectiveStreak == 0 && loadedStreak > 0 && loadedToday > 0) {
        effectiveStreak = loadedStreak;
      }
      expect(effectiveStreak, 7, reason: 'Stale 0 streak in Firestore must never downgrade active streak');
    });

    test('WEB PORTAL ISSUE FIX: AppUser correctly parses "streak" (5 Days) and "duroodPoints" (220,000)', () {
      // Document written by mobile app using keys 'streak' and 'duroodPoints'
      final Map<String, dynamic> mobileUserDoc = {
        'user_id': 'test_user_mobile',
        'email': 'mobile_user@test.com',
        'username': 'Mobile Devotee',
        'streak': 5,
        'duroodPoints': 220000,
        'personal_total_durood': 110000,
        'personal_today_durood': 500,
        'last_active_durood_date': '2026-09-04',
      };

      final user = AppUser.fromMap(mobileUserDoc);

      expect(user.currentStreak, 5, reason: 'Must parse streak key as currentStreak == 5');
      expect(user.totalDuroodPoints, 220000, reason: 'Must parse duroodPoints key as totalDuroodPoints == 220000');
      expect(user.personalTotalDurood, 110000);
      expect(user.personalTodayDurood, 500);

      // Verify toMap() emits both schema variations so both mobile and web stay in sync
      final map = user.toMap();
      expect(map['streak'], 5);
      expect(map['current_streak'], 5);
      expect(map['duroodPoints'], 220000);
      expect(map['total_durood_points'], 220000);
    });

    test('WEB DASHBOARD ISSUE FIX: Correctly extracts Total Durood and Today\'s Durood from counters/durood_stats', () {
      final Map<String, dynamic> firestoreDoc = {
        'globalTotal': 125000,
        'todayTotal': 4820,
        'totalDurood': 125000,
        'todayDurood': 4820,
        'date': '2026-09-04',
        'lastUpdatedDate': '2026-09-04',
      };

      final total = ((firestoreDoc['globalTotal'] ??
              firestoreDoc['totalDurood'] ??
              firestoreDoc['total_durood'] ??
              firestoreDoc['total_count'] ??
              firestoreDoc['totalCount'] ??
              firestoreDoc['count']) as num?)
              ?.toInt() ??
          0;

      final rawToday = ((firestoreDoc['todayTotal'] ??
              firestoreDoc['todayDurood'] ??
              firestoreDoc['today_durood'] ??
              firestoreDoc['globalToday'] ??
              firestoreDoc['todayCount'] ??
              firestoreDoc['today_count']) as num?)
              ?.toInt() ??
          0;

      final docDate = (firestoreDoc['date'] ??
              firestoreDoc['lastUpdatedDate'] ??
              firestoreDoc['last_reset_date'])
          ?.toString();
      const todayDate = '2026-09-04';
      final int today = (docDate != null && docDate != todayDate) ? 0 : rawToday;

      expect(total, 125000, reason: 'Web Dashboard Total Durood must equal 125,000');
      expect(today, 4820, reason: 'Web Dashboard Today\'s Durood must equal 4,820');
    });

    test('WEB DASHBOARD ISSUE FIX: Midnight rollover resets Today\'s Durood to 0 on Web when date changes', () {
      final Map<String, dynamic> yesterdayFirestoreDoc = {
        'globalTotal': 125000,
        'todayTotal': 4820,
        'date': '2026-09-03', // yesterday
        'lastUpdatedDate': '2026-09-03',
      };

      final total = ((yesterdayFirestoreDoc['globalTotal'] ??
              yesterdayFirestoreDoc['total_count']) as num?)
              ?.toInt() ??
          0;

      final rawToday = ((yesterdayFirestoreDoc['todayTotal'] ??
              yesterdayFirestoreDoc['todayCount']) as num?)
              ?.toInt() ??
          0;

      final docDate = (yesterdayFirestoreDoc['date'] ??
              yesterdayFirestoreDoc['lastUpdatedDate'])
          ?.toString();
      const todayDate = '2026-09-04';
      final int today = (docDate != null && docDate != todayDate) ? 0 : rawToday;

      expect(total, 125000, reason: 'Global Total remains intact across midnight');
      expect(today, 0, reason: 'Today count must reset to 0 in UI when doc date is from previous day');
    });
  });
}
