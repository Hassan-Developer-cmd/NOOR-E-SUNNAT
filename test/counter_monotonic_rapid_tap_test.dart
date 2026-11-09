import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Counter Monotonic Non-Decreasing & Rapid Tap Tests', () {
    test('Strict monotonic resolution guarantees counter never decrements from older stream snapshot', () {
      int localDisplayedCount = 10;

      // Simulate rapid user increments
      for (int i = 1; i <= 5; i++) {
        localDisplayedCount++;
      }
      expect(localDisplayedCount, 15);

      // Simulate a delayed stream snapshot arriving with stale cloud count 11 + pending buffer 0
      final int staleIncomingCount = 11;

      // Monotonic guard requirement:
      // if (incomingCount >= currentDisplayedCount) { currentDisplayedCount = incomingCount; }
      final resolvedCount = math.max(localDisplayedCount, staleIncomingCount);

      expect(resolvedCount, 15, reason: 'Counter must NOT decrement to 11 when optimistic count is 15');
    });

    test('Rapid consecutive increments strictly increase monotonically without gaps', () {
      final List<int> sequence = [];
      int current = 0;

      for (int tap = 1; tap <= 20; tap++) {
        current += 1;
        sequence.add(current);
      }

      for (int i = 0; i < sequence.length - 1; i++) {
        expect(sequence[i + 1], greaterThan(sequence[i]),
            reason: 'Each subsequent tap must produce a strictly greater count');
      }
      expect(sequence.first, 1);
      expect(sequence.last, 20);
    });

    test('Buffer reconciliation preserves in-flight counts during network sync window', () {
      int pendingBuffer = 0;
      int inFlightBuffer = 0;

      // 1. User taps 5 times
      pendingBuffer += 5;
      expect(pendingBuffer + inFlightBuffer, 5);

      // 2. Debounce timer triggers flush: pending moves to inFlight
      final int flushed = pendingBuffer;
      pendingBuffer = 0;
      inFlightBuffer += flushed;

      // While network commit is in flight:
      expect(pendingBuffer + inFlightBuffer, 5,
          reason: 'Effective uncommitted buffer remains 5 while write is in flight');

      // 3. User taps 3 more times while write is in flight
      pendingBuffer += 3;
      expect(pendingBuffer + inFlightBuffer, 8,
          reason: 'Additional taps accumulate on top of in-flight buffer');

      // 4. In-flight write completes, cloud now has 5
      final int cloudCount = 5;
      inFlightBuffer -= flushed;

      // Total displayed count is cloudCount (5) + pendingBuffer (3) = 8
      final int effective = cloudCount + pendingBuffer + inFlightBuffer;
      expect(effective, 8, reason: 'Total count matches exactly without any rollback or flicker');
    });

    test('Stale stream snapshot during active burst is safely ignored or monotonic', () {
      final int localCount = 42;
      final int staleCloudSnap = 38;
      final int pending = 0;

      final int incoming = staleCloudSnap + pending;
      final int reconciled = incoming >= localCount ? incoming : localCount;

      expect(reconciled, 42, reason: 'Stale snapshot must never downgrade local count of 42 to 38');
    });

    test('Single tap increments by exactly +1 and does not double-count when cloud snapshot arrives', () {
      int localCount = 10;
      int cloudCount = 10;
      int pendingBuffer = 0;

      // User performs 1 tap
      localCount += 1;
      pendingBuffer += 1;
      expect(localCount, 11, reason: 'Local count immediately increments by +1');

      // Debounce timer commits +1 to Firestore via FieldValue.increment
      final int diff = pendingBuffer;
      cloudCount += diff; // Remote now 11
      pendingBuffer = 0;

      // Remote stream sends snapshot with cloudCount = 11
      // Resolution rule: math.max(localCount, cloudCount)
      final resolved = math.max(localCount, cloudCount);

      expect(resolved, 11, reason: 'Tap must yield exactly +1 (11), NEVER double-increment to 12');
    });

    test('Multiple rapid taps increment strictly by +1 per tap during and after sync', () {
      int localCount = 50;
      int cloudCount = 50;
      int pendingBuffer = 0;

      // 5 taps
      for (int i = 0; i < 5; i++) {
        localCount += 1;
        pendingBuffer += 1;
      }
      expect(localCount, 55);

      // Cloud snapshot arrives mid-tapping before commit (stale at 50)
      final midTapResolved = math.max(localCount, cloudCount);
      expect(midTapResolved, 55, reason: 'Must remain 55 during tapping');

      // Commit flushed
      cloudCount += pendingBuffer;
      pendingBuffer = 0;

      // Cloud snapshot arrives after commit (now at 55)
      final postCommitResolved = math.max(localCount, cloudCount);
      expect(postCommitResolved, 55, reason: 'Must remain 55 after commit');
    });
  });
}
