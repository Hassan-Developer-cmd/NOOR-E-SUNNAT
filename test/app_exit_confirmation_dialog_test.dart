import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:islamic_app/core/localization/app_translations.dart';
import 'package:islamic_app/core/widgets/app_exit_confirmation_dialog.dart';
import 'package:islamic_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await globalLanguageProvider.init();
  });

  group('AppTranslations Exit Keys', () {
    test('English and Urdu translations contain exit app keys', () {
      expect(AppTranslations.get('exit_app_title', 'en'), isNotEmpty);
      expect(AppTranslations.get('exit_app_msg', 'en'), isNotEmpty);
      expect(AppTranslations.get('exit_app_action', 'en'), equals('Exit App'));
      expect(AppTranslations.get('exit_app_cancel', 'en'), equals('Cancel'));

      expect(AppTranslations.get('exit_app_title', 'ur'), isNotEmpty);
      expect(AppTranslations.get('exit_app_msg', 'ur'), isNotEmpty);
      expect(AppTranslations.get('exit_app_action', 'ur'), equals('ایپ بند کریں'));
      expect(AppTranslations.get('exit_app_cancel', 'ur'), equals('منسوخ'));
    });
  });

  group('AppExitConfirmationDialog Widget Tests', () {
    testWidgets('Renders properly in English and handles Cancel button', (tester) async {
      await globalLanguageProvider.setLanguage('en');

      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await AppExitConfirmationDialog.show(context);
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Check English title and actions
      expect(find.text('Exit NOOR E SUNNAT?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Exit App'), findsOneWidget);
      expect(find.byIcon(Icons.power_settings_new_rounded), findsOneWidget);
      expect(find.byIcon(Icons.exit_to_app_rounded), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog dismissed, result is false
      expect(find.byType(AppExitConfirmationDialog), findsNothing);
      expect(dialogResult, equals(false));
    });

    testWidgets('Renders properly in English and handles Exit App button', (tester) async {
      await globalLanguageProvider.setLanguage('en');

      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await AppExitConfirmationDialog.show(context);
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap Exit App
      await tester.tap(find.text('Exit App'));
      await tester.pumpAndSettle();

      // Dialog dismissed, result is true
      expect(find.byType(AppExitConfirmationDialog), findsNothing);
      expect(dialogResult, equals(true));
    });

    testWidgets('Renders properly in Urdu with RTL layout', (tester) async {
      await globalLanguageProvider.setLanguage('ur');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await AppExitConfirmationDialog.show(context);
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify Urdu texts
      expect(find.text('ایپ سے خروج؟'), findsOneWidget);
      expect(find.text('منسوخ'), findsOneWidget);
      expect(find.text('ایپ بند کریں'), findsOneWidget);

      // Reset to English
      await globalLanguageProvider.setLanguage('en');
    });
  });
}
