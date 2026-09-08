import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/localization/app_translations.dart';
import 'package:islamic_app/core/models/app_user.dart';
import 'package:islamic_app/core/widgets/terms_acceptance_dialog.dart';
import 'package:islamic_app/services/terms_acceptance_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Terms & Conditions Bilingual Content Requirements', () {
    test('English authenticity clause matches required text exactly', () {
      final text = AppTranslations.get('terms_point_1', 'en');
      expect(
        text,
        'Our Islamic research team takes Islamic content from authentic Islamic books and sources and has it reviewed by Islamic scholars.',
      );
    });

    test('Urdu authenticity clause matches required text exactly', () {
      final text = AppTranslations.get('terms_point_1', 'ur');
      expect(
        text,
        'ہماری اسلامی ریسرچ ٹیم اسلامی مواد مستند اسلامی کتب اور ذرائع سے حاصل کرتی ہے اور اسے علماء کرام سے چیک کرواتی ہے۔',
      );
    });

    test('English disclaimer clause matches required text exactly', () {
      final text = AppTranslations.get('terms_point_disclaimer', 'en');
      expect(
        text,
        'Despite our efforts, there may be occasional errors in the content, such as text or data mistakes.',
      );
    });

    test('Urdu disclaimer clause matches required text exactly', () {
      final text = AppTranslations.get('terms_point_disclaimer', 'ur');
      expect(
        text,
        'ہماری بھرپور کوشش کے باوجود مواد میں کبھی کبھار متن یا معلومات کی معمولی غلطی ہو سکتی ہے۔',
      );
    });

    test('Bilingual CTA button text is defined accurately', () {
      expect(AppTranslations.get('terms_accept_btn', 'en'), 'Accept and Continue');
      expect(AppTranslations.get('terms_accept_btn', 'ur'), 'قبول کریں اور جاری رکھیں');
    });
  });

  group('TermsAcceptanceService Storage & Logic', () {
    test('hasUserAcceptedTerms returns false when key is absent in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final accepted = await TermsAcceptanceService.hasUserAcceptedTerms();
      expect(accepted, isFalse);
    });

    test('hasUserAcceptedTerms returns true when has_accepted_terms_v1 is true in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'has_accepted_terms_v1': true,
      });
      final accepted = await TermsAcceptanceService.hasUserAcceptedTerms();
      expect(accepted, isTrue);
    });

    test('acceptTerms persists has_accepted_terms_v1 = true in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      await TermsAcceptanceService.acceptTerms();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('has_accepted_terms_v1'), isTrue);
    });
  });

  group('AppUser Model Terms Serialization', () {
    test('AppUser parses hasAcceptedTerms and termsAcceptedAt properly', () {
      final now = DateTime.now();
      final user = AppUser.fromMap({
        'uid': 'test_uid',
        'email': 'test@example.com',
        'hasAcceptedTerms': true,
        'termsAcceptedAt': now.toIso8601String(),
      });

      expect(user.hasAcceptedTerms, isTrue);
      expect(user.termsAcceptedAt, isNotNull);

      final map = user.toMap();
      expect(map['hasAcceptedTerms'], isTrue);
      expect(map['termsAcceptedAt'], isNotNull);
    });
  });

  group('TermsAcceptanceDialog Widget Tests', () {
    testWidgets('Renders Terms Acceptance Dialog with updated clauses and CTA button in English and Urdu', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      bool acceptedCallbackTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TermsAcceptanceDialog(
              onAccepted: () => acceptedCallbackTriggered = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify dialog is visible
      expect(find.byType(TermsAcceptanceDialog), findsOneWidget);

      // Verify English clauses and CTA are rendered initially
      expect(
        find.textContaining('Our Islamic research team takes Islamic content'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Despite our efforts, there may be occasional errors'),
        findsOneWidget,
      );
      expect(find.textContaining('Accept and Continue'), findsOneWidget);

      // Toggle language to Urdu via chip
      await tester.tap(find.text('اردو'));
      await tester.pumpAndSettle();

      // Verify Urdu clauses and CTA are now visible
      expect(
        find.textContaining('ہماری اسلامی ریسرچ ٹیم اسلامی مواد مستند اسلامی کتب اور ذرائع'),
        findsOneWidget,
      );
      expect(
        find.textContaining('ہماری بھرپور کوشش کے باوجود مواد میں کبھی کبھار'),
        findsOneWidget,
      );
      expect(find.textContaining('قبول کریں اور جاری رکھیں'), findsOneWidget);

      // Tap "Accept and Continue"
      await tester.tap(find.textContaining('قبول کریں اور جاری رکھیں'));
      await tester.pumpAndSettle();

      // Verify callback triggered and SharedPreferences updated
      expect(acceptedCallbackTriggered, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('has_accepted_terms_v1'), isTrue);
    });
  });
}
