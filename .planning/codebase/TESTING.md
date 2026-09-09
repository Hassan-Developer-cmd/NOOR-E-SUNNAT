# Testing Patterns

**Analysis Date:** 2026-09-09

## Test Framework

**Runner:**
- `flutter_test` (Flutter SDK)
- Config: Configured via `pubspec.yaml` under `dev_dependencies`

**Assertion Library:**
- `package:flutter_test/flutter_test.dart` assertions and matchers (`expect()`, `findsOneWidget`, `findsNothing`, `isTrue`, `isFalse`, `equals`)

**Run Commands:**
```bash
flutter test                                   # Run all automated test suites
flutter test test/counter_persistence_test.dart # Run specific test suite
flutter test --coverage                        # Run tests with LCOV coverage report
```

## Test File Organization

**Location:**
- Separate top-level `test/` directory located at repository root.
- 23 test files covering units, utilities, state persistence, and widget rendering.

**Naming:**
- Matches target feature or utility with `_test.dart` suffix:
  - `test/counter_persistence_test.dart`
  - `test/counter_monotonic_rapid_tap_test.dart`
  - `test/web_admin_desync_fix_test.dart`
  - `test/hijri_date_test.dart`
  - `test/image_compression_helper_test.dart`
  - `test/app_exit_confirmation_dialog_test.dart`

**Structure:**
```
test/
├── app_exit_confirmation_dialog_test.dart
├── campaign_popup_test.dart
├── counter_monotonic_rapid_tap_test.dart
├── counter_persistence_test.dart
├── dialog_rebuild_guard_test.dart
├── durood_summary_card_test.dart
├── event_image_upload_test.dart
├── fcm_v1_test.dart
├── hijri_date_test.dart
├── home_screen_viewport_fold_test.dart
├── image_compression_helper_test.dart
├── masail_aqaid_reorder_test.dart
├── notifications_test.dart
├── number_formatter_test.dart
├── page_view_swipe_navigation_test.dart
├── profile_image_picker_test.dart
├── profile_settings_tab_test.dart
├── team_images_test.dart
├── terms_acceptance_test.dart
├── test_email_apis.dart
├── ui_layout_fixes_test.dart
├── web_admin_desync_fix_test.dart
└── widget_test.dart
```

## Test Structure

**Suite Organization:**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:islamic_app/services/counter_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Counter Persistence & Date Transition Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Persists count across simulated app restart', () async {
      final prefs = await SharedPreferences.getInstance();
      const countAdded = 15;
      await prefs.setInt('cached_personal_total', countAdded);

      final reloadedPrefs = await SharedPreferences.getInstance();
      expect(reloadedPrefs.getInt('cached_personal_total'), equals(countAdded));
    });
  });
}
```

## Mocking

**Platform Channels & Shared Preferences:**
- Standard Flutter Test mock harnesses are utilized for platform channels and disk caching:
  - `SharedPreferences.setMockInitialValues({...})` for injecting mock local disk states without native platform dependencies.
  - `TestWidgetsFlutterBinding.ensureInitialized()` for headless widget testing.

**What to Mock:**
- Local persistent key-value store (`SharedPreferences`).
- Firebase platform bindings during pure unit tests.
- Camera and native photo gallery pickers (`image_picker`).

**What NOT to Mock:**
- Business models and JSON serialization logic (`AppUser.fromMap`, `DailyContentModel.fromMap`).
- Date calculation math and Hijri algorithms (`IslamicDateHelper`, `StreakHelper`).
- Image compression and byte calculation algorithms (`ImageCompressionHelper`).

## Fixtures and Factories

**Test Data:**
- Direct in-code Map fixtures simulating Firestore document snapshots:
```dart
final testUserMap = {
  'user_id': 'test_uid_123',
  'email': 'user@example.com',
  'username': 'Test User',
  'personal_total_durood': 100,
  'current_streak': 5,
  'is_admin': false,
};
final user = AppUser.fromMap(testUserMap);
```

## Coverage

**Requirements:**
- High coverage enforced across core user flows:
  - Durood counter monotonic rapid tapping & midnight auto-reset.
  - Offline SharedPreferences persistence and recovery.
  - Hijri date calculations with dynamic offset calibration.
  - Web Admin state synchronization and event reordering.

## Test Types

**Unit Tests:**
- Validate algorithmic correctness, pure helper calculations (`StreakHelper`, `IslamicDateHelper`, `NumberFormatter`), and model serialization.

**Widget Tests:**
- Verify UI rendering, modal dialogs (`AppExitConfirmationDialog`, `TermsAcceptanceDialog`), gesture interactions, and multi-language RTL layout behavior using `tester.pumpWidget()` and `tester.tap()`.

**State Transition & Regression Tests:**
- Validate system edge cases like rapid consecutive tapping (`counter_monotonic_rapid_tap_test.dart`) and web admin desynchronization guards (`web_admin_desync_fix_test.dart`).

## Common Patterns

**Simulating Time and Midnight Transitions:**
```dart
test('Midnight Auto-Reset: Resets My Today to 0 when date actually changes', () async {
  final prefs = await SharedPreferences.getInstance();
  const yesterdayStr = '2026-09-08';
  final todayStr = '2026-09-09';

  await prefs.setInt('my_durood_$yesterdayStr', 50);
  await prefs.setString('my_durood_date', yesterdayStr);

  final storedDate = prefs.getString('my_durood_date');
  final int myToday = (storedDate != null && storedDate != todayStr) ? 0 : 50;
  expect(myToday, equals(0));
});
```

**Widget Pump with Localizations:**
```dart
testWidgets('Renders properly in English and handles Cancel button', (WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: AppExitConfirmationDialog(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.text('Exit App'), findsOneWidget);
});
```

---

*Testing analysis: 2026-09-09*
