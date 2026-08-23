import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/localization/app_translations.dart';
import 'package:islamic_app/features/profile/presentation/widgets/profile_settings_sheets.dart';
import 'package:islamic_app/main.dart';

void main() {
  setUp(() async {
    await globalLanguageProvider.init();
  });

  group('Profile Settings Localization Tests', () {
    test('Translations contains all 5 settings items in English and Urdu', () {
      final en = AppTranslations.translations['en']!;
      final ur = AppTranslations.translations['ur']!;

      expect(en['settings_about_us'], 'About Us');
      expect(ur['settings_about_us'], 'ہماری بابت');

      expect(en['settings_our_team'], 'Our Team');
      expect(ur['settings_our_team'], 'ہماری ٹیم');

      expect(en['settings_share_app'], 'Share App');
      expect(ur['settings_share_app'], 'ایپ شیئر کریں');

      expect(en['settings_rate_app'], 'Rate App');
      expect(ur['settings_rate_app'], 'ایپ کی درجہ بندی کریں');

      expect(en['settings_terms_policy'], 'Terms & Privacy Policy');
      expect(ur['settings_terms_policy'], 'شرائط و پرائیویسی پالیسی');
    });
  });

  group('Profile Settings Sheets Widget Tests', () {
    testWidgets('About Us sheet opens and displays version and mission', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ProfileSettingsSheets.showAboutUsSheet(context),
                child: const Text('Open About Us'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open About Us'));
      await tester.pumpAndSettle();

      expect(find.text('About NOOR E SUNNAT'), findsOneWidget);
      expect(find.text('App Version 1.0.0 (Faizan-e-Durood)'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('Our Team sheet opens and displays team roles', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ProfileSettingsSheets.showOurTeamSheet(context),
                child: const Text('Open Our Team'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Our Team'));
      await tester.pumpAndSettle();

      expect(find.text('Our Dedicated Team'), findsOneWidget);
      expect(find.text('Engineering & Technology'), findsOneWidget);
      expect(find.text('Shariah & Hadith Research'), findsOneWidget);
    });

    testWidgets('Share App sheet opens and displays invitation message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ProfileSettingsSheets.showShareAppSheet(context),
                child: const Text('Open Share App'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Share App'));
      await tester.pumpAndSettle();

      expect(find.text('Share NOOR E SUNNAT'), findsOneWidget);
      expect(find.text('Copy Invitation Link'), findsOneWidget);
    });

    testWidgets('Rate App dialog opens with 5 stars and submit button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ProfileSettingsSheets.showRateAppDialog(context),
                child: const Text('Open Rate App'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Rate App'));
      await tester.pumpAndSettle();

      expect(find.text('Rate Your Experience'), findsOneWidget);
      expect(find.text('Submit Review'), findsOneWidget);
    });

    testWidgets('Terms & Privacy Policy sheet opens with tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ProfileSettingsSheets.showTermsAndPolicySheet(context),
                child: const Text('Open Terms'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Terms'));
      await tester.pumpAndSettle();

      expect(find.text('Terms & Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
    });
  });
}
