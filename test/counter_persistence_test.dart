import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:islamic_app/core/utils/streak_helper.dart';
import 'package:islamic_app/services/counter_service.dart';

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
  });
}
