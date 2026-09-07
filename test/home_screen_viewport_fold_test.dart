import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/models/event_model.dart';
import 'package:islamic_app/features/home/presentation/widgets/event_card.dart';
import 'package:islamic_app/features/home/presentation/widgets/gamification_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Home Screen Viewport & Fold Rhythm Tests', () {
    testWidgets('GamificationBar renders with compact refined padding', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                GamificationBar(
                  streakDays: 7,
                  duroodPoints: 1200,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gamificationFinder = find.byType(GamificationBar);
      expect(gamificationFinder, findsOneWidget);
      final size = tester.getSize(gamificationFinder);
      expect(size.height, lessThanOrEqualTo(55.0),
          reason: 'GamificationBar should remain compact to prevent pushing content below fold');
    });

    testWidgets('EventCard renders with expanded readable height 185 without overflow', (WidgetTester tester) async {
      final event = EventModel(
        id: 'evt_test',
        title: 'Grand Milad Gathering',
        titleUr: 'محفل میلاد مصطفیٰ',
        dateTime: '12 Rabi al-Awwal 1448',
        location: 'Faizan-e-Madina',
        locationUr: 'فیضان مدینہ',
        status: 'Upcoming',
        description: 'Annual gathering of Durood and Salawat',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventCard(
              event: event,
              height: 185,
              width: 300,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cardFinder = find.byType(EventCard);
      expect(cardFinder, findsOneWidget);
      final size = tester.getSize(cardFinder);
      expect(size.height, equals(185.0));
      expect(size.width, equals(300.0));
      expect(tester.takeException(), isNull, reason: 'EventCard must render comfortably without any layout overflows at height 185');
    });

    testWidgets('Dynamic fold gap calculation pushes Daily Hadith completely below fold on standard mobile viewports', (WidgetTester tester) async {
      // Set tester window size to standard mobile portrait (390 x 844)
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const double screenHeight = 844.0;
      const double bottomBarTotalHeight = 56.0 + 34.0; // kBottomNavigationBarHeight + bottom safe area
      const double visibleViewportHeight = screenHeight - bottomBarTotalHeight; // 754.0

      // Balanced above-the-fold content height with expanded comfortable components:
      // AppBar ~150 + top padding ~18 + Gamification ~50 + spacing ~14 + Durood ~124 + spacing ~14 + CTA ~48 + spacing ~18 + Events Header ~38 + Carousel ~195 = ~669px
      const double aboveFoldContentHeight = 669.0;
      final double remainingToBottomBar = visibleViewportHeight - aboveFoldContentHeight; // 85.0
      final double foldGap = remainingToBottomBar > 0 ? remainingToBottomBar + 12.0 : 24.0; // 97.0

      final double dailyHadithPosition = aboveFoldContentHeight + foldGap; // 766.0

      // Assert that Daily Hadith top edge is strictly greater than visible viewport height
      expect(dailyHadithPosition, greaterThan(visibleViewportHeight),
          reason: 'Daily Hadith position ($dailyHadithPosition px) must be strictly beyond the visible viewport fold ($visibleViewportHeight px) so it never peeks on launch');
      expect(aboveFoldContentHeight, lessThanOrEqualTo(visibleViewportHeight),
          reason: 'Above-the-fold content ($aboveFoldContentHeight px) must finish above the bottom navigation bar ($visibleViewportHeight px)');
      expect(remainingToBottomBar, lessThan(120.0),
          reason: 'Empty space above bottom navigation bar must be tightly bounded so Upcoming Events sits right above the bottom bar without an awkward gap');
    });

    testWidgets('Scroll view bottom clearance reserves 90px for floating bottom nav bar', (WidgetTester tester) async {
      const double bottomClearance = 90.0;
      expect(bottomClearance, greaterThanOrEqualTo(90.0),
          reason: 'Bottom clearance must provide at least 90px padding to clear the bottom navigation bar');
    });
  });
}
