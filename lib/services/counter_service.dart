import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/streak_helper.dart';
import 'auth_service.dart';

/// Holds a snapshot of all counter values for the UI to consume.
class CounterSnapshot {
  final int globalTotal;
  final int globalToday;
  final int personalTotal;
  final int personalToday;
  final int currentStreak;
  final int duroodPoints;

  const CounterSnapshot({
    this.globalTotal = 0,
    this.globalToday = 0,
    this.personalTotal = 0,
    this.personalToday = 0,
    this.currentStreak = 0,
    this.duroodPoints = 0,
  });

  CounterSnapshot copyWith({
    int? globalTotal,
    int? globalToday,
    int? personalTotal,
    int? personalToday,
    int? currentStreak,
    int? duroodPoints,
  }) {
    return CounterSnapshot(
      globalTotal: globalTotal ?? this.globalTotal,
      globalToday: globalToday ?? this.globalToday,
      personalTotal: personalTotal ?? this.personalTotal,
      personalToday: personalToday ?? this.personalToday,
      currentStreak: currentStreak ?? this.currentStreak,
      duroodPoints: duroodPoints ?? this.duroodPoints,
    );
  }
}

class CounterService extends ChangeNotifier with WidgetsBindingObserver {
  static CounterService _instance = CounterService._internal();
  factory CounterService() {
    if (_instance._isDisposed) {
      _instance = CounterService._internal();
    }
    return _instance;
  }

  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // SharedPreferences Storage Keys
  static const String _keyGlobalTotal = 'cached_global_total';
  static const String _keyGlobalToday = 'cached_global_today';
  static const String _keyGlobalDate = 'cached_global_date';
  static const String _keyPersonalTotal = 'cached_personal_total';
  static const String _keyStreak = 'cached_current_streak';
  static const String _keyPoints = 'cached_durood_points';
  static const String _prefixMyDurood = 'my_durood_';
  static const String _prefixMyTodayLegacy = 'my_durood_today_';
  static const String _keyMyDuroodDate = 'my_durood_date';
  static const String _keyActiveUid = 'cached_active_uid';

  static SharedPreferences? _prefs;

  // --- State ---
  CounterSnapshot _snapshot = const CounterSnapshot();
  CounterSnapshot get snapshot => _snapshot;

  final StreamController<CounterSnapshot> _snapshotController =
      StreamController<CounterSnapshot>.broadcast();

  /// Reactive stream emitting latest CounterSnapshot whenever counts update.
  Stream<CounterSnapshot> get snapshotStream => _snapshotController.stream;

  // Exposed live streams for UI StreamBuilders
  /// Stream of global counter document snapshots ('counters/durood_stats').
  Stream<DocumentSnapshot<Map<String, dynamic>>> get globalCounterStream =>
      _firestore.collection('counters').doc('durood_stats').snapshots();

  /// Stream of current user's document snapshots ('users/{uid}').
  Stream<DocumentSnapshot<Map<String, dynamic>>?> get userCounterStream {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(null);
      return _firestore.collection('users').doc(user.uid).snapshots();
    });
  }

  // Internal buffer for debounced writes
  int _pendingBuffer = 0;
  Timer? _debounceTimer;
  StreamSubscription? _authSub;
  StreamSubscription? _globalSub;
  StreamSubscription? _userSub;

  CounterService._internal() {
    WidgetsBinding.instance.addObserver(this);
    _hydrateFromStorage();
    _startStreams();
  }

  /// Explicit storage pre-hydration called in main() before runApp().
  static Future<void> initStorage() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _instance._hydrateFromStorage();
    } catch (e) {
      if (kDebugMode) print('CounterService.initStorage error: $e');
    }
  }

  void _hydrateFromStorage() {
    final prefs = _prefs;
    if (prefs == null) return;

    final todayStr = StreakHelper.toCalendarDateString(DateTime.now());

    // 1. Global totals from cache
    final cachedGlobalDate = prefs.getString(_keyGlobalDate);
    final isGlobalSameDay = StreakHelper.isSameDay(cachedGlobalDate, todayStr);
    final globalTotal = prefs.getInt(_keyGlobalTotal) ?? _snapshot.globalTotal;
    final globalToday = isGlobalSameDay
        ? (prefs.getInt(_keyGlobalToday) ?? _snapshot.globalToday)
        : 0;

    // 2. Midnight Auto-Reset Logic for "My Today":
    // Check if storedDate != currentDateString
    final storedDate = prefs.getString(_keyMyDuroodDate);
    final int myToday;
    if (storedDate != null && storedDate != todayStr) {
      // Date has actually changed (new day has started): set "My Today" count to 0 and update storedDate
      myToday = 0;
      prefs.setInt('$_prefixMyDurood$todayStr', 0);
      prefs.setString(_keyMyDuroodDate, todayStr);
    } else {
      // Same day or initial install: load existing accumulated count
      myToday = prefs.getInt('$_prefixMyDurood$todayStr') ??
          prefs.getInt('$_prefixMyTodayLegacy$todayStr') ??
          0;
      prefs.setString(_keyMyDuroodDate, todayStr);
    }

    // Hydrate cached active UID to guard against auth cold-start resets
    _activeUid = prefs.getString(_keyActiveUid) ?? _activeUid;

    final personalTotal = prefs.getInt(_keyPersonalTotal) ?? _snapshot.personalTotal;
    final streak = prefs.getInt(_keyStreak) ?? _snapshot.currentStreak;
    final points = prefs.getInt(_keyPoints) ?? _snapshot.duroodPoints;

    _updateSnapshot(CounterSnapshot(
      globalTotal: globalTotal,
      globalToday: globalToday,
      personalTotal: personalTotal,
      personalToday: myToday,
      currentStreak: streak,
      duroodPoints: points,
    ));
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs = prefs;
      final todayStr = StreakHelper.toCalendarDateString(DateTime.now());

      await prefs.setInt(_keyGlobalTotal, _snapshot.globalTotal);
      await prefs.setInt(_keyGlobalToday, _snapshot.globalToday);
      await prefs.setString(_keyGlobalDate, todayStr);
      await prefs.setInt(_keyPersonalTotal, _snapshot.personalTotal);
      await prefs.setInt('$_prefixMyDurood$todayStr', _snapshot.personalToday);
      await prefs.setInt('$_prefixMyTodayLegacy$todayStr', _snapshot.personalToday);
      await prefs.setString(_keyMyDuroodDate, todayStr);
      if (_activeUid != null) {
        await prefs.setString(_keyActiveUid, _activeUid!);
      }
      await prefs.setInt(_keyStreak, _snapshot.currentStreak);
      await prefs.setInt(_keyPoints, _snapshot.duroodPoints);
    } catch (e) {
      if (kDebugMode) print('CounterService._saveToStorage error: $e');
    }
  }

  void _updateSnapshot(CounterSnapshot newSnap) {
    if (_isDisposed) return;
    _snapshot = newSnap;
    if (!_snapshotController.isClosed) {
      _snapshotController.add(_snapshot);
    }
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  String? _activeUid;

  /// Completely resets in-memory and local cached personal counter state on sign out or account deletion.
  void resetLocalState() {
    _activeUid = null;
    _pendingBuffer = 0;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _updateSnapshot(CounterSnapshot(
      globalTotal: _snapshot.globalTotal,
      globalToday: _snapshot.globalToday,
      personalTotal: 0,
      personalToday: 0,
      currentStreak: 0,
      duroodPoints: 0,
    ));
    try {
      _prefs?.remove(_keyActiveUid);
      _prefs?.remove(_keyMyDuroodDate);
      _prefs?.remove(_keyPersonalTotal);
      _prefs?.remove(_keyStreak);
      _prefs?.remove(_keyPoints);
      final todayStr = StreakHelper.toCalendarDateString(DateTime.now());
      _prefs?.remove('$_prefixMyDurood$todayStr');
      _prefs?.remove('$_prefixMyTodayLegacy$todayStr');
    } catch (_) {}
  }

  // ── Streams ────────────────────────────────────────────────

  void _startStreams() {
    try {
      if (Firebase.apps.isEmpty) return;
    } catch (_) {
      return;
    }

    // 1. Global counter stream ('counters/durood_stats')
    _globalSub = globalCounterStream.listen((snap) {
      if (snap.exists && snap.data() != null) {
        _processGlobalSnap(snap.data()!);
      }
    }, onError: (e) {
      if (kDebugMode) print('CounterService global stream error: $e');
    });

    // 2. User counter stream reacting to Auth state changes
    _authSub = _auth.authStateChanges().listen((user) async {
      await _userSub?.cancel();
      if (user != null) {
        if (_activeUid != null && _activeUid != user.uid) {
          // Explicit account switch between two different users: reset personal counts in memory so no previous user data leaks!
          _updateSnapshot(CounterSnapshot(
            globalTotal: _snapshot.globalTotal,
            globalToday: _snapshot.globalToday,
            personalTotal: 0,
            personalToday: 0,
            currentStreak: 0,
            duroodPoints: 0,
          ));
        }
        _activeUid = user.uid;
        _prefs?.setString(_keyActiveUid, user.uid);

        // Ensure user doc exists in Firestore safely without overwriting existing counts
        await AuthService.ensureUserDocExists(user);

        // Check user's daily_stats subcollection in cloud to restore if higher
        _syncDailyStatsFromFirestore(user.uid);

        _userSub = _firestore.collection('users').doc(user.uid).snapshots().listen((snap) {
          if (snap.exists && snap.data() != null) {
            _processUserSnap(snap.data()!);
          }
        }, onError: (e) {
          if (kDebugMode) print('CounterService user stream error: $e');
        });
      } else {
        _activeUid = null;
        resetLocalState();
      }
    });
  }

  Future<void> _syncDailyStatsFromFirestore(String uid) async {
    try {
      final todayStr = StreakHelper.toCalendarDateString(DateTime.now());
      final dailySnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('daily_stats')
          .doc(todayStr)
          .get();

      if (dailySnap.exists && dailySnap.data() != null) {
        final data = dailySnap.data()!;
        final cloudToday = (data['todayDuroodCount'] ?? data['count'] ?? data['todayCount'] as num?)?.toInt() ?? 0;
        if (cloudToday > _snapshot.personalToday) {
          _updateSnapshot(_snapshot.copyWith(personalToday: cloudToday));
          _saveToStorage();
        }
      }
    } catch (e) {
      if (kDebugMode) print('CounterService._syncDailyStatsFromFirestore notice: $e');
    }
  }

  void _processGlobalSnap(Map<String, dynamic> data) {
    final todayStr = StreakHelper.toCalendarDateString(DateTime.now());
    final lastReset = data['lastUpdatedDate'] ?? data['last_reset_date'];
    final isSameDay = StreakHelper.isSameDay(lastReset, todayStr);

    final int firestoreToday = isSameDay
        ? (((data['todayTotal'] ?? data['today_count']) as num?)?.toInt() ?? 0)
        : 0;
    final int firestoreTotal = ((data['globalTotal'] ?? data['total_count']) as num?)?.toInt() ?? 0;

    // Preserve higher local values if local increments are currently in flight
    final effectiveGlobalTotal = firestoreTotal >= _snapshot.globalTotal
        ? firestoreTotal
        : _snapshot.globalTotal;
    final effectiveGlobalToday = firestoreToday >= _snapshot.globalToday
        ? firestoreToday
        : _snapshot.globalToday;

    _updateSnapshot(CounterSnapshot(
      globalTotal: effectiveGlobalTotal,
      globalToday: effectiveGlobalToday,
      personalTotal: _snapshot.personalTotal,
      personalToday: _snapshot.personalToday,
      currentStreak: _snapshot.currentStreak,
      duroodPoints: _snapshot.duroodPoints,
    ));

    _saveToStorage();

    if (!isSameDay && lastReset != null) {
      _resetGlobalTodayInFirestore(todayStr);
    }
  }

  void _processUserSnap(Map<String, dynamic> data) {
    final todayStr = StreakHelper.toCalendarDateString(DateTime.now());
    final lastActive = data['lastDuroodDate'] ??
        data['last_active_durood_date'] ??
        data['last_active_timestamp'] ??
        data['last_active_date'] ??
        data['last_durood_at'];
    final isSameDay = StreakHelper.isSameDay(lastActive, todayStr);

    final int rawStreak = ((data['current_streak'] ?? data['streak']) as num?)?.toInt() ?? 0;
    final int effectiveStreak = StreakHelper.calculateEffectiveStreak(
      storedStreak: rawStreak,
      lastActiveDate: lastActive,
    );

    final int firestorePersonalTotal = (data['personal_total_durood'] as num?)?.toInt() ?? 0;
    final int firestorePersonalToday = isSameDay
        ? (((data['todayDuroodCount'] ?? data['personal_today_durood'] ?? data['todayCount']) as num?)?.toInt() ?? 0)
        : 0;

    // Use firestore counts directly if higher, but NEVER downgrade local counts on the same day!
    final int effectivePersonalTotal = _pendingBuffer > 0 || _snapshot.personalTotal > firestorePersonalTotal
        ? _snapshot.personalTotal
        : firestorePersonalTotal;
    final int effectivePersonalToday = isSameDay
        ? (_snapshot.personalToday > firestorePersonalToday ? _snapshot.personalToday : firestorePersonalToday)
        : 0;

    _updateSnapshot(CounterSnapshot(
      globalTotal: _snapshot.globalTotal,
      globalToday: _snapshot.globalToday,
      personalTotal: effectivePersonalTotal,
      personalToday: effectivePersonalToday,
      currentStreak: effectiveStreak,
      duroodPoints: (data['total_durood_points'] as num?)?.toInt() ?? _snapshot.duroodPoints,
    ));

    _saveToStorage();
  }

  Future<void> _resetGlobalTodayInFirestore(String todayStr) async {
    try {
      await _firestore.collection('counters').doc('durood_stats').set({
        'todayTotal': 0,
        'lastUpdatedDate': todayStr,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) print('CounterService._resetGlobalTodayInFirestore error: $e');
    }
  }

  /// Adds bulk Durood amount to counter.
  void addBulkDurood(int amount) => increment(amount);

  /// Buffer a tap locally, notify UI immediately, persist to SharedPreferences under daily key,
  /// and commit to Firestore within 400ms (flushed instantly on app exit).
  void increment(int count) {
    if (count <= 0) return;

    _pendingBuffer += count;
    final todayStr = StreakHelper.toCalendarDateString(DateTime.now());
    final updatedMyToday = _snapshot.personalToday + count;

    // 1. Optimistically update in-memory state
    _updateSnapshot(CounterSnapshot(
      globalTotal: _snapshot.globalTotal + count,
      globalToday: _snapshot.globalToday + count,
      personalTotal: _snapshot.personalTotal + count,
      personalToday: updatedMyToday,
      currentStreak: _snapshot.currentStreak == 0 ? 1 : _snapshot.currentStreak,
      duroodPoints: _snapshot.duroodPoints + (count * 2),
    ));

    // 2. Immediately persist to SharedPreferences under daily key so sudden app kill never loses count
    _prefs?.setInt('$_prefixMyDurood$todayStr', updatedMyToday);
    _prefs?.setInt('$_prefixMyTodayLegacy$todayStr', updatedMyToday);
    _prefs?.setString(_keyMyDuroodDate, todayStr);
    _saveToStorage();

    // 3. Fast debounce flush to Firestore
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), flushImmediately);
  }

  /// Immediately commits any buffered increments to Firestore.
  Future<void> flushImmediately() async {
    _debounceTimer?.cancel();
    if (_pendingBuffer <= 0) return;
    final count = _pendingBuffer;
    _pendingBuffer = 0;

    try {
      final todayStr = StreakHelper.toCalendarDateString(DateTime.now());
      final batch = _firestore.batch();

      // 1. Global counter update with daily reset check
      final globalRef = _firestore.collection('counters').doc('durood_stats');
      final globalSnap = await globalRef.get();
      final globalData = globalSnap.data() ?? {};
      final globalLastReset = globalData['lastUpdatedDate'] ?? globalData['last_reset_date'];
      final isGlobalSameDay = StreakHelper.isSameDay(globalLastReset, todayStr);

      if (isGlobalSameDay) {
        batch.set(
          globalRef,
          {
            'globalTotal': FieldValue.increment(count),
            'todayTotal': FieldValue.increment(count),
            'lastUpdatedDate': todayStr,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } else {
        batch.set(
          globalRef,
          {
            'globalTotal': FieldValue.increment(count),
            'todayTotal': count,
            'lastUpdatedDate': todayStr,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      // 2. User counter update with daily reset & streak logic
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        final userRef = _firestore.collection('users').doc(uid);
        final userSnap = await userRef.get();
        final data = userSnap.data() ?? {};
        final lastActive = data['lastDuroodDate'] ??
            data['last_active_durood_date'] ??
            data['last_active_timestamp'] ??
            data['last_active_date'] ??
            data['last_durood_at'];

        final currentStoredStreak = ((data['current_streak'] ?? data['streak']) as num?)?.toInt() ?? 0;
        final longestStoredStreak = ((data['longest_streak'] ?? data['best_streak']) as num?)?.toInt() ?? currentStoredStreak;

        final streakUpdates = StreakHelper.computeStreakOnDuroodRecitation(
          currentStoredStreak: currentStoredStreak,
          longestStoredStreak: longestStoredStreak,
          lastActiveDate: lastActive,
          todayDateStr: todayStr,
        );
        final isUserNewDay = lastActive == null || !StreakHelper.isSameDay(lastActive, todayStr);

        batch.set(
          userRef,
          {
            'personal_total_durood': FieldValue.increment(count),
            'personal_today_durood': isUserNewDay ? count : FieldValue.increment(count),
            'todayCount': isUserNewDay ? count : FieldValue.increment(count),
            'todayDuroodCount': isUserNewDay ? count : FieldValue.increment(count),
            'lastDuroodDate': todayStr,
            'total_durood_points': FieldValue.increment(count * 2),
            'last_active_durood_date': todayStr,
            'last_active_timestamp': FieldValue.serverTimestamp(),
            'last_durood_at': FieldValue.serverTimestamp(),
            ...streakUpdates,
          },
          SetOptions(merge: true),
        );

        // 3. User daily_stats subcollection: users/{userId}/daily_stats/{dateString}
        final dailyStatRef = userRef.collection('daily_stats').doc(todayStr);
        batch.set(
          dailyStatRef,
          {
            'date': todayStr,
            'count': FieldValue.increment(count),
            'todayCount': FieldValue.increment(count),
            'todayDuroodCount': FieldValue.increment(count),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();
    } catch (e) {
      if (kDebugMode) print('CounterService.flushImmediately error: $e');
      // Restore pending buffer so counts aren't lost on network glitch
      _pendingBuffer += count;
    }
  }

  // ── App Lifecycle: Flush on pause, inactive, or detach ───────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkMidnightReset();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      flushImmediately();
      _saveToStorage();
    }
  }

  void _checkMidnightReset() {
    final todayStr = StreakHelper.toCalendarDateString(DateTime.now());
    final storedDate = _prefs?.getString(_keyMyDuroodDate);
    if (storedDate != null && storedDate != todayStr) {
      // Midnight has elapsed while app was in background
      _prefs?.setString(_keyMyDuroodDate, todayStr);
      _prefs?.setInt('$_prefixMyDurood$todayStr', 0);
      _prefs?.setInt('$_prefixMyTodayLegacy$todayStr', 0);
      _updateSnapshot(_snapshot.copyWith(
        personalToday: 0,
        globalToday: 0,
      ));
      _saveToStorage();
    }
  }

  // ── Reset ───────────────────────────────────────────────────

  Future<void> resetPersonalToday() async {
    final todayStr = StreakHelper.toCalendarDateString(DateTime.now());
    _updateSnapshot(_snapshot.copyWith(personalToday: 0));
    await _prefs?.setInt('$_prefixMyDurood$todayStr', 0);
    await _prefs?.setInt('$_prefixMyTodayLegacy$todayStr', 0);

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestore.collection('users').doc(uid).set({
        'todayDuroodCount': 0,
        'personal_today_durood': 0,
        'todayCount': 0,
      }, SetOptions(merge: true));

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('daily_stats')
          .doc(todayStr)
          .set({
        'count': 0,
        'todayCount': 0,
        'todayDuroodCount': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) print('CounterService.resetPersonalToday error: $e');
    }
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    flushImmediately();
    _saveToStorage();
    _debounceTimer?.cancel();
    _authSub?.cancel();
    _globalSub?.cancel();
    _userSub?.cancel();
    if (!_snapshotController.isClosed) {
      _snapshotController.close();
    }
    super.dispose();
  }
}
