import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/models/event_model.dart';
import 'package:islamic_app/features/home/presentation/widgets/event_card.dart';
import 'package:islamic_app/features/knowledge_hub/presentation/ask_question_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EventModel Null-Safety & Parsing Tests', () {
    test('EventModel.fromMap safely parses null and missing values', () {
      final model = EventModel.fromMap('evt_001', {});
      expect(model.id, equals('evt_001'));
      expect(model.title, equals(''));
      expect(model.titleUr, equals(''));
      expect(model.dateTime, equals(''));
      expect(model.location, equals(''));
      expect(model.status, equals('Coming Soon'));
      expect(model.imageUrl, isNull);
      expect(model.order, equals(0));
    });

    test('EventModel.fromMap parses String and num fields safely', () {
      final model = EventModel.fromMap('evt_002', {
        'title': 'Milad Conference',
        'title_ur': 'محفل میلاد',
        'date_time': '2026-09-12 20:00',
        'location': 'Faizan-e-Madina',
        'location_ur': 'فیضان مدینہ',
        'status': 'Ongoing',
        'order': 5,
        'image_url': 'https://example.com/banner.jpg',
      });

      expect(model.id, equals('evt_002'));
      expect(model.title, equals('Milad Conference'));
      expect(model.titleUr, equals('محفل میلاد'));
      expect(model.dateTime, equals('2026-09-12 20:00'));
      expect(model.location, equals('Faizan-e-Madina'));
      expect(model.locationUr, equals('فیضان مدینہ'));
      expect(model.status, equals('Ongoing'));
      expect(model.order, equals(5));
      expect(model.imageUrl, equals('https://example.com/banner.jpg'));
      expect(model.getStatusLabel(false), contains('LIVE NOW'));
      expect(model.getStatusLabel(true), contains('جاری ہے'));
    });

    test('EventModel.fromMap safely handles string orders and DateTime objects', () {
      final now = DateTime(2026, 8, 20);
      final model = EventModel.fromMap('evt_003', {
        'title': 'Durood Ijtima',
        'dateTime': now,
        'order': '12',
      });

      expect(model.dateTime, equals('20/8/2026'));
      expect(model.order, equals(12));
    });
  });

  group('AskQuestionSheet UI Layout & Safety Tests', () {
    testWidgets('AskQuestionSheet renders properly with SingleChildScrollView', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AskQuestionSheet(),
          ),
        ),
      );

      // Verify that SingleChildScrollView is present inside sheet
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });

  group('EventCard Bidirectional & RTL Tests', () {
    testWidgets('EventCard renders with bidirectional padding and badge', (WidgetTester tester) async {
      const event = EventModel(
        id: 'evt_test',
        title: 'Weekly Durood Gathering',
        titleUr: 'ہفتہ وار محفل درود',
        dateTime: 'Every Friday after Maghrib',
        location: 'Main Hall',
        locationUr: 'مرکزی ہال',
        status: 'Coming Soon',
        description: 'Join us for weekly salawat',
        descriptionUr: 'ہفتہ وار محفل درود میں شرکت فرمائیں',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EventCard(
              event: event,
            ),
          ),
        ),
      );

      expect(find.text('Weekly Durood Gathering'), findsOneWidget);
      expect(find.text('Main Hall'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    });
  });
}
