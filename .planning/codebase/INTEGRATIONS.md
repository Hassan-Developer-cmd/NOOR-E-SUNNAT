# External Integrations

**Analysis Date:** 2026-09-09

## APIs & External Services

**Firebase Cloud Messaging (FCM v1 API):**
- Purpose: Broadcast push notifications, daily reminders, and question answer alerts to users.
  - Client SDK: `firebase_messaging` (`^15.2.4`) in `lib/main.dart` and `lib/services/notification_service.dart`.
  - Server / Admin Dispatch: Direct HTTP v1 REST endpoint `https://fcm.googleapis.com/v1/projects/islamic-app-ed1ed/messages:send` managed by `FcmV1Service` in `lib/services/fcm_v1_service.dart`.
  - Auth: Service Account OAuth2 credentials via `googleapis_auth` (`^2.3.3`) generating short-lived Bearer tokens.
  - Topics: Global broadcast topic `all_users` subscribed on startup in `_initMobileMessaging` (`lib/main.dart`).

**Google Cloud Functions Proxy:**
- Purpose: Fallback HTTP broadcast trigger for web admin panel when direct REST API is subject to CORS or network barriers.
  - Endpoint: `https://us-central1-islamic-app-ed1ed.cloudfunctions.net/sendFCMBroadcastHttp` in `lib/services/fcm_v1_service.dart`.

**Google Identity & Sign-In:**
- Purpose: One-tap Google authentication on Android, iOS, and Web.
  - Client SDK: `google_sign_in` (`^6.3.0`) in `lib/services/auth_service.dart`.
  - Auth: Google OAuth2 clientId configured in `lib/firebase_options.dart` and `android/app/google-services.json`.

**System Share & Launch Services:**
- Purpose: Sharing Islamic content, Hadith quotes, and opening external URLs.
  - Client SDKs: `share_plus` (`^10.1.4`), `url_launcher` (`^6.3.1`).

## Data Storage

**Databases:**
- Google Cloud Firestore (Multi-region Serverless NoSQL):
  - Configuration: `DefaultFirebaseOptions` in `lib/firebase_options.dart`.
  - Offline Persistence: Enabled via `Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED)` in `lib/main.dart`.
  - Client: `cloud_firestore` (`^5.6.9`).
  - Key Collections:
    - `users` — App user documents indexed by Auth UID (`lib/core/models/app_user.dart`).
    - `global_counter` — Aggregated community Durood counts (`totals`, `main`) (`lib/services/counter_service.dart`).
    - `daily_content` — Daily Hadith, Quranic Ayats, Topic of the Day (`lib/core/models/daily_content_model.dart`).
    - `events` — Islamic milestones, conferences, and campaigns (`lib/core/models/event_model.dart`).
    - `questions` — Community Q&A submissions, status tracking, answers (`lib/core/models/question_model.dart`).
    - `masail` — Jurisprudential (Fiqh) guidance categorized with custom order indexing (`lib/core/models/masail_model.dart`).
    - `aqaid` — Islamic belief and doctrine library with order indexing (`lib/core/models/aqaid_model.dart`).
    - `campaign_popups` — In-app modal alert broadcasts with scheduling flags (`lib/core/models/campaign_popup_model.dart`).
    - `app_config` — Dynamic application settings, Hijri date calibration, and FCM credentials.

**File & Image Storage:**
- Client-Side Compressed Base64 Storage:
  - Images for profile avatars, event banners, and campaign popups are compressed client-side to target byte budgets (< 400KB) via `ImageCompressionHelper` (`lib/core/utils/image_compression_helper.dart`) using the `image` (`^4.9.2`) package, then stored directly as Base64 strings in Firestore documents to bypass Firebase Storage billing constraints.
- Firebase Storage Bucket:
  - Bucket reference `islamic-app-ed1ed.firebasestorage.app` configured in `lib/firebase_options.dart`.

**Caching:**
- Local Shared Preferences (`shared_preferences` `^2.5.2`):
  - `my_today_${uid}_${date}` — User's daily Durood count isolated per user and calendar date (`lib/services/counter_service.dart`).
  - `cached_personal_total`, `cached_global_total`, `cached_current_streak` — Instant zero-latency cold start UI hydration.
  - `selected_language` — User's chosen locale (`en` vs `ur`) in `lib/core/providers/language_provider.dart`.
  - `has_accepted_terms` — Offline terms & conditions acceptance guard in `lib/services/terms_acceptance_service.dart`.

## Authentication & Identity

**Auth Provider:**
- Firebase Authentication (`firebase_auth` `^5.7.0`):
  - Methods: Email/Password login & signup, Google Sign-In OAuth2 credential exchange (`lib/services/auth_service.dart`).
  - Session Persistence: Handled natively by Firebase Auth with additional SharedPreferences backup flags (`auth_session_active`, `auth_session_uid`).
  - Admin Authorization: Role-based access control checking `is_admin == true` in the user's Firestore document (`lib/services/admin_service.dart`).
  - Web Entry Gate: Enforces clean sign-out on web launch and requires admin credentials to access `AdminDashboardWeb` (`lib/main.dart`).

## Monitoring & Observability

**Error Tracking:**
- Local console logging with `kDebugMode` guards throughout `lib/services/` and `lib/core/`.
- No external third-party error monitoring APM (e.g. Sentry, Firebase Crashlytics) is currently wired.

**Logs:**
- Dart standard output (`print`) wrapped in `if (kDebugMode)` checks to eliminate debug output in production release builds.

## CI/CD & Deployment

**Hosting:**
- Web: Firebase Hosting or static web server hosting Flutter Web build artifacts (`build/web/`).
- Mobile: Google Play Store distribution for Android.

**CI Pipeline:**
- Local build and test runner (`flutter test`, `flutter analyze`).

## Environment Configuration

**Required Configurations:**
- `lib/firebase_options.dart`: Project configurations for web, android, ios, macos, and windows targets.
- `android/app/google-services.json`: Native Android Firebase configuration.
- Service Account Credentials: Stored dynamically in Firestore collection `app_config/fcm_v1_credentials` or loaded via `service-account.json`.

**Secrets Location:**
- Firebase client public API keys reside in `lib/firebase_options.dart`.
- Service account private keys are configured to load dynamically from Firestore `app_config` with an embedded fallback in `lib/services/fcm_v1_service.dart`.

## Webhooks & Callbacks

**Incoming:**
- FCM Background Message Handler: Native Android/iOS background handler annotated with `@pragma('vm:entry-point')` in `lib/main.dart` (`_firebaseMessagingBackgroundHandler`).
- Local Notification Tap Callbacks: Configured in `NotificationService.initialize()` in `lib/services/notification_service.dart`.

**Outgoing:**
- FCM Send Requests: Dispatched via HTTPS POST to `https://fcm.googleapis.com/v1/projects/islamic-app-ed1ed/messages:send` when admins publish events or announce notifications.

---

*Integration audit: 2026-09-09*
