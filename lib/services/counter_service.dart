import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
}

class CounterService extends ChangeNotifier {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

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

  CounterService() {
    _startStreams();
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
    // 1. Global counter stream
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

        _userSub = _firestore.collection('users').doc(user.uid).snapshots().listen((snap) {
          if (snap.exists && snap.data() != null) {
            _processUserSnap(snap.data()!);
          }
        }, onError: (e) {
          if (kDebugMode) print('CounterService user stream error: $e');
        });
      } else {
        _updateSnapshot(CounterSnapshot(
          globalTotal: _snapshot.globalTotal,
          globalToday: _snapshot.globalToday,
          personalTotal: 0,
          personalToday: 0,
          currentStreak: 0,
          duroodPoints: 0,
        ));
      }
    });
  }

  void _processGlobalSnap(Map<String, dynamic> data) {
    final todayStr = StreakHelper.toCalendarDateString(DateTime.now());
    final lastReset = data['lastUpdatedDate'] ?? data['last_reset_date'];
    final isSameDay = StreakHelper.isSameDay(lastReset, todayStr);

    final int globalTodayCount = isSameDay ? ((data['todayTotal'] ?? data['today_count']) as num?)?.toInt() ?? 0 : 0;
    final int globalTotalCount = ((data['globalTotal'] ?? data['total_count']) as num?)?.toInt() ?? 0;

    _updateSnapshot(CounterSnapshot(
      globalTotal: globalTotalCount,
      globalToday: globalTodayCount,
      personalTotal: _snapshot.personalTotal,
      personalToday: _snapshot.personalToday,
      currentStreak: _snapshot.currentStreak,
      duroodPoints: _snapshot.duroodPoints,
    ));

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

    _updateSnapshot(CounterSnapshot(
      globalTotal: _snapshot.globalTotal,
      globalToday: _snapshot.globalToday,
      personalTotal: (data['personal_total_durood'] as num?)?.toInt() ?? 0,
      personalToday: isSameDay ? ((data['personal_today_durood'] as num?)?.toInt() ?? 0) : 0,
      currentStreak: effectiveStreak,
      duroodPoints: (data['total_durood_points'] as num?)?.toInt() ?? 0,
    ));
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

  /// Buffer a tap locally, notify UI immediately, flush to Firestore after 2s.
  void increment(int count) {
    _pendingBuffer += count;
    // Optimistically update UI
    _updateSnapshot(CounterSnapshot(
      globalTotal: _snapshot.globalTotal + count,
      globalToday: _snapshot.globalToday + count,
      personalTotal: _snapshot.personalTotal + count,
      personalToday: _snapshot.personalToday + count,
      currentStreak: _snapshot.currentStreak == 0 ? 1 : _snapshot.currentStreak,
      duroodPoints: _snapshot.duroodPoints + (count * 2),
    ));

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), _flushBuffer);
  }

  Future<void> _flushBuffer() async {
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
      final isGlobalNewDay = globalLastReset == null || !StreakHelper.isSameDay(globalLastReset, todayStr);

      if (isGlobalNewDay) {
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
      } else {
        batch.set(
          globalRef,
          {
            'globalTotal': FieldValue.increment(count),
            'todayTotal': FieldValue.increment(count),
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
            'total_durood_points': FieldValue.increment(count * 2),
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
      if (kDebugMode) print('CounterService._flushBuffer error: $e');
      // Re-add to buffer so counts aren't lost on network glitch
      _pendingBuffer += count;
    }
  }

  // ── Reset ───────────────────────────────────────────────────

  Future<void> resetPersonalToday() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestore.collection('users').doc(uid).set({
        'personal_today_durood': 0,
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) print('CounterService.resetPersonalToday error: $e');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _authSub?.cancel();
    _globalSub?.cancel();
    _userSub?.cancel();
    _snapshotController.close();
    super.dispose();
  }
}
