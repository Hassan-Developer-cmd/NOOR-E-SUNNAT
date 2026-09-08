import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/models/campaign_popup_model.dart';
import 'package:islamic_app/core/widgets/campaign_popup_dialog.dart';
import 'package:islamic_app/services/campaign_popup_service.dart';

void main() {
  group('CampaignPopupModel Unit Tests', () {
    test('Default model contains valid fallback values', () {
      final model = CampaignPopupModel.defaultConfig();
      expect(model.isActive, isTrue);
      expect(model.showActionButton, isTrue);
      expect(model.titleEnglish, contains('Global Durood Campaign'));
      expect(model.titleUrdu, contains('خصوصی مہم برائے درود پاک'));
      expect(model.buttonTextEnglish, 'Recite Now');
      expect(model.buttonTextUrdu, 'شرکت کریں');
      expect(model.targetRoute, '/counter');
      expect(model.imageType, 'url');
    });

    test('getTitle / getDetails / getButtonText returns correct language', () {
      const model = CampaignPopupModel(
        titleEnglish: 'Mega Durood Campaign',
        titleUrdu: 'عظیم الشان درود مہم',
        detailsEnglish: 'Win spiritual prizes',
        detailsUrdu: 'روحانی انعامات حاصل کریں',
        buttonTextEnglish: 'Join Now',
        buttonTextUrdu: 'ابھی شامل ہوں',
      );

      // English
      expect(model.getTitle(false), 'Mega Durood Campaign');
      expect(model.getDetails(false), 'Win spiritual prizes');
      expect(model.getButtonText(false), 'Join Now');

      // Urdu
      expect(model.getTitle(true), 'عظیم الشان درود مہم');
      expect(model.getDetails(true), 'روحانی انعامات حاصل کریں');
      expect(model.getButtonText(true), 'ابھی شامل ہوں');
    });

    test('Serialization toMap and fromMap works seamlessly with showActionButton', () {
      const original = CampaignPopupModel(
        id: 'launch_popup',
        isActive: false,
        showActionButton: false,
        titleEnglish: 'Ramadan 2026',
        titleUrdu: 'رمضان المبارک',
        detailsEnglish: 'Fast and pray',
        detailsUrdu: 'روزہ اور عبادت',
        buttonTextEnglish: 'Explore',
        buttonTextUrdu: 'دیکھیں',
        targetRoute: '/counter',
        imageType: 'base64',
        imageBase64: 'abc123xyz',
      );

      final map = original.toMap();
      final restored = CampaignPopupModel.fromMap('launch_popup', map);

      expect(restored.isActive, isFalse);
      expect(restored.showActionButton, isFalse);
      expect(restored.titleEnglish, 'Ramadan 2026');
      expect(restored.titleUrdu, 'رمضان المبارک');
      expect(restored.targetRoute, '/counter');
      expect(restored.imageType, 'base64');
      expect(restored.imageBase64, 'abc123xyz');
    });
  });

  group('CampaignPopupService Session Guard Tests', () {
    test('Session tracking marks and resets correctly', () {
      CampaignPopupService.resetSession();
      expect(CampaignPopupService.hasShownInSession, isFalse);
      expect(CampaignPopupService.isDialogShowing, isFalse);

      CampaignPopupService.markShownInSession();
      expect(CampaignPopupService.hasShownInSession, isTrue);

      CampaignPopupService.resetSession();
      expect(CampaignPopupService.hasShownInSession, isFalse);
      expect(CampaignPopupService.isDialogShowing, isFalse);
    });
  });

  group('CampaignPopupDialog Widget Tests', () {
    testWidgets('Renders modal dialog with CTA button when showActionButton is true', (WidgetTester tester) async {
      final config = CampaignPopupModel.defaultConfig();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CampaignPopupDialog(
              config: config,
              isPreview: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(config.titleEnglish), findsOneWidget);
      expect(find.text(config.detailsEnglish), findsOneWidget);
      expect(find.text(config.buttonTextEnglish), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('Renders modal dialog without CTA button when showActionButton is false', (WidgetTester tester) async {
      final config = CampaignPopupModel.defaultConfig().copyWith(showActionButton: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CampaignPopupDialog(
              config: config,
              isPreview: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(config.titleEnglish), findsOneWidget);
      expect(find.text(config.detailsEnglish), findsOneWidget);
      expect(find.text(config.buttonTextEnglish), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });
  });
}
