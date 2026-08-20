import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/models/event_model.dart';

class EventsService {
  static final _firestore = FirebaseFirestore.instance;

  /// Live stream of events directly from Firestore with administrator arrangement ordering.
  static Stream<List<EventModel>> get eventsStream {
    return _firestore.collection('events').snapshots().map((snap) {
      final List<EventModel> list = [];
      for (final doc in snap.docs) {
        try {
          final data = doc.data();
          list.add(EventModel.fromMap(doc.id, data));
        } catch (e) {
          if (kDebugMode) {
            print('EventsService: Error parsing event document ${doc.id}: $e');
          }
        }
      }

      // Priority fallback ranking: Ongoing/Live (0), Featured (1), Coming Soon (2), Completed (3), Cancelled (4)
      int statusRank(String s) {
        switch (s.toLowerCase().trim()) {
          case 'ongoing':
            return 0;
          case 'featured':
            return 1;
          case 'coming soon':
            return 2;
          case 'completed':
            return 3;
          case 'cancelled':
            return 4;
          default:
            return 2;
        }
      }

      DateTime parseSafeDate(dynamic raw) {
        if (raw == null) return DateTime.fromMillisecondsSinceEpoch(0);
        if (raw is Timestamp) return raw.toDate();
        if (raw is DateTime) return raw;
        if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
        if (raw is String) {
          return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
        }
        return DateTime.fromMillisecondsSinceEpoch(0);
      }

      list.sort((a, b) {
        // 1. Primary sort: Administrator arrangement order (#1, #2, #3, ...)
        final bool aHasOrder = a.order > 0;
        final bool bHasOrder = b.order > 0;

        if (aHasOrder && bHasOrder) {
          if (a.order != b.order) return a.order.compareTo(b.order);
        } else if (aHasOrder) {
          return -1;
        } else if (bHasOrder) {
          return 1;
        }

        // 2. Secondary fallback: Status rank
        final rankA = statusRank(a.status);
        final rankB = statusRank(b.status);
        if (rankA != rankB) return rankA.compareTo(rankB);

        // 3. Tertiary fallback: Creation time (newest first)
        final DateTime aTime = parseSafeDate(a.createdAt);
        final DateTime bTime = parseSafeDate(b.createdAt);
        return bTime.compareTo(aTime);
      });

      return list;
    }).handleError((e) {
      if (kDebugMode) print('EventsService stream error: $e');
      return <EventModel>[];
    });
  }
}
