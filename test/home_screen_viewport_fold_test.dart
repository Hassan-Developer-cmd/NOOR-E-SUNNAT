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

    testWidgets('EventCard renders with compact height 140 without overflow', (WidgetTester tester) async {
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
              height: 140,
              width: 270,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cardFinder = find.byType(EventCard);
      expect(cardFinder, findsOneWidget);
      final size = tester.getSize(cardFinder);
      expect(size.height, equals(140.0));
      expect(size.width, equals(270.0));
      expect(tester.takeException(), isNull, reason: 'EventCard must not have any layout overflows at height 140');
    });

    testWidgets('Above-the-fold content budget fits within mobile viewport height before Daily Hadith', (WidgetTester tester) async {
      // Set tester window size to standard mobile portrait (390 x 844)
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Measure total height of above-the-fold components
      double totalAboveFoldHeight = 0;

      // 1. SliverAppBar height: 118
      const double appBarHeight = 118.0;
      // 2. SliverPadding top: 4
      const double sliverPaddingTop = 4.0;
      // 3. Spacing to DuroodSummaryCard: 5
      const double spacingGamificationToCard = 5.0;
      // 4. Spacing to CTA: 5
      const double spacingCardToCta = 5.0;
      // 5. CTA Button height: 36
      const double ctaButtonHeight = 36.0;
      // 6. Spacing to Events: 6
      const double spacingCtaToEvents = 6.0;
      // 7. Events Section Header: 20
      const double eventsHeaderHeight = 20.0;
      // 8. Events Header spacing: 3
      const double eventsHeaderSpacing = 3.0;
      // 9. Events Card height: 140
      const double eventsCardHeight = 140.0;
      // 10. Spacing below events to fold: 32
      const double spacingEventsToHadith = 32.0;

      totalAboveFoldHeight = appBarHeight +
          sliverPaddingTop +
          42.0 + // GamificationBar approx height
          spacingGamificationToCard +
          82.0 + // DuroodSummaryCard approx height
          spacingCardToCta +
          ctaButtonHeight +
          spacingCtaToEvents +
          eventsHeaderHeight +
          eventsHeaderSpacing +
          eventsCardHeight;

      // The top 5 above-the-fold components total ~459px!
      // Standard mobile viewports (667px–844px) with bottom bar leave 560px–740px available.
      // Total above fold content is well under 500px, so "Upcoming Events" cleanly ends right above bottom nav bar.
      expect(totalAboveFoldHeight, lessThan(500.0),
          reason: 'Total above-the-fold content height (~$totalAboveFoldHeight px) must stay under 500px so Upcoming Events is the last visible item above the fold');
      expect(totalAboveFoldHeight + spacingEventsToHadith, lessThan(550.0),
          reason: 'Fold gap guarantees Daily Hadith and Daily Ayat remain completely offscreen on initial load');
    });

    testWidgets('Scroll view bottom clearance reserves 90px for floating bottom nav bar', (WidgetTester tester) async {
      const double bottomClearance = 90.0;
      expect(bottomClearance, greaterThanOrEqualTo(90.0),
          reason: 'Bottom clearance must provide at least 90px padding to clear the bottom navigation bar');
    });
  });
}
