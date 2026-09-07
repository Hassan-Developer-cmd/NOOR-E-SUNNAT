import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/features/home/presentation/widgets/durood_summary_card.dart';
import 'package:islamic_app/services/counter_service.dart';

class FakeCounterService extends ChangeNotifier implements CounterService {
  @override
  CounterSnapshot get snapshot => const CounterSnapshot(
        globalTotal: 20300,
        globalToday: 14100,
        personalTotal: 16600,
        personalToday: 14100,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DuroodSummaryCard Bold Typography & Visual Definition Tests', () {
    late FakeCounterService fakeCounterService;

    setUp(() {
      fakeCounterService = FakeCounterService();
    });

    testWidgets('Renders all 4 metrics with bold weights, prominent sizes, and high contrast', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 2.0, 844 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DuroodSummaryCard(
                counterService: fakeCounterService,
                onSendSalawat: () {},
                globalTotal: 20300,
                todayTotal: 14100,
                myTotal: 16600,
                myToday: 14100,
                isLoggedIn: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify no layout overflow exception
      expect(tester.takeException(), isNull);

      // Verify card container visual definition (gradient, border, shadows)
      final containerFinder = find.byType(Container).first;
      final containerWidget = tester.widget<Container>(containerFinder);
      final decoration = containerWidget.decoration as BoxDecoration;

      expect(decoration.border, isNotNull);
      expect(decoration.border?.top.width, equals(1.2));
      expect(decoration.border?.top.color, equals(const Color(0xFFB45309).withValues(alpha: 0.35)));
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow!.length, greaterThanOrEqualTo(2));

      // Verify Card Title typography
      final titleTextFinder = find.text('Durood Count');
      expect(titleTextFinder, findsOneWidget);
      final titleText = tester.widget<Text>(titleTextFinder);
      expect(titleText.style?.fontWeight, equals(FontWeight.w700));
      expect(titleText.style?.color, equals(const Color(0xFF451A03)));

      // Verify Category Labels bold weights and high contrast
      final globalTotalLabelFinder = find.text('GLOBAL TOTAL');
      expect(globalTotalLabelFinder, findsOneWidget);
      final globalTotalLabel = tester.widget<Text>(globalTotalLabelFinder);
      expect(globalTotalLabel.style?.fontWeight, equals(FontWeight.w700));
      expect(globalTotalLabel.style?.color, equals(const Color(0xFF78350F)));

      final myTotalLabelFinder = find.text('MY TOTAL');
      expect(myTotalLabelFinder, findsOneWidget);
      final myTotalLabel = tester.widget<Text>(myTotalLabelFinder);
      expect(myTotalLabel.style?.fontWeight, equals(FontWeight.w700));
      expect(myTotalLabel.style?.color, equals(const Color(0xFF78350F)));

      // Verify Numeric Values prominence (20.0 sp, FontWeight.w800, high contrast espresso color)
      final number20kFinder = find.text('20.3K');
      expect(number20kFinder, findsOneWidget);
      final number20k = tester.widget<Text>(number20kFinder);
      expect(number20k.style?.fontWeight, equals(FontWeight.w800));
      expect(number20k.style?.fontSize, equals(20.0));
      expect(number20k.style?.color, equals(const Color(0xFF451A03)));

      final number16kFinder = find.text('16.6K');
      expect(number16kFinder, findsOneWidget);
      final number16k = tester.widget<Text>(number16kFinder);
      expect(number16k.style?.fontWeight, equals(FontWeight.w800));
      expect(number16k.style?.fontSize, equals(20.0));
      expect(number16k.style?.color, equals(const Color(0xFF451A03)));

      // Verify 4 numbers are displayed cleanly side-by-side
      expect(find.text('14.1K'), findsNWidgets(2));
    });

    testWidgets('Renders cleanly on narrow 320dp viewport without layout overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320 * 2.0, 640 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DuroodSummaryCard(
                counterService: fakeCounterService,
                onSendSalawat: () {},
                globalTotal: 20300,
                todayTotal: 14100,
                myTotal: 16600,
                myToday: 14100,
                isLoggedIn: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders 2 columns for public/unauthenticated view without overflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DuroodSummaryCard(
              counterService: fakeCounterService,
              onSendSalawat: () {},
              globalTotal: 20300,
              todayTotal: 14100,
              isLoggedIn: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('GLOBAL TOTAL'), findsOneWidget);
      expect(find.text('GLOBAL TODAY'), findsOneWidget);
      expect(find.text('MY TOTAL'), findsNothing);
      expect(find.text('MY TODAY'), findsNothing);
    });
  });
}
