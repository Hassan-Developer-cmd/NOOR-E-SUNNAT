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

  /// Returns today's ISO calendar date string: "YYYY-MM-DD"
  static String get _todayDateString => DateTime.now().toIso8601String().split('T')[0];

  /// Isolated SharedPreferences key for the current user's count today:
  /// my_durood_${userId}_${todayDateString}
  String get _todayKey {
    final uid = _auth.currentUser?.uid ?? _activeUid ?? 'guest';
    final today = _todayDateString;
    return 'my_durood_${uid}_$today';
  }

  /// Computes isolated SharedPreferences key for user's personal count today:
  /// my_durood_${userId}_${todayDateString}
  static String _getUserTodayKey(String? uid, String dateStr) {
    final effectiveUid = (uid != null && uid.isNotEmpty) ? uid : 'guest';
    return 'my_durood_${effectiveUid}_$dateStr';
  }

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

  /// Stream of current user's profile document snapshots ('users/{uid}').
  Stream<DocumentSnapshot<Map<String, dynamic>>?> get userCounterStream {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(null);
      return _firestore.collection('users').doc(user.uid).snapshots();
    });
  }

  /// Stream of current user's daily stats document ('users/{uid}/daily_stats/{todayDateString}').
  Stream<DocumentSnapshot<Map<String, dynamic>>?> get userDailyStatsStream {
    final todayStr = _todayDateString;
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(null);
      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('daily_stats')
          .doc(todayStr)
          .snapshots();
    });
  }

  // Internal buffer for debounced writes
  int _pendingBuffer = 0;
  Timer? _debounceTimer;
  StreamSubscription? _authSub;
  StreamSubscription? _globalSub;
  StreamSubscription? _userSub;
  StreamSubscription? _userDailySub;

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

    final todayStr = _todayDateString;

    // 1. Global totals from cache
    final cachedGlobalDate = prefs.getString(_keyGlobalDate);
    final isGlobalSameDay = StreakHelper.isSameDay(cachedGlobalDate, todayStr);
    final globalTotal = prefs.getInt(_keyGlobalTotal) ?? _snapshot.globalTotal;
    final globalToday = isGlobalSameDay
        ? (prefs.getInt(_keyGlobalToday) ?? _snapshot.globalToday)
        : 0;

    // 2. User-specific "My Today" from isolated key 'my_durood_${userId}_${todayDateString}'
    final storedDate = prefs.getString(_keyMyDuroodDate);
    final activeUid = _auth.currentUser?.uid ?? prefs.getString(_keyActiveUid) ?? _activeUid;
    _activeUid = activeUid;

    final int myToday;
    if (storedDate != null && (storedDate != todayStr || storedDate.compareTo(todayStr) < 0)) {
      // Midnight transition (current date > stored key date): reset "My Today" count to 0 and update storedDate
      myToday = 0;
      prefs.setInt(_todayKey, 0);
      if (activeUid != null) {
        prefs.setInt('my_durood_${activeUid}_$todayStr', 0);
      }
      prefs.setInt('$_prefixMyDurood$todayStr', 0);
      prefs.setString(_keyMyDuroodDate, todayStr);
    } else {
      // Same day: read user-isolated key immediately
      myToday = _readMyTodayFromPrefs(prefs, todayStr);
      prefs.setString(_keyMyDuroodDate, todayStr);
    }

    // 3. Personal Total from user key or global fallback
    final personalTotal = (activeUid != null && activeUid != 'guest')
        ? (prefs.getInt('${_keyPersonalTotal}_$activeUid') ?? prefs.getInt(_keyPersonalTotal) ?? _snapshot.personalTotal)
        : (prefs.getInt(_keyPersonalTotal) ?? _snapshot.personalTotal);

    // 4. Streak from user key or global fallback
    final rawCachedStreak = (activeUid != null && activeUid != 'guest')
        ? (prefs.getInt('${_keyStreak}_$activeUid') ?? prefs.getInt(_keyStreak) ?? _snapshot.currentStreak)
        : (prefs.getInt(_keyStreak) ?? _snapshot.currentStreak);

    final effectiveCachedStreak = StreakHelper.calculateEffectiveStreak(
      storedStreak: rawCachedStreak,
      lastActiveDate: storedDate,
    );
    final streak = effectiveCachedStreak > 0
        ? effectiveCachedStreak
        : (myToday > 0 ? (rawCachedStreak > 0 ? rawCachedStreak : 1) : 0);

    // 5. Durood Points from user key or global fallback
    final points = (activeUid != null && activeUid != 'guest')
        ? (prefs.getInt('${_keyPoints}_$activeUid') ?? prefs.getInt(_keyPoints) ?? _snapshot.duroodPoints)
        : (prefs.getInt(_keyPoints) ?? _snapshot.duroodPoints);

    _updateSnapshot(CounterSnapshot(
      globalTotal: globalTotal,
      globalToday: globalToday,
      personalTotal: personalTotal,
      personalToday: myToday,
      currentStreak: streak,
      duroodPoints: points,
    ));
  }

  int _readMyTodayFromPrefs(SharedPreferences prefs, String todayStr) {
    // 1. Primary: _todayKey
    final primaryVal = prefs.getInt(_todayKey);
    if (primaryVal != null && primaryVal > 0) return primaryVal;

    // 2. Active UID key if set
    if (_activeUid != null && _activeUid != 'guest') {
      final activeVal = prefs.getInt('my_durood_${_activeUid}_$todayStr');
      if (activeVal != null && activeVal > 0) return activeVal;
    }

    // 3. Current user UID key if currentUser is non-null
    final currentUid = _auth.currentUser?.uid;
    if (currentUid != null && currentUid != 'guest') {
      final currentVal = prefs.getInt('my_durood_${currentUid}_$todayStr');
      if (currentVal != null && currentVal > 0) return currentVal;
    }

    // 4. Fallback to generic key
    final genericVal = prefs.getInt('$_prefixMyDurood$todayStr');
    if (genericVal != null && genericVal > 0) return genericVal;

    // 5. Fallback to legacy key
    final legacyVal = prefs.getInt('$_prefixMyTodayLegacy$todayStr');
    if (legacyVal != null && legacyVal > 0) return legacyVal;

    return primaryVal ?? 0;
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs = prefs;
      final todayStr = _todayDateString;
      final userKey = _todayKey;
      final uid = _activeUid ?? _auth.currentUser?.uid;

      await prefs.setInt(_keyGlobalTotal, _snapshot.globalTotal);
      await prefs.setInt(_keyGlobalToday, _snapshot.globalToday);
      await prefs.setString(_keyGlobalDate, todayStr);
      await prefs.setInt(_keyPersonalTotal, _snapshot.personalTotal);
      await prefs.setInt(userKey, _snapshot.personalToday);
      if (uid != null && uid != 'guest') {
        await prefs.setInt('my_durood_${uid}_$todayStr', _snapshot.personalToday);
        await prefs.setInt('${_keyPersonalTotal}_$uid', _snapshot.personalTotal);
        await prefs.setInt('${_keyStreak}_$uid', _snapshot.currentStreak);
        await prefs.setInt('${_keyPoints}_$uid', _snapshot.duroodPoints);
      }
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
    final oldUid = _activeUid;
    _activeUid = null;
    _pendingBuffer = 0;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _userDailySub?.cancel();
    _userDailySub = null;
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
      final todayStr = _todayDateString;
      if (oldUid != null) {
        _prefs?.remove('my_durood_${oldUid}_$todayStr');
      }
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
      await _userDailySub?.cancel();
      if (user != null) {
        _activeUid = user.uid;
        _prefs?.setString(_keyActiveUid, user.uid);

        // When the user is loaded/authenticated, re-run _hydrateFromStorage()
        // so the user-specific count, streak, and points are restored instantly
        _hydrateFromStorage();

        // Ensure user doc exists in Firestore safely without overwriting existing counts
        await AuthService.ensureUserDocExists(user);

        // 1. Stream strictly to users/{userId}/daily_stats/{todayDateString}
        _listenToUserDailyStats(user.uid);

        // 2. Stream user profile doc for streak, points, total
        _userSub = _firestore.collection('users').doc(user.uid).snapshots().listen((snap) {
          if (snap.exists && snap.data() != null) {
            _processUserSnap(snap.data()!);
          }
        }, onError: (e) {
          if (kDebugMode) print('CounterService user stream error: $e');
        });
      } else {
        _activeUid = null;
        // Do NOT call resetLocalState() here on transient null auth events at startup!
        // Explicit logout in AuthService.signOut() / deleteAccount() calls resetLocalState().
      }
    });
  }

  /// Streams strictly to users/{userId}/daily_stats/{todayDateString} for isolated "My Today"
  void _listenToUserDailyStats(String uid) {
    _userDailySub?.cancel();
    final todayStr = _todayDateString;
    final userKey = _todayKey;

    _userDailySub = _firestore
        .collection('users')
        .doc(uid)
        .collection('daily_stats')
        .doc(todayStr)
        .snapshots()
        .listen((snap) {
      if (snap.exists && snap.data() != null) {
        final data = snap.data()!;
        final int cloudMyToday = ((data['myToday'] ??
                data['todayDuroodCount'] ??
                data['todayCount'] ??
                data['count']) as num?)
                ?.toInt() ??
            0;

        final int effectiveMyToday = _pendingBuffer > 0
            ? (_snapshot.personalToday >= cloudMyToday
                ? _snapshot.personalToday
                : cloudMyToday)
            : (_snapshot.personalToday > cloudMyToday
                ? _snapshot.personalToday
                : cloudMyToday);

        if (effectiveMyToday != _snapshot.personalToday) {
          _updateSnapshot(_snapshot.copyWith(personalToday: effectiveMyToday));
        }
        _prefs?.setInt(userKey, effectiveMyToday);
        if (_activeUid != null && _activeUid != 'guest') {
          _prefs?.setInt('my_durood_${_activeUid}_$todayStr', effectiveMyToday);
        }
        _prefs?.setInt('$_prefixMyDurood$todayStr', effectiveMyToday);
        _prefs?.setString(_keyMyDuroodDate, todayStr);
      } else {
        // Document does not exist yet in Firestore: do NOT overwrite with 0!
        // Retain the locally saved value until synced.
      }
    }, onError: (e) {
      if (kDebugMode) print('CounterService user daily stats stream error: $e');
    });
  }

  void _processGlobalSnap(Map<String, dynamic> data) {
    final todayStr = _todayDateString;
    final docDate = (data['date'] ?? data['lastUpdatedDate'] ?? data['last_reset_date'])?.toString();
    final isSameDay = docDate == todayStr;

    final int firestoreToday = isSameDay
        ? (((data['todayTotal'] ?? data['globalToday'] ?? data['todayCount'] ?? data['today_count']) as num?)?.toInt() ?? 0)
        : 0;
    final int firestoreTotal = ((data['globalTotal'] ?? data['total_count']) as num?)?.toInt() ?? 0;

    // Preserve higher local values if local increments are currently in flight
    final effectiveGlobalTotal = firestoreTotal >= _snapshot.globalTotal
        ? firestoreTotal
        : _snapshot.globalTotal;
    final effectiveGlobalToday = isSameDay
        ? (firestoreToday >= _snapshot.globalToday ? firestoreToday : _snapshot.globalToday)
        : 0;

    _updateSnapshot(CounterSnapshot(
      globalTotal: effectiveGlobalTotal,
      globalToday: effectiveGlobalToday,
      personalTotal: _snapshot.personalTotal,
      personalToday: _snapshot.personalToday,
      currentStreak: _snapshot.currentStreak,
      duroodPoints: _snapshot.duroodPoints,
    ));

    _saveToStorage();

    if (!isSameDay && docDate != null) {
      _resetGlobalTodayInFirestore(todayStr);
    }
  }

  void _processUserSnap(Map<String, dynamic> data) {
    final todayStr = _todayDateString;
    final lastActive = data['lastDuroodDate'] ??
        data['last_active_durood_date'] ??
        data['last_active_timestamp'] ??
        data['last_active_date'] ??
        data['last_durood_at'];

    // 1. STREAK: Parse from current_streak, streak, or daily_streak
    final int rawStreak = ((data['current_streak'] ??
        data['streak'] ??
        data['daily_streak']) as num?)?.toInt() ?? 0;

    int effectiveStreak = StreakHelper.calculateEffectiveStreak(
      storedStreak: rawStreak,
      lastActiveDate: lastActive,
    );

    // If local snapshot has an active streak, NEVER downgrade to 0!
    if (effectiveStreak == 0 && _snapshot.currentStreak > 0) {
      if (_snapshot.personalToday > 0 || _pendingBuffer > 0) {
        effectiveStreak = _snapshot.currentStreak;
      } else {
        final storedDate = _prefs?.getString(_keyMyDuroodDate);
        if (storedDate != null && StreakHelper.calendarDaysDifference(storedDate, todayStr) <= 1) {
          effectiveStreak = _snapshot.currentStreak;
        }
      }
    } else if (_snapshot.currentStreak > effectiveStreak && _pendingBuffer > 0) {
      effectiveStreak = _snapshot.currentStreak;
    }

    if (_snapshot.personalToday > 0 && effectiveStreak == 0) {
      effectiveStreak = 1;
    }

    // 2. PERSONAL TOTAL: Parse across all field variations
    final int firestorePersonalTotal = ((data['personal_total_durood'] ??
        data['total_durood_count'] ??
        data['personal_durood'] ??
        data['total_recitations'] ??
        data['total_count'] ??
        data['totalDurood']) as num?)?.toInt() ?? 0;

    // Use firestore counts directly if higher, but NEVER downgrade local counts!
    final int effectivePersonalTotal = _pendingBuffer > 0 || _snapshot.personalTotal > firestorePersonalTotal
        ? _snapshot.personalTotal
        : firestorePersonalTotal;

    // 3. PERSONAL TODAY: Preserve local today and accept cloud if higher on same day
    final bool isSameDay = StreakHelper.isSameDay(lastActive, todayStr);
    final int firestorePersonalToday = isSameDay
        ? (((data['myToday'] ?? data['todayDuroodCount'] ?? data['personal_today_durood'] ?? data['todayCount']) as num?)?.toInt() ?? 0)
        : 0;

    final int effectivePersonalToday = firestorePersonalToday > _snapshot.personalToday
        ? firestorePersonalToday
        : _snapshot.personalToday;

    // 4. DUROOD POINTS: Parse across all field variations (total_durood_points, durood_points, duroodPoints, points)
    final int firestorePoints = ((data['total_durood_points'] ??
        data['durood_points'] ??
        data['duroodPoints'] ??
        data['points']) as num?)?.toInt() ?? 0;

    // Never downgrade Durood points to 0 if local points exist!
    final int effectivePoints = _pendingBuffer > 0 || _snapshot.duroodPoints > firestorePoints
        ? _snapshot.duroodPoints
        : firestorePoints;

    _updateSnapshot(CounterSnapshot(
      globalTotal: _snapshot.globalTotal,
      globalToday: _snapshot.globalToday,
      personalTotal: effectivePersonalTotal,
      personalToday: effectivePersonalToday,
      currentStreak: effectiveStreak,
      duroodPoints: effectivePoints,
    ));

    _saveToStorage();
  }

  Future<void> _resetGlobalTodayInFirestore(String todayStr) async {
    try {
      await _firestore.collection('counters').doc('durood_stats').set({
        'todayTotal': 0,
        'date': todayStr,
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
    final todayStr = _todayDateString;
    final updatedMyToday = _snapshot.personalToday + count;
    final updatedStreak = _snapshot.currentStreak <= 0 ? 1 : _snapshot.currentStreak;
    final updatedPoints = _snapshot.duroodPoints + (count * 2);

    // 1. Optimistically update in-memory state
    _updateSnapshot(CounterSnapshot(
      globalTotal: _snapshot.globalTotal + count,
      globalToday: _snapshot.globalToday + count,
      personalTotal: _snapshot.personalTotal + count,
      personalToday: updatedMyToday,
      currentStreak: updatedStreak,
      duroodPoints: updatedPoints,
    ));

    // 2. Immediately persist to SharedPreferences under user-specific daily key
    final userKey = _todayKey;
    _prefs?.setInt(userKey, updatedMyToday);
    final uid = _activeUid ?? _auth.currentUser?.uid;
    if (uid != null && uid != 'guest') {
      _prefs?.setInt('my_durood_${uid}_$todayStr', updatedMyToday);
      _prefs?.setInt('${_keyPersonalTotal}_$uid', _snapshot.personalTotal);
      _prefs?.setInt('${_keyStreak}_$uid', updatedStreak);
      _prefs?.setInt('${_keyPoints}_$uid', updatedPoints);
    }
    _prefs?.setInt('$_prefixMyDurood$todayStr', updatedMyToday);
    _prefs?.setInt('$_prefixMyTodayLegacy$todayStr', updatedMyToday);
    _prefs?.setString(_keyMyDuroodDate, todayStr);
    _prefs?.setInt(_keyStreak, updatedStreak);
    _prefs?.setInt(_keyPoints, updatedPoints);
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
      final todayStr = _todayDateString;
      final batch = _firestore.batch();

      // 1. Global counter update with midnight check
      final globalRef = _firestore.collection('counters').doc('durood_stats');
      final globalSnap = await globalRef.get();
      final globalData = globalSnap.data() ?? {};
      final String? globalDate = (globalData['date'] ?? globalData['lastUpdatedDate'] ?? globalData['last_reset_date'])?.toString();

      if (globalDate != todayStr) {
        // First user recitation after 12:00 AM midnight:
        // Reset todayTotal to count, update date, and increment globalTotal
        batch.set(
          globalRef,
          {
            'globalTotal': FieldValue.increment(count),
            'todayTotal': count,
            'date': todayStr,
            'lastUpdatedDate': todayStr,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } else {
        // Same day: atomically increment both globalTotal and todayTotal
        batch.set(
          globalRef,
          {
            'globalTotal': FieldValue.increment(count),
            'todayTotal': FieldValue.increment(count),
            'date': todayStr,
            'lastUpdatedDate': todayStr,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      // 2. User Private Subcollection & Profile updates
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        final userRef = _firestore.collection('users').doc(uid);
        final dailyStatRef = userRef.collection('daily_stats').doc(todayStr);

        // Subcollection: users/{userId}/daily_stats/{dateString}
        batch.set(
          dailyStatRef,
          {
            'myToday': FieldValue.increment(count),
            'todayDuroodCount': FieldValue.increment(count),
            'todayCount': FieldValue.increment(count),
            'count': FieldValue.increment(count),
            'date': todayStr,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        final userSnap = await userRef.get();
        final data = userSnap.data() ?? {};
        final lastActive = data['lastDuroodDate'] ??
            data['last_active_durood_date'] ??
            data['last_active_timestamp'] ??
            data['last_active_date'] ??
            data['last_durood_at'];

        final currentStoredStreak = ((data['current_streak'] ?? data['streak'] ?? data['daily_streak']) as num?)?.toInt() ?? 0;
        final longestStoredStreak = ((data['longest_streak'] ?? data['best_streak']) as num?)?.toInt() ?? currentStoredStreak;

        // Ensure currentStoredStreak is at least the local current streak
        final effectiveStoredStreak = currentStoredStreak > _snapshot.currentStreak
            ? currentStoredStreak
            : _snapshot.currentStreak;

        final streakUpdates = StreakHelper.computeStreakOnDuroodRecitation(
          currentStoredStreak: effectiveStoredStreak,
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
            'durood_points': FieldValue.increment(count * 2),
            'points': FieldValue.increment(count * 2),
            'last_active_durood_date': todayStr,
            'last_active_timestamp': FieldValue.serverTimestamp(),
            'last_durood_at': FieldValue.serverTimestamp(),
            ...streakUpdates,
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();
    } catch (e) {
      if (kDebugMode) print('CounterService.flushImmediately error: $e');
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
    final todayStr = _todayDateString;
    final storedDate = _prefs?.getString(_keyMyDuroodDate);
    if (storedDate != null && (storedDate != todayStr || storedDate.compareTo(todayStr) < 0)) {
      // Midnight has elapsed while app was in background
      final userKey = _getUserTodayKey(_activeUid ?? _auth.currentUser?.uid, todayStr);
      _prefs?.setString(_keyMyDuroodDate, todayStr);
      _prefs?.setInt(userKey, 0);
      _prefs?.setInt('$_prefixMyDurood$todayStr', 0);
      _prefs?.setInt('$_prefixMyTodayLegacy$todayStr', 0);
      _updateSnapshot(_snapshot.copyWith(
        personalToday: 0,
        globalToday: 0,
      ));
      _saveToStorage();

      // Re-bind daily stats stream for current user on new day
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        _listenToUserDailyStats(uid);
      }
    }
  }

  // ── Reset ───────────────────────────────────────────────────

  Future<void> resetPersonalToday() async {
    final todayStr = _todayDateString;
    _updateSnapshot(_snapshot.copyWith(personalToday: 0));
    final userKey = _getUserTodayKey(_activeUid ?? _auth.currentUser?.uid, todayStr);
    await _prefs?.setInt(userKey, 0);
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
        'myToday': 0,
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
    _userDailySub?.cancel();
    if (!_snapshotController.isClosed) {
      _snapshotController.close();
    }
    super.dispose();
  }
}
