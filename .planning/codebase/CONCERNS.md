# Codebase Concerns

**Analysis Date:** 2026-09-09

## Tech Debt

**Monolithic Web Admin Dashboard File:**
- Issue: `lib/features/admin_panel/presentation/admin_dashboard_web.dart` is 6,746 lines (~300 KB). It combines the overview dashboard, events management, Masail editor, Aqaid editor, daily content scheduling, push notification form, user roles, and Q&A management into a single file and stateful class.
- Files: `lib/features/admin_panel/presentation/admin_dashboard_web.dart`
- Impact: Increased cognitive load, higher risk of merge conflicts, slower IDE analysis, and difficulty in testing individual admin sections in isolation.
- Fix approach: Extract each of the 10 navigation tabs into standalone widgets under `lib/features/admin_panel/presentation/widgets/` (following the pattern established by `campaign_popup_admin_tab.dart`).

**Legacy Firestore Schema Variations:**
- Issue: Historic user records contain polymorphic field names for Durood counts and points (e.g., `myTotal`, `totalCount`, `duroodCount`, `total_count`, `personal_total_durood`, `totalDurood`, `totalPoints`, `duroodPoints`, `points`).
- Files: `lib/core/models/app_user.dart`
- Impact: `AppUser.fromMap` requires defensive fallback loops scanning 6–7 keys per property.
- Fix approach: Execute a one-time administrative Firestore migration script to canonicalize all user documents to standard snake_case keys (`personal_total_durood`, `personal_today_durood`, `total_durood_points`, `current_streak`).

**Notification Architecture Split:**
- Issue: Notification logic is split between `lib/services/notification_service.dart` (local notifications, foreground listener) and `lib/services/fcm_v1_service.dart` (service account auth, HTTP v1 API dispatch, Cloud Function proxy).
- Files: `lib/services/notification_service.dart`, `lib/services/fcm_v1_service.dart`
- Impact: Blurred boundary between client notification display and administrative broadcast dispatch.
- Fix approach: Formally separate client-side notification presentation from admin-side dispatch mechanisms.

## Known Bugs

- None currently unresolved in test suite. Recent fixes have resolved Masail/Aqaid order index synchronization and web admin desynchronization (`test/web_admin_desync_fix_test.dart`, `test/masail_aqaid_reorder_test.dart`).

## Security Considerations

**Hardcoded Service Account Fallback Key:**
- Risk: `lib/services/fcm_v1_service.dart` contains a hardcoded fallback Google Cloud service account private key (`_embeddedServiceAccount`).
- Files: `lib/services/fcm_v1_service.dart`
- Current mitigation: The service prioritizes credentials stored in Firestore `app_config/fcm_v1_credentials` or local `service-account.json`.
- Recommendations: Completely remove the hardcoded private key from client source code. All FCM v1 notification dispatch should be proxied through an authenticated Cloud Function verifying the caller's Firebase Auth ID token and admin claims.

**Client-Side Admin Role Verification:**
- Risk: Administrative privileges are checked in Flutter code (`user?.isAdmin ?? false` in `AdminService.isAdmin()`).
- Files: `lib/services/admin_service.dart`, `lib/features/admin_panel/presentation/admin_login_screen.dart`
- Current mitigation: UI gates unauthorized access to `AdminDashboardWeb`.
- Recommendations: Ensure Firestore Security Rules (`firestore.rules`) enforce `request.auth.token.admin == true` on write operations to `events`, `daily_content`, `aqaid`, `masail`, and `app_config` so direct client API requests cannot bypass UI controls.

## Performance Bottlenecks

**Base64 Encoded Images in Firestore Documents:**
- Problem: Profile images, event banners, and campaign popups are compressed and stored as Base64 strings directly in Firestore documents.
- Files: `lib/core/utils/image_compression_helper.dart`, `lib/core/models/event_model.dart`, `lib/core/models/app_user.dart`
- Cause: Designed to avoid Firebase Storage billing/rules overhead by embedding data into Firestore records.
- Improvement path: Although `ImageCompressionHelper` enforces < 200–400KB limits, high-resolution document embeds increase Firestore document payload size and bandwidth costs. Migrate image uploads to Cloud Storage (or Cloudflare R2) and store clean HTTPS URLs in Firestore.

**Single Document Global Counter Contention:**
- Problem: All user counter increments aggregate into `global_counter/totals`.
- Files: `lib/services/counter_service.dart`
- Cause: Cloud Firestore limits writes to an individual document to approximately 1 write per second.
- Improvement path: While `CounterService` buffers taps client-side (1.5-second debounce), thousands of concurrent active users tapping during events could exceed the single-document write throughput limit. Implement distributed counter sharding (e.g. 10–20 shards in `global_counter/totals/shards`) with a periodic aggregator.

## Fragile Areas

**Midnight Date Transition & Daily Reset:**
- Files: `lib/services/counter_service.dart`, `lib/core/utils/streak_helper.dart`
- Why fragile: Date transition calculations depend on the user's local device clock (`DateTime.now()`). Users with incorrect device dates or timezone shifts across midnight could experience premature or delayed daily resets.
- Safe modification: All modifications to date formatting must use `StreakHelper.toCalendarDateString()` and be validated against `test/counter_persistence_test.dart`.
- Test coverage: Comprehensive unit tests in `test/counter_persistence_test.dart` and `test/counter_monotonic_rapid_tap_test.dart`.

**Web Admin Drag-and-Drop Reordering:**
- Files: `lib/features/admin_panel/presentation/admin_dashboard_web.dart`, `lib/services/admin_service.dart`
- Why fragile: Rapid drag reordering updates 1-indexed order fields across entire Firestore collections via batch writes. Any desync between in-memory state and Firestore snapshots can cause item jumping.
- Safe modification: Always verify with `test/masail_aqaid_reorder_test.dart` and `test/web_admin_desync_fix_test.dart`.

## Scaling Limits

**Global Counter Document Throughput:**
- Current capacity: Debounced client updates allow thousands of casual users; sustained simultaneous tapping peak capacity is capped at ~50–100 writes/sec to the single document before Firestore contention errors occur.
- Limit: 1 write per second per document sustained.
- Scaling path: Introduce Firestore Distributed Counters pattern.

**Base64 In-Document Storage:**
- Current capacity: Capped at 1 MB per Firestore document.
- Limit: Heavy images or rich descriptions approaching 1MB will fail Firestore document size validations.
- Scaling path: Enforce Cloud Storage URL references.

## Dependencies at Risk

- `googleapis_auth: ^2.3.3` & `http: ^1.2.1`: Used in Flutter Web to mint OAuth tokens for FCM. Web cross-origin resource sharing (CORS) rules on Google APIs require proxying through Cloud Functions.
- `flutter_local_notifications: ^22.3.0`: Android 13+ runtime notification permissions (`POST_NOTIFICATIONS`) and iOS APNs permissions require strict platform manifest alignment.

## Missing Critical Features

- Automated Crash Reporting / APM: No Firebase Crashlytics or Sentry integration for real-time production exception tracking.
- Automated Cloud Backups: No scheduled cloud export configured for Firestore data safeguarding.

## Test Coverage Gaps

**Untested Areas:**
- `lib/features/profile/presentation/widgets/terms_and_conditions_sheet.dart`: Modal rendering and scrolling behavior.
- `lib/services/fcm_v1_service.dart`: Live Google OAuth2 token handshake against Google OAuth endpoint (mocked in test suite).
- Priority: Medium.

---

*Concerns audit: 2026-09-09*
