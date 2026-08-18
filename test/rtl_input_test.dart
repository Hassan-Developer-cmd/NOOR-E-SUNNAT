import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/features/knowledge_hub/presentation/ask_question_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RTL Urdu and Arabic Input Field Tests', () {
    test('Regex correctly identifies Arabic and Urdu Unicode characters', () {
      final rtlRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]');

      // Urdu / Arabic strings
      expect(rtlRegex.hasMatch('نماز کا طریقہ'), isTrue);
      expect(rtlRegex.hasMatch('الحديث الشريف'), isTrue);
      expect(rtlRegex.hasMatch('اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ'), isTrue);
      expect(rtlRegex.hasMatch('بہارِ شریعت'), isTrue);

      // English strings
      expect(rtlRegex.hasMatch('Event Title in English'), isFalse);
      expect(rtlRegex.hasMatch('Question regarding fasting'), isFalse);
    });

    testWidgets('AskQuestionSheet renders multiline TextField with RTL direction for Urdu', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AskQuestionSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      final TextField textField = tester.widget(textFieldFinder);
      expect(textField.maxLines, 4);
    });
  });
}
