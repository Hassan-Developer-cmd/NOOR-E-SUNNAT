import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/features/admin_panel/presentation/admin_login_screen.dart';
import 'package:islamic_app/features/auth/presentation/login_screen.dart';
import 'package:islamic_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('AdminLoginScreen UI component test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdminLoginScreen(
          onAdminAuthenticated: () {},
          onCancel: () {},
        ),
      ),
    );

    expect(find.text('Admin Portal Access'), findsOneWidget);
    expect(find.text('Sign In as Admin'), findsWidgets);
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('LoginScreen UI component test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          onLoginSuccess: () {},
          onOpenWebAdmin: () {},
        ),
      ),
    );

    expect(find.text('NOOR E SUNNAT'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('LoginScreen fits on standard mobile viewport without overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 2.0, 844 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          onLoginSuccess: () {},
          onOpenWebAdmin: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NOOR E SUNNAT'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('LoginScreen displays Log In button correctly in English and Urdu', (WidgetTester tester) async {
    await globalLanguageProvider.setLanguage('en');
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          onLoginSuccess: () {},
          onOpenWebAdmin: () {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Log In'), findsWidgets);

    await globalLanguageProvider.setLanguage('ur');
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          onLoginSuccess: () {},
          onOpenWebAdmin: () {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('لاگ ان کریں'), findsWidgets);
    expect(tester.takeException(), isNull);

    // Reset language to default Urdu
    await globalLanguageProvider.setLanguage('ur');
  });
}

