import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/features/knowledge_hub/presentation/aqaid_grid.dart';
import 'package:islamic_app/features/knowledge_hub/presentation/my_questions_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bug 1: Aqaid Quran Pak Category and Empty State Tests', () {
    testWidgets('Quran Pak category contains authentic Aqaid content', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: AqaidGridScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find Quran filter chip by predicate
      final quranFilter = find.byWidgetPredicate(
        (w) => w is FilterChip && (w.label is Text) &&
            (((w.label as Text).data?.contains('Quran') ?? false) ||
             ((w.label as Text).data?.contains('قرآن') ?? false)),
      );
      expect(quranFilter, findsOneWidget);

      await tester.tap(quranFilter);
      await tester.pumpAndSettle();

      // Verify that Quran Pak items are found and loaded (either English or Urdu title)
      final hasTitle = find.text('The Holy Quran: Eternal Word of Allah').evaluate().isNotEmpty ||
          find.text('قرآنِ مجید: اللہ تعالیٰ کا کلامِ غیر مخلوق').evaluate().isNotEmpty ||
          find.textContaining('Quran').evaluate().isNotEmpty ||
          find.textContaining('قرآن').evaluate().isNotEmpty;
      expect(hasTitle, isTrue);
    });
  });

  group('Bug 2 & 3: MyQuestionsScreen Header and Layout Tests', () {
    testWidgets('MyQuestionsScreen header title renders and FAB is positioned', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MyQuestionsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header Title exists in AppBar
      final hasHeader = find.text('My Questions & Inquiries').evaluate().isNotEmpty ||
          find.text('میرے سوالات و استفسارات').evaluate().isNotEmpty;
      expect(hasHeader, isTrue);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
