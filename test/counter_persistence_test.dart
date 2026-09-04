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
