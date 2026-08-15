import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../dummy_data/mock_masail.dart';
import '../dummy_data/mock_aqaid.dart';
import '../dummy_data/mock_events.dart';
import '../models/masail_model.dart';
import '../models/aqaid_model.dart';
import '../models/daily_content_model.dart';
import '../models/event_model.dart';

class FirestoreSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Checks essential Firestore collections (`masail_entries`, `aqaid_entries`, `daily_content`, `events`, `global_counter`).
  ///
  /// If a collection already contains documents (`count > 0`), seeding is skipped for that collection.
  /// If a collection is empty (`count == 0`), default data is safely seeded.
  static Future<Map<String, dynamic>> checkAndSeedFirestore({bool force = false}) async {
    final Map<String, dynamic> results = {
      'masail_entries': {'count': 0, 'seeded': false, 'status': ''},
      'aqaid_entries': {'count': 0, 'seeded': false, 'status': ''},
      'daily_content': {'count': 0, 'seeded': false, 'status': ''},
      'events': {'count': 0, 'seeded': false, 'status': ''},
      'global_counter': {'count': 0, 'seeded': false, 'status': ''},
    };

    try {
      if (kDebugMode) {
        print('===========================================================');
        print('[Seeder] Starting Automated Firestore Collection Inspection');
        print('===========================================================');
      }

      // 1. Check & Seed Masail Entries
      final masailSnap = await _firestore.collection('masail_entries').get();
      final masailCount = masailSnap.docs.length;
      results['masail_entries']['count'] = masailCount;

      if (masailCount > 0 && !force) {
        results['masail_entries']['status'] = 'Skipped (Already has $masailCount docs)';
        if (kDebugMode) {
          print('[Seeder] Collection masail_entries already has data ($masailCount docs). Skipping.');
        }
      } else {
        final batch = _firestore.batch();
        for (var m in MockMasailData.items) {
          final docRef = _firestore.collection('masail_entries').doc(m.id);
          final itemModel = MasailItemModel(
            id: m.id,
            categoryId: m.categoryId,
            question: m.question,
            questionUr: m.questionUr,
            answer: m.answer,
            answerUr: m.answerUr,
            book: m.book,
            bookUr: m.bookUr,
          );
          batch.set(docRef, itemModel.toMap(), SetOptions(merge: true));
        }
        await batch.commit();
        results['masail_entries']['seeded'] = true;
        results['masail_entries']['status'] = 'Seeded ${MockMasailData.items.length} items';
        if (kDebugMode) {
          print('[Seeder] Collection masail_entries seeded successfully (${MockMasailData.items.length} items).');
        }
      }

      // 2. Check & Seed Aqaid Entries
      final aqaidSnap = await _firestore.collection('aqaid_entries').get();
      final aqaidCount = aqaidSnap.docs.length;
      results['aqaid_entries']['count'] = aqaidCount;

      if (aqaidCount > 0 && !force) {
        results['aqaid_entries']['status'] = 'Skipped (Already has $aqaidCount docs)';
        if (kDebugMode) {
          print('[Seeder] Collection aqaid_entries already has data ($aqaidCount docs). Skipping.');
        }
      } else {
        final batch = _firestore.batch();
        for (var a in MockAqaidData.items) {
          final docRef = _firestore.collection('aqaid_entries').doc(a.id);
          final itemModel = AqaidItemModel(
            id: a.id,
            categoryId: a.categoryId,
            title: a.title,
            titleUr: a.titleUr,
            arabicText: a.arabicText,
            explanation: a.explanation,
            explanationUr: a.explanationUr,
            book: a.book,
            bookUr: a.bookUr,
          );
          batch.set(docRef, itemModel.toMap(), SetOptions(merge: true));
        }
        await batch.commit();
        results['aqaid_entries']['seeded'] = true;
        results['aqaid_entries']['status'] = 'Seeded ${MockAqaidData.items.length} items';
        if (kDebugMode) {
          print('[Seeder] Collection aqaid_entries seeded successfully (${MockAqaidData.items.length} items).');
        }
      }

      // 3. Check & Seed Daily Content
      final dailySnap = await _firestore.collection('daily_content').get();
      final dailyCount = dailySnap.docs.length;
      results['daily_content']['count'] = dailyCount;

      if (dailyCount > 0 && !force) {
        results['daily_content']['status'] = 'Skipped (Already has $dailyCount docs)';
        if (kDebugMode) {
          print('[Seeder] Collection daily_content already has data ($dailyCount docs). Skipping.');
        }
      } else {
        const defaultHadith = DailyContentModel(
          id: 'default_hadith',
          type: 'hadith',
          title: 'Virtue of Sending Durood',
          titleUr: 'درود شریف کی فضیلت',
          arabicText: 'مَنْ صَلَّى عَلَيَّ وَاحِدَةً صَلَّى اللهُ عَلَيْهِ عَشْرًا',
          content:
              'Whoever sends blessings upon me once, Allah will send blessings upon him ten times.',
          contentUr:
              'جو شخص مجھ پر ایک بار درود بھیجتا ہے، اللہ تعالیٰ اس پر دس رحمتیں نازل فرماتا ہے۔',
          citation: 'Sahih Muslim 408',
          citationUr: 'صحیح مسلم ۴۰۸',
          isActive: true,
        );
        await _firestore.collection('daily_content').doc(defaultHadith.id).set(
              defaultHadith.toMap(),
              SetOptions(merge: true),
            );
        results['daily_content']['seeded'] = true;
        results['daily_content']['status'] = 'Seeded default Hadith';
        if (kDebugMode) {
          print('[Seeder] Collection daily_content seeded successfully.');
        }
      }

      // 4. Check & Seed Events
      final eventsSnap = await _firestore.collection('events').get();
      final eventsCount = eventsSnap.docs.length;
      results['events']['count'] = eventsCount;

      if (eventsCount > 0 && !force) {
        results['events']['status'] = 'Skipped (Already has $eventsCount docs)';
        if (kDebugMode) {
          print('[Seeder] Collection events already has data ($eventsCount docs). Skipping.');
        }
      } else {
        final batch = _firestore.batch();
        for (var e in MockEventsData.events) {
          final docRef = _firestore.collection('events').doc(e.id);
          final eventModel = EventModel(
            id: e.id,
            title: e.title,
            titleUr: e.titleUr,
            dateTime: e.dateTime,
            location: e.location,
            locationUr: e.locationUr,
            status: e.status,
            description: e.description,
            descriptionUr: e.descriptionUr,
          );
          batch.set(docRef, eventModel.toMap(), SetOptions(merge: true));
        }
        await batch.commit();
        results['events']['seeded'] = true;
        results['events']['status'] = 'Seeded ${MockEventsData.events.length} events';
        if (kDebugMode) {
          print('[Seeder] Collection events seeded successfully (${MockEventsData.events.length} items).');
        }
      }

      // 5. Check & Seed Global Counter
      final counterRef = _firestore.collection('global_counter').doc('main');
      final counterSnap = await counterRef.get();
      results['global_counter']['count'] = counterSnap.exists ? 1 : 0;

      if (counterSnap.exists && !force) {
        results['global_counter']['status'] = 'Skipped (Already exists)';
        if (kDebugMode) {
          print('[Seeder] Collection global_counter already has main doc. Skipping.');
        }
      } else {
        final todayStr = DateTime.now().toIso8601String().split('T').first;
        await counterRef.set({
          'total_count': 125000,
          'today_count': 4820,
          'last_reset_date': todayStr,
          'created_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        results['global_counter']['seeded'] = true;
        results['global_counter']['status'] = 'Seeded global counter main doc';
        if (kDebugMode) {
          print('[Seeder] Collection global_counter main doc seeded successfully.');
        }
      }

      if (kDebugMode) {
        print('===========================================================');
        print('[Seeder] Firestore Inspection & Seeding Complete');
        print('===========================================================');
      }

      return results;
    } catch (e) {
      if (kDebugMode) {
        print('[Seeder] Firestore inspection error: $e');
      }
      return {'error': e.toString()};
    }
  }

  /// Sets initial baseline starting numbers for global counter.
  static Future<bool> updateGlobalCounterBaseline({
    int totalCount = 125000,
    int todayCount = 4820,
  }) async {
    try {
      final todayStr = DateTime.now().toIso8601String().split('T').first;
      await _firestore.collection('global_counter').doc('main').set({
        'total_count': totalCount,
        'today_count': todayCount,
        'last_reset_date': todayStr,
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (kDebugMode) {
        print('[Seeder] Global counter baseline set to total_count: $totalCount, today_count: $todayCount');
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('[Seeder] Error updating global counter baseline: $e');
      return false;
    }
  }

  /// Legacy helper method for backwards compatibility.
  static Future<bool> seedDefaultDataToFirestore({bool force = false}) async {
    final res = await checkAndSeedFirestore(force: force);
    return !res.containsKey('error');
  }
}
