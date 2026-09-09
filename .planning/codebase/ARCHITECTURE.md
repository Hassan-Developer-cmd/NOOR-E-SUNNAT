<!-- refreshed: 2026-09-09 -->
# Architecture

**Analysis Date:** 2026-09-09

## System Overview

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        Presentation & Navigation                       │
├───────────────────┬──────────────────┬─────────────────┬───────────────┤
│    MainShell      │  HomeScreen /    │  KnowledgeHub   │  Web Admin    │
│  (Bottom Nav Bar) │  CounterScreen   │  (Aqaid/Masail) │  Dashboard    │
│  `lib/main.dart`  │  `lib/features/` │ `lib/features/` │`lib/features/`│
└────────┬──────────┴────────┬─────────┴────────┬────────┴───────┬───────┘
         │                   │                  │                │
         ▼                   ▼                  ▼                ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        Services & Business Logic                       │
├───────────────────┬──────────────────┬─────────────────┬───────────────┤
│  CounterService   │   AuthService    │  AdminService   │  FcmV1Service │
│  (Sync & Cache)   │ (Firebase/Google)│  (Admin Ops)    │ (FCM REST v1) │
│  `lib/services/`  │ `lib/services/`  │ `lib/services/` │`lib/services/`│
└────────┬──────────┴────────┬─────────┴────────┬────────┴───────┬───────┘
         │                   │                  │                │
         ▼                   ▼                  ▼                ▼
┌────────────────────────────────────────────────────────────────────────┐
│                           Core Foundation                              │
├───────────────────┬──────────────────┬─────────────────┬───────────────┤
│  Models & DTOs    │ Localization &   │ Theme & Colors  │ Utils/Helpers │
│  `lib/core/`      │ Provider (RTL)   │ `lib/core/`     │ `lib/core/`   │
└────────┬──────────┴────────┬─────────┴────────┬────────┴───────┬───────┘
         │                   │                  │                │
         ▼                   ▼                  ▼                ▼
┌────────────────────────────────────────────────────────────────────────┐
│                     External & Storage Infrastructure                  │
├───────────────────────────────┬────────────────────────────────────────┤
│     Cloud Firestore           │      SharedPreferences                 │
│  (Real-time NoSQL Documents)  │  (Zero-latency local disk key-value)   │
└───────────────────────────────┴────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| `NoorESunnatApp` | App root with theme, dynamic RTL/LTR directionality, and platform routing gate | `lib/main.dart` |
| `_WebAdminEntryGate` | Web-only access controller requiring Firebase Admin authentication before showing dashboard | `lib/main.dart` |
| `AuthWrapper` | Reactive auth state router handling splash completion and persistent mobile login sessions | `lib/main.dart` |
| `MainShell` | 5-tab persistent bottom navigation container (`HomeScreen`, `Aqaid`, `Masail`, `Q&A`, `Profile`) | `lib/main.dart` |
| `CounterService` | High-frequency tap debounce buffering, monotonic counting, local storage hydration, Firestore sync | `lib/services/counter_service.dart` |
| `AuthService` | Identity resolution, Google Sign-In, user document provisioning, session persistence | `lib/services/auth_service.dart` |
| `AdminService` | Administrative CRUD, content reordering, role checking, database seeding | `lib/services/admin_service.dart` |
| `FcmV1Service` | OAuth2 service account authorization and FCM HTTP v1 notification dispatch | `lib/services/fcm_v1_service.dart` |
| `NotificationService` | Local heads-up notifications, channel management, foreground FCM handling | `lib/services/notification_service.dart` |
| `LanguageProvider` | Multi-language state (`en` vs `ur`), RTL text direction, SharedPreferences sync | `lib/core/providers/language_provider.dart` |
| `AdminDashboardWeb` | Comprehensive 10-tab administrative management web console | `lib/features/admin_panel/presentation/admin_dashboard_web.dart` |

## Architecture Pattern

**Layered Feature-First Architecture:**
- **Core Layer (`lib/core/`):** Shared foundational models (`AppUser`, `EventModel`, `DailyContentModel`), styling (`AppColors`, `AppTypography`, `AppTheme`), localization (`AppTranslations`, `LanguageProvider`), and utilities (`StreakHelper`, `IslamicDateHelper`, `ImageCompressionHelper`).
- **Service Layer (`lib/services/`):** Encapsulated singletons and static facades managing I/O, business rules, debouncing, and cloud interactions.
- **Feature Layer (`lib/features/`):** Domain-specific feature modules containing `presentation/` screens and widgets (`home`, `counter`, `knowledge_hub`, `events`, `profile`, `auth`, `admin_panel`, `splash`).
- **State Management:** Reactive hybrid pattern combining `ChangeNotifier` (`CounterService`, `LanguageProvider`), `StreamBuilder` for Firestore collections, and `ValueListenableBuilder` / `StatefulWidget` for local widget state.

## Data Flow

**Counter & Tap Pipeline:**
1. **User Interaction:** User taps the counter button on `HomeScreen` or `CounterScreen`.
2. **Optimistic Local Update:** `CounterService.incrementPersonal()` updates the local in-memory `CounterSnapshot` instantly and notifies listeners without network delay.
3. **Local Disk Persistence:** Immediately written to SharedPreferences key `my_today_${uid}_${date}` and `cached_personal_total`.
4. **Debounced Network Sync:** A 1.5-second debounce buffer accumulates rapid taps. Once settled or upon application lifecycle state change (`paused`/`detached`), increments are committed to Firestore:
   - `global_counter/totals` updated via `FieldValue.increment(delta)`.
   - User doc `users/{uid}` updated via `FieldValue.increment(delta)` alongside streak checks.
5. **Real-Time Convergence:** Firestore snapshots stream aggregated global totals and leaderboard updates back to subscribed UI listeners.

## Key Abstractions

**`CounterSnapshot`:**
- Purpose: Immutable value object representing current counters (global total, global today, personal total, personal today, streak, durood points).
- Location: `lib/services/counter_service.dart`
- Pattern: Immutable snapshot with `copyWith`.

**`AppUser`:**
- Purpose: Strongly-typed entity representing authenticated users with defensive numeric parsing accommodating varied legacy Firestore schemas.
- Location: `lib/core/models/app_user.dart`
- Pattern: Factory constructor `AppUser.fromMap` with dynamic key fallbacks.

**`LanguageProvider`:**
- Purpose: App-wide reactive localization notifier controlling current locale and RTL text direction.
- Location: `lib/core/providers/language_provider.dart`
- Pattern: `ChangeNotifier` bound to top-level `MaterialApp`.

## Entry Points

**`main()`:**
- Location: `lib/main.dart`
- Triggers: Native app launch (Android, iOS, Web, Desktop).
- Responsibilities: Ensures Flutter binding, locks portrait orientation, initializes Firebase, enables Firestore offline cache, hydrates `LanguageProvider` and `CounterService` from storage, and launches `NoorESunnatApp`.

**`_firebaseMessagingBackgroundHandler()`:**
- Location: `lib/main.dart`
- Triggers: Native OS background FCM push event when application is terminated or backgrounded.
- Responsibilities: Initializes background Firebase instance, catches data-only payloads, and posts high-priority local tray alerts.

**`_WebAdminEntryGate`:**
- Location: `lib/main.dart`
- Triggers: Opening application on Web browser (`kIsWeb == true`).
- Responsibilities: Prevents normal user app access on web, clears stale sessions, and enforces admin authentication before loading `AdminDashboardWeb`.

## Architectural Constraints

- **Threading:** Single-threaded Dart event loop; heavy image processing is handled synchronously or via lightweight helper routines; background notifications run in a dedicated isolate (`_firebaseMessagingBackgroundHandler`).
- **Global State:** Singleton service instances (`CounterService`, `LanguageProvider`, `AuthService`) maintain long-lived in-memory caches.
- **Offline First:** All counter interactions must function seamlessly with no network connection, persisting to local disk and reconciling with Firestore on reconnect.
- **Bi-Directional Layout:** Must support Left-to-Right (LTR) for English and Right-to-Left (RTL) for Urdu seamlessly across all screens.

## Anti-Patterns

### Blocking App Startup on Network Round-Trips

**What happens:** Calling awaiting network calls (e.g. Firestore queries or remote configs) inside `main()` before `runApp()`.
**Why it's wrong:** Causes slow cold starts, blank white screens, or crash on spotty cellular connections.
**Do this instead:** Hydrate instant local cache first via `SharedPreferences`, call `runApp()`, and run network fetches in `_initNonBlockingServices()` (`lib/main.dart`).

### Direct Firestore Writes on Every Tap

**What happens:** Sending Firestore write requests on every single tap of the Durood counter.
**Why it's wrong:** Exhausts Firestore quotas, hits rate limits, incurs billing costs, and causes UI stutter.
**Do this instead:** Use the debounce buffering mechanism in `CounterService` (`lib/services/counter_service.dart`).

## Error Handling

**Strategy:** Graceful degradation with local fallbacks.

**Patterns:**
- Try/catch blocks around all Firestore and SharedPreferences read/write operations.
- `kDebugMode` logging to surface errors during development while keeping production quiet.
- Stream error handlers (`onError: (e) { ... }`) on real-time snapshots to prevent unhandled stream faults from crashing UI.

## Cross-Cutting Concerns

**Logging:** Console `print()` statements guarded with `kDebugMode`.
**Validation:** Model validation inside `fromMap` factory methods (e.g., `AppUser.parseNumeric` in `lib/core/models/app_user.dart`).
**Authentication:** Role-based guard (`AdminService.isAdmin()`) protecting administrative functionality and endpoints.

---

*Architecture analysis: 2026-09-09*
