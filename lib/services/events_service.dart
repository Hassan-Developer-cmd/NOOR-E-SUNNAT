import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/models/event_model.dart';

class EventsService {
  static final _firestore = FirebaseFirestore.instance;

  /// Live stream of events directly from Firestore with administrator arrangement ordering.
  static Stream<List<EventModel>> get eventsStream {
    return _firestore.collection('events').snapshots().map((snap) {
      final list = snap.docs
          .map((doc) => EventModel.fromMap(doc.id, doc.data()))
          .toList();

      // Priority fallback ranking: Ongoing/Live (0), Featured (1), Coming Soon (2), Completed (3), Cancelled (4)
      int statusRank(String s) {
        switch (s.toLowerCase()) {
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
        final aCreated = a.createdAt;
        final bCreated = b.createdAt;
        final DateTime aTime = aCreated is Timestamp
            ? aCreated.toDate()
            : (aCreated is String ? DateTime.tryParse(aCreated) ?? DateTime.fromMillisecondsSinceEpoch(0) : DateTime.fromMillisecondsSinceEpoch(0));
        final DateTime bTime = bCreated is Timestamp
            ? bCreated.toDate()
            : (bCreated is String ? DateTime.tryParse(bCreated) ?? DateTime.fromMillisecondsSinceEpoch(0) : DateTime.fromMillisecondsSinceEpoch(0));
        return bTime.compareTo(aTime);
      });

      return list;
    }).handleError((e) {
      if (kDebugMode) print('EventsService stream error: $e');
      return <EventModel>[];
    });
  }
}
