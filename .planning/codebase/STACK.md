# Technology Stack

**Analysis Date:** 2026-09-09

## Languages

**Primary:**
- Dart `^3.12.2` - Entire client application logic, Flutter UI, models, utilities, services, and tests (`lib/`, `test/`).

**Secondary:**
- JavaScript / HTML / CSS - Flutter web shell and progressive web app bootstrap (`web/index.html`, `web/manifest.json`).
- XML / Gradle (Groovy/Kotlin) - Android native platform layer and build configuration (`android/app/build.gradle`, `android/build.gradle`).
- Swift / Objective-C - iOS native platform integration (`ios/Runner/`).

## Runtime

**Environment:**
- Flutter SDK (Channel stable) with Dart 3.x
- Target Runtimes: Android (API 21+), iOS (12.0+), Web (modern evergreen browsers: Chrome, Safari, Firefox, Edge), Windows, macOS.

**Package Manager:**
- `pub` (via `flutter pub`)
- Manifest: `pubspec.yaml`
- Lockfile: `pubspec.lock` (present and tracked)

## Frameworks

**Core:**
- Flutter Framework (`sdk: flutter`) - Cross-platform UI toolkit with Material 3 design and cupertino icon set (`pubspec.yaml`).
- `cloud_firestore: ^5.6.9` - NoSQL cloud database for real-time syncing and serverless data storage.
- `firebase_auth: ^5.7.0` - Authentication identity and session management.
- `firebase_core: ^3.15.2` - Firebase modular initialization and platform configuration.

**Testing:**
- `flutter_test` (`sdk: flutter`) - Unit, widget, and asynchronous state transition testing.

**Build/Dev:**
- `flutter_lints: ^6.0.0` - Static code analysis and linting rules (`analysis_options.yaml`).
- `FlutterFire CLI` - Firebase platform binding generator (`lib/firebase_options.dart`).

## Key Dependencies

**Critical:**
- `cloud_firestore` (`^5.6.9`) - Drives real-time counters, user progress, events, daily content, Q&A, and admin panel state.
- `firebase_auth` (`^5.7.0`) - User authentication via Email/Password and Google Sign-In (`lib/services/auth_service.dart`).
- `firebase_messaging` (`^15.2.4`) - Firebase Cloud Messaging (FCM) background/foreground push notification receiver (`lib/main.dart`).
- `flutter_local_notifications` (`^22.3.0`) - Heads-up native tray alerts, high importance notification channels, scheduled reminders (`lib/services/notification_service.dart`).
- `shared_preferences` (`^2.5.2`) - Fast offline disk persistence for personal Durood counters, active streaks, language preference, and terms acceptance (`lib/services/counter_service.dart`).

**Infrastructure & Utilities:**
- `google_sign_in` (`^6.3.0`) - OAuth2 Google identity provider flow for Android/iOS/Web.
- `googleapis_auth` (`^2.3.3`) - Service account OAuth2 Bearer token generation for FCM HTTP v1 REST endpoints (`lib/services/fcm_v1_service.dart`).
- `http` (`^1.2.1`) - HTTP client for cloud function triggers and external API interactions.
- `google_fonts` (`^6.2.1`) - Islamic calligraphy and multilingual typography (Inter for English, Noto Sans Arabic / Amiri for Urdu & Arabic) (`lib/core/constants/app_typography.dart`).
- `image_picker` (`^1.1.2`) - Gallery and camera photo selection for profiles, events, and questions (`lib/features/profile/presentation/profile_screen.dart`).
- `image` (`^4.9.2`) - Client-side image compression and encoding to Base64/JPEG before Firestore storage (`lib/core/utils/image_compression_helper.dart`).
- `share_plus` (`^10.1.4`) - Native system share sheet for sharing daily Hadith, Ayats, and Durood milestones.
- `url_launcher` (`^6.3.1`) - External hyperlink opening for community links and external references.

## Configuration

**Environment:**
- Firebase Options: Generated cross-platform configuration file (`lib/firebase_options.dart`) configuring Firebase Project `islamic-app-ed1ed`.
- Dynamic App Config: Firestore collection `app_config` holding runtime settings such as `fcm_v1_credentials` and Hijri calendar offsets.
- Local Storage: SharedPreferences keys for cached counters, date transition markers (`my_durood_YYYY-MM-DD`), and user preferences.

**Build:**
- `analysis_options.yaml` - Linter options extending `package:flutter_lints/flutter.yaml`.
- `android/app/build.gradle` - Android compileSdkVersion, minSdkVersion, targetSdkVersion, multidex, and Google Services plugin.
- `android/build.gradle` - Top-level Gradle repositories and classpath dependencies.
- `web/index.html` - Web PWA entry, viewport scaling, service worker bootstrap.

## Platform Requirements

**Development:**
- Flutter SDK 3.24+ / Dart SDK 3.5+
- Android Studio / Android SDK (Platform 34, Build-Tools 34.0.0)
- Google Chrome (for Web development & Web Admin Dashboard testing)
- Node.js (for GSD orchestrator tooling)

**Production:**
- Android: APK / AAB compiled for arm64-v8a, armeabi-v7a, x86_64; distributed via Google Play Store.
- Web: Responsive web deployment hosted via Firebase Hosting or web server; primarily serves Web Admin Dashboard (`_WebAdminEntryGate` in `lib/main.dart`).
- iOS: Planned iOS Runner release targeting iOS 12.0+.

---

*Stack analysis: 2026-09-09*
