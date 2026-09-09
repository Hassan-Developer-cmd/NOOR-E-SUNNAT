# Codebase Structure

**Analysis Date:** 2026-09-09

## Directory Layout

```
islamic_app/
├── android/                 # Android native project & Gradle build configuration
├── assets/                  # Static application assets
│   ├── icons/               # App icons and vector symbols
│   ├── images/              # Illustration graphics and backgrounds
│   └── images/team/         # Team and scholar avatar assets
├── ios/                     # iOS native project & Xcode configuration
├── lib/                     # Main Dart application source code
│   ├── core/                # Shared foundational utilities, constants, models, widgets
│   │   ├── constants/       # App colors, theme definitions, typography
│   │   ├── localization/    # Multilingual translation dictionaries (EN/UR)
│   │   ├── models/          # Strongly typed domain entities & serialization
│   │   ├── providers/       # State notifiers (e.g., LanguageProvider)
│   │   ├── services/        # Low-level core helper services (e.g., Email OTP)
│   │   ├── utils/           # Date calculations, streaks, compression, seeding
│   │   └── widgets/         # Cross-feature reusable dialogs, avatars, buttons
│   ├── features/            # Feature-first application modules
│   │   ├── admin_panel/     # Web administrative console and login screens
│   │   ├── auth/            # Mobile login, registration, and credential flows
│   │   ├── counter/         # Durood counter screen, buttons, stat cards, chips
│   │   ├── events/          # Event lists, status badges, details
│   │   ├── home/            # Home dashboard, quick counter, daily content cards
│   │   ├── knowledge_hub/   # Islamic knowledge, Aqaid, Masail, Q&A screens
│   │   ├── profile/         # User profile, history, settings, photo upload
│   │   └── splash/          # Animated branded splash screen
│   ├── presentation/        # App-wide global presentation widgets
│   │   └── widgets/         # Shared global widgets
│   ├── services/            # Top-level application services (Auth, Counter, Admin, FCM)
│   ├── firebase_options.dart # Generated FlutterFire cross-platform options
│   └── main.dart            # Application entry point, routing, and shell lifecycle
├── test/                    # Unit, widget, and state regression test suite
├── web/                     # Web deployment entry, manifest, and icons
├── pubspec.yaml             # Dart dependencies and asset manifests
└── analysis_options.yaml    # Static analysis and linting configuration
```

## Directory Purposes

**`lib/core/`:**
- Purpose: Foundational shared code utilized across multiple features.
- Contains: Constants, data models, typography definitions, date and streak helpers, common modals.
- Key files: `lib/core/constants/app_colors.dart`, `lib/core/constants/app_typography.dart`, `lib/core/constants/app_theme.dart`, `lib/core/localization/app_translations.dart`, `lib/core/models/app_user.dart`.

**`lib/features/`:**
- Purpose: Self-contained feature domains encapsulating UI presentation and business logic.
- Contains: Feature screens, sub-widgets, and feature-specific state management.
- Key directories: `lib/features/home/`, `lib/features/counter/`, `lib/features/knowledge_hub/`, `lib/features/admin_panel/`.

**`lib/services/`:**
- Purpose: Application-level business services connecting UI components to Firestore, Auth, Push Notifications, and local storage.
- Contains: Singleton service classes and background task coordinators.
- Key files: `lib/services/counter_service.dart`, `lib/services/auth_service.dart`, `lib/services/admin_service.dart`, `lib/services/fcm_v1_service.dart`.

**`test/`:**
- Purpose: Automated regression, unit, and widget tests ensuring offline persistence, UI layout sanity, and auth flows.
- Contains: 23 standalone Dart test suites using `flutter_test`.
- Key files: `test/counter_persistence_test.dart`, `test/web_admin_desync_fix_test.dart`, `test/app_exit_confirmation_dialog_test.dart`.

## Key File Locations

**Entry Points:**
- `lib/main.dart`: Mobile/Web application startup, Firestore settings, non-blocking background initialization, top-level shell.

**Configuration:**
- `pubspec.yaml`: Dependencies, assets, and project versioning.
- `lib/firebase_options.dart`: Multi-platform Firebase credentials and project bindings.
- `analysis_options.yaml`: Dart analyzer rules and linter activation.

**Core Logic:**
- `lib/services/counter_service.dart`: Tap debouncing, local storage synchronization, monotonic counter integrity.
- `lib/services/auth_service.dart`: Authentication state streams, Google credential exchange, session caching.
- `lib/core/utils/streak_helper.dart`: Daily activity calculation and streak maintenance algorithms.
- `lib/core/utils/islamic_date_helper.dart`: Hijri calendar formatting and offset calculations.

**Testing:**
- `test/counter_persistence_test.dart`: Counter disk serialization and midnight auto-reset test coverage.
- `test/web_admin_desync_fix_test.dart`: Administrative state sync validation.

## Naming Conventions

**Files:**
- Lowercase snake_case: `app_colors.dart`, `counter_screen.dart`, `admin_dashboard_web.dart`.
- Test files suffix with `_test.dart`: `counter_persistence_test.dart`.

**Directories:**
- Lowercase snake_case: `knowledge_hub/`, `admin_panel/`.

**Classes & Enums:**
- UpperCamelCase: `CounterService`, `AppUser`, `EventModel`, `MainShell`.

**Variables & Functions:**
- lowerCamelCase: `globalTotal`, `incrementPersonal()`, `resolveCurrentUser()`.
- Private members prefix with underscore: `_prefs`, `_snapshot`, `_isDisposed`.

## Where to Add New Code

**New Feature:**
- Create directory under `lib/features/<feature_name>/`
- Structure:
  - `lib/features/<feature_name>/presentation/<feature_name>_screen.dart`
  - `lib/features/<feature_name>/presentation/widgets/` (for modular subcomponents)
- If applicable, register tab in `MainShell` (`lib/main.dart`) or route table.
- Add companion tests in `test/<feature_name>_test.dart`.

**New Data Model:**
- Add model file to `lib/core/models/<model_name>_model.dart`.
- Include strongly typed properties, `fromMap(String id, Map<String, dynamic> map)`, and `toMap()` methods.
- Ensure numeric fields use defensive parsing (e.g. `AppUser.parseNumeric`).

**New Utility or Helper:**
- Place pure helper functions or algorithms in `lib/core/utils/<utility_name>_helper.dart`.
- Ensure utility has zero UI dependencies and is independently unit testable.

**New Shared Widget / Dialog:**
- Reusable modals and UI components belong in `lib/core/widgets/<widget_name>.dart`.

## Special Directories

**`assets/images/team/`:**
- Contains team member and scholar portraits referenced in the "About Us" / team credits. Committed to source control.

**`.planning/`:**
- GSD planning, milestone tracking, and codebase intelligence documentation. Committed to repository.

**`build/`:**
- Flutter compilation output directory. Ignored by git (`.gitignore`).

---

*Structure analysis: 2026-09-09*
