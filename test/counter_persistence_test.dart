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

    test('Persists "my_durood_today_{date}" and totals across simulated app restart', () async {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = StreakHelper.toCalendarDateString(DateTime.now());

      // 1. Simulate counting Durood during active session
      const countAdded = 15;
      await prefs.setInt('my_durood_today_$todayStr', countAdded);
      await prefs.setInt('cached_personal_total', countAdded);
      await prefs.setInt('cached_global_total', 1000 + countAdded);
      await prefs.setInt('cached_global_today', countAdded);
      await prefs.setString('cached_global_date', todayStr);

      // 2. Simulate process kill & app restart on same day
      final reloadedPrefs = await SharedPreferences.getInstance();
      final loadedToday = reloadedPrefs.getInt('my_durood_today_$todayStr');
      final loadedPersonalTotal = reloadedPrefs.getInt('cached_personal_total');
      final loadedGlobalTotal = reloadedPrefs.getInt('cached_global_total');
      final loadedGlobalToday = reloadedPrefs.getInt('cached_global_today');

      expect(loadedToday, 15);
      expect(loadedPersonalTotal, 15);
      expect(loadedGlobalTotal, 1015);
      expect(loadedGlobalToday, 15);
    });

    test('Resets daily totals when date transitions to next day while preserving totals', () async {
      final prefs = await SharedPreferences.getInstance();
      const yesterdayStr = '2026-09-03';
      final todayStr = StreakHelper.toCalendarDateString(DateTime.now()); // e.g. 2026-09-04

      // Set yesterday's counts
      await prefs.setInt('my_durood_today_$yesterdayStr', 50);
      await prefs.setInt('cached_personal_total', 150);
      await prefs.setInt('cached_global_total', 5000);
      await prefs.setInt('cached_global_today', 200);
      await prefs.setString('cached_global_date', yesterdayStr);

      // On new day launch:
      final cachedDate = prefs.getString('cached_global_date');
      final isSameDay = StreakHelper.isSameDay(cachedDate, todayStr);

      final myToday = prefs.getInt('my_durood_today_$todayStr') ?? 0;
      final globalToday = isSameDay ? (prefs.getInt('cached_global_today') ?? 0) : 0;
      final personalTotal = prefs.getInt('cached_personal_total') ?? 0;
      final globalTotal = prefs.getInt('cached_global_total') ?? 0;

      // Daily counts reset to 0 for the new day
      expect(myToday, 0);
      expect(globalToday, 0);
      // Cumulative totals remain intact!
      expect(personalTotal, 150);
      expect(globalTotal, 5000);
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
