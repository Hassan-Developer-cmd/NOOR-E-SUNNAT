import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/models/event_model.dart';
import 'package:islamic_app/features/home/presentation/widgets/event_card.dart';
import 'package:islamic_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Upcoming Events Language Toggle Reactivity Tests', () {
    testWidgets('EventCard updates text immediately when language toggle changes', (WidgetTester tester) async {
      const testEvent = EventModel(
        id: 'event-toggle-1',
        title: "Weekly Jumu'ah Durood Majlis",
        titleUr: 'ہفتہ وار جمعۃ المبارک درود مجلس',
        dateTime: 'Every Friday - After Maghrib',
        location: 'Faizan-e-Madina',
        locationUr: 'فیضانِ مدینہ',
        status: 'Featured',
        description: 'Blessed gathering',
      );

      // Start in English
      await globalLanguageProvider.setLanguage('en');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventCard(
              event: testEvent,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify English text is shown
      expect(find.text("Weekly Jumu'ah Durood Majlis"), findsOneWidget);
      expect(find.text('⭐ FEATURED'), findsOneWidget);
      expect(find.text('Faizan-e-Madina'), findsOneWidget);

      // Toggle language to Urdu
      globalLanguageProvider.toggleLanguage();
      await tester.pumpAndSettle();

      // Verify Urdu text is shown instantly
      expect(find.text('ہفتہ وار جمعۃ المبارک درود مجلس'), findsOneWidget);
      expect(find.text('⭐ خصوصی'), findsOneWidget);
      expect(find.text('فیضانِ مدینہ'), findsOneWidget);
      expect(find.text("Weekly Jumu'ah Durood Majlis"), findsNothing);

      // Toggle back to English
      globalLanguageProvider.toggleLanguage();
      await tester.pumpAndSettle();

      // Verify English text is back immediately
      expect(find.text("Weekly Jumu'ah Durood Majlis"), findsOneWidget);
      expect(find.text('⭐ FEATURED'), findsOneWidget);
      expect(find.text('Faizan-e-Madina'), findsOneWidget);
      expect(find.text('ہفتہ وار جمعۃ المبارک درود مجلس'), findsNothing);

      // Rapidly toggle multiple times
      for (int i = 0; i < 6; i++) {
        globalLanguageProvider.toggleLanguage();
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // Verify consistent state
      final isUrdu = globalLanguageProvider.isUrdu;
      if (isUrdu) {
        expect(find.text('ہفتہ وار جمعۃ المبارک درود مجلس'), findsOneWidget);
      } else {
        expect(find.text("Weekly Jumu'ah Durood Majlis"), findsOneWidget);
      }
    });
  });
}
