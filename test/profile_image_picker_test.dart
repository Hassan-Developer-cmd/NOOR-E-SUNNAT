import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:islamic_app/core/localization/app_translations.dart';
import 'package:islamic_app/core/models/app_user.dart';
import 'package:islamic_app/core/widgets/user_avatar.dart';
import 'package:islamic_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await globalLanguageProvider.init();
  });

  // 1x1 transparent PNG Base64 for testing
  const validBase64Image =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

  group('AppUser Profile Image Model Tests', () {
    test('AppUser parses profileImageBase64 from map', () {
      final user = AppUser.fromMap({
        'user_id': 'u123',
        'email': 'ali@example.com',
        'username': 'Ali Raza',
        'profileImageBase64': validBase64Image,
      });

      expect(user.userId, equals('u123'));
      expect(user.username, equals('Ali Raza'));
      expect(user.profileImageBase64, equals(validBase64Image));
    });

    test('AppUser parses profile_image_base64 fallback from map', () {
      final user = AppUser.fromMap({
        'user_id': 'u124',
        'email': 'ahmed@example.com',
        'username': 'Ahmed',
        'profile_image_base64': validBase64Image,
      });

      expect(user.profileImageBase64, equals(validBase64Image));
    });

    test('AppUser toMap includes profileImageBase64 when present', () {
      const user = AppUser(
        userId: 'u125',
        email: 'test@example.com',
        username: 'Test User',
        photoUrl: '',
        profileImageBase64: validBase64Image,
      );

      final map = user.toMap();
      expect(map['profileImageBase64'], equals(validBase64Image));
    });
  });

  group('Profile Picture Translations Tests', () {
    test('English translations contain photo picker keys', () {
      expect(AppTranslations.get('profile_picture_title', 'en'), equals('Profile Picture'));
      expect(AppTranslations.get('take_photo', 'en'), equals('Take Photo'));
      expect(AppTranslations.get('choose_from_gallery', 'en'), equals('Choose from Gallery'));
      expect(AppTranslations.get('photo_updated_success', 'en'), contains('successfully'));
      expect(AppTranslations.get('photo_update_failed', 'en'), contains('Failed'));
    });

    test('Urdu translations contain photo picker keys', () {
      expect(AppTranslations.get('profile_picture_title', 'ur'), equals('پروفائل تصویر'));
      expect(AppTranslations.get('take_photo', 'ur'), equals('کیمرہ سے تصویر لیں'));
      expect(AppTranslations.get('choose_from_gallery', 'ur'), equals('گیلری سے منتخب کریں'));
      expect(AppTranslations.get('photo_updated_success', 'ur'), contains('کامیابی'));
      expect(AppTranslations.get('photo_update_failed', 'ur'), contains('ناکامی'));
    });
  });

  group('UserAvatar Widget Tests', () {
    testWidgets('Renders initial letter when no image is provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              radius: 36,
              displayName: 'Hassan',
            ),
          ),
        ),
      );

      expect(find.text('H'), findsOneWidget);
    });

    testWidgets('Renders decoded Base64 image when profileImageBase64 is provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              radius: 36,
              profileImageBase64: validBase64Image,
              displayName: 'Hassan',
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('H'), findsNothing);
    });

    testWidgets('Handles corrupted Base64 gracefully without crash and shows fallback initial',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              radius: 36,
              profileImageBase64: r'INVALID_BASE64_NOT_AN_IMAGE!@#$',
              displayName: 'Usman',
            ),
          ),
        ),
      );

      expect(find.text('U'), findsOneWidget);
    });

    testWidgets('Renders edit button and triggers callback on tap', (tester) async {
      bool editTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              radius: 36,
              displayName: 'Bilal',
              showEditButton: true,
              onEditPressed: () {
                editTapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.camera_alt_rounded));
      await tester.pump();

      expect(editTapped, isTrue);
    });

    testWidgets('Renders loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              radius: 36,
              displayName: 'Hamza',
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
