import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/masail_model.dart';
import '../models/aqaid_model.dart';
import '../models/daily_content_model.dart';
import '../models/event_model.dart';

class FirestoreSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Checks essential Firestore collections (`masail_entries`, `aqaid_entries`, `daily_content`, `events`, `counters`).
  ///
  /// If a collection already contains documents (`count > 0`), seeding is skipped for that collection.
  /// If a collection is empty (`count == 0`), default data is safely seeded.
  static Future<Map<String, dynamic>> checkAndSeedFirestore({bool force = false}) async {
    final Map<String, dynamic> results = {
      'masail_entries': {'count': 0, 'seeded': false, 'status': ''},
      'aqaid_entries': {'count': 0, 'seeded': false, 'status': ''},
      'daily_content': {'count': 0, 'seeded': false, 'status': ''},
      'events': {'count': 0, 'seeded': false, 'status': ''},
      'counters': {'count': 0, 'seeded': false, 'status': ''},
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
      } else {
        final batch = _firestore.batch();
        for (var m in _initialMasailSeed) {
          final docRef = _firestore.collection('masail_entries').doc(m.id);
          batch.set(docRef, m.toMap(), SetOptions(merge: true));
        }
        await batch.commit();
        results['masail_entries']['seeded'] = true;
        results['masail_entries']['status'] = 'Seeded ${_initialMasailSeed.length} items';
      }

      // 2. Check & Seed Aqaid Entries
      final aqaidSnap = await _firestore.collection('aqaid_entries').get();
      final aqaidCount = aqaidSnap.docs.length;
      results['aqaid_entries']['count'] = aqaidCount;

      if (aqaidCount > 0 && !force) {
        results['aqaid_entries']['status'] = 'Skipped (Already has $aqaidCount docs)';
      } else {
        final batch = _firestore.batch();
        for (var a in _initialAqaidSeed) {
          final docRef = _firestore.collection('aqaid_entries').doc(a.id);
          batch.set(docRef, a.toMap(), SetOptions(merge: true));
        }
        await batch.commit();
        results['aqaid_entries']['seeded'] = true;
        results['aqaid_entries']['status'] = 'Seeded ${_initialAqaidSeed.length} items';
      }

      // 3. Check & Seed Daily Content
      final dailySnap = await _firestore.collection('daily_content').get();
      final dailyCount = dailySnap.docs.length;
      results['daily_content']['count'] = dailyCount;

      if (dailyCount > 0 && !force) {
        results['daily_content']['status'] = 'Skipped (Already has $dailyCount docs)';
        const defaultHadith = DailyContentModel(
          id: 'default_hadith',
          type: 'hadith',
          title: 'Virtue of Sending Durood',
          titleUr: 'درود شریف کی فضیلت',
          arabicText: 'مَنْ صَلَّى عَلَيَّ وَاحِدَةً صَلَّى اللهُ عَلَيْهِ عَشْرًا',
          content: 'He who sends a single Salawat upon me, Allah will send ten blessings upon him.',
          contentUr: 'جس نے مجھ پر ایک مرتبہ درود بھیجا، اللہ تعالیٰ اس پر دس رحمتیں نازل فرمائے گا۔',
          citation: 'Sahih Muslim (408)',
          citationUr: 'صحیح مسلم (۴۰۸)',
          isActive: true,
          isTopicOfTheDay: true,
        );

        const defaultAyat = DailyContentModel(
          id: 'default_ayat',
          type: 'ayat',
          title: 'Commandment of Sending Durood & Salam',
          titleUr: 'درود و سلام بھیجنے کا قرآنی حکم',
          arabicText: 'إِنَّ اللَّهَ وَمَلَائِكَتَهُ يُصَلُّونَ عَلَى النَّبِيِّ ۚ يَا أَيُّهَا الَّذِينَ آمَنُوا صَلُّوا عَلَيْهِ وَسَلِّمُوا تَسْلِيمًا',
          content: 'Indeed, Allah and His angels send blessings upon the Prophet. O you who have believed, ask [Allah to confer] blessing upon him and ask [Allah to grant him] peace.',
          contentUr: 'بے شک اللہ اور اس کے فرشتے نبی پر درود بھیجتے ہیں۔ اے ایمان والو! تم بھی ان پر درود اور خوب سلام بھیجو۔',
          citation: 'Surah Al-Ahzab (33:56)',
          citationUr: 'سورۃ الاحزاب (۳۳:۵۶)',
          isActive: true,
          isTopicOfTheDay: true,
        );

        final batch = _firestore.batch();
        batch.set(
          _firestore.collection('daily_content').doc(defaultHadith.id),
          defaultHadith.toMap(),
          SetOptions(merge: true),
        );
        batch.set(
          _firestore.collection('daily_content').doc(defaultAyat.id),
          defaultAyat.toMap(),
          SetOptions(merge: true),
        );
        await batch.commit();
        results['daily_content']['seeded'] = true;
        results['daily_content']['status'] = 'Seeded default Hadith & Ayat';
      }


      // 4. Check & Seed Events
      final eventsSnap = await _firestore.collection('events').get();
      final eventsCount = eventsSnap.docs.length;
      results['events']['count'] = eventsCount;

      if (eventsCount > 0 && !force) {
        results['events']['status'] = 'Skipped (Already has $eventsCount docs)';
      } else {
        final batch = _firestore.batch();
        for (var e in _initialEventsSeed) {
          final docRef = _firestore.collection('events').doc(e.id);
          batch.set(docRef, e.toMap(), SetOptions(merge: true));
        }
        await batch.commit();
        results['events']['seeded'] = true;
        results['events']['status'] = 'Seeded ${_initialEventsSeed.length} events';
      }

      // 5. Check & Seed Global Counter in 'global_counter/main'
      final counterRef = _firestore.collection('global_counter').doc('main');
      final counterSnap = await counterRef.get();
      results['counters'] = {'count': counterSnap.exists ? 1 : 0};

      if (!counterSnap.exists || force) {
        await recalculateAndSyncGlobalCounter();
        results['counters']['seeded'] = true;
        results['counters']['status'] = 'Cleaned & seeded global_counter/main';
      } else {
        final d = counterSnap.data();
        final currentTotal = d?['globalTotal'] ?? d?['total_count'];
        // Purge corrupted values (e.g. 100000510003818, stale 125000, or redundant fields)
        final hasCorruptedData = currentTotal == null ||
            currentTotal == 125000 ||
            (currentTotal is num && currentTotal > 1000000000) ||
            (d != null && (d.containsKey('total_count') || d.containsKey('todayDurood') || d.containsKey('today_count')));

        if (hasCorruptedData) {
          await recalculateAndSyncGlobalCounter();
          results['counters']['status'] = 'Purged corrupted fields and reset to true aggregated count';
        } else {
          results['counters']['status'] = 'Skipped (Already clean)';
        }
      }

      // Automatically purge/delete redundant counters/durood_stats if it exists
      try {
        final legacyDoc = await _firestore.collection('counters').doc('durood_stats').get();
        if (legacyDoc.exists) {
          await _firestore.collection('counters').doc('durood_stats').delete();
        }
      } catch (_) {}

      // 6. Check & Seed Launch Campaign Popup
      final popupRef = _firestore.collection('settings').doc('launch_popup');
      final popupSnap = await popupRef.get();
      if (!popupSnap.exists || force) {
        final defaultPopupData = {
          'isActive': true,
          'titleEnglish': "Rabi'ul Awwal 2026",
          'titleUrdu': 'ربیع الاول ۱۴۴۸ / ۲۰۲۶',
          'detailsEnglish': 'Complete Durood, Shamail, Seerah, and courses to win prizes!',
          'detailsUrdu': 'انعامات جیتنے کے لیے درود پاک، شمائل، سیرت اور کورسز مکمل کریں!',
          'buttonTextEnglish': 'Get Started',
          'buttonTextUrdu': 'شروع کریں',
          'targetRoute': '/events',
          'imageType': 'url',
          'imageUrl': '',
          'imageBase64': '',
          'updatedAt': FieldValue.serverTimestamp(),
        };
        await popupRef.set(defaultPopupData, SetOptions(merge: true));
        await _firestore.collection('app_popups').doc('launch_popup').set(defaultPopupData, SetOptions(merge: true));
        results['launch_popup'] = {'seeded': true, 'status': 'Seeded default launch popup'};
      } else {
        results['launch_popup'] = {'seeded': false, 'status': 'Skipped (Already exists)'};
      }

      return results;
    } catch (e) {
      if (kDebugMode) print('[Seeder] Firestore inspection error: $e');
      return {'error': e.toString()};
    }
  }

  /// Aggregates all users' personal_total_durood and today's Durood from Firestore
  /// and writes clean, standardized baseline numbers into global_counter/main.
  /// Overwrites the document completely to purge any corrupted/duplicate fields.
  static Future<Map<String, dynamic>> recalculateAndSyncGlobalCounter() async {
    try {
      final todayStr = DateTime.now().toIso8601String().split('T').first;
      final usersSnap = await _firestore.collection('users').get();
      int aggregatedTotal = 0;
      int aggregatedToday = 0;

      for (final doc in usersSnap.docs) {
        final data = doc.data();
        final userTotal = ((data['personal_total_durood'] ?? data['total_durood_count'] ?? data['total_count']) as num?)?.toInt() ?? 0;
        aggregatedTotal += userTotal;

        final lastActive = (data['lastActiveDate'] ?? data['last_active_durood_date'] ?? data['lastDuroodDate'])?.toString();
        if (lastActive != null && lastActive.startsWith(todayStr)) {
          final userToday = ((data['myToday'] ?? data['personal_today_durood'] ?? data['today_count']) as num?)?.toInt() ?? 0;
          aggregatedToday += userToday;
        }
      }

      final payload = <String, dynamic>{
        'globalTotal': aggregatedTotal,
        'todayTotal': aggregatedToday,
        'date': todayStr,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Set without merge: wipes corrupted fields like 100000510003818 and duplicate field names
      await _firestore.collection('global_counter').doc('main').set(payload);
      return payload;
    } catch (e) {
      if (kDebugMode) print('[Seeder] recalculateAndSyncGlobalCounter error: $e');
      return {};
    }
  }

  /// Sets initial baseline starting numbers for global counter.
  static Future<bool> updateGlobalCounterBaseline({
    int totalCount = 0,
    int todayCount = 0,
  }) async {
    try {
      final todayStr = DateTime.now().toIso8601String().split('T').first;
      await _firestore.collection('global_counter').doc('main').set({
        'globalTotal': totalCount,
        'todayTotal': todayCount,
        'date': todayStr,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) print('[Seeder] Error updating global counter baseline: $e');
      return false;
    }
  }

  static Future<bool> seedDefaultDataToFirestore({bool force = false}) async {
    final res = await checkAndSeedFirestore(force: force);
    return !res.containsKey('error');
  }

  // ── Initial Seed Collections ───────────────────────────────────

  static const List<MasailItemModel> _initialMasailSeed = [
    MasailItemModel(
      id: 'namaz_1',
      categoryId: 'namaz',
      question: 'What should one do if Sajda Sahw is forgotten in Salah?',
      questionUr: 'اگر نماز میں سجدہ سہو بھول جائے تو کیا حکم ہے؟',
      answer: 'If the person turned their chest away from the Qibla or spoke after the initial Salam, they must repeat the entire prayer. If they remembered immediately while facing the Qibla, they can perform two Sajdahs, recite Tashahhud, and conclude with Salam.',
      answerUr: 'اگر قبلہ سے سینہ پھر گیا یا کلام کر لیا تو نماز کا اعادہ واجب ہے۔ اگر سلام پھیرنے کے بعد یاد آ جائے اور کوئی منافی عمل نہ کیا ہو تو فورا سجدہ سہو کر کے تشہد پڑھ کر سلام پھیر دے۔',
      book: 'Bahar-e-Shariat, Vol. 1, Page 710',
      bookUr: 'بہارِ شریعت، حصہ ۴، صفحہ ۷۱۰',
    ),
    MasailItemModel(
      id: 'namaz_2',
      categoryId: 'namaz',
      question: 'Is it permissible to perform Salah while wearing socks with holes?',
      questionUr: 'کیا سوراخ والی جرابوں میں نماز ادا ہو جاتی ہے؟',
      answer: 'Normal thin cotton or nylon socks with small tears do not invalidate prayer as long as the total exposed skin of the required body area (Satr) does not equal or exceed the width of three fingers during a single pillar.',
      answerUr: 'عام سوتی یا نائلون کی جرابوں پر اگر چھوٹا سوراخ ہو تو نماز ادا ہو جائے گی، بشرطیکہ وہ تین انگلیوں کے برابر نہ کھلا ہو۔',
      book: 'Fatawa Razawiyya, Vol. 7, Page 245',
      bookUr: 'فتاویٰ رضویہ، جلد ۷، صفحہ ۲۴۵',
    ),
    MasailItemModel(
      id: 'wuzu_1',
      categoryId: 'wuzu',
      question: 'Does bleeding from gums invalidate Wuzu?',
      questionUr: 'کیا مسوڑھوں سے خون نکلنے سے وضو ٹوٹ جاتا ہے؟',
      answer: 'If the blood is equal to or more prominent than the saliva (indicated by yellow or reddish color upon spitting), Wuzu is invalidated. If saliva remains predominantly clear or slightly yellowish, Wuzu remains intact.',
      answerUr: 'اگر تھوک میں خون کا رنگ غالب یا برابر ہو (سرخی یا گہرا پن ہو) تو وضو ٹوٹ جاتا ہے۔ اگر تھوک غالب ہو اور زردی مائل ہو تو وضو نہیں ٹوٹتا۔',
      book: 'Al-Durr Al-Mukhtar, Vol. 1',
      bookUr: 'الدر المختار، جلد ۱',
    ),
    MasailItemModel(
      id: 'zakat_1',
      categoryId: 'zakat',
      question: 'Can Zakat be given to close relatives?',
      questionUr: 'کیا زکوٰۃ قریبی رشتہ داروں کو دی جا سکتی ہے؟',
      answer: 'Zakat cannot be given to direct ascendants (parents, grandparents) or direct descendants (children, grandchildren) nor between spouses. It CAN be given to needy brothers, sisters, uncles, aunts, and cousins, which earns double reward (charity + upholding family ties).',
      answerUr: 'زکوٰۃ اپنے اصول (ماں، باپ، دادا وغیرہ) اور فروع (بیٹا، بیٹی، پوتا وغیرہ) اور میاں بیوی ایک دوسرے کو نہیں دے سکتے۔ بھائی، بہن، چچا، ماموں، خالہ اگر مستحق ہوں تو انہیں دینا جائز اور دگنے ثواب کا باعث ہے۔',
      book: 'Radd al-Muhtar, Vol. 2',
      bookUr: 'رد المحتار، جلد ۲',
    ),
  ];

  static const List<AqaidItemModel> _initialAqaidSeed = [
    AqaidItemModel(
      id: 'aq_1',
      categoryId: 'tawheed',
      title: 'Tawheed: Absolute Oneness of Allah',
      titleUr: 'توحید: اللہ تعالیٰ کی یکتائی اور صفات',
      arabicText: 'قُلْ هُوَ اللَّهُ أَحَدٌ',
      explanation: 'Allah Almighty is One in His Being, Attributes, and Actions. He has no partner, equal, or associate. He alone is Eternal, without beginning or end, and all creation is dependent upon Him.',
      explanationUr: 'اللہ تعالیٰ اپنی ذات، صفات اور افعال میں یکتا و بے مثال ہے۔ اس کا کوئی شریک یا ہمسر نہیں۔ وہ ازلی و ابدی ہے اور تمام کائنات اس کی محتاج ہے۔',
      book: 'Surah Al-Ikhlas (112:1-4)',
      bookUr: 'سورۃ الاخلاص (۱-۴)',
    ),
    AqaidItemModel(
      id: 'aq_2',
      categoryId: 'risalat',
      title: 'Finality of Prophethood (Khatam-an-Nabiyyin)',
      titleUr: 'عقیدہ ختمِ نبوت (خاتم النبیین)',
      arabicText: 'مَّا كَانَ مُحَمَّدٌ أَبَا أَحَدٍ مِّن رِّجَالِكُمْ وَلَٰكِن رَّسُولَ اللَّهِ وَخَاتَمَ النَّبِيِّينَ',
      explanation: 'Prophet Muhammad (ﷺ) is the final and ultimate Messenger of Allah. No new prophet will ever come after him until the Day of Judgment. Believing in the finality of his Prophethood is an essential article of Islamic faith.',
      explanationUr: 'سیدنا محمد رسول اللہ صلی اللہ علیہ وآلہ وسلم اللہ کے آخری نبی ہیں۔ آپ کے بعد قیامت تک کوئی نیا نبی نہیں آ سکتا۔ ختمِ نبوت پر ایمان لانا ہر مسلمان پر فرضِ عین ہے۔',
      book: 'Surah Al-Ahzab (33:40)',
      bookUr: 'سورۃ الاحزاب (۴۰)',
    ),
    AqaidItemModel(
      id: 'aq_3',
      categoryId: 'ahle_sunnat',
      title: 'Love and Reverence for the Noble Ahl al-Bayt and Sahaba',
      titleUr: 'اہل ِ بیتِ اطہار اور صحابہ کرام سے محبت',
      arabicText: 'أَصْحَابِي كَالنُّجُومِ بِأَيِّهِمُ اقْتَدَيْتُمُ اهْتَدَيْتُمْ',
      explanation: 'The authentic creed of Ahle Sunnat requires profound love and reverence for the pure Ahl al-Bayt (family of the Prophet) and all the noble Sahaba (Companions). Slandering or disrespecting any Companion is strictly prohibited.',
      explanationUr: 'اہل ِ سنت والجماعت کا عقیدہ ہے کہ تمام صحابہ کرام عادل و باوقار ہیں اور اہلِ بیتِ اطہار سے محبت ایمان کا حصہ ہے۔ کسی بھی صحابی کی تنقیص گمراہی ہے۔',
      book: 'Sharh Al-Aqaid Al-Nasafiyya',
      bookUr: 'شرح العقائد النسفیہ',
    ),
  ];

  static const List<EventModel> _initialEventsSeed = [
    EventModel(
      id: '1',
      title: 'Global Milad Gathering 2026',
      titleUr: 'عالمی اجتماعِ میلاد النبی ۲۰۲۶ء',
      dateTime: 'Dec 24, 8:00 PM',
      location: 'Jamia Masjid Al-Aksa, Main Hall',
      locationUr: 'جامع مسجد الاقصیٰ، مرکزی ہال',
      status: 'Featured',
      description: 'Join millions globally in a collective recitation of Durood Shareef leading up to the blessed month of Rabi al-Awwal.',
      descriptionUr: 'ربیع الاول کے مبارک مہینے کی آمد کی خوشی میں دنیا بھر کے لاکھوں مسلمانوں کے ساتھ اجتماعی درود پاک پڑھنے کی محفل میں شرکت فرمائیں۔',
    ),
    EventModel(
      id: '2',
      title: 'Weekly Jumu\'ah Durood Majlis',
      titleUr: 'ہفتہ وار جمعۃ المبارک درود مجلس',
      dateTime: 'Every Friday after Asr',
      location: 'Live Stream & Central Masjid',
      locationUr: 'لائیو اسٹریم و مرکزی جامع مسجد',
      status: 'Ongoing',
      description: 'Sending special Salawat upon Prophet Muhammad (ﷺ) on the blessed day of Friday.',
      descriptionUr: 'جمعۃ المبارک کے بابرکت دن نمازِ عصر کے بعد نبی کریم صلی اللہ علیہ وآلہ وسلم کی بارگاہ میں خصوصی درود و سلام نذر کرنا۔',
    ),
    EventModel(
      id: '3',
      title: 'Ramadan Preparation & Durood Drive',
      titleUr: 'استقبالِ رمضان و درود شریف مہم',
      dateTime: 'Mar 15, 6:30 PM',
      location: 'Islamic Cultural Center Auditorium',
      locationUr: 'اسلامک کلچرل سینٹر آڈیٹوریم',
      status: 'Coming Soon',
      description: 'Preparing our hearts for Ramadan through Durood, Istighfar, and lectures on Fiqh.',
      descriptionUr: 'درود پاک، استغفار اور فتاویٰ و مسائل کے بیانات کے ذریعے رمضان المبارک کے لیے دلوں کی تیاری۔',
    ),
  ];
}
