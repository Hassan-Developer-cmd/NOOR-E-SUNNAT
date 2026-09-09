# Coding Conventions

**Analysis Date:** 2026-09-09

## Naming Patterns

**Files:**
- Use lowercase `snake_case.dart` for all Dart source files: `counter_service.dart`, `admin_dashboard_web.dart`, `app_translations.dart`.
- Test files must mirror the target with a `_test.dart` suffix: `counter_persistence_test.dart`.

**Classes & Types:**
- Use `UpperCamelCase` for classes, mixins, enums, and typedefs: `CounterService`, `AppUser`, `NoorESunnatApp`, `LanguageProvider`.
- Private state classes use leading underscore: `_MainShellState`, `_WebAdminEntryGateState`.

**Functions & Methods:**
- Use `lowerCamelCase` for method and function names: `incrementPersonal()`, `resolveCurrentUser()`, `seedDefaultDataToFirestore()`.
- Private helper methods use leading underscore: `_clearStaleSession()`, `_initMobileMessaging()`.

**Variables & Fields:**
- Use `lowerCamelCase` for properties and variables: `personalTotal`, `globalTotal`, `isUrdu`.
- Private fields use leading underscore: `_snapshot`, `_counterService`, `_prefs`.
- Constants use `lowerCamelCase` or `kCamelCase`: `_keyGlobalTotal`, `_kProductionZeroResetKey`, `kIsWeb`.

## Code Style

**Formatting:**
- Official Dart Formatter (`dart format`).
- 2-space indentation, trailing commas on multi-line parameter lists for optimal Flutter widget tree formatting.

**Linting:**
- Linter configured via `analysis_options.yaml` extending `package:flutter_lints/flutter.yaml`.
- Key rules observed:
  - `prefer_const_constructors`: Const constructors must be used whenever widget subtree allows it.
  - `use_key_in_widget_constructors`: Every widget accepts an optional `super.key`.
  - `avoid_print`: Console output must be guarded with `kDebugMode` or avoided in production.

## Import Organization

**Order:**
1. Standard Dart SDK packages (`dart:async`, `dart:convert`, `dart:io`).
2. Flutter framework & third-party package imports (`package:flutter/material.dart`, `package:cloud_firestore/...`).
3. Local/relative project imports (`../core/constants/app_colors.dart`, `firebase_options.dart`).

```dart
// Example from lib/services/counter_service.dart:
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/streak_helper.dart';
import 'auth_service.dart';
```

## Error Handling

**Defensive Data Parsing:**
- Firestore documents may contain inconsistent types across legacy records (int vs double vs String). Models must implement robust fallback converters:
```dart
static int parseNumeric(dynamic value, [int defaultValue = 0]) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final clean = value.replaceAll(',', '').trim();
    final parsed = int.tryParse(clean) ?? double.tryParse(clean)?.toInt();
    if (parsed != null) return parsed;
  }
  return defaultValue;
}
```

**Asynchronous Guarding:**
- All network interactions with Firebase and HTTP APIs must be wrapped in `try { ... } catch (e) { ... }` blocks.
- Non-blocking background promises should use `unawaited(...)` with local error catching to prevent unhandled asynchronous exceptions.

## Logging

**Framework:**
- Native Dart `print` wrapped in `kDebugMode` checks.
- Production builds (`kReleaseMode`) must never leak debugging logs or user personal info to logcat.

```dart
if (kDebugMode) {
  print('CounterService: Synchronized $delta increments with Firestore.');
}
```

## Comments

**Documentation & Annotations:**
- Triple-slash (`///`) docstrings on public APIs, services, and model classes explaining intent, parameters, and invariants.
- Section separators used inside large services (e.g. `// ── Events CRUD ───`).
- VM annotations for entry points: `@pragma('vm:entry-point')` for background isolate handlers (`_firebaseMessagingBackgroundHandler`).

## Function Design

**Size:**
- Modular, focused business methods in services.
- Large UI widgets broken into smaller private builder methods or dedicated stateless sub-widgets (`widgets/`).

**Parameters:**
- Named parameters preferred for widgets and complex models (`required this.title, this.isActive = true`).
- Optional callbacks typed as `VoidCallback?` or `ValueChanged<T>?`.

## Module Design

**State Encapsulation:**
- Services encapsulate external SDK calls (`FirebaseFirestore.instance`, `FirebaseAuth.instance`). UI widgets do not directly construct Firestore write batches; they call service methods (`CounterService`, `AdminService`).
- UI reads state either via reactive streams (`StreamBuilder`) or listeners (`ListenableBuilder` listening to `ChangeNotifier`).

---

*Convention analysis: 2026-09-09*
