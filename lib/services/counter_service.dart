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
  /// my_today_${userId}_${todayDateString}
  String get _todayKey {
    final uid = _auth.currentUser?.uid ?? _activeUid ?? 'guest';
    final today = _todayDateString;
    return 'my_today_${uid}_$today';
  }

  /// Computes isolated SharedPreferences key for user's personal count today:
  /// my_today_${userId}_${todayDateString}
  static String _getUserTodayKey(String? uid, String dateStr) {
    final effectiveUid = (uid != null && uid.isNotEmpty) ? uid : 'guest';
    return 'my_today_${effectiveUid}_$dateStr';
  }

  // --- State ---
  CounterSnapshot _snapshot = const CounterSnapshot();
  CounterSnapshot get snapshot => _snapshot;

  final StreamController<CounterSnapshot> _snapshotController =
      StreamController<CounterSnapshot>.broadcast();

  /// Reactive stream emitting latest CounterSnapshot whenever counts update.
  Stream<CounterSnapshot> get snapshotStream => _snapshotController.stream;

  // Exposed live streams for UI StreamBuilders
  /// Stream of global counter document snapshots ('global_counter/main').
  Stream<DocumentSnapshot<Map<String, dynamic>>> get globalCounterStream =>
      _firestore.collection('global_counter').doc('main').snapshots();

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
  int get pendingBuffer => _pendingBuffer;
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

    // 1. Global totals from cache with corruption purge
    final cachedGlobalDate = prefs.getString(_keyGlobalDate);
    final isGlobalSameDay = StreakHelper.isSameDay(cachedGlobalDate, todayStr);
    final rawGlobalTotal = prefs.getInt(_keyGlobalTotal) ?? _snapshot.globalTotal;
    final int globalTotal = (rawGlobalTotal > 1000000000 || rawGlobalTotal < 0) ? 0 : rawGlobalTotal;
    if (rawGlobalTotal != globalTotal) {
      prefs.remove(_keyGlobalTotal);
    }

    final rawGlobalToday = prefs.getInt(_keyGlobalToday) ?? _snapshot.globalToday;
    final int globalToday = isGlobalSameDay
        ? ((rawGlobalToday > 1000000000 || rawGlobalToday < 0) ? 0 : rawGlobalToday)
        : 0;
    if (rawGlobalToday != globalToday) {
      prefs.remove(_keyGlobalToday);
    }

    // 2. User-specific "My Today" from isolated key 'my_today_${userId}_${todayDateString}'
    final storedDate = prefs.getString(_keyMyDuroodDate);
    final activeUid = _auth.currentUser?.uid ?? prefs.getString(_keyActiveUid) ?? _activeUid;
    _activeUid = activeUid;

    final int myToday;
    if (storedDate != null && (storedDate != todayStr || storedDate.compareTo(todayStr) < 0)) {
      // Midnight transition (current date > stored key date): reset "My Today" count to 0 and update storedDate
      myToday = 0;
      prefs.setInt(_todayKey, 0);
      if (activeUid != null) {
        prefs.setInt('my_today_${activeUid}_$todayStr', 0);
        prefs.setInt('my_durood_${activeUid}_$todayStr', 0);
      }
      prefs.setInt('$_prefixMyDurood$todayStr', 0);
      prefs.setString(_keyMyDuroodDate, todayStr);
    } else {
      // Same day: read user-isolated key immediately
      final rawMyToday = _readMyTodayFromPrefs(prefs, todayStr);
      myToday = (rawMyToday > 1000000000 || rawMyToday < 0) ? 0 : rawMyToday;
      prefs.setString(_keyMyDuroodDate, todayStr);
    }

    // 3. Personal Total strictly from user-isolated key
    final rawPersonalTotal = (activeUid != null && activeUid != 'guest')
        ? (prefs.getInt('my_total_$activeUid') ?? prefs.getInt('${_keyPersonalTotal}_$activeUid') ?? 0)
        : 0;
    final int personalTotal = (rawPersonalTotal > 1000000000 || rawPersonalTotal < 0) ? 0 : rawPersonalTotal;
    // Purge deprecated shared key if present to avoid cross-user contamination
    if (prefs.containsKey(_keyPersonalTotal)) {
      prefs.remove(_keyPersonalTotal);
    }

    // 4. Streak from user key or global fallback
    final rawCachedStreak = (activeUid != null && activeUid != 'guest')
        ? (prefs.getInt('user_streak_$activeUid') ?? prefs.getInt('${_keyStreak}_$activeUid') ?? prefs.getInt(_keyStreak) ?? _snapshot.currentStreak)
        : (prefs.getInt(_keyStreak) ?? _snapshot.currentStreak);

    final cachedLastStreakDate = (activeUid != null && activeUid != 'guest')
        ? (prefs.getString('last_streak_date_$activeUid') ?? prefs.getString('last_active_date_$activeUid') ?? storedDate)
        : storedDate;

    final effectiveCachedStreak = StreakHelper.calculateEffectiveStreak(
      storedStreak: rawCachedStreak,
      lastActiveDate: cachedLastStreakDate,
    );
    final streak = effectiveCachedStreak > 0
        ? effectiveCachedStreak
        : (myToday > 0 ? (rawCachedStreak > 0 ? rawCachedStreak : 1) : 0);

    // 5. Durood Points from user key or global fallback
    final rawPoints = (activeUid != null && activeUid != 'guest')
        ? (prefs.getInt('durood_points_$activeUid') ?? prefs.getInt('${_keyPoints}_$activeUid') ?? prefs.getInt(_keyPoints) ?? _snapshot.duroodPoints)
        : (prefs.getInt(_keyPoints) ?? _snapshot.duroodPoints);
    final int points = (rawPoints > 1000000000 || rawPoints < 0) ? 0 : rawPoints;

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
    final uid = _activeUid ?? _auth.currentUser?.uid ?? 'guest';
    if (uid == 'guest') return 0;

    // 0. Primary unified key: my_today_${userId}_${todayDateString}
    final unifiedVal = prefs.getInt('my_today_${uid}_$todayStr');
    if (unifiedVal != null && unifiedVal > 0) return unifiedVal;

    // 1. User-isolated key
    final userKey = _todayKey;
    final primaryVal = prefs.getInt(userKey);
    if (primaryVal != null && primaryVal > 0) return primaryVal;

    // 2. Active UID key if set
    final activeVal = prefs.getInt('my_durood_${uid}_$todayStr');
    if (activeVal != null && activeVal > 0) return activeVal;

    return 0;
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs = prefs;
      final todayStr = _todayDateString;
      final userKey = _todayKey;
      final uid = _activeUid ?? _auth.currentUser?.uid;

      if (_snapshot.globalTotal <= 1000000000 && _snapshot.globalTotal >= 0) {
        await prefs.setInt(_keyGlobalTotal, _snapshot.globalTotal);
      } else {
        await prefs.remove(_keyGlobalTotal);
      }
      if (_snapshot.globalToday <= 1000000000 && _snapshot.globalToday >= 0) {
        await prefs.setInt(_keyGlobalToday, _snapshot.globalToday);
      } else {
        await prefs.remove(_keyGlobalToday);
      }
      await prefs.setString(_keyGlobalDate, todayStr);
      await prefs.setInt(userKey, _snapshot.personalToday);
      if (uid != null && uid != 'guest') {
        await prefs.setInt('my_today_${uid}_$todayStr', _snapshot.personalToday);
        await prefs.setInt('my_total_$uid', _snapshot.personalTotal);
        await prefs.setInt('durood_points_$uid', _snapshot.duroodPoints);
        await prefs.setInt('user_streak_$uid', _snapshot.currentStreak);
        await prefs.setString('last_streak_date_$uid', todayStr);

        await prefs.setInt('my_durood_${uid}_$todayStr', _snapshot.personalToday);
        await prefs.setInt('${_keyPersonalTotal}_$uid', _snapshot.personalTotal);
        await prefs.setInt('${_keyStreak}_$uid', _snapshot.currentStreak);
        await prefs.setInt('${_keyPoints}_$uid', _snapshot.duroodPoints);
        await prefs.setString('last_active_date_$uid', todayStr);
      }
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

    // 1. Global counter stream ('global_counter/main')
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

        // Authoritative cloud count + any active uncommitted pending buffer
        final int effectiveMyToday = cloudMyToday + _pendingBuffer;

        if (effectiveMyToday != _snapshot.personalToday) {
          _updateSnapshot(_snapshot.copyWith(personalToday: effectiveMyToday));
        }
        _prefs?.setInt(userKey, effectiveMyToday);
        if (_activeUid != null && _activeUid != 'guest') {
          _prefs?.setInt('my_today_${_activeUid}_$todayStr', effectiveMyToday);
          _prefs?.setInt('my_durood_${_activeUid}_$todayStr', effectiveMyToday);
        }
        _prefs?.setString(_keyMyDuroodDate, todayStr);
      } else {
        // Document does not exist yet in Firestore today:
        final int effectiveMyToday = _pendingBuffer;
        if (effectiveMyToday != _snapshot.personalToday) {
          _updateSnapshot(_snapshot.copyWith(personalToday: effectiveMyToday));
        }
        _prefs?.setInt(userKey, effectiveMyToday);
        if (_activeUid != null && _activeUid != 'guest') {
          _prefs?.setInt('my_today_${_activeUid}_$todayStr', effectiveMyToday);
          _prefs?.setInt('my_durood_${_activeUid}_$todayStr', effectiveMyToday);
        }
      }
    }, onError: (e) {
      if (kDebugMode) print('CounterService user daily stats stream error: $e');
    });
  }

  void _processGlobalSnap(Map<String, dynamic> data) {
    final todayStr = _todayDateString;
    final docDate = (data['date'] ?? data['last_reset_date'] ?? data['lastUpdatedDate'])?.toString();
    final isSameDay = docDate == todayStr;

    final int rawFirestoreToday = isSameDay
        ? (((data['todayTotal'] ?? data['today_count'] ?? data['globalToday']) as num?)?.toInt() ?? 0)
        : 0;
    final int firestoreToday = (rawFirestoreToday > 1000000000 || rawFirestoreToday < 0) ? 0 : rawFirestoreToday;

    final int rawFirestoreTotal = ((data['globalTotal'] ?? data['total_count']) as num?)?.toInt() ?? 0;
    final int firestoreTotal = (rawFirestoreTotal > 1000000000 || rawFirestoreTotal < 0) ? 0 : rawFirestoreTotal;

    // Detect if local snapshot was corrupted with astronomical numbers (> 1 billion)
    final bool isCorrupted = _snapshot.globalTotal > 1000000000 ||
        _snapshot.globalTotal < 0 ||
        _snapshot.globalToday > 1000000000 ||
        _snapshot.globalToday < 0;

    // Detect if database was cleaned/reset or has a massive discrepancy (> 10,000)
    final bool largeDiscrepancy = (_snapshot.globalTotal - firestoreTotal).abs() > 10000;

    final int effectiveGlobalTotal;
    final int effectiveGlobalToday;

    if (isCorrupted || largeDiscrepancy || _pendingBuffer <= 0) {
      // Authoritative cloud value (+ any pending local buffer)
      effectiveGlobalTotal = firestoreTotal + _pendingBuffer;
      effectiveGlobalToday = isSameDay ? (firestoreToday + _pendingBuffer) : 0;
    } else {
      // Retain optimistic increments if local is close to firestore and not corrupted
      effectiveGlobalTotal = _snapshot.globalTotal >= firestoreTotal
          ? _snapshot.globalTotal
          : firestoreTotal;
      effectiveGlobalToday = isSameDay
          ? (_snapshot.globalToday >= firestoreToday ? _snapshot.globalToday : firestoreToday)
          : 0;
    }

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
    final dynamic rawStreakDateVal = data['lastStreakDate'];
    final dynamic rawStreakDate = (rawStreakDateVal is String && rawStreakDateVal.trim().isEmpty)
        ? null
        : rawStreakDateVal;

    final lastActive = rawStreakDate ??
        data['lastActiveDate'] ??
        data['lastDuroodDate'] ??
        data['last_active_durood_date'] ??
        data['last_active_timestamp'] ??
        data['last_active_date'] ??
        data['last_durood_at'];

    // 1. STREAK: Parse from streak, current_streak, or daily_streak
    final int rawStreak = ((data['streak'] ??
        data['current_streak'] ??
        data['daily_streak']) as num?)?.toInt() ?? 0;

    // Snapchat-style streak calculation: 0 if last streak date is older than yesterday
    int effectiveStreak = StreakHelper.calculateEffectiveStreak(
      storedStreak: rawStreak,
      lastActiveDate: lastActive,
    );

    // If an optimistic pending buffer is actively being tapped, ensure at least 1
    if (_pendingBuffer > 0 && effectiveStreak == 0) {
      effectiveStreak = 1;
    }

    // 2. PERSONAL TOTAL: Firestore document is the authoritative Single Source of Truth
    final int firestorePersonalTotal = ((data['myTotal'] ??
        data['personal_total_durood'] ??
        data['total_durood_count'] ??
        data['personal_durood'] ??
        data['total_recitations'] ??
        data['total_count'] ??
        data['totalDurood']) as num?)?.toInt() ?? 0;

    // Single source of truth: Cloud count + any uncommitted pending taps
    final int effectivePersonalTotal = firestorePersonalTotal + _pendingBuffer;

    // 3. PERSONAL TODAY: If doc contains today count for same day and subcollection hasn't fired yet
    final bool isSameDay = StreakHelper.isSameDay(lastActive, todayStr);
    final int? firestorePersonalToday = isSameDay
        ? (((data['myToday'] ?? data['todayDuroodCount'] ?? data['personal_today_durood'] ?? data['todayCount']) as num?)?.toInt())
        : null;

    final int effectivePersonalToday = firestorePersonalToday != null
        ? (firestorePersonalToday + _pendingBuffer)
        : _snapshot.personalToday;

    // 4. DUROOD POINTS: Parse across all field variations
    final int firestorePoints = ((data['duroodPoints'] ??
        data['total_durood_points'] ??
        data['durood_points'] ??
        data['points']) as num?)?.toInt() ?? 0;

    final int effectivePoints = firestorePoints + _pendingBuffer;

    _updateSnapshot(CounterSnapshot(
      globalTotal: _snapshot.globalTotal,
      globalToday: _snapshot.globalToday,
      personalTotal: effectivePersonalTotal,
      personalToday: effectivePersonalToday,
      currentStreak: effectiveStreak,
      duroodPoints: effectivePoints,
    ));

    final uid = _activeUid ?? _auth.currentUser?.uid;
    if (uid != null && uid != 'guest') {
      _prefs?.setInt('my_total_$uid', effectivePersonalTotal);
      _prefs?.setInt('${_keyPersonalTotal}_$uid', effectivePersonalTotal);
      _prefs?.setInt('my_today_${uid}_$todayStr', effectivePersonalToday);
      _prefs?.setInt('durood_points_$uid', effectivePoints);
      _prefs?.setInt('${_keyPoints}_$uid', effectivePoints);
      _prefs?.setInt('user_streak_$uid', effectiveStreak);
      _prefs?.setInt('${_keyStreak}_$uid', effectiveStreak);
    }

    _saveToStorage();
  }

  Future<void> _resetGlobalTodayInFirestore(String todayStr) async {
    try {
      final payload = {
        'todayTotal': 0,
        'date': todayStr,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestore.collection('global_counter').doc('main').set(payload, SetOptions(merge: true));
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
    final updatedPoints = _snapshot.duroodPoints + count;

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
    final uid = _activeUid ?? _auth.currentUser?.uid ?? 'guest';
    _prefs?.setInt('my_today_${uid}_$todayStr', updatedMyToday);
    _prefs?.setInt('my_total_$uid', _snapshot.personalTotal + count);
    _prefs?.setInt('durood_points_$uid', updatedPoints);
    _prefs?.setInt('user_streak_$uid', updatedStreak);

    if (uid != 'guest') {
      _prefs?.setInt('my_durood_${uid}_$todayStr', updatedMyToday);
      _prefs?.setInt('${_keyPersonalTotal}_$uid', _snapshot.personalTotal + count);
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

      // 1. Global counter update strictly in global_counter/main with midnight check
      final globalRef = _firestore.collection('global_counter').doc('main');
      final globalSnap = await globalRef.get();
      final globalData = globalSnap.data() ?? {};
      final String? globalDate = (globalData['date'] ?? globalData['last_reset_date'] ?? globalData['lastUpdatedDate'])?.toString();

      final Map<String, dynamic> globalPayload = (globalDate != todayStr)
          ? {
              'globalTotal': FieldValue.increment(count),
              'todayTotal': count,
              'date': todayStr,
              'updatedAt': FieldValue.serverTimestamp(),
            }
          : {
              'globalTotal': FieldValue.increment(count),
              'todayTotal': FieldValue.increment(count),
              'date': todayStr,
              'updatedAt': FieldValue.serverTimestamp(),
            };

      batch.set(globalRef, globalPayload, SetOptions(merge: true));

      // 2. User Lifetime Update & User Daily Subcollection updates
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
        final lastActive = data['lastStreakDate'] ??
            data['lastActiveDate'] ??
            data['lastDuroodDate'] ??
            data['last_active_durood_date'];

        final currentStoredStreak = ((data['streak'] ?? data['current_streak'] ?? data['daily_streak']) as num?)?.toInt() ?? 0;
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
            'myTotal': FieldValue.increment(count),
            'duroodPoints': FieldValue.increment(count),
            'lastStreakDate': todayStr,
            'lastActiveDate': todayStr,
            // Legacy keys maintained for bidirectional compatibility
            'personal_total_durood': FieldValue.increment(count),
            'personal_today_durood': isUserNewDay ? count : FieldValue.increment(count),
            'myToday': isUserNewDay ? count : FieldValue.increment(count),
            'todayCount': isUserNewDay ? count : FieldValue.increment(count),
            'todayDuroodCount': isUserNewDay ? count : FieldValue.increment(count),
            'lastDuroodDate': todayStr,
            'total_durood_points': FieldValue.increment(count),
            'durood_points': FieldValue.increment(count),
            'points': FieldValue.increment(count),
            'last_active_durood_date': todayStr,
            'last_active_timestamp': FieldValue.serverTimestamp(),
            'last_durood_at': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
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
        'myToday': 0,
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
