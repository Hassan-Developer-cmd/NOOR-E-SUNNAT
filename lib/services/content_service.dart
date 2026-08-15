import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/models/masail_model.dart';
import '../core/models/aqaid_model.dart';
import '../core/models/daily_content_model.dart';
import '../core/dummy_data/mock_masail.dart';
import '../core/dummy_data/mock_aqaid.dart';

class ContentService {
  static final _firestore = FirebaseFirestore.instance;

  // ── Hadith / Ayat of the Day ─────────────────────────────────

  /// Live stream of the active Daily Hadith / Ayat of the Day.
  static Stream<DailyContentModel?> get dailyContentStream {
    return _firestore
        .collection('daily_content')
        .where('is_active', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isNotEmpty) {
        return DailyContentModel.fromMap(snap.docs.first.id, snap.docs.first.data());
      }
      return _defaultDailyContent;
    }).handleError((e) {
      if (kDebugMode) print('ContentService.dailyContentStream error: $e');
      return _defaultDailyContent;
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
      );

  // ── Masail ──────────────────────────────────────────────────

  /// Live stream of Masail items. Falls back to mock data if collection empty.
  static Stream<List<MasailItemModel>> get masailStream {
    return _firestore
        .collection('masail_entries')
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return _mockMasailItems;
      try {
        return snap.docs
            .map((doc) => MasailItemModel.fromMap(doc.id, doc.data()))
            .toList();
      } catch (e) {
        if (kDebugMode) print('ContentService.masailStream error: $e');
        return _mockMasailItems;
      }
    }).handleError((e) {
      if (kDebugMode) print('ContentService masail error: $e');
      return _mockMasailItems;
    });
  }

  // ── Aqaid ───────────────────────────────────────────────────

  /// Live stream of Aqaid items. Falls back to mock data if collection empty.
  static Stream<List<AqaidItemModel>> get aqaidStream {
    return _firestore
        .collection('aqaid_entries')
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return _mockAqaidItems;
      try {
        return snap.docs
            .map((doc) => AqaidItemModel.fromMap(doc.id, doc.data()))
            .toList();
      } catch (e) {
        if (kDebugMode) print('ContentService.aqaidStream error: $e');
        return _mockAqaidItems;
      }
    }).handleError((e) {
      if (kDebugMode) print('ContentService aqaid error: $e');
      return _mockAqaidItems;
    });
  }

  // ── Fallback helpers & Category filtering ──────────────────────

  /// Always returns standard fixed category list from MockMasailData
  static List<MasailCategory> getCategories() {
    return MockMasailData.categories;
  }

  /// Always returns standard Aqaid categories from MockAqaidData
  static List<AqaidCategory> getAqaidCategories() {
    return MockAqaidData.categories;
  }

  static List<MasailItemModel> getMasailByCategory(List<MasailItemModel> firestoreList, String categoryId) {
    final filtered = firestoreList.where((m) => m.categoryId == categoryId).toList();
    if (filtered.isNotEmpty) return filtered;
    final mockFiltered = _mockMasailItems.where((m) => m.categoryId == categoryId).toList();
    if (mockFiltered.isNotEmpty) return mockFiltered;
    return _mockMasailItems;
  }

  static List<AqaidItemModel> getAqaidByCategory(List<AqaidItemModel> firestoreList, String categoryId) {
    final filtered = firestoreList.where((a) => a.categoryId == categoryId).toList();
    if (filtered.isNotEmpty) return filtered;
    final mockFiltered = _mockAqaidItems.where((a) => a.categoryId == categoryId).toList();
    if (mockFiltered.isNotEmpty) return mockFiltered;
    return _mockAqaidItems;
  }

  static List<MasailItemModel> get _mockMasailItems {
    return MockMasailData.items
        .map((m) => MasailItemModel(
              id: m.id,
              categoryId: m.categoryId,
              question: m.question,
              questionUr: m.questionUr,
              answer: m.answer,
              answerUr: m.answerUr,
              citation: m.citation,
              citationUr: m.citationUr,
              referenceBook: m.referenceBook,
              referenceBookUr: m.referenceBookUr,
            ))
        .toList();
  }

  static List<AqaidItemModel> get _mockAqaidItems {
    return MockAqaidData.items
        .map((a) => AqaidItemModel(
              id: a.id,
              categoryId: a.categoryId,
              title: a.title,
              titleUr: a.titleUr,
              arabicText: a.arabicText,
              explanation: a.explanation,
              explanationUr: a.explanationUr,
              reference: a.reference,
              referenceUr: a.referenceUr,
            ))
        .toList();
  }
}

