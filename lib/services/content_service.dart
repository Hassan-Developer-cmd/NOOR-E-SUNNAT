import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/models/masail_model.dart';
import '../core/models/aqaid_model.dart';
import '../core/models/daily_content_model.dart';

class ContentService {
  static final _firestore = FirebaseFirestore.instance;

  // ── Hadith / Ayat of the Day & Topic of the Day ────────────

  /// Live stream of the active Daily Hadith / Ayat or Topic of the Day.
  static Stream<DailyContentModel?> get dailyContentStream {
    return _firestore
        .collection('daily_content')
        .snapshots()
        .map((snap) {
      if (snap.docs.isNotEmpty) {
        // Priority 1: Topic of the day
        final topicDoc = snap.docs.where((d) => d.data()['is_topic_of_the_day'] == true).firstOrNull;
        if (topicDoc != null) {
          return DailyContentModel.fromMap(topicDoc.id, topicDoc.data());
        }
        // Priority 2: is_active == true
        final activeDoc = snap.docs.where((d) => d.data()['is_active'] == true).firstOrNull;
        if (activeDoc != null) {
          return DailyContentModel.fromMap(activeDoc.id, activeDoc.data());
        }
        // Fallback: newest document
        return DailyContentModel.fromMap(snap.docs.first.id, snap.docs.first.data());
      }
      return _defaultDailyContent;
    }).handleError((e) {
      if (kDebugMode) print('ContentService.dailyContentStream error: $e');
      return _defaultDailyContent;
    });
  }

  /// Live stream of all historical Daily Hadith & Ayat documents (Archive).
  static Stream<List<DailyContentModel>> get allDailyContentHistoryStream {
    return _firestore
        .collection('daily_content')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => DailyContentModel.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) {
        final aTime = a.createdAt ?? a.scheduledDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? b.scheduledDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime); // newest first
      });
      return list.isNotEmpty ? list : [_defaultDailyContent];
    }).handleError((e) {
      if (kDebugMode) print('ContentService.allDailyContentHistoryStream error: $e');
      return [_defaultDailyContent];
    });
  }

  static DailyContentModel get _defaultDailyContent => const DailyContentModel(
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
        isTopicOfTheDay: true,
      );

  // ── Masail ──────────────────────────────────────────────────

  /// Live stream of Masail items from Firestore.
  static Stream<List<MasailItemModel>> get masailStream {
    return _firestore
        .collection('masail_entries')
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((doc) => MasailItemModel.fromMap(doc.id, doc.data()))
          .toList();
    }).handleError((e) {
      if (kDebugMode) print('ContentService masail error: $e');
      return <MasailItemModel>[];
    });
  }

  // ── Aqaid ───────────────────────────────────────────────────

  /// Live stream of Aqaid items from Firestore.
  static Stream<List<AqaidItemModel>> get aqaidStream {
    return _firestore
        .collection('aqaid_entries')
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((doc) => AqaidItemModel.fromMap(doc.id, doc.data()))
          .toList();
    }).handleError((e) {
      if (kDebugMode) print('ContentService aqaid error: $e');
      return <AqaidItemModel>[];
    });
  }

  // ── Category Definitions & Filtering ──────────────────────────

  /// Returns standard category list for Masail
  static List<MasailCategory> getCategories() {
    return MasailCategory.defaultCategories;
  }

  /// Returns standard category list for Aqaid
  static List<AqaidCategory> getAqaidCategories() {
    return AqaidCategory.defaultCategories;
  }

  static List<MasailItemModel> getMasailByCategory(List<MasailItemModel> firestoreList, String categoryId) {
    return firestoreList.where((m) => m.categoryId == categoryId).toList();
  }

  static List<AqaidItemModel> getAqaidByCategory(List<AqaidItemModel> firestoreList, String categoryId) {
    return firestoreList.where((a) => a.categoryId == categoryId).toList();
  }
}
