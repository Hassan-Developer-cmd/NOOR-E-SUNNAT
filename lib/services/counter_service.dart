import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  static final CounterService _instance = CounterService._internal();
  factory CounterService() => _instance;

  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // SharedPreferences Storage Keys
  static const String _keyGlobalTotal = 'cached_global_total';
  static const String _keyGlobalToday = 'cached_global_today';
  static const String _keyGlobalDate = 'cached_global_date';
  static const String _keyPersonalTotal = 'cached_personal_total';
  static const String _keyStreak = 'cached_current_streak';
  static const String _keyPoints = 'cached_durood_points';
  static const String _prefixMyToday = 'my_durood_today_';

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

    // 2. User-specific "My Today" from 'my_durood_today_${todayDateString}'
    final myToday = prefs.getInt('$_prefixMyToday$todayStr') ?? 0;
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
      await prefs.setInt('$_prefixMyToday$todayStr', _snapshot.personalToday);
      await prefs.setInt(_keyStreak, _snapshot.currentStreak);
      await prefs.setInt(_keyPoints, _snapshot.duroodPoints);
    } catch (e) {
      if (kDebugMode) print('CounterService._saveToStorage error: $e');
    }
  }

  void _updateSnapshot(CounterSnapshot newSnap) {
    _snapshot = newSnap;
    if (!_snapshotController.isClosed) {
      _snapshotController.add(_snapshot);
    }
    notifyListeners();
  }

  // ── Streams ────────────────────────────────────────────────

  void _startStreams() {
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
        // Do NOT wipe personal counts to 0! Preserve local cached values.
        _updateSnapshot(CounterSnapshot(
          globalTotal: _snapshot.globalTotal,
          globalToday: _snapshot.globalToday,
          personalTotal: _snapshot.personalTotal,
          personalToday: _snapshot.personalToday,
          currentStreak: _snapshot.currentStreak,
          duroodPoints: _snapshot.duroodPoints,
        ));
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
        final cloudToday = (data['count'] ?? data['todayCount'] as num?)?.toInt() ?? 0;
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
    final lastActive = data['last_active_durood_date'] ??
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
        ? (((data['personal_today_durood'] ?? data['todayCount']) as num?)?.toInt() ?? 0)
        : 0;

    // Never regress local personal counts if offline/local has higher count
    final int effectivePersonalTotal = firestorePersonalTotal >= _snapshot.personalTotal
        ? firestorePersonalTotal
        : _snapshot.personalTotal;
    final int effectivePersonalToday = firestorePersonalToday >= _snapshot.personalToday
        ? firestorePersonalToday
        : _snapshot.personalToday;

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

  /// Buffer a tap locally, notify UI immediately, persist to SharedPreferences,
  /// and commit to Firestore within 400ms (flushed instantly on app exit).
  void increment(int count) {
    if (count <= 0) return;

    _pendingBuffer += count;

    // 1. Optimistically update in-memory state
    _updateSnapshot(CounterSnapshot(
      globalTotal: _snapshot.globalTotal + count,
      globalToday: _snapshot.globalToday + count,
      personalTotal: _snapshot.personalTotal + count,
      personalToday: _snapshot.personalToday + count,
      currentStreak: _snapshot.currentStreak == 0 ? 1 : _snapshot.currentStreak,
      duroodPoints: _snapshot.duroodPoints + (count * 2),
    ));

    // 2. Immediately persist to SharedPreferences so sudden app kill never loses count
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
        final lastActive = data['last_active_durood_date'] ??
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
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      flushImmediately();
      _saveToStorage();
    }
  }

  // ── Reset ───────────────────────────────────────────────────

  Future<void> resetPersonalToday() async {
    final todayStr = StreakHelper.toCalendarDateString(DateTime.now());
    _updateSnapshot(_snapshot.copyWith(personalToday: 0));
    await _prefs?.setInt('$_prefixMyToday$todayStr', 0);

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestore.collection('users').doc(uid).set({
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
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) print('CounterService.resetPersonalToday error: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    flushImmediately();
    _saveToStorage();
    _debounceTimer?.cancel();
    _authSub?.cancel();
    _globalSub?.cancel();
    _userSub?.cancel();
    _snapshotController.close();
    super.dispose();
  }
}
