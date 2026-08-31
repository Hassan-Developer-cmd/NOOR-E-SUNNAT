import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/models/team_member.dart';
import 'package:islamic_app/features/profile/presentation/widgets/profile_settings_sheets.dart';
import 'package:islamic_app/main.dart';

void main() {
  setUp(() async {
    await globalLanguageProvider.init();
  });

  test('All team members image paths exist on filesystem', () {
    for (final member in TeamMember.allMembers) {
      if (member.imagePath != null) {
        final file = File(member.imagePath!);
        expect(file.existsSync(), isTrue, reason: 'File does not exist: ${member.imagePath}');
      }
    }
  });

  testWidgets('Our Team sheet renders all team member avatars cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ProfileSettingsSheets.showOurTeamSheet(context),
              child: const Text('Open Team'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Team'));
    await tester.pumpAndSettle();

    expect(find.text('HASSAN AWAN'), findsOneWidget);
    expect(find.text('DAWOOD AHMAD'), findsNWidgets(2));
    expect(find.text('MUHAMMAD ASIM'), findsOneWidget);
    expect(find.text('AHTESHAM'), findsOneWidget);
    expect(find.text('MUHAMMAD IBRAHIM ATTARI'), findsOneWidget);
  });
}
