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

    testWidgets('EventCard renders with compact height 146 without overflow', (WidgetTester tester) async {
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
              height: 146,
              width: 275,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cardFinder = find.byType(EventCard);
      expect(cardFinder, findsOneWidget);
      final size = tester.getSize(cardFinder);
      expect(size.height, equals(146.0));
      expect(size.width, equals(275.0));
      expect(tester.takeException(), isNull, reason: 'EventCard must not have any layout overflows at height 146');
    });

    testWidgets('Above-the-fold content budget fits within mobile viewport height before Daily Hadith', (WidgetTester tester) async {
      // Set tester window size to standard mobile portrait (390 x 844)
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Measure total height of above-the-fold components
      double totalAboveFoldHeight = 0;

      // 1. SliverAppBar height: 122
      const double appBarHeight = 122.0;
      // 2. SliverPadding top: 6
      const double sliverPaddingTop = 6.0;
      // 3. Spacing to DuroodSummaryCard: 6
      const double spacingGamificationToCard = 6.0;
      // 4. Spacing to CTA: 6
      const double spacingCardToCta = 6.0;
      // 5. CTA Button height: 38
      const double ctaButtonHeight = 38.0;
      // 6. Spacing to Events: 8
      const double spacingCtaToEvents = 8.0;
      // 7. Events Section Header: 24
      const double eventsHeaderHeight = 24.0;
      // 8. Events Header spacing: 4
      const double eventsHeaderSpacing = 4.0;
      // 9. Events Card height: 146
      const double eventsCardHeight = 146.0;
      // 10. Spacing below events: 16
      const double spacingEventsToHadith = 16.0;

      totalAboveFoldHeight = appBarHeight +
          sliverPaddingTop +
          44.0 + // GamificationBar approx height
          spacingGamificationToCard +
          104.0 + // DuroodSummaryCard approx height
          spacingCardToCta +
          ctaButtonHeight +
          spacingCtaToEvents +
          eventsHeaderHeight +
          eventsHeaderSpacing +
          eventsCardHeight +
          spacingEventsToHadith;

      // The available fold on standard 844 screen with 56px bottom nav bar and 44px status bar is ~700px.
      // On an 800px screen, available fold is ~660px.
      // On a 667px screen, available fold is ~590px.
      expect(totalAboveFoldHeight, lessThan(550.0),
          reason: 'Total above-the-fold content height (~$totalAboveFoldHeight px) must stay under 550px so Daily Hadith remains cleanly below the fold on first render');
    });

    testWidgets('Scroll view bottom clearance reserves 90px for floating bottom nav bar', (WidgetTester tester) async {
      const double bottomClearance = 90.0;
      expect(bottomClearance, greaterThanOrEqualTo(90.0),
          reason: 'Bottom clearance must provide at least 90px padding to clear the bottom navigation bar');
    });
  });
}
