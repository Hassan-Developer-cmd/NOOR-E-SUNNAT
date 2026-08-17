import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/models/masail_model.dart';
import '../core/models/aqaid_model.dart';
import '../core/models/daily_content_model.dart';

class ContentService {
  static final _firestore = FirebaseFirestore.instance;

  // ── Hadith / Ayat of the Day & Topic of the Day ────────────

  static final DailyContentModel defaultHadith = const DailyContentModel(
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
    isTopicOfTheDay: true,
  );

  static final DailyContentModel defaultAyat = const DailyContentModel(
    id: 'default_ayat',
    type: 'ayat',
    title: 'Commandment of Sending Durood & Salam',
    titleUr: 'درود و سلام بھیجنے کا قرآنی حکم',
    arabicText:
        'إِنَّ اللَّهَ وَمَلَائِكَتَهُ يُصَلُّونَ عَلَى النَّبِيِّ ۚ يَا أَيُّهَا الَّذِينَ آمَنُوا صَلُّوا عَلَيْهِ وَسَلِّمُوا تَسْلِيمًا',
    content:
        'Indeed, Allah and His angels send blessings upon the Prophet. O you who have believed, ask [Allah to confer] blessing upon him and ask [Allah to grant him] peace.',
    contentUr:
        'بے شک اللہ اور اس کے فرشتے نبی پر درود بھیجتے ہیں۔ اے ایمان والو! تم بھی ان پر درود اور خوب سلام بھیجو۔',
    citation: 'Surah Al-Ahzab (33:56)',
    citationUr: 'سورۃ الاحزاب (۳۳:۵۶)',
    isActive: true,
    isTopicOfTheDay: true,
  );

  static final DailyContentModel defaultTopicOfTheDay = const DailyContentModel(
    id: 'default_topic',
    type: 'topicOfTheDay',
    title: 'Virtue of Abundant Durood on Blessed Friday',
    titleUr: 'جمعۃ المبارک کے دن کثرت سے درود شریف پڑھنے کی فضیلت',
    arabicText: 'أَكْثِرُوا عَلَيَّ مِنَ الصَّلَاةِ فِي يَوْمِ الْجُمُعَةِ فَإِنَّ صَلَاتَكُمْ مَعْرُوضَةٌ عَلَيَّ',
    content:
        'Increase your recitations of Salawat upon me on Friday, for your Salawat are directly presented to me.',
    contentUr:
        'جمعہ کے دن مجھ پر کثرت سے درود بھیجا کرو، کیونکہ تمہارا درود مجھ پر پیش کیا جاتا ہے۔',
    citation: 'Sunan Abi Dawud 1047',
    citationUr: 'سنن ابی داؤد ۱۰۴۷',
    isActive: true,
    isTopicOfTheDay: true,
  );

  /// Live stream of active Daily Hadiths list (newest first).
  static Stream<List<DailyContentModel>> get dailyHadithsStream {
    return _firestore
        .collection('daily_content')
        .snapshots()
        .map((snap) {
      final items = snap.docs
          .map((doc) => DailyContentModel.fromMap(doc.id, doc.data()))
          .where((d) => d.isHadith && d.isActive)
          .toList();

      items.sort((a, b) {
        if (a.isTopicOfTheDay && !b.isTopicOfTheDay) return -1;
        if (!a.isTopicOfTheDay && b.isTopicOfTheDay) return 1;
        final aTime = a.createdAt ?? a.scheduledDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? b.scheduledDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      return items.isNotEmpty ? items : [defaultHadith];
    }).handleError((e) {
      if (kDebugMode) print('ContentService.dailyHadithsStream error: $e');
      return [defaultHadith];
    });
  }

  /// Live stream of active Daily Ayats list (newest first).
  static Stream<List<DailyContentModel>> get dailyAyatsStream {
    return _firestore
        .collection('daily_content')
        .snapshots()
        .map((snap) {
      final items = snap.docs
          .map((doc) => DailyContentModel.fromMap(doc.id, doc.data()))
          .where((d) => d.isAyat && d.isActive)
          .toList();

      items.sort((a, b) {
        if (a.isTopicOfTheDay && !b.isTopicOfTheDay) return -1;
        if (!a.isTopicOfTheDay && b.isTopicOfTheDay) return 1;
        final aTime = a.createdAt ?? a.scheduledDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? b.scheduledDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      return items.isNotEmpty ? items : [defaultAyat];
    }).handleError((e) {
      if (kDebugMode) print('ContentService.dailyAyatsStream error: $e');
      return [defaultAyat];
    });
  }

  /// Live stream of all active Topic of the Day entries.
  static Stream<List<DailyContentModel>> get topicsOfTheDayStream {
    return _firestore
        .collection('daily_content')
        .snapshots()
        .map((snap) {
      final items = snap.docs
          .map((doc) => DailyContentModel.fromMap(doc.id, doc.data()))
          .where((d) => d.isTopicOfTheDay && d.isActive)
          .toList();

      items.sort((a, b) {
        final aTime = a.createdAt ?? a.scheduledDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? b.scheduledDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      if (items.isNotEmpty) return items;
      return [defaultTopicOfTheDay, defaultHadith, defaultAyat];
    }).handleError((e) {
      if (kDebugMode) print('ContentService.topicsOfTheDayStream error: $e');
      return [defaultTopicOfTheDay, defaultHadith, defaultAyat];
    });
  }

  /// Live stream of single primary daily content item for legacy widgets.
  static Stream<DailyContentModel?> get dailyContentStream {
    return _firestore
        .collection('daily_content')
        .snapshots()
        .map((snap) {
      if (snap.docs.isNotEmpty) {
        // Priority 1: Topic of the day
        final topicDoc = snap.docs.where((d) => d.data()['is_topic_of_the_day'] == true && (d.data()['is_active'] as bool? ?? true)).firstOrNull;
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
      return defaultHadith;
    }).handleError((e) {
      if (kDebugMode) print('ContentService.dailyContentStream error: $e');
      return defaultHadith;
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
      return list.isNotEmpty ? list : [defaultHadith, defaultAyat];
    }).handleError((e) {
      if (kDebugMode) print('ContentService.allDailyContentHistoryStream error: $e');
      return [defaultHadith, defaultAyat];
    });
  }


  // ── Masail ──────────────────────────────────────────────────

  /// Live stream of Masail items from Firestore.
  static Stream<List<MasailItemModel>> get masailStream {
    try {
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
    } catch (_) {
      return Stream.value(<MasailItemModel>[]);
    }
  }

  // ── Aqaid ───────────────────────────────────────────────────

  /// Live stream of Aqaid items from Firestore.
  static Stream<List<AqaidItemModel>> get aqaidStream {
    try {
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
    } catch (_) {
      return Stream.value(<AqaidItemModel>[]);
    }
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
