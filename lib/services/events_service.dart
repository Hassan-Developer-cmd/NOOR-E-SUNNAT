import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/models/event_model.dart';
import '../core/dummy_data/mock_events.dart';

class EventsService {
  static final _firestore = FirebaseFirestore.instance;

  /// Live stream of events from Firestore. Falls back to mock data if empty.
  static Stream<List<EventModel>> get eventsStream {
    return _firestore
        .collection('events')
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return _fallback;
      try {
        return snap.docs
            .map((doc) => EventModel.fromMap(doc.id, doc.data()))
            .toList();
      } catch (e) {
        if (kDebugMode) print('EventsService.eventsStream parse error: $e');
        return _fallback;
      }
    }).handleError((e) {
      if (kDebugMode) print('EventsService stream error: $e');
      return _fallback;
    });
  }

  /// Converts the existing mock events into EventModel for the fallback.
  static List<EventModel> get _fallback {
    return MockEventsData.events
        .map((e) => EventModel(
              id: e.id,
              title: e.title,
              dateTime: e.dateTime,
              location: e.location,
              status: e.status,
              description: e.description,
            ))
        .toList();
  }
}
