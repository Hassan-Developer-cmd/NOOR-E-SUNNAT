import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/models/event_model.dart';
import 'package:islamic_app/features/home/presentation/widgets/event_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EventCard Widget Tests', () {
    testWidgets('Renders EventCard with English details and handles onTap', (WidgetTester tester) async {
      bool tapped = false;
      const testEvent = EventModel(
        id: 'event-1',
        title: 'Grand Mehfil-e-Naat',
        titleUr: 'عظیم الشان محفل نعت',
        dateTime: 'March 15, 2026 - 8:00 PM',
        location: 'Faizan-e-Madina, Karachi',
        locationUr: 'فیضان مدینہ، کراچی',
        status: 'Featured',
        description: 'Special annual gathering',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventCard(
              event: testEvent,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // Verify Title, DateTime, Location, and Status Badge
      expect(find.text('Grand Mehfil-e-Naat'), findsOneWidget);
      expect(find.text('March 15, 2026 - 8:00 PM'), findsOneWidget);
      expect(find.text('Faizan-e-Madina, Karachi'), findsOneWidget);
      expect(find.text('⭐ FEATURED'), findsOneWidget);

      // Verify Icons
      expect(find.byIcon(Icons.calendar_today_rounded), findsOneWidget);
      expect(find.byIcon(Icons.location_on_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsOneWidget);

      // Test tap
      await tester.tap(find.byType(EventCard));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('Renders Ongoing Live Event with live stream icon and badge', (WidgetTester tester) async {
      const liveEvent = EventModel(
        id: 'event-2',
        title: 'Weekly Ijtima',
        titleUr: 'ہفتہ وار اجتماع',
        dateTime: 'Today - Live',
        location: 'Main Hall & YouTube',
        locationUr: 'مین ہال اور یوٹیوب',
        status: 'Ongoing',
        description: 'Live broadcast',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EventCard(
              event: liveEvent,
            ),
          ),
        ),
      );

      expect(find.text('Weekly Ijtima'), findsOneWidget);
      expect(find.text('🔥 LIVE NOW'), findsOneWidget);
      expect(find.byIcon(Icons.sensors_rounded), findsOneWidget);
    });

    testWidgets('PageView with multiple EventCards behaves properly with dots', (WidgetTester tester) async {
      final events = [
        const EventModel(
          id: '1',
          title: 'Event 1',
          dateTime: 'Date 1',
          location: 'Loc 1',
          status: 'Featured',
          description: 'Desc 1',
        ),
        const EventModel(
          id: '2',
          title: 'Event 2',
          dateTime: 'Date 2',
          location: 'Loc 2',
          status: 'Coming Soon',
          description: 'Desc 2',
        ),
      ];

      int activeIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    SizedBox(
                      height: 175,
                      child: PageView.builder(
                        controller: PageController(viewportFraction: 1.0),
                        physics: const BouncingScrollPhysics(),
                        pageSnapping: true,
                        itemCount: events.length,
                        onPageChanged: (idx) {
                          setState(() {
                            activeIndex = idx;
                          });
                        },
                        itemBuilder: (context, index) {
                          return EventCard(event: events[index]);
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(events.length, (index) {
                        final isActive = index == activeIndex;
                        return Container(
                          key: ValueKey('dot_$index'),
                          width: isActive ? 22 : 7,
                          height: 7,
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Initially on Event 1
      expect(find.text('Event 1'), findsOneWidget);
      expect(activeIndex, 0);

      // Swipe to page 2
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Now on Event 2
      expect(find.text('Event 2'), findsOneWidget);
      expect(activeIndex, 1);
    });
  });
}
