import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/models/event_model.dart';
import 'package:islamic_app/features/home/presentation/widgets/event_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EventCard Widget Tests', () {
    const testEventEnglish = EventModel(
      id: 'event-101',
      title: 'Grand Annual Durood Conference',
      titleUr: 'عظیم الشان سالانہ درود کانفرنس',
      dateTime: 'Sunday, 15 Sha\'ban - 8:00 PM',
      location: 'Central Mosque, Karachi',
      locationUr: 'مرکزی جامع مسجد، کراچی',
      status: 'Featured',
      description: 'Annual gathering of Salawat & Salam',
    );

    testWidgets('Renders EventCard with English details and handles onTap', (WidgetTester tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventCard(
              event: testEventEnglish,
              onTap: () {
                wasTapped = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check title
      expect(find.text('Grand Annual Durood Conference'), findsOneWidget);

      // Check dateTime
      expect(find.text('Sunday, 15 Sha\'ban - 8:00 PM'), findsOneWidget);

      // Check location
      expect(find.text('Central Mosque, Karachi'), findsOneWidget);

      // Check status label
      expect(find.text('⭐ FEATURED'), findsOneWidget);

      // Tap card
      await tester.tap(find.byType(EventCard));
      expect(wasTapped, isTrue);
    });

    testWidgets('Horizontal ListView with multiple EventCards scrolls smoothly', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: events.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return EventCard(event: events[index]);
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially Event 1 is visible
      expect(find.text('Event 1'), findsOneWidget);

      // Scroll horizontally
      await tester.drag(find.byType(ListView), const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Now Event 2 is visible
      expect(find.text('Event 2'), findsOneWidget);
    });
  });
}
