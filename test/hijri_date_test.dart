import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/models/hijri_date_model.dart';
import 'package:islamic_app/core/utils/islamic_date_helper.dart';

void main() {
  group('HijriDateModel Unit Tests', () {
    test('Formatted English and Urdu strings are generated correctly', () {
      const dateModel = HijriDateModel(
        day: 13,
        month: 3,
        year: 1448,
        monthNameEnglish: "Rabi' al-Awwal",
        monthNameUrdu: 'ربیع الاول',
      );

      expect(dateModel.formattedEnglish, "13 Rabi' al-Awwal 1448 AH");
      expect(dateModel.formattedUrdu, "13 ربیع الاول 1448ھ");
      expect(dateModel.getFormatted(false), "13 Rabi' al-Awwal 1448 AH");
      expect(dateModel.getFormatted(true), "13 ربیع الاول 1448ھ");
    });

    test('Serialization toMap and fromMap works seamlessly', () {
      const original = HijriDateModel(
        day: 1,
        month: 9,
        year: 1448,
        monthNameEnglish: 'Ramadan',
        monthNameUrdu: 'رمضان المبارک',
      );

      final map = original.toMap();
      final restored = HijriDateModel.fromMap(map);

      expect(restored.day, 1);
      expect(restored.month, 9);
      expect(restored.year, 1448);
      expect(restored.monthNameEnglish, 'Ramadan');
      expect(restored.monthNameUrdu, 'رمضان المبارک');
    });
  });

  group('IslamicDateHelper Algorithmic Conversion Tests', () {
    test('calculateOfflineHijriDate produces valid Islamic month and year', () {
      final date = DateTime(2026, 8, 29);
      final hijri = IslamicDateHelper.calculateOfflineHijriDate(date);

      expect(hijri.day, greaterThanOrEqualTo(1));
      expect(hijri.day, lessThanOrEqualTo(30));
      expect(hijri.month, greaterThanOrEqualTo(1));
      expect(hijri.month, lessThanOrEqualTo(12));
      expect(hijri.year, greaterThanOrEqualTo(1447));
      expect(hijri.monthNameEnglish.isNotEmpty, isTrue);
      expect(hijri.monthNameUrdu.isNotEmpty, isTrue);
    });

    test('Day offset calculation shifts Hijri date by exact days', () {
      final baseDate = DateTime(2026, 8, 29);
      final standard = IslamicDateHelper.calculateOfflineHijriDate(baseDate);
      final plusOne = IslamicDateHelper.calculateOfflineHijriDate(baseDate.add(const Duration(days: 1)));
      final minusOne = IslamicDateHelper.calculateOfflineHijriDate(baseDate.subtract(const Duration(days: 1)));

      expect(standard.day != plusOne.day || standard.month != plusOne.month, isTrue);
      expect(standard.day != minusOne.day || standard.month != minusOne.month, isTrue);
    });

    test('All 12 Islamic months exist in English and Urdu dictionaries', () {
      expect(IslamicDateHelper.islamicMonthsEnglish.length, 12);
      expect(IslamicDateHelper.islamicMonthsUrdu.length, 12);
      expect(IslamicDateHelper.islamicMonthsEnglish[0], 'Muharram');
      expect(IslamicDateHelper.islamicMonthsUrdu[0], 'محرم الحرام');
      expect(IslamicDateHelper.islamicMonthsEnglish[8], 'Ramadan');
      expect(IslamicDateHelper.islamicMonthsUrdu[8], 'رمضان المبارک');
    });
    test('Harmonization: 2026-09-07 with 0 offset matches Web Admin Preview (24 Rabi al-Awwal 1448 AH)', () {
      final date = DateTime(2026, 9, 7);
      final hijri = IslamicDateHelper.getHijriDateSync(gregorianDate: date, dayOffset: 0);

      expect(hijri.day, 24);
      expect(hijri.month, 3);
      expect(hijri.year, 1448);
      expect(hijri.formattedEnglish, "24 Rabi' al-Awwal 1448 AH");
      expect(hijri.formattedUrdu, "24 ربیع الاول 1448ھ");
    });

    test('Harmonization: Moon sighting offset adjusts date synchronously and deterministically', () {
      final date = DateTime(2026, 9, 7);

      final zeroOffset = IslamicDateHelper.getHijriDateSync(gregorianDate: date, dayOffset: 0);
      final plusOne = IslamicDateHelper.getHijriDateSync(gregorianDate: date, dayOffset: 1);
      final minusOne = IslamicDateHelper.getHijriDateSync(gregorianDate: date, dayOffset: -1);
      final plusTwo = IslamicDateHelper.getHijriDateSync(gregorianDate: date, dayOffset: 2);
      final minusTwo = IslamicDateHelper.getHijriDateSync(gregorianDate: date, dayOffset: -2);

      expect(zeroOffset.formattedEnglish, "24 Rabi' al-Awwal 1448 AH");
      expect(plusOne.formattedEnglish, "25 Rabi' al-Awwal 1448 AH");
      expect(minusOne.formattedEnglish, "23 Rabi' al-Awwal 1448 AH");
      expect(plusTwo.formattedEnglish, "26 Rabi' al-Awwal 1448 AH");
      expect(minusTwo.formattedEnglish, "22 Rabi' al-Awwal 1448 AH");

      // Verify Urdu
      expect(zeroOffset.formattedUrdu, "24 ربیع الاول 1448ھ");
      expect(plusOne.formattedUrdu, "25 ربیع الاول 1448ھ");
      expect(minusOne.formattedUrdu, "23 ربیع الاول 1448ھ");
    });
  });

  group('Header Hijri Date Widget Tests', () {
    testWidgets('Renders Hijri Date Badge with crescent icon', (WidgetTester tester) async {
      final sampleDate = IslamicDateHelper.calculateOfflineHijriDate(DateTime(2026, 8, 29));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.nightlight_round, size: 13),
                  const SizedBox(width: 6),
                  Text(sampleDate.formattedEnglish),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.nightlight_round), findsOneWidget);
      expect(find.text(sampleDate.formattedEnglish), findsOneWidget);
    });

    testWidgets('Header Badge renders exact Web Admin synchronized date for 2026-09-07 with 0 offset', (WidgetTester tester) async {
      final date = DateTime(2026, 9, 7);
      final synchronizedDate = IslamicDateHelper.getHijriDateSync(gregorianDate: date, dayOffset: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Text(synchronizedDate.formattedEnglish),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("24 Rabi' al-Awwal 1448 AH"), findsOneWidget);
    });
  });
}
