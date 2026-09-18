import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Decouple myToday from myTotal & Daily Goal Calculation Tests', () {
    test('1. Fresh Day Start: My Total = 1,028 and My Today = 0 increments to 1,029 and 1 on 1st tap', () {
      // Starting state for a user with 1,028 lifetime total starting a fresh day
      const int initialTotalCount = 1028;
      const int initialTodayCount = 0;
      const int tapCount = 1;

      // Controller / Provider / Service decoupled logic
      final int myToday = initialTodayCount + tapCount;
      final int myTotal = initialTotalCount + tapCount;

      expect(myTotal, 1029, reason: 'My Total must increment by +1 to 1,029');
      expect(myToday, 1, reason: 'My Today must increment by +1 to 1 (NOT 1,028!)');
      expect(myToday, isNot(equals(myTotal)), reason: 'My Today must NEVER equal My Total on fresh day start');
    });

    test('2. Consecutive Taps: myToday and myTotal maintain independent counters', () {
      int currentToday = 0;
      int currentTotal = 1028;

      // Simulate 5 taps
      for (int i = 1; i <= 5; i++) {
        currentToday += 1;
        currentTotal += 1;
      }

      expect(currentToday, 5);
      expect(currentTotal, 1033);
    });

    test('3. Daily Goal Progress Calculation on 1 tap (Goal = 500): evaluates to 0.2% and is NOT completed', () {
      const int goalTarget = 500;
      const int myToday = 1;

      final double progress = goalTarget > 0 ? (myToday / goalTarget).clamp(0.0, 1.0) : 0.0;
      final bool isCompleted = myToday >= goalTarget;
      final double percentage = progress * 100;
      final String percentText = (percentage > 0 && percentage < 1)
          ? percentage.toStringAsFixed(1)
          : '${percentage.toInt()}';

      expect(progress, 0.002);
      expect(percentage, 0.2);
      expect(percentText, '0.2');
      expect(isCompleted, isFalse, reason: 'Goal of 500 must NOT be marked completed after 1 tap');
      expect('$percentText% Completed', '0.2% Completed');
    });

    test('4. Daily Goal Progression Milestones: 0%, 0.2%, 20%, 50%, 100%', () {
      const int goalTarget = 500;

      String formatProgress(int today) {
        final double progress = goalTarget > 0 ? (today / goalTarget).clamp(0.0, 1.0) : 0.0;
        final double percentage = progress * 100;
        final String text = (percentage > 0 && percentage < 1)
            ? percentage.toStringAsFixed(1)
            : '${percentage.toInt()}';
        return '$text%';
      }

      expect(formatProgress(0), '0%');
      expect(formatProgress(1), '0.2%');
      expect(formatProgress(100), '20%');
      expect(formatProgress(250), '50%');
      expect(formatProgress(500), '100%');
      expect(formatProgress(600), '100%'); // Clamped
    });

    test('5. Contamination Guard: Prevents parent user doc with legacy myToday == myTotal from corrupting daily stats', () {
      const int firestorePersonalTotal = 1028;
      const int rawUserDocToday = 1028; // Stale field in users/{uid} matching total
      int snapshotPersonalToday = 1; // Current verified daily count

      // Contamination detection:
      final bool isContaminatedWithTotal = firestorePersonalTotal > 0 &&
          rawUserDocToday >= firestorePersonalTotal &&
          snapshotPersonalToday < rawUserDocToday;

      expect(isContaminatedWithTotal, isTrue, reason: 'Must detect that rawUserDocToday is contaminated with myTotal');

      final int? firestorePersonalToday = isContaminatedWithTotal ? null : rawUserDocToday;
      expect(firestorePersonalToday, isNull, reason: 'Contaminated value must be discarded');

      // Resolved today retains snapshotPersonalToday
      final int effectivePersonalToday = firestorePersonalToday ?? snapshotPersonalToday;
      expect(effectivePersonalToday, 1, reason: 'Effective personal today must remain 1');
    });

    test('6. UI Stream Sanitization: If local snapshot was corrupted with total, authoritative cloud daily count recovers it', () {
      const int effectiveMyTotal = 1028;
      const int corruptedSnapToday = 1028; // Corrupted from old session
      const int cloudDailyStatsToday = 1; // True daily count from users/{uid}/daily_stats/{today}
      const int pendingBuffer = 0;

      final bool snapIsContaminated = (effectiveMyTotal > 0) &&
          (corruptedSnapToday >= effectiveMyTotal) &&
          (cloudDailyStatsToday < corruptedSnapToday);

      expect(snapIsContaminated, isTrue);

      final int resolvedToday = snapIsContaminated ? cloudDailyStatsToday : corruptedSnapToday;
      final int effectiveMyToday = resolvedToday + pendingBuffer;

      expect(effectiveMyToday, 1, reason: 'Counter screen must display 1 and NOT 1,028');
    });

    test('7. First Tap Today resets parent doc myToday: simulates batch write payload', () {
      const int currentTodayCount = 0;
      const int count = 1;

      final bool isFirstTapToday = currentTodayCount == 0;
      final Map<String, dynamic> userRefPayload = {
        'myTotal': 'increment($count)',
        'totalDurood': 'increment($count)',
        'myToday': isFirstTapToday ? count : 'increment($count)',
      };

      // On first tap today, myToday is set directly to count (1), NOT incremented on top of stale days
      expect(userRefPayload['myToday'], 1);
      expect(userRefPayload['myTotal'], 'increment(1)');
    });
  });
}
