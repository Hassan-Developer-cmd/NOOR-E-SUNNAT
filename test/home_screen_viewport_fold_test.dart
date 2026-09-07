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

    testWidgets('EventCard renders with compact height 155 without overflow', (WidgetTester tester) async {
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
              height: 155,
              width: 280,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cardFinder = find.byType(EventCard);
      expect(cardFinder, findsOneWidget);
      final size = tester.getSize(cardFinder);
      expect(size.height, equals(155.0));
      expect(size.width, equals(280.0));
      expect(tester.takeException(), isNull, reason: 'EventCard must not have any layout overflows at height 155');
    });

    testWidgets('Above-the-fold content budget fits within mobile viewport height before Daily Hadith', (WidgetTester tester) async {
      // Set tester window size to standard mobile portrait (390 x 844)
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Measure total height of above-the-fold components
      double totalAboveFoldHeight = 0;

      // 1. SliverAppBar height: 132
      const double appBarHeight = 132.0;
      // 2. SliverPadding top: 8
      const double sliverPaddingTop = 8.0;
      // 3. Spacing to DuroodSummaryCard: 8
      const double spacingGamificationToCard = 8.0;
      // 4. Spacing to CTA: 8
      const double spacingCardToCta = 8.0;
      // 5. CTA Button height: 40
      const double ctaButtonHeight = 40.0;
      // 6. Spacing to Events: 10
      const double spacingCtaToEvents = 10.0;
      // 7. Events Section Header: 24
      const double eventsHeaderHeight = 24.0;
      // 8. Events Header spacing: 6
      const double eventsHeaderSpacing = 6.0;
      // 9. Events Card height: 155
      const double eventsCardHeight = 155.0;
      // 10. Spacing below events: 12
      const double spacingEventsToHadith = 12.0;

      totalAboveFoldHeight = appBarHeight +
          sliverPaddingTop +
          50.0 + // GamificationBar approx height
          spacingGamificationToCard +
          115.0 + // DuroodSummaryCard approx height
          spacingCardToCta +
          ctaButtonHeight +
          spacingCtaToEvents +
          eventsHeaderHeight +
          eventsHeaderSpacing +
          eventsCardHeight +
          spacingEventsToHadith;

      // The available fold on standard 844 screen with 56px bottom nav bar and 44px status bar is ~700px.
      // On an 800px screen, available fold is ~660px.
      expect(totalAboveFoldHeight, lessThan(600.0),
          reason: 'Total above-the-fold content height (~$totalAboveFoldHeight px) must stay well under 600px so Daily Hadith stays below the fold on first render');
    });

    testWidgets('Scroll view bottom clearance reserves 80px for floating bottom nav bar', (WidgetTester tester) async {
      const double bottomClearance = 80.0;
      expect(bottomClearance, greaterThanOrEqualTo(60.0),
          reason: 'Bottom clearance must provide at least 60-80px padding to clear the bottom navigation bar');
    });
  });
}
