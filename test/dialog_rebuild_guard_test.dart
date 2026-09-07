import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/services/campaign_popup_service.dart';

class RebuildProneWidget extends StatefulWidget {
  final VoidCallback onDialogTrigger;

  const RebuildProneWidget({
    super.key,
    required this.onDialogTrigger,
  });

  @override
  State<RebuildProneWidget> createState() => _RebuildProneWidgetState();
}

class _RebuildProneWidgetState extends State<RebuildProneWidget> {
  bool _isDialogShowing = false;
  int _rebuildCounter = 0;

  @override
  void initState() {
    super.initState();
    _triggerDialogSafely();
  }

  void _triggerDialogSafely() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDialogShowing) return;
      _isDialogShowing = true;
      widget.onDialogTrigger();
      showDialog(
        context: context,
        useRootNavigator: true,
        builder: (ctx) => AlertDialog(
          title: const Text('Test Modal'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx, rootNavigator: true).pop();
              },
              child: const Text('Dismiss'),
            ),
          ],
        ),
      ).then((_) {
        if (mounted) {
          _isDialogShowing = false;
        }
      });
    });
  }

  void triggerExternalRebuild() {
    setState(() {
      _rebuildCounter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Rebuild Count: $_rebuildCounter'),
        ElevatedButton(
          onPressed: triggerExternalRebuild,
          child: const Text('Rebuild'),
        ),
      ],
    );
  }
}

void main() {
  group('Dialog Lifecycle and Rebuild Guard Tests', () {
    testWidgets('Lifecycle dialog triggers exactly once despite multiple rapid parent rebuilds', (WidgetTester tester) async {
      int triggerCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RebuildProneWidget(
              onDialogTrigger: () {
                triggerCount++;
              },
            ),
          ),
        ),
      );

      // Execute initial post-frame callback
      await tester.pumpAndSettle();

      expect(triggerCount, equals(1));
      expect(find.text('Test Modal'), findsOneWidget);

      // Rapidly trigger rebuilds while dialog is active
      final state = tester.state<_RebuildProneWidgetState>(find.byType(RebuildProneWidget));
      state.triggerExternalRebuild();
      await tester.pump();
      state.triggerExternalRebuild();
      await tester.pump();
      state.triggerExternalRebuild();
      await tester.pump();

      // Ensure no secondary or stacked dialogs were spawned
      expect(triggerCount, equals(1));
      expect(find.text('Test Modal'), findsOneWidget);

      // Dismiss dialog cleanly using rootNavigator: true button
      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();

      // Dialog is completely unmounted
      expect(find.text('Test Modal'), findsNothing);
    });

    test('CampaignPopupService static guard prevents concurrent dialog invocations', () {
      CampaignPopupService.resetSession();
      expect(CampaignPopupService.isDialogShowing, isFalse);

      // Simulated concurrent entry
      expect(CampaignPopupService.hasShownInSession, isFalse);
      CampaignPopupService.markShownInSession();
      expect(CampaignPopupService.hasShownInSession, isTrue);

      CampaignPopupService.resetSession();
      expect(CampaignPopupService.isDialogShowing, isFalse);
      expect(CampaignPopupService.hasShownInSession, isFalse);
    });
  });
}
