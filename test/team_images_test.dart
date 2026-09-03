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
        expect(file.lengthSync(), greaterThan(1000), reason: 'File is empty: ${member.imagePath}');
      }
    }
  });

  test('Team member image files are valid PNG/JPEG bytes', () {
    for (final member in TeamMember.allMembers) {
      if (member.imagePath != null) {
        final bytes = File(member.imagePath!).readAsBytesSync();
        // Check PNG magic bytes (0x89 0x50 0x4E 0x47) or JPEG magic bytes (0xFF 0xD8)
        final isPng = bytes.length > 4 && bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47;
        final isJpeg = bytes.length > 2 && bytes[0] == 0xFF && bytes[1] == 0xD8;
        expect(isPng || isJpeg, isTrue, reason: 'File is not a valid image format: ${member.imagePath}');
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
    expect(find.textContaining('MUHAMMAD IBRAHIM'), findsOneWidget);
  });
}
