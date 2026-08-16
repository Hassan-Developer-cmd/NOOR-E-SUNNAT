import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/features/admin_panel/presentation/admin_login_screen.dart';
import 'package:islamic_app/features/auth/presentation/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    expect(find.text('Sign In as Admin'), findsOneWidget);
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

    expect(find.text('Faizan e Durood'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}

