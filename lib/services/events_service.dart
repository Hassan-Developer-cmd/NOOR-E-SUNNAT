import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/models/event_model.dart';

class EventsService {
  static final _firestore = FirebaseFirestore.instance;

  /// Live stream of events directly from Firestore.
  static Stream<List<EventModel>> get eventsStream {
    return _firestore
        .collection('events')
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((doc) => EventModel.fromMap(doc.id, doc.data()))
          .toList();
    }).handleError((e) {
      if (kDebugMode) print('EventsService stream error: $e');
      return <EventModel>[];
    });
  }
}
