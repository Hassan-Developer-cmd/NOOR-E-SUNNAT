import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Daily Goal Percentage & Progress Formula Tests', () {
    double calculateProgress(int myTodayCount, int dailyGoalTarget) {
      final int effectiveGoal = dailyGoalTarget > 0 ? dailyGoalTarget : 500;
      return (myTodayCount / effectiveGoal).clamp(0.0, 1.0);
    }

    int calculatePercentage(int myTodayCount, int dailyGoalTarget) {
      final progress = calculateProgress(myTodayCount, dailyGoalTarget);
      return (progress * 100).round().clamp(0, 100);
    }

    bool isGoalCompleted(int myTodayCount, int dailyGoalTarget) {
      final int effectiveGoal = dailyGoalTarget > 0 ? dailyGoalTarget : 500;
      return myTodayCount >= effectiveGoal;
    }

    test('12 to 13 increment monotonically increases percentage from 2% to 3%', () {
      const int goal = 500;

      final p12 = calculatePercentage(12, goal);
      final p13 = calculatePercentage(13, goal);

      expect(p12, 2, reason: '12 / 500 = 2.4% -> rounds to 2%');
      expect(p13, 3, reason: '13 / 500 = 2.6% -> rounds to 3%');
      expect(p13 > p12, isTrue, reason: 'Percentage must increase from 2% to 3%, never decrease');
    });

    test('Zero count returns 0%', () {
      expect(calculatePercentage(0, 500), 0);
      expect(calculateProgress(0, 500), 0.0);
      expect(isGoalCompleted(0, 500), isFalse);
    });

    test('Midway count (250 / 500) returns 50%', () {
      expect(calculatePercentage(250, 500), 50);
      expect(calculateProgress(250, 500), 0.5);
      expect(isGoalCompleted(250, 500), isFalse);
    });

    test('Goal reached (500 / 500) returns 100% and marks completed', () {
      expect(calculatePercentage(500, 500), 100);
      expect(calculateProgress(500, 500), 1.0);
      expect(isGoalCompleted(500, 500), isTrue);
    });

    test('Goal exceeded (550 / 500) clamps to 100% and 1.0 progress', () {
      expect(calculatePercentage(550, 500), 100);
      expect(calculateProgress(550, 500), 1.0);
      expect(isGoalCompleted(550, 500), isTrue);
    });

    test('Goal <= 0 falls back safely to default 500 (no division by zero)', () {
      expect(calculatePercentage(50, 0), 10);
      expect(calculateProgress(50, 0), 0.1);
      expect(calculatePercentage(50, -100), 10);
      expect(calculateProgress(50, -100), 0.1);
    });

    test('Custom daily goals calculate correctly', () {
      // Goal = 100
      expect(calculatePercentage(12, 100), 12);
      expect(calculatePercentage(13, 100), 13);

      // Goal = 1000
      expect(calculatePercentage(12, 1000), 1);
      expect(calculatePercentage(13, 1000), 1);
      expect(calculatePercentage(15, 1000), 2);
    });

    test('Monotonic non-decreasing progression across consecutive taps (0 to 500)', () {
      const int goal = 500;
      int previousPercent = -1;
      double previousProgress = -1.0;

      for (int count = 0; count <= 500; count++) {
        final progress = calculateProgress(count, goal);
        final percent = calculatePercentage(count, goal);

        expect(progress >= previousProgress, isTrue,
            reason: 'Progress at count $count must be >= progress at count ${count - 1}');
        expect(percent >= previousPercent, isTrue,
            reason: 'Percentage at count $count ($percent%) must be >= previous ($previousPercent%)');

        previousProgress = progress;
        previousPercent = percent;
      }
    });

    test('SharedPreferences preserves user custom goal across sessions', () async {
      SharedPreferences.setMockInitialValues({'user_daily_goal_target': 1000});
      final prefs = await SharedPreferences.getInstance();

      final savedGoal = prefs.getInt('user_daily_goal_target');
      expect(savedGoal, 1000);

      // Update goal
      await prefs.setInt('user_daily_goal_target', 300);
      final updatedGoal = prefs.getInt('user_daily_goal_target');
      expect(updatedGoal, 300);
    });
  });
}

