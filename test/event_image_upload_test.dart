import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/models/event_model.dart';
import 'package:islamic_app/features/home/presentation/widgets/event_card.dart';
import 'package:islamic_app/main.dart';

void main() {
  setUp(() async {
    await globalLanguageProvider.init();
  });

  group('EventModel Dual Image Serialization Tests', () {
    test('EventModel serializes and parses URL image correctly', () {
      final event = EventModel(
        id: 'event-url-1',
        title: 'Milad un Nabi Conference',
        dateTime: '12 Rabi-ul-Awwal',
        location: 'Faizan-e-Madina',
        status: 'Featured',
        description: 'Grand Annual Milad Gathering',
        imageType: EventModel.imageTypeUrl,
        imageUrl: 'https://example.com/milad.jpg',
      );

      final map = event.toMap();
      expect(map['image_type'], 'url');
      expect(map['image_url'], 'https://example.com/milad.jpg');
      expect(map['image_base64'], isNull);

      final parsed = EventModel.fromMap('event-url-1', map);
      expect(parsed.imageType, 'url');
      expect(parsed.imageUrl, 'https://example.com/milad.jpg');
      expect(parsed.imageBase64, isNull);
    });

    test('EventModel serializes and parses Base64 image correctly', () {
      final dummyBase64 = base64Encode(Uint8List.fromList([0, 1, 2, 3, 4, 5, 6, 7]));
      final event = EventModel(
        id: 'event-b64-1',
        title: 'Shab-e-Barat Vigil',
        dateTime: '15 Shaban',
        location: 'Main Hall',
        status: 'Ongoing',
        description: 'Night of forgiveness',
        imageType: EventModel.imageTypeBase64,
        imageBase64: dummyBase64,
      );

      final map = event.toMap();
      expect(map['image_type'], 'base64');
      expect(map['image_base64'], dummyBase64);
      expect(map['image_url'], isNull);

      final parsed = EventModel.fromMap('event-b64-1', map);
      expect(parsed.imageType, 'base64');
      expect(parsed.imageBase64, dummyBase64);
      expect(parsed.imageUrl, isNull);
    });
  });

  group('EventCard Dual Image Rendering Widget Tests', () {
    testWidgets('EventCard renders Image.network when imageUrl is provided', (WidgetTester tester) async {
      final event = EventModel(
        id: 'test-1',
        title: 'Jummah Gathering',
        dateTime: 'Friday 1:30 PM',
        location: 'Central Mosque',
        status: 'Featured',
        description: 'Weekly Durood Mehfil',
        imageType: EventModel.imageTypeUrl,
        imageUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventCard(event: event),
          ),
        ),
      );

      expect(find.text('Jummah Gathering'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('EventCard renders Image.memory when imageBase64 is provided', (WidgetTester tester) async {
      // 1x1 transparent PNG Base64
      const transparentPngBase64 =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

      final event = EventModel(
        id: 'test-b64',
        title: 'Special Seerah Workshop',
        dateTime: 'Sunday 10:00 AM',
        location: 'Auditorium',
        status: 'Coming Soon',
        description: 'Interactive Seerah Course',
        imageType: EventModel.imageTypeBase64,
        imageBase64: transparentPngBase64,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventCard(event: event),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Special Seerah Workshop'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });
  });
}
