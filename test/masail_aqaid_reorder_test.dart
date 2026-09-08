import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/models/masail_model.dart';
import 'package:islamic_app/core/models/aqaid_model.dart';

void main() {
  group('MasailItemModel orderIndex & Backward Compatibility', () {
    test('defaults to orderIndex 0 if omitted in constructor', () {
      const item = MasailItemModel(
        id: 'm1',
        categoryId: 'namaz',
        question: 'Q1',
        answer: 'A1',
        book: 'Book 1',
      );
      expect(item.orderIndex, equals(0));
    });

    test('serializes and deserializes orderIndex correctly', () {
      const item = MasailItemModel(
        id: 'm1',
        categoryId: 'namaz',
        question: 'Q1',
        answer: 'A1',
        book: 'Book 1',
        orderIndex: 4,
      );

      final map = item.toMap();
      expect(map['orderIndex'], equals(4));

      final fromMap = MasailItemModel.fromMap('m1', map);
      expect(fromMap.orderIndex, equals(4));
    });

    test('falls back to legacy order field or defaultOrderIndex when orderIndex missing', () {
      final legacyMapWithOrder = {
        'category_id': 'namaz',
        'question': 'Q1',
        'answer': 'A1',
        'book': 'Book 1',
        'order': 7,
      };
      final fromOrder = MasailItemModel.fromMap('m2', legacyMapWithOrder);
      expect(fromOrder.orderIndex, equals(7));

      final legacyMapWithoutOrder = {
        'category_id': 'namaz',
        'question': 'Q1',
        'answer': 'A1',
        'book': 'Book 1',
      };
      final fromDefault = MasailItemModel.fromMap('m3', legacyMapWithoutOrder, defaultOrderIndex: 12);
      expect(fromDefault.orderIndex, equals(12));
    });

    test('copyWith updates orderIndex properly', () {
      const original = MasailItemModel(
        id: 'm1',
        categoryId: 'namaz',
        question: 'Q1',
        answer: 'A1',
        book: 'Book 1',
        orderIndex: 2,
      );
      final updated = original.copyWith(orderIndex: 10);
      expect(updated.orderIndex, equals(10));
      expect(updated.question, equals('Q1'));
    });
  });

  group('AqaidItemModel orderIndex & Backward Compatibility', () {
    test('defaults to orderIndex 0 if omitted in constructor', () {
      const item = AqaidItemModel(
        id: 'a1',
        categoryId: 'tawheed',
        title: 'Title 1',
        arabicText: 'Arabic',
        explanation: 'Exp',
        book: 'Book 1',
      );
      expect(item.orderIndex, equals(0));
    });

    test('serializes and deserializes orderIndex and order correctly', () {
      const item = AqaidItemModel(
        id: 'a1',
        categoryId: 'tawheed',
        title: 'Title 1',
        arabicText: 'Arabic',
        explanation: 'Exp',
        book: 'Book 1',
        orderIndex: 5,
      );

      final map = item.toMap();
      expect(map['orderIndex'], equals(5));
      expect(map['order'], equals(5));

      final fromMap = AqaidItemModel.fromMap('a1', map);
      expect(fromMap.orderIndex, equals(5));
    });

    test('falls back to legacy order or defaultOrderIndex when orderIndex missing', () {
      final legacyMapWithOrder = {
        'category_id': 'tawheed',
        'title': 'Title 1',
        'arabic_text': 'Arabic',
        'explanation': 'Exp',
        'book': 'Book 1',
        'order': 9,
      };
      final fromOrder = AqaidItemModel.fromMap('a2', legacyMapWithOrder);
      expect(fromOrder.orderIndex, equals(9));

      final legacyMapWithoutOrder = {
        'category_id': 'tawheed',
        'title': 'Title 1',
        'arabic_text': 'Arabic',
        'explanation': 'Exp',
        'book': 'Book 1',
      };
      final fromDefault = AqaidItemModel.fromMap('a3', legacyMapWithoutOrder, defaultOrderIndex: 15);
      expect(fromDefault.orderIndex, equals(15));
    });

    test('copyWith updates orderIndex properly', () {
      const original = AqaidItemModel(
        id: 'a1',
        categoryId: 'tawheed',
        title: 'Title 1',
        arabicText: 'Arabic',
        explanation: 'Exp',
        book: 'Book 1',
        orderIndex: 3,
      );
      final updated = original.copyWith(orderIndex: 8);
      expect(updated.orderIndex, equals(8));
      expect(updated.title, equals('Title 1'));
    });
  });

  group('Masail and Aqaid Sorting by orderIndex', () {
    test('sorts items in strictly ascending orderIndex order', () {
      final items = [
        const MasailItemModel(id: '3', categoryId: 'namaz', question: 'Q3', answer: 'A', book: 'B', orderIndex: 10),
        const MasailItemModel(id: '1', categoryId: 'namaz', question: 'Q1', answer: 'A', book: 'B', orderIndex: 0),
        const MasailItemModel(id: '2', categoryId: 'namaz', question: 'Q2', answer: 'A', book: 'B', orderIndex: 5),
      ];

      items.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

      expect(items.map((e) => e.id).toList(), equals(['1', '2', '3']));
    });
  });

  group('ReorderableListView UI Widget Test', () {
    testWidgets('ReorderableListView displays drag handles with grab cursor and restricted initiation', (tester) async {
      final items = ['Item 1', 'Item 2', 'Item 3'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: items.length,
              // ignore: deprecated_member_use
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = items.removeAt(oldIndex);
                items.insert(newIndex, item);
              },
              itemBuilder: (context, index) {
                return Container(
                  key: ValueKey(items[index]),
                  child: Row(
                    children: [
                      ReorderableDragStartListener(
                        index: index,
                        child: const MouseRegion(
                          cursor: SystemMouseCursors.grab,
                          child: Icon(Icons.drag_indicator_rounded),
                        ),
                      ),
                      Text(items[index]),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Verify all items and drag handles rendered
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
      expect(find.byIcon(Icons.drag_indicator_rounded), findsNWidgets(3));

      // Verify drag start listener exists
      expect(find.byType(ReorderableDragStartListener), findsNWidgets(3));
    });
  });
}
